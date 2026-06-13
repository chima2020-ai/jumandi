import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { login as apiLogin, type User } from './api';

const TOKEN_KEY = 'jumandi_admin_token';
const USER_KEY = 'jumandi_admin_user';

type AuthContextValue = {
  token: string | null;
  user: User | null;
  isAdmin: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  setSession: (token: string, user: User) => void;
};

const AuthContext = createContext<AuthContextValue | null>(null);

function loadStoredUser(): User | null {
  try {
    const raw = localStorage.getItem(USER_KEY);
    return raw ? (JSON.parse(raw) as User) : null;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(() => localStorage.getItem(TOKEN_KEY));
  const [user, setUser] = useState<User | null>(loadStoredUser);

  const setSession = useCallback((newToken: string, newUser: User) => {
    localStorage.setItem(TOKEN_KEY, newToken);
    localStorage.setItem(USER_KEY, JSON.stringify(newUser));
    setToken(newToken);
    setUser(newUser);
  }, []);

  const login = useCallback(
    async (email: string, password: string) => {
      const { token: t, user: u } = await apiLogin(email, password);
      if (u.role !== 'admin') {
        throw new Error('This account is not an admin');
      }
      setSession(t, u);
    },
    [setSession],
  );

  const logout = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    setToken(null);
    setUser(null);
  }, []);

  const value = useMemo(
    () => ({
      token,
      user,
      isAdmin: user?.role === 'admin',
      login,
      logout,
      setSession,
    }),
    [token, user, login, logout, setSession],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
