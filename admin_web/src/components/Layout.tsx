import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth';

export default function Layout() {
  const { user, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();

  const linkClass = (path: string) =>
    `nav-link${location.pathname === path ? ' active' : ''}`;

  return (
    <div className="layout">
      <header className="layout-header">
        <div>
          <div className="logo">Jumandi</div>
          <span className="badge">ADMIN</span>
        </div>
        <nav className="layout-nav">
          <Link to="/" className={linkClass('/')}>
            Overview
          </Link>
          <Link to="/drivers" className={linkClass('/drivers')}>
            Drivers
          </Link>
          <Link to="/add-driver" className={linkClass('/add-driver')}>
            Add Driver
          </Link>
        </nav>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          <span className="muted" style={{ fontSize: '0.8rem' }}>
            {user?.name}
          </span>
          <button
            type="button"
            className="btn btn-ghost"
            onClick={() => {
              logout();
              navigate('/login');
            }}
          >
            Logout
          </button>
        </div>
      </header>
      <main className="layout-main">
        <Outlet />
      </main>
    </div>
  );
}
