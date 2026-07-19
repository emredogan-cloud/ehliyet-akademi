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
/**
 * Senkronlanan anahtarlar (userState / /api/state ile).
 * NOT: `ea:entitlements:v1` KASITEN burada YOK — sahiplik `purchases` tablosunun türevidir, userState
 * ile senkronlanMAZ. Aksi halde bir kullanıcının paketi aynı tarayıcıda başka kullanıcıya sızardı
 * (P0). Entitlements yalnız `reconcileEntitlements()` ile purchases'tan yeniden yazılır (cache).
 */
export const SYNC_KEYS = [
  'ea:answers:v1',
  'ea:cards:v1',
  'ea:streak:v1',
  'ea:readiness:v1',
  'ea:examQuota:v1',
  'ea:aiQuota:v1',
  'ea:counters:v1',
  'ea:lessonsViewed:v1',
  'ea:avatar:v1',
  'ea:theme',
] as const;

/** Kullanıcıya-özel anahtarlar — çıkışta temizlenir (tema/rıza cihaz tercihidir, KALIR). */
const USER_SCOPED_KEYS = [
  'ea:entitlements:v1',
  'ea:answers:v1',
  'ea:cards:v1',
  'ea:streak:v1',
  'ea:readiness:v1',
  'ea:examQuota:v1',
  'ea:aiQuota:v1',
  'ea:counters:v1',
  'ea:lessonsViewed:v1',
  'ea:avatar:v1',
  'ea:premiumWelcomeShown:v1',
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
  // KÖK DÜZELTME (Ödeme): sahiplik SUNUCUDA `purchases` tablosunda tutulur (webhook oraya yazar),
  // ama /api/state yalnız userState'i senkronlar → webhook ile alınan paket istemciye HİÇ ulaşmıyordu.
  // Her senkronda purchases → ea:entitlements uzlaştırılır (giriş + çapraz-cihaz + checkout dönüşü).
  await reconcileEntitlements();
}

/**
 * Yetki cache'ini SUNUCUNUN `purchases` tablosuna göre YENİDEN YAZAR (authoritative SET, union DEĞİL).
 * Sunucu bu kullanıcı için tek doğruluk kaynağıdır → aynı tarayıcıdaki BAŞKA kullanıcıdan kalan bayat
 * yerel yetki SIZAMAZ (P0 kök düzeltmesi). Ağ hatasında yerel korunur (ödemiş kullanıcı erişim
 * kaybetmez). Döner: bu kullanıcının gerçek sahiplik listesi.
 */
export async function reconcileEntitlements(): Promise<string[]> {
  const { status, data } = await api<{ purchases?: Array<{ productId: string }> }>(
    '/api/purchases'
  );
  if (status !== 200 || !Array.isArray(data.purchases)) {
    return (readLocal('ea:entitlements:v1') as string[] | null) ?? [];
  }
  const owned = Array.from(new Set(data.purchases.map((p) => p.productId)));
  writeLocal('ea:entitlements:v1', owned); // SET: sunucu neyse yerel odur (bayat yetki temizlenir)
  return owned;
}

export async function me(): Promise<AuthUser | null> {
  const { status, data } = await api<{ user: AuthUser | null }>('/api/auth/me');
  authed = status === 200 && !!data.user;
  if (authed && data.user) bindSession(data.user.id);
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
  if (data.user) bindSession(data.user.id); // farklı önceki kullanıcı verisini temizle (P0)
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
  if (data.user) bindSession(data.user.id); // farklı önceki kullanıcı verisini temizle (P0)
  await fullSync();
  return { ok: true };
}

export async function logout(): Promise<void> {
  await api('/api/auth/logout', { method: 'POST', body: '{}' });
  authed = false;
  // P0: kullanıcıya-özel yerel veriyi TEMİZLE → sonraki kullanıcı (aynı tarayıcı) bayat
  // ilerleme/sahiplik/premium miras ALMAZ. Tema/rıza cihaz tercihidir, korunur.
  clearUserScoped();
  try {
    localStorage.removeItem('ea:sessionUser');
  } catch {
    /* yoksay */
  }
}

/** Kullanıcıya-özel localStorage anahtarlarını siler (çıkış / kullanıcı değişimi). */
export function clearUserScoped(): void {
  try {
    for (const k of USER_SCOPED_KEYS) localStorage.removeItem(k);
  } catch {
    /* yoksay */
  }
}

/**
 * Yerel veriyi bir kullanıcıya BAĞLAR. Bu tarayıcıda daha önce BAŞKA kullanıcı oturum açtıysa
 * (ea:sessionUser farklı), onun bayat verisi TEMİZLENİR → premium/ilerleme sızıntısı önlenir (P0).
 * Misafirde işaret yoktur → ilk kayıtta veri KORUNUR (misafir ilerlemesi hesaba taşınır).
 */
function bindSession(userId: string): void {
  try {
    const prev = localStorage.getItem('ea:sessionUser');
    if (prev && prev !== userId) clearUserScoped();
    localStorage.setItem('ea:sessionUser', userId);
  } catch {
    /* yoksay */
  }
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
