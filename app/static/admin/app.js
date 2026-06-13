const API = '';
const TOKEN_KEY = 'jumandi_admin_token';
const USER_KEY = 'jumandi_admin_user';

function getToken() { return localStorage.getItem(TOKEN_KEY); }
function getUser() { try { return JSON.parse(localStorage.getItem(USER_KEY) || 'null'); } catch { return null; } }
function setSession(token, user) {
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(USER_KEY, JSON.stringify(user));
}
function clearSession() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}

async function api(path, options = {}) {
  const headers = { ...(options.headers || {}) };
  if (options.json) {
    headers['Content-Type'] = 'application/json';
    options.body = JSON.stringify(options.json);
  }
  const token = getToken();
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${API}${path}`, { ...options, headers });
  if (!res.ok) {
    let msg = 'Request failed';
    try {
      const d = await res.json();
      if (d.detail) {
        if (typeof d.detail === 'string') msg = d.detail;
        else if (Array.isArray(d.detail)) msg = d.detail.map(e => e.msg || e).join(', ');
      }
    } catch {}
    throw new Error(msg);
  }
  if (res.status === 204) return null;
  return res.json();
}

function path() {
  const p = window.location.pathname;
  if (p === '/admin' || p === '/admin/') return '/';
  if (p.startsWith('/admin/')) return p.slice('/admin'.length) || '/';
  return '/';
}

function nav(to) {
  window.history.pushState({}, '', '/admin' + (to === '/' ? '' : to));
  render();
}

window.addEventListener('popstate', render);

function el(html) {
  const t = document.createElement('template');
  t.innerHTML = html.trim();
  return t.content.firstChild;
}

function fmtDate(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  return d.toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });
}

function statusBadge(status) {
  const label = (status || '').replace(/_/g, ' ');
  return `<span class="status status-${status}">${label}</span>`;
}

function authLayout(title, subtitle, inner, extra = '') {
  return el(`
    <div class="auth-page">
      <div class="auth-wrap">
        <div class="auth-hero">
          <div class="auth-icon">⚙</div>
          <div class="logo">Jumandi</div>
          <div class="badge" style="margin-top:.5rem">ADMIN PORTAL</div>
          <h1 style="margin:1rem 0 .35rem;font-size:1.25rem">${title}</h1>
          <p class="muted">${subtitle}</p>
        </div>
        ${extra}
        <div class="card">${inner}</div>
      </div>
    </div>
  `);
}

function appLayout(active, content) {
  const user = getUser();
  const links = [
    ['/', 'Overview'],
    ['/orders', 'Orders'],
    ['/customers', 'Customers'],
    ['/drivers', 'Drivers'],
  ];
  const navHtml = links.map(([href, label]) =>
    `<a href="/admin${href === '/' ? '' : href}" data-nav="${href}" class="${active === href ? 'active' : ''}">${label}</a>`
  ).join('');
  return el(`
    <div>
      <header class="layout-header">
        <div><span class="logo">Jumandi</span> <span class="badge">ADMIN</span></div>
        <nav class="nav">${navHtml}</nav>
        <div style="display:flex;align-items:center;gap:.75rem">
          <span class="muted" style="font-size:.8rem">${user?.name || ''}</span>
          <button type="button" class="btn btn-ghost" id="logout-btn">Logout</button>
        </div>
      </header>
      <main class="layout-main">${content}</main>
    </div>
  `);
}

function wireAppChrome(root) {
  root.querySelector('#logout-btn')?.addEventListener('click', () => {
    clearSession();
    nav('/login');
  });
  root.querySelectorAll('[data-nav]').forEach(a => {
    a.addEventListener('click', e => {
      e.preventDefault();
      nav(a.getAttribute('data-nav'));
    });
  });
}

async function pageLogin(root) {
  let needsSetup = false;
  try {
    const s = await api('/api/admin/setup/status');
    needsSetup = s.needs_setup;
  } catch {}

  const setupBanner = needsSetup ? `
    <div class="setup-banner">
      <p style="margin:0 0 .75rem">No admin account yet.</p>
      <button type="button" class="btn btn-primary" id="go-setup" style="max-width:260px;margin:0 auto">Create admin account</button>
    </div>` : '';

  root.replaceChildren(authLayout(
    'Sign in',
    'Manage orders, customers, drivers, and everything happening in the app',
    `
      <div class="field"><label>ADMIN EMAIL</label><input id="email" type="email" placeholder="admin@jumandi.com" /></div>
      <div class="field"><label>PASSWORD</label><input id="password" type="password" /></div>
      <p class="error hidden" id="err"></p>
      <button type="button" class="btn btn-primary" id="login-btn">Sign in</button>
    `,
    setupBanner
  ));

  root.querySelector('#go-setup')?.addEventListener('click', () => nav('/setup'));
  root.querySelector('#login-btn').addEventListener('click', async () => {
    const err = root.querySelector('#err');
    err.classList.add('hidden');
    try {
      const email = root.querySelector('#email').value.trim();
      const password = root.querySelector('#password').value;
      const form = new URLSearchParams();
      form.set('username', email);
      form.set('password', password);
      const res = await fetch(`${API}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: form,
      });
      if (!res.ok) throw new Error('Incorrect email or password');
      const data = await res.json();
      if (data.user.role !== 'admin') throw new Error('This account is not an admin');
      setSession(data.access_token, data.user);
      nav('/');
    } catch (e) {
      err.textContent = e.message;
      err.classList.remove('hidden');
    }
  });
}

