'use client';

/**
 * İstemci auth + senkron katmanı (Sprint 1, Epic 1+4).
 * Giriş sonrası: sunucu durumu ÇEKİLİR (sunucu kazanır), yalnız-yerel anahtarlar İTİLİR.
 * Sonraki yazımlar `syncSet` ile hem localStorage'a hem (oturum varsa) sunucuya gider.
 */

export interface AuthUser {
  id: string;
  email: string;
  name: string;
  role: 'user' | 'editor' | 'admin';
}

/** Ham (JSON'suz) saklanan anahtarlar — kök tema scripti doğrudan okur. */
const RAW_KEYS = new Set(['ea:theme']);
/** Senkronlanan anahtarlar (sunucudaki izin listesiyle birebir). */
export const SYNC_KEYS = [
  'ea:answers:v1',
  'ea:cards:v1',
  'ea:streak:v1',
  'ea:readiness:v1',
  'ea:entitlements:v1',
  'ea:examQuota:v1',
  'ea:theme',
] as const;

let authed = false;
let pushTimer: ReturnType<typeof setTimeout> | null = null;
const pending = new Map<string, unknown>();

export function isAuthed(): boolean {
  return authed;
}

async function api<T>(path: string, init?: RequestInit): Promise<{ status: number; data: T }> {
  const res = await fetch(path, {
    ...init,
    headers: { 'content-type': 'application/json', ...(init?.headers ?? {}) },
    credentials: 'same-origin',
  });
  const data = (await res.json().catch(() => ({}))) as T;
  return { status: res.status, data };
}

function readLocal(key: string): unknown {
  try {
    const raw = localStorage.getItem(key);
    if (raw === null) return null;
    return RAW_KEYS.has(key) ? raw : JSON.parse(raw);
  } catch {
    return null;
  }
}
function writeLocal(key: string, value: unknown): void {
  try {
    if (RAW_KEYS.has(key)) localStorage.setItem(key, String(value));
    else localStorage.setItem(key, JSON.stringify(value));
  } catch {
    /* kota */
  }
}

/** Yerel yaz + (girişliyse) sunucuya debounce'lu it. Tüm modüller bunun üzerinden yazar. */
export function syncSet(key: string, value: unknown): void {
  writeLocal(key, value);
  if (!authed) return;
  pending.set(key, value);
  if (pushTimer) clearTimeout(pushTimer);
  pushTimer = setTimeout(() => {
    const items = [...pending.entries()].map(([k, v]) => ({ key: k, value: v }));
    pending.clear();
    void api('/api/state', { method: 'PUT', body: JSON.stringify({ items }) });
  }, 400);
}

/** Giriş sonrası tam senkron: sunucu → yerel (mevcutsa), yalnız-yerel → sunucu. */
export async function fullSync(): Promise<void> {
  const { status, data } = await api<{ items: Array<{ key: string; value: unknown }> }>(
    '/api/state'
  );
  if (status !== 200) return;
  const serverKeys = new Set(data.items.map((i) => i.key));
  for (const it of data.items) writeLocal(it.key, it.value);
  const toPush = SYNC_KEYS.filter((k) => !serverKeys.has(k))
    .map((k) => ({ key: k, value: readLocal(k) }))
    .filter((i) => i.value !== null);
  if (toPush.length)
    await api('/api/state', { method: 'PUT', body: JSON.stringify({ items: toPush }) });
}

export async function me(): Promise<AuthUser | null> {
  const { status, data } = await api<{ user: AuthUser | null }>('/api/auth/me');
  authed = status === 200 && !!data.user;
  return authed ? data.user : null;
}

export async function register(
  email: string,
  password: string,
  name: string
): Promise<{ ok: boolean; error?: string }> {
  const { status, data } = await api<{ user?: AuthUser; error?: string }>('/api/auth/register', {
    method: 'POST',
    body: JSON.stringify({ email, password, name }),
  });
  if (status !== 201)
    return { ok: false, error: (data as { error?: string }).error ?? 'Kayıt başarısız.' };
  authed = true;
  await fullSync();
  return { ok: true };
}

export async function login(
  email: string,
  password: string
): Promise<{ ok: boolean; error?: string }> {
  const { status, data } = await api<{ user?: AuthUser; error?: string }>('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
  if (status !== 200)
    return { ok: false, error: (data as { error?: string }).error ?? 'Giriş başarısız.' };
  authed = true;
  await fullSync();
  return { ok: true };
}

export async function logout(): Promise<void> {
  await api('/api/auth/logout', { method: 'POST', body: '{}' });
  authed = false;
}

export async function forgotPassword(
  email: string
): Promise<{ ok: boolean; devToken?: string; note?: string }> {
  const { data } = await api<{ ok: boolean; devToken?: string; note?: string }>(
    '/api/auth/forgot',
    { method: 'POST', body: JSON.stringify({ email }) }
  );
  return data;
}

export async function resetPassword(
  token: string,
  password: string
): Promise<{ ok: boolean; error?: string }> {
  const { status, data } = await api<{ ok?: boolean; error?: string }>('/api/auth/reset', {
    method: 'POST',
    body: JSON.stringify({ token, password }),
  });
  return status === 200 ? { ok: true } : { ok: false, error: data.error };
}

/** Sunucudaki satın almaları yerele geri yükle (restore). */
export async function restorePurchases(): Promise<string[]> {
  const { status, data } = await api<{ purchases: Array<{ productId: string }> }>('/api/purchases');
  if (status !== 200) return [];
  const owned = data.purchases.map((p) => p.productId);
  writeLocal('ea:entitlements:v1', owned);
  return owned;
}

/** Sunucu-taraflı satın alma (girişliyken). */
export async function serverPurchase(productId: string): Promise<string[] | null> {
  const { status, data } = await api<{ owned?: string[] }>('/api/purchases', {
    method: 'POST',
    body: JSON.stringify({ productId }),
  });
  if (status !== 200 || !data.owned) return null;
  writeLocal('ea:entitlements:v1', data.owned);
  return data.owned;
}
