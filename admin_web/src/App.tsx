import { Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider, useAuth } from './auth';
import Layout from './components/Layout';
import AddDriverPage from './pages/AddDriver';
import DashboardPage from './pages/Dashboard';
import DriversPage from './pages/Drivers';
import LoginPage from './pages/Login';
import SetupPage from './pages/Setup';

function PrivateRoute({ children }: { children: React.ReactNode }) {
  const { token, isAdmin } = useAuth();
  if (!token || !isAdmin) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/setup" element={<SetupPage />} />
      <Route
        element={
          <PrivateRoute>
            <Layout />
          </PrivateRoute>
        }
      >
        <Route path="/" element={<DashboardPage />} />
        <Route path="/drivers" element={<DriversPage />} />
        <Route path="/add-driver" element={<AddDriverPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <AppRoutes />
    </AuthProvider>
  );
}
