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
  const base = '/admin';
  window.history.pushState({}, '', base + (to === '/' ? '' : to));
  render();
}

window.addEventListener('popstate', render);

function el(html) {
  const t = document.createElement('template');
  t.innerHTML = html.trim();
  return t.content.firstChild;
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
  return el(`
    <div>
      <header class="layout-header">
        <div><span class="logo">Jumandi</span> <span class="badge">ADMIN</span></div>
        <nav class="nav">
          <a href="/admin" data-nav="/" class="${active === '/' ? 'active' : ''}">Overview</a>
          <a href="/admin/drivers" data-nav="/drivers" class="${active === '/drivers' ? 'active' : ''}">Drivers</a>
          <a href="/admin/add-driver" data-nav="/add-driver" class="${active === '/add-driver' ? 'active' : ''}">Add Driver</a>
        </nav>
        <div style="display:flex;align-items:center;gap:.75rem">
          <span class="muted" style="font-size:.8rem">${user?.name || ''}</span>
          <button type="button" class="btn btn-ghost" id="logout-btn">Logout</button>
        </div>
      </header>
      <main class="layout-main">${content}</main>
    </div>
  `);
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
    'Manage delivery drivers and accounts',
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
    'Set up the first admin account',
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

async function pageDashboard(root) {
  const user = getUser();
  let agents = [];
  try { agents = await loadAgents(); } catch {}
  const online = agents.filter(a => a.is_available).length;

  const layout = appLayout('/', `
    <h1 class="page-title">Welcome, ${user?.name || 'Admin'}</h1>
    <p class="muted" style="margin-bottom:1.25rem">Create delivery logins and share them with your drivers.</p>
    <div class="stat-grid">
      <div class="stat"><div class="stat-label">TOTAL DRIVERS</div><div class="stat-value">${agents.length}</div></div>
      <div class="stat"><div class="stat-label">ONLINE</div><div class="stat-value">${online}</div></div>
      <div class="stat"><div class="stat-label">OFFLINE</div><div class="stat-value">${agents.length - online}</div></div>
    </div>
    <div class="card card-accent" style="margin-bottom:1.25rem">
      <h2 style="font-size:1rem;margin:0 0 .5rem">Quick action</h2>
      <p class="muted" style="margin-bottom:1rem">Add a driver, then give them the email and password to sign in on the delivery app.</p>
      <button type="button" class="btn btn-primary" id="go-add" style="max-width:280px">+ Add delivery driver</button>
    </div>
    <h2 style="font-size:1.05rem">Recent drivers</h2>
    <div id="agent-list">${agents.length ? agents.slice(0, 5).map(a => agentRow(a, false)).join('') : '<p class="muted">No drivers yet.</p>'}</div>
    ${agents.length > 5 ? '<p style="margin-top:1rem"><a href="/admin/drivers">View all drivers →</a></p>' : ''}
  `);
  root.replaceChildren(layout);
  wireAppChrome(root);
  root.querySelector('#go-add')?.addEventListener('click', () => nav('/add-driver'));
}

async function pageDrivers(root) {
  let agents = [];
  let error = '';
  try { agents = await loadAgents(); } catch (e) { error = e.message; }

  const layout = appLayout('/drivers', `
    <h1 class="page-title">Delivery drivers</h1>
    <p class="muted" style="margin-bottom:1.25rem">${agents.length} driver(s)</p>
    ${error ? `<p class="error">${error}</p>` : ''}
    <div id="agent-list">${agents.length ? agents.map(a => agentRow(a, true)).join('') : '<div class="card"><p class="muted">No drivers yet. <a href="/admin/add-driver">Add one</a></p></div>'}</div>
  `);
  root.replaceChildren(layout);
  wireAppChrome(root);
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
  const layout = appLayout('/add-driver', `
    <h1 class="page-title">Add delivery driver</h1>
    <p class="muted" style="margin-bottom:1.25rem">Create login credentials for the Jumandi delivery app.</p>
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
      ok.textContent = `Driver ${agent.email} created! Share these login details.`;
      ok.classList.remove('hidden');
      setTimeout(() => nav('/drivers'), 2000);
    } catch (e) {
      err.textContent = e.message;
      err.classList.remove('hidden');
    }
  });
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

  if (p === '/drivers') return pageDrivers(root);
  if (p === '/add-driver') return pageAddDriver(root);
  return pageDashboard(root);
}

render();
