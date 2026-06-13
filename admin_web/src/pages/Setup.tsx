import { FormEvent, useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { getSetupStatus, setupAdmin } from '../api';
import { useAuth } from '../auth';

export default function SetupPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    getSetupStatus()
      .then((s) => {
        if (!s.needs_setup) navigate('/login');
      })
      .finally(() => setChecking(false));
  }, [navigate]);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (password !== confirm) {
      setError('Passwords do not match');
      return;
    }
    setError('');
    setLoading(true);
    try {
      await setupAdmin({ name: name.trim(), email: email.trim(), phone: phone.trim(), password });
      await login(email.trim(), password);
      navigate('/');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Setup failed');
    } finally {
      setLoading(false);
    }
  }

  if (checking) {
    return (
      <div className="auth-page">
        <p className="muted">Loading…</p>
      </div>
    );
  }

  return (
    <div className="auth-page">
      <div className="auth-wrap">
        <div className="auth-hero">
          <div className="auth-icon">+</div>
          <div className="logo">Jumandi</div>
          <h1 style={{ marginTop: '1rem', fontSize: '1.35rem' }}>Create admin</h1>
          <p className="muted">Set up the first admin account</p>
        </div>

        <form className="card" onSubmit={onSubmit}>
          <div className="field">
            <label htmlFor="name">FULL NAME</label>
            <input id="name" value={name} onChange={(e) => setName(e.target.value)} required />
          </div>
          <div className="field">
            <label htmlFor="email">EMAIL</label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="phone">PHONE</label>
            <input id="phone" value={phone} onChange={(e) => setPhone(e.target.value)} required />
          </div>
          <div className="field">
            <label htmlFor="password">PASSWORD</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              minLength={6}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="confirm">CONFIRM PASSWORD</label>
            <input
              id="confirm"
              type="password"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              required
            />
          </div>
          {error && <p className="error">{error}</p>}
          <button type="submit" className="btn btn-primary" disabled={loading}>
            {loading ? 'Creating…' : 'Create admin & sign in'}
          </button>
          <p style={{ textAlign: 'center', marginTop: '1rem' }}>
            <Link to="/login">Back to login</Link>
          </p>
        </form>
      </div>
    </div>
  );
}
