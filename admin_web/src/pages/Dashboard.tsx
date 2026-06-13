import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { listDeliveryAgents, type User } from '../api';
import { useAuth } from '../auth';

function AgentRow({ agent, onDelete }: { agent: User; onDelete: () => void }) {
  return (
    <div className="card agent-card">
      <div className="agent-avatar">{agent.name.charAt(0).toUpperCase()}</div>
      <div className="agent-info">
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: '0.5rem' }}>
          <span className="agent-name">{agent.name}</span>
          <span className={`status ${agent.is_available ? 'status-online' : 'status-offline'}`}>
            {agent.is_available ? 'Online' : 'Offline'}
          </span>
        </div>
        <div className="agent-meta">{agent.email}</div>
        <div className="agent-meta">{agent.phone}</div>
      </div>
      <button type="button" className="btn btn-danger" onClick={onDelete}>
        Delete
      </button>
    </div>
  );
}

export function useDrivers() {
  const { token } = useAuth();
  const [agents, setAgents] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const reload = async () => {
    if (!token) return;
    setLoading(true);
    setError('');
    try {
      setAgents(await listDeliveryAgents(token));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load drivers');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
  }, [token]);

  return { agents, loading, error, reload };
}

export default function DashboardPage() {
  const { user } = useAuth();
  const { agents, loading, error } = useDrivers();
  const online = agents.filter((a) => a.is_available).length;

  return (
    <>
      <h1 className="page-title">Welcome, {user?.name}</h1>
      <p className="muted" style={{ marginBottom: '1.5rem' }}>
        Manage delivery drivers and share login details with your team.
      </p>

      <div className="stat-grid" style={{ marginBottom: '1.5rem' }}>
        <div className="stat">
          <div className="stat-label">TOTAL DRIVERS</div>
          <div className="stat-value">{agents.length}</div>
        </div>
        <div className="stat">
          <div className="stat-label">ONLINE</div>
          <div className="stat-value">{online}</div>
        </div>
        <div className="stat">
          <div className="stat-label">OFFLINE</div>
          <div className="stat-value">{agents.length - online}</div>
        </div>
      </div>

      <div className="card card-accent" style={{ marginBottom: '1.5rem' }}>
        <h2 style={{ fontSize: '1rem', marginBottom: '0.5rem' }}>Quick actions</h2>
        <p className="muted" style={{ marginBottom: '1rem' }}>
          Create a driver account, then give them the email and password to sign in on the delivery app.
        </p>
        <Link to="/add-driver" className="btn btn-primary" style={{ maxWidth: 280 }}>
          + Add delivery driver
        </Link>
      </div>

      <h2 style={{ fontSize: '1.1rem', marginBottom: '0.75rem' }}>Recent drivers</h2>
      {loading && <p className="muted">Loading drivers…</p>}
      {error && <p className="error">{error}</p>}
      {!loading && agents.length === 0 && (
        <div className="card empty">No drivers yet. Add your first delivery driver.</div>
      )}
      <div className="agent-list">
        {agents.slice(0, 5).map((agent) => (
          <AgentRow key={agent.id} agent={agent} onDelete={() => {}} />
        ))}
      </div>
      {agents.length > 5 && (
        <p style={{ marginTop: '1rem' }}>
          <Link to="/drivers">View all drivers →</Link>
        </p>
      )}
    </>
  );
}
