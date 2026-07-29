/**
 * Faz 5 — hesap silme: yeniden kimlik doğrulama kuralı.
 *
 * Route handler'lar bellek-içi PGlite üstünde uçtan uca koşar (NODE_ENV=test → getDb memory://).
 */
import { describe, it, expect } from 'vitest';
import { eq } from 'drizzle-orm';
import { getDb, users } from '@ea/db';
import { POST as register } from '@/app/api/auth/register/route';
import { GET as accountGet, DELETE as accountDelete } from '@/app/api/account/route';
import { GET as me } from '@/app/api/auth/me/route';

const BASE = 'http://test.local';

function post(path: string, body: unknown, cookie?: string): Request {
  return new Request(BASE + path, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...(cookie ? { cookie } : {}) },
    body: JSON.stringify(body),
  });
}
function get(path: string, cookie?: string): Request {
  return new Request(BASE + path, { headers: cookie ? { cookie } : {} });
}
function del(path: string, body?: unknown, cookie?: string): Request {
  return new Request(BASE + path, {
    method: 'DELETE',
    headers: { 'content-type': 'application/json', ...(cookie ? { cookie } : {}) },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
}
function cookieOf(res: Response): string {
  return (res.headers.get('set-cookie') ?? '').split(';')[0] ?? '';
}

const PW = 'cok-gizli-123';

describe('hesap silme — parolalı hesap', () => {
  const email = `del-pw-${Date.now()}@ea.dev`;
  let cookie = '';

  it('kayıt olur', async () => {
    const res = await register(post('/api/auth/register', { email, password: PW, name: 'Sil' }));
    expect(res.status).toBe(201);
    cookie = cookieOf(res);
  });

  it('GET /api/account: parola gerektiğini bildirir', async () => {
    const res = await accountGet(get('/api/account', cookie));
    expect(res.status).toBe(200);
    const body = (await res.json()) as { requiresPassword: boolean; email: string };
    expect(body.requiresPassword).toBe(true);
    expect(body.email).toBe(email);
  });

  it('parolasız silme reddedilir (400) ve hesap DURUR', async () => {
    const res = await accountDelete(del('/api/account', undefined, cookie));
    expect(res.status).toBe(400);
    // En önemli iddia: hesap hâlâ var.
    expect((await me(get('/api/auth/me', cookie))).status).toBe(200);
  });

  it('YANLIŞ parola reddedilir (403) ve hesap DURUR', async () => {
    const res = await accountDelete(del('/api/account', { password: 'yanlis-parola' }, cookie));
    expect(res.status).toBe(403);
    expect((await res.json()).error).toMatch(/parola/i);
    expect((await me(get('/api/auth/me', cookie))).status).toBe(200);
  });

  it('doğru parola ile silinir; oturum çerezi temizlenir ve satır gider', async () => {
    const res = await accountDelete(del('/api/account', { password: PW }, cookie));
    expect(res.status).toBe(200);
    expect(res.headers.get('set-cookie') ?? '').toContain('Max-Age=0');

    const db = await getDb();
    const rows = await db.select({ id: users.id }).from(users).where(eq(users.email, email));
    expect(rows).toHaveLength(0);
    // Oturum da düştü (FK cascade).
    expect((await me(get('/api/auth/me', cookie))).status).toBe(401);
  });
});

describe('hesap silme — parolası OLMAYAN hesap (Google)', () => {
  const email = `del-google-${Date.now()}@ea.dev`;
  let cookie = '';

  it('hazırlık: parolalı kayıt açılır, sonra sentinel yazılır', async () => {
    const res = await register(post('/api/auth/register', { email, password: PW, name: 'G' }));
    cookie = cookieOf(res);
    // Google akışının bıraktığı durumun aynısı (`api/auth/google` bunu yazıyor).
    const db = await getDb();
    await db
      .update(users)
      .set({ passwordHash: 'google$no-password' })
      .where(eq(users.email, email));
  });

  it('GET /api/account: parola gerekmediğini bildirir', async () => {
    const res = await accountGet(get('/api/account', cookie));
    const body = (await res.json()) as { requiresPassword: boolean };
    expect(body.requiresPassword).toBe(false);
  });

  /// Parolası olmayan hesaptan parola istemek imkânsızı istemek olurdu; oturum tek dayanaktır.
  it('gövdesiz silme kabul edilir', async () => {
    const res = await accountDelete(del('/api/account', undefined, cookie));
    expect(res.status).toBe(200);
    const db = await getDb();
    const rows = await db.select({ id: users.id }).from(users).where(eq(users.email, email));
    expect(rows).toHaveLength(0);
  });
});

describe('hesap silme — oturumsuz', () => {
  it('401 döner ve hiçbir şey silinmez', async () => {
    expect((await accountDelete(del('/api/account', { password: PW }))).status).toBe(401);
    expect((await accountGet(get('/api/account'))).status).toBe(401);
  });
});
