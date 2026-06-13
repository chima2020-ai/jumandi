import { FormEvent, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { createDeliveryAgent } from '../api';
import { useAuth } from '../auth';

export default function AddDriverPage() {
  const { token } = useAuth();
  const navigate = useNavigate();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!token) return;
    setError('');
    setSuccess('');
    setLoading(true);
    try {
      const agent = await createDeliveryAgent(token, {
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password,
      });
      setSuccess(`Driver ${agent.email} created! Share these login details with them.`);
      setName('');
      setEmail('');
      setPhone('');
      setPassword('');
      setTimeout(() => navigate('/drivers'), 2000);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not create driver');
    } finally {
      setLoading(false);
    }
  }

  return (
    <>
      <h1 className="page-title">Add delivery driver</h1>
      <p className="muted" style={{ marginBottom: '1.5rem' }}>
        Create login credentials. The driver uses these on the Jumandi app delivery login.
      </p>

      <form className="card card-accent" onSubmit={onSubmit} style={{ maxWidth: 520 }}>
        <div className="field">
          <label htmlFor="name">FULL NAME</label>
          <input id="name" value={name} onChange={(e) => setName(e.target.value)} required />
        </div>
        <div className="field">
          <label htmlFor="email">EMAIL (LOGIN)</label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="driver@jumandi.com"
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
            placeholder="Min 6 characters"
            required
          />
        </div>
        {error && <p className="error">{error}</p>}
        {success && <p style={{ color: 'var(--success)', marginBottom: '1rem' }}>{success}</p>}
        <button type="submit" className="btn btn-primary" disabled={loading}>
          {loading ? 'Creating…' : 'Create driver login'}
        </button>
      </form>
    </>
  );
}
