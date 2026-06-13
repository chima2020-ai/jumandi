import { FormEvent, useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { getSetupStatus } from '../api';
import { useAuth } from '../auth';

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [needsSetup, setNeedsSetup] = useState(false);

  useEffect(() => {
    getSetupStatus()
      .then((s) => setNeedsSetup(s.needs_setup))
      .catch(() => {});
  }, []);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(email.trim(), password);
      navigate('/');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-page">
      <div className="auth-wrap">
        <div className="auth-hero">
          <div className="auth-icon">⚙</div>
          <div className="logo">Jumandi</div>
          <div className="badge" style={{ marginTop: '0.5rem' }}>
            ADMIN PORTAL
          </div>
          <h1 style={{ marginTop: '1rem', fontSize: '1.35rem' }}>Sign in</h1>
          <p className="muted">Manage delivery drivers and accounts</p>
        </div>

        {needsSetup && (
          <div className="setup-banner">
            <p style={{ margin: '0 0 0.75rem' }}>No admin account yet.</p>
            <Link to="/setup" className="btn btn-primary" style={{ display: 'inline-flex', width: 'auto' }}>
              Create admin account
            </Link>
          </div>
        )}

        <form className="card" onSubmit={onSubmit}>
          <div className="field">
            <label htmlFor="email">ADMIN EMAIL</label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@jumandi.com"
              required
            />
          </div>
          <div className="field">
            <label htmlFor="password">PASSWORD</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          {error && <p className="error">{error}</p>}
          <button type="submit" className="btn btn-primary" disabled={loading}>
            {loading ? 'Signing in…' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  );
}
