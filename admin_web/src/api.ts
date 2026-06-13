export const API_BASE =
  import.meta.env.VITE_API_URL ??
  (import.meta.env.PROD ? '' : 'https://jumandi.onrender.com');

export type User = {
  id: number;
  name: string;
  email: string;
  phone: string;
  role: string;
  is_available: boolean;
  is_verified: boolean;
};

export type SetupStatus = {
  needs_setup: boolean;
  admin_count: number;
};

async function parseError(res: Response): Promise<string> {
  try {
    const data = await res.json();
    if (typeof data.detail === 'string') return data.detail;
    return 'Request failed';
  } catch {
    return res.statusText || 'Request failed';
  }
}

export async function getSetupStatus(): Promise<SetupStatus> {
  const res = await fetch(`${API_BASE}/api/admin/setup/status`);
  if (!res.ok) throw new Error(await parseError(res));
  return res.json();
}

export async function setupAdmin(body: {
  name: string;
  email: string;
  phone: string;
  password: string;
}): Promise<User> {
  const res = await fetch(`${API_BASE}/api/admin/setup`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(await parseError(res));
  return res.json();
}

export async function login(email: string, password: string): Promise<{ token: string; user: User }> {
  const form = new URLSearchParams();
  form.set('username', email);
  form.set('password', password);

  const res = await fetch(`${API_BASE}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: form,
  });
  if (!res.ok) throw new Error(await parseError(res));
  const data = await res.json();
  return { token: data.access_token, user: data.user };
}

function authHeaders(token: string) {
  return {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`,
  };
}

export async function listDeliveryAgents(token: string): Promise<User[]> {
  const res = await fetch(`${API_BASE}/api/admin/delivery-agents`, {
    headers: authHeaders(token),
  });
  if (!res.ok) throw new Error(await parseError(res));
  const data = await res.json();
  return data.agents;
}

export async function createDeliveryAgent(
  token: string,
  body: { name: string; email: string; phone: string; password: string },
): Promise<User> {
  const res = await fetch(`${API_BASE}/api/admin/delivery-agents`, {
    method: 'POST',
    headers: authHeaders(token),
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(await parseError(res));
  return res.json();
}

export async function deleteDeliveryAgent(token: string, id: number): Promise<void> {
  const res = await fetch(`${API_BASE}/api/admin/delivery-agents/${id}`, {
    method: 'DELETE',
    headers: authHeaders(token),
  });
  if (!res.ok) throw new Error(await parseError(res));
}
