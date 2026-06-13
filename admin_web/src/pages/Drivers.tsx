import { deleteDeliveryAgent } from '../api';
import { useAuth } from '../auth';
import { useDrivers } from './Dashboard';

export default function DriversPage() {
  const { token } = useAuth();
  const { agents, loading, error, reload } = useDrivers();

  async function handleDelete(id: number, name: string) {
    if (!token) return;
    if (!confirm(`Delete driver "${name}"? They will lose login access.`)) return;
    try {
      await deleteDeliveryAgent(token, id);
      await reload();
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Delete failed');
    }
  }

  return (
    <>
      <h1 className="page-title">Delivery drivers</h1>
      <p className="muted" style={{ marginBottom: '1.5rem' }}>
        {agents.length} driver{agents.length === 1 ? '' : 's'} registered
      </p>

      {loading && <p className="muted">Loading…</p>}
      {error && <p className="error">{error}</p>}

      {!loading && agents.length === 0 && (
        <div className="card empty">No drivers yet. Go to Add Driver to create one.</div>
      )}

      <div className="agent-list">
        {agents.map((agent) => (
          <div key={agent.id} className="card agent-card">
            <div className="agent-avatar">{agent.name.charAt(0).toUpperCase()}</div>
            <div className="agent-info">
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: '0.5rem' }}>
                <span className="agent-name">{agent.name}</span>
                <span className={`status ${agent.is_available ? 'status-online' : 'status-offline'}`}>
                  {agent.is_available ? 'Online' : 'Offline'}
                </span>
              </div>
              <div className="agent-meta">📧 {agent.email}</div>
              <div className="agent-meta">📱 {agent.phone}</div>
              <div className="agent-meta" style={{ marginTop: '0.5rem' }}>
                Share these login details with the driver for the Jumandi delivery app.
              </div>
            </div>
            <button
              type="button"
              className="btn btn-danger"
              onClick={() => handleDelete(agent.id, agent.name)}
            >
              Delete
            </button>
          </div>
        ))}
      </div>
    </>
  );
}