async function pageSetup(root) {
  root.replaceChildren(authLayout(
    'Create admin',
    'Set up the first admin account to manage the app',
    `
      <div class="field"><label>FULL NAME</label><input id="name" /></div>
      <div class="field"><label>EMAIL</label><input id="email" type="email" /></div>
      <div class="field"><label>PHONE</label><input id="phone" /></div>
      <div class="field"><label>PASSWORD</label><input id="password" type="password" minlength="6" /></div>
      <div class="field"><label>CONFIRM PASSWORD</label><input id="confirm" type="password" /></div>
      <p class="error hidden" id="err"></p>
      <button type="button" class="btn btn-primary" id="setup-btn">Create admin & sign in</button>
      <p style="text-align:center;margin-top:1rem"><a href="/admin/login">Back to login</a></p>
    `
  ));

  root.querySelector('#setup-btn').addEventListener('click', async () => {
    const err = root.querySelector('#err');
    err.classList.add('hidden');
    const password = root.querySelector('#password').value;
    if (password !== root.querySelector('#confirm').value) {
      err.textContent = 'Passwords do not match';
      err.classList.remove('hidden');
      return;
    }
    try {
      const body = {
        name: root.querySelector('#name').value.trim(),
        email: root.querySelector('#email').value.trim(),
        phone: root.querySelector('#phone').value.trim(),
        password,
      };
      await api('/api/admin/setup', { method: 'POST', json: body });
      const form = new URLSearchParams();
      form.set('username', body.email);
      form.set('password', body.password);
      const res = await fetch(`${API}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: form,
      });
      const data = await res.json();
      setSession(data.access_token, data.user);
      nav('/');
    } catch (e) {
      err.textContent = e.message;
      err.classList.remove('hidden');
    }
  });
}

async function pageDashboard(root) {
  const user = getUser();
  let overview = null;
  let activity = [];
  try {
    [overview, activity] = await Promise.all([
      api('/api/admin/overview'),
      api('/api/admin/activity?limit=15'),
    ]);
  } catch {}

  const o = overview || {};
  const activityHtml = (activity.items || []).length
    ? activity.items.map(item => `
        <li class="activity-item">
          <span class="activity-dot ${item.type}"></span>
          <div class="activity-msg">
            ${item.message}
            ${item.booking_id ? `<br><a href="/admin/orders/${item.booking_id}" data-nav="/orders/${item.booking_id}">View order #${item.booking_id}</a>` : ''}
          </div>
          <span class="activity-time">${fmtDate(item.created_at)}</span>
        </li>`).join('')
    : '<p class="muted">No activity yet. Orders and sign-ups will appear here.</p>';

  const layout = appLayout('/', `
    <h1 class="page-title">Operations overview</h1>
    <p class="muted page-sub">Welcome ${user?.name || 'Admin'} — here is everything happening in Jumandi right now.</p>

    <div class="stat-grid">
      <div class="stat"><div class="stat-label">TOTAL ORDERS</div><div class="stat-value">${o.bookings_total ?? '—'}</div></div>
      <div class="stat"><div class="stat-label">PENDING</div><div class="stat-value">${o.bookings_pending ?? '—'}</div></div>
      <div class="stat"><div class="stat-label">ACTIVE</div><div class="stat-value">${o.bookings_active ?? '—'}</div></div>
      <div class="stat"><div class="stat-label">DELIVERED</div><div class="stat-value">${o.bookings_delivered ?? '—'}</div></div>
      <div class="stat"><div class="stat-label">CANCELLED</div><div class="stat-value">${o.bookings_cancelled ?? '—'}</div></div>
      <div class="stat"><div class="stat-label">GAS DELIVERED</div><div class="stat-value sm">${o.gas_kg_delivered ?? 0} kg</div></div>
    </div>

    <div class="stat-grid">
      <div class="stat"><div class="stat-label">CUSTOMERS</div><div class="stat-value">${o.customers ?? '—'}</div></div>
      <div class="stat"><div class="stat-label">DRIVERS</div><div class="stat-value">${o.drivers ?? '—'}</div></div>
      <div class="stat"><div class="stat-label">DRIVERS ONLINE</div><div class="stat-value">${o.drivers_online ?? '—'}</div></div>
      <div class="stat"><div class="stat-label">CHAT MESSAGES</div><div class="stat-value">${o.messages_total ?? '—'}</div></div>
      <div class="stat"><div class="stat-label">CALLS</div><div class="stat-value">${o.calls_total ?? '—'}</div></div>
    </div>

    <div class="grid-2">
      <div>
        <h2 class="section-title">Live activity</h2>
        <div class="card"><ul class="activity-list">${activityHtml}</ul></div>
      </div>
      <div>
        <h2 class="section-title">Quick actions</h2>
        <div class="card card-accent">
          <p class="muted" style="margin:0 0 1rem">Jump to key areas of the app.</p>
          <button type="button" class="btn btn-primary btn-sm" data-nav="/orders" style="margin-bottom:.5rem;width:100%">View all orders</button>
          <button type="button" class="btn btn-ghost btn-sm" data-nav="/customers" style="margin-bottom:.5rem;width:100%">View customers</button>
          <button type="button" class="btn btn-ghost btn-sm" data-nav="/drivers" style="margin-bottom:.5rem;width:100%">Manage drivers</button>
          <button type="button" class="btn btn-ghost btn-sm" data-nav="/add-driver" style="width:100%">+ Add new driver</button>
        </div>
      </div>
    </div>
  `);
  root.replaceChildren(layout);
  wireAppChrome(root);
  layout.querySelectorAll('[data-nav]').forEach(btn => {
    btn.addEventListener('click', e => {
      e.preventDefault();
      nav(btn.getAttribute('data-nav'));
    });
  });
}

function bookingTableRows(bookings) {
  if (!bookings.length) return '<tr><td colspan="7" class="muted">No orders found.</td></tr>';
  return bookings.map(b => `
    <tr>
      <td><a href="/admin/orders/${b.id}" data-nav="/orders/${b.id}">#${b.id}</a></td>
      <td>${b.customer?.name || '—'}<br><span class="muted">${b.customer?.phone || ''}</span></td>
      <td>${b.gas_kg} kg</td>
      <td>${statusBadge(b.status)}</td>
      <td>${b.delivery_agent?.name || '<span class="muted">Unassigned</span>'}</td>
      <td style="max-width:180px">${b.address}</td>
      <td>${fmtDate(b.created_at)}</td>
    </tr>`).join('');
}

async function pageOrders(root, statusFilter = '') {
  let data = { bookings: [], total: 0 };
  let error = '';
  try {
    const q = statusFilter ? `?status=${statusFilter}` : '';
    data = await api(`/api/admin/bookings${q}`);
  } catch (e) { error = e.message; }

  const filters = [
    ['', 'All'],
    ['pending', 'Pending'],
    ['accepted', 'Accepted'],
    ['in_transit', 'In transit'],
    ['delivered', 'Delivered'],
    ['cancelled', 'Cancelled'],
  ];

  const layout = appLayout('/orders', `
    <h1 class="page-title">Orders</h1>
    <p class="muted page-sub">${data.total} order(s) in the system</p>
    ${error ? `<p class="error">${error}</p>` : ''}
    <div class="filter-tabs" id="order-filters">
      ${filters.map(([val, label]) =>
        `<button type="button" data-status="${val}" class="${statusFilter === val ? 'active' : ''}">${label}</button>`
      ).join('')}
    </div>
    <div class="table-wrap">
      <table class="data-table">
        <thead>
          <tr>
            <th>ORDER</th><th>CUSTOMER</th><th>GAS</th><th>STATUS</th>
            <th>DRIVER</th><th>ADDRESS</th><th>PLACED</th>
          </tr>
        </thead>
        <tbody>${bookingTableRows(data.bookings)}</tbody>
      </table>
    </div>
  `);
  root.replaceChildren(layout);
  wireAppChrome(root);
  layout.querySelector('#order-filters')?.addEventListener('click', e => {
    const btn = e.target.closest('[data-status]');
    if (!btn) return;
    pageOrders(root, btn.dataset.status);
  });
  layout.querySelectorAll('tbody [data-nav]').forEach(a => {
    a.addEventListener('click', e => { e.preventDefault(); nav(a.getAttribute('data-nav')); });
  });
}

async function pageOrderDetail(root, bookingId) {
  let booking = null;
  let error = '';
  try {
    booking = await api(`/api/admin/bookings/${bookingId}`);
  } catch (e) { error = e.message; }

  if (error || !booking) {
    const layout = appLayout('/orders', `
      <a href="/admin/orders" class="back-link" data-nav="/orders">← Back to orders</a>
      <p class="error">${error || 'Order not found'}</p>
    `);
    root.replaceChildren(layout);
    wireAppChrome(root);
    return;
  }

  const layout = appLayout('/orders', `
    <a href="/admin/orders" class="back-link" data-nav="/orders">← Back to orders</a>
    <h1 class="page-title">Order #${booking.id}</h1>
    <p class="page-sub">${statusBadge(booking.status)}</p>

    <div class="card card-accent">
      <div class="detail-grid">
        <div class="detail-item"><label>GAS QUANTITY</label><span>${booking.gas_kg} kg</span></div>
        <div class="detail-item"><label>PLACED</label><span>${fmtDate(booking.created_at)}</span></div>
        <div class="detail-item"><label>ACCEPTED</label><span>${fmtDate(booking.accepted_at)}</span></div>
        <div class="detail-item"><label>DELIVERED</label><span>${fmtDate(booking.delivered_at)}</span></div>
      </div>
      <div class="detail-item" style="margin-bottom:.75rem"><label>DELIVERY ADDRESS</label><span>${booking.address}</span></div>
      <div class="detail-item"><label>LOCATION</label><span>${booking.latitude.toFixed(5)}, ${booking.longitude.toFixed(5)}</span></div>
      ${booking.notes ? `<div class="detail-item" style="margin-top:.75rem"><label>NOTES</label><span>${booking.notes}</span></div>` : ''}
    </div>

    <div class="grid-2">
      <div class="card">
        <h3 style="margin:0 0 .75rem;font-size:.95rem">Customer</h3>
        ${booking.customer ? `
          <div class="agent">
            <div class="agent-avatar">${booking.customer.name.charAt(0)}</div>
            <div class="agent-body">
              <div class="agent-name">${booking.customer.name}</div>
              <div class="agent-meta">${booking.customer.email}</div>
              <div class="agent-meta">${booking.customer.phone}</div>
            </div>
          </div>` : '<p class="muted">—</p>'}
      </div>
      <div class="card">
        <h3 style="margin:0 0 .75rem;font-size:.95rem">Delivery driver</h3>
        ${booking.delivery_agent ? `
          <div class="agent">
            <div class="agent-avatar">${booking.delivery_agent.name.charAt(0)}</div>
            <div class="agent-body">
              <div class="agent-name">${booking.delivery_agent.name}</div>
              <div class="agent-meta">${booking.delivery_agent.email}</div>
              <div class="agent-meta">${booking.delivery_agent.phone}</div>
              <div style="margin-top:.35rem">${booking.delivery_agent.is_available ? '<span class="status status-on">Online</span>' : '<span class="status status-off">Offline</span>'}</div>
            </div>
          </div>` : '<p class="muted">No driver assigned yet</p>'}
      </div>
    </div>
  `);
  root.replaceChildren(layout);
  wireAppChrome(root);
}

async function pageCustomers(root) {
  let data = { customers: [], total: 0 };
  let error = '';
  try { data = await api('/api/admin/customers'); } catch (e) { error = e.message; }

  const rows = data.customers.length
    ? data.customers.map(c => `
        <tr>
          <td><div class="agent-avatar" style="display:inline-flex;width:32px;height:32px;font-size:.8rem">${c.name.charAt(0)}</div> ${c.name}</td>
          <td>${c.email}</td>
          <td>${c.phone}</td>
          <td>${c.is_verified ? '<span class="status status-delivered">Verified</span>' : '<span class="status status-pending">Unverified</span>'}</td>
        </tr>`).join('')
    : '<tr><td colspan="4" class="muted">No customers yet.</td></tr>';

  const layout = appLayout('/customers', `
    <h1 class="page-title">Customers</h1>
    <p class="muted page-sub">${data.total} registered customer(s)</p>
    ${error ? `<p class="error">${error}</p>` : ''}
    <div class="table-wrap">
      <table class="data-table">
        <thead><tr><th>NAME</th><th>EMAIL</th><th>PHONE</th><th>STATUS</th></tr></thead>
        <tbody>${rows}</tbody>
      </table>
    </div>
  `);
  root.replaceChildren(layout);
  wireAppChrome(root);
}

async function loadAgents() {
  const data = await api('/api/admin/delivery-agents');
  return data.agents || [];
}

function agentRow(agent, showDelete) {
  const st = agent.is_available ? 'status-on">Online' : 'status-off">Offline';
  return `
    <div class="card agent">
      <div class="agent-avatar">${agent.name.charAt(0).toUpperCase()}</div>
      <div class="agent-body">
        <div style="display:flex;justify-content:space-between;gap:.5rem">
          <span class="agent-name">${agent.name}</span>
          <span class="status ${st}</span>
        </div>
        <div class="agent-meta">${agent.email}</div>
        <div class="agent-meta">${agent.phone}</div>
      </div>
      ${showDelete ? `<button type="button" class="btn btn-danger" data-del="${agent.id}" data-name="${agent.name}">Delete</button>` : ''}
    </div>`;
}

async function pageDrivers(root) {
  let agents = [];
  let error = '';
  try { agents = await loadAgents(); } catch (e) { error = e.message; }
  const online = agents.filter(a => a.is_available).length;

  const layout = appLayout('/drivers', `
    <div style="display:flex;flex-wrap:wrap;justify-content:space-between;align-items:flex-start;gap:1rem;margin-bottom:1rem">
      <div>
        <h1 class="page-title">Delivery drivers</h1>
        <p class="muted page-sub">${agents.length} driver(s) — ${online} online</p>
      </div>
      <button type="button" class="btn btn-primary btn-sm" data-nav="/add-driver" style="width:auto">+ Add driver</button>
    </div>
    ${error ? `<p class="error">${error}</p>` : ''}
    <div id="agent-list">${agents.length ? agents.map(a => agentRow(a, true)).join('') : '<div class="card"><p class="muted">No drivers yet.</p></div>'}</div>
  `);
  root.replaceChildren(layout);
  wireAppChrome(root);
  layout.querySelector('[data-nav="/add-driver"]')?.addEventListener('click', e => {
    e.preventDefault();
    nav('/add-driver');
  });
  layout.querySelectorAll('[data-del]').forEach(btn => {
    btn.addEventListener('click', async () => {
      if (!confirm(`Delete driver "${btn.dataset.name}"?`)) return;
      try {
        await api(`/api/admin/delivery-agents/${btn.dataset.del}`, { method: 'DELETE' });
        render();
      } catch (e) { alert(e.message); }
    });
  });
}

function pageAddDriver(root) {
  const layout = appLayout('/drivers', `
    <a href="/admin/drivers" class="back-link" data-nav="/drivers">← Back to drivers</a>
    <h1 class="page-title">Add delivery driver</h1>
    <p class="muted page-sub">Create login credentials for the Jumandi delivery app.</p>
    <div class="card card-accent" style="max-width:520px">
      <div class="field"><label>FULL NAME</label><input id="name" /></div>
      <div class="field"><label>EMAIL (LOGIN)</label><input id="email" type="email" placeholder="driver@jumandi.com" /></div>
      <div class="field"><label>PHONE</label><input id="phone" /></div>
      <div class="field"><label>PASSWORD</label><input id="password" type="password" minlength="6" placeholder="Min 6 characters" /></div>
      <p class="error hidden" id="err"></p>
      <p class="hidden" id="ok" style="color:var(--success);margin-bottom:1rem"></p>
      <button type="button" class="btn btn-primary" id="create-btn">Create driver login</button>
    </div>
  `);
  root.replaceChildren(layout);
  wireAppChrome(root);
  layout.querySelector('#create-btn').addEventListener('click', async () => {
    const err = layout.querySelector('#err');
    const ok = layout.querySelector('#ok');
    err.classList.add('hidden');
    ok.classList.add('hidden');
    try {
      const agent = await api('/api/admin/delivery-agents', {
        method: 'POST',
        json: {
          name: layout.querySelector('#name').value.trim(),
          email: layout.querySelector('#email').value.trim(),
          phone: layout.querySelector('#phone').value.trim(),
          password: layout.querySelector('#password').value,
        },
      });
      ok.textContent = `Driver ${agent.email} created!`;
      ok.classList.remove('hidden');
      setTimeout(() => nav('/drivers'), 2000);
    } catch (e) {
      err.textContent = e.message;
      err.classList.remove('hidden');
    }
  });
}

async function render() {
  const root = document.getElementById('app');
  const p = path();
  const token = getToken();
  const isAuth = token && getUser()?.role === 'admin';

  if (p === '/login' || p === '/setup') {
    if (isAuth) { nav('/'); return; }
    if (p === '/setup') return pageSetup(root);
    return pageLogin(root);
  }

  if (!isAuth) { nav('/login'); return; }

  const orderMatch = p.match(/^\/orders\/(\d+)$/);
  if (orderMatch) return pageOrderDetail(root, orderMatch[1]);
  if (p === '/orders') return pageOrders(root);
  if (p === '/customers') return pageCustomers(root);
  if (p === '/drivers') return pageDrivers(root);
  if (p === '/add-driver') return pageAddDriver(root);
  return pageDashboard(root);
}

render();
