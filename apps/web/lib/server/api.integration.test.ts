/**
 * API entegrasyon testleri — route handler'lar bellek-içi PGlite üstünde uçtan uca.
 * (NODE_ENV=test → getDb memory:// kullanır; ağ yok, gerçek handler kodu test edilir.)
 */
import { describe, it, expect } from 'vitest';
import { POST as register } from '@/app/api/auth/register/route';
import { POST as login } from '@/app/api/auth/login/route';
import { POST as logout } from '@/app/api/auth/logout/route';
import { GET as me } from '@/app/api/auth/me/route';
import { POST as forgot } from '@/app/api/auth/forgot/route';
import { POST as reset } from '@/app/api/auth/reset/route';
import { GET as stateGet, PUT as statePut } from '@/app/api/state/route';
import { GET as purchasesGet, POST as purchasesPost } from '@/app/api/purchases/route';

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
function put(path: string, body: unknown, cookie?: string): Request {
  return new Request(BASE + path, {
    method: 'PUT',
    headers: { 'content-type': 'application/json', ...(cookie ? { cookie } : {}) },
    body: JSON.stringify(body),
  });
}
function cookieOf(res: Response): string {
  const sc = res.headers.get('set-cookie') ?? '';
  return sc.split(';')[0] ?? '';
}

const EMAIL = `it-${Date.now()}@ea.dev`;
const PW = 'cok-gizli-123';

describe('auth + state + purchases (entegrasyon)', () => {
  let cookie = '';

  it('register: hesap açar, oturum çerezi döner', async () => {
    const res = await register(
      post('/api/auth/register', { email: EMAIL, password: PW, name: 'IT' })
    );
    expect(res.status).toBe(201);
    cookie = cookieOf(res);
    expect(cookie).toMatch(/^ea_session=[a-f0-9]{64}$/);
  });

  it('register: aynı e-posta 409; zayıf parola 400', async () => {
    expect(
      (await register(post('/api/auth/register', { email: EMAIL, password: PW }))).status
    ).toBe(409);
    expect(
      (await register(post('/api/auth/register', { email: 'x@y.dev', password: 'kisa' }))).status
    ).toBe(400);
  });

  it('me: çerezle kullanıcıyı döner; çerezsiz 401', async () => {
    const ok = await me(get('/api/auth/me', cookie));
    expect(ok.status).toBe(200);
    expect(((await ok.json()) as { user: { email: string } }).user.email).toBe(EMAIL);
    expect((await me(get('/api/auth/me'))).status).toBe(401);
  });

  it('login: yanlış parola 401; doğrusu yeni oturum (çok-cihaz)', async () => {
    expect(
      (await login(post('/api/auth/login', { email: EMAIL, password: 'yanlis-parola' }))).status
    ).toBe(401);
    const res = await login(post('/api/auth/login', { email: EMAIL, password: PW }));
    expect(res.status).toBe(200);
    const second = cookieOf(res);
    expect(second).not.toBe(cookie); // ayrı cihaz oturumu
    // her iki oturum da geçerli
    expect((await me(get('/api/auth/me', cookie))).status).toBe(200);
    expect((await me(get('/api/auth/me', second))).status).toBe(200);
  });

  it('state: PUT upsert + GET geri okur; izinsiz anahtar sessizce elenir', async () => {
    const putRes = await statePut(
      put(
        '/api/state',
        {
          items: [
            { key: 'ea:streak:v1', value: { current: 2, best: 3, lastDay: '2026-07-15' } },
            { key: 'ea:hacker', value: { x: 1 } }, // izinli değil
          ],
        },
        cookie
      )
    );
    expect(((await putRes.json()) as { saved: number }).saved).toBe(1);
    const getRes = await stateGet(get('/api/state', cookie));
    const items = ((await getRes.json()) as { items: Array<{ key: string; value: unknown }> })
      .items;
    expect(items.find((i) => i.key === 'ea:streak:v1')).toBeTruthy();
    expect(items.find((i) => i.key === 'ea:hacker')).toBeFalsy();
  });

  it('purchases: sunucu-taraflı sahiplik + idempotent + restore', async () => {
    const res = await purchasesPost(post('/api/purchases', { productId: 'komple-b' }, cookie));
    expect(((await res.json()) as { owned: string[] }).owned).toContain('komple-b');
    // ikinci kez → idempotent
    const res2 = await purchasesPost(post('/api/purchases', { productId: 'komple-b' }, cookie));
    expect(((await res2.json()) as { owned: string[] }).owned.length).toBe(1);
    // geçersiz ürün
    expect((await purchasesPost(post('/api/purchases', { productId: 'yok' }, cookie))).status).toBe(
      404
    );
    // restore
    const list = await purchasesGet(get('/api/purchases', cookie));
    expect(
      ((await list.json()) as { purchases: Array<{ productId: string }> }).purchases[0]?.productId
    ).toBe('komple-b');
  });

  it('forgot/reset: token ile parola değişir, TÜM oturumlar düşer', async () => {
    const f = await forgot(post('/api/auth/forgot', { email: EMAIL }));
    const { devToken } = (await f.json()) as { devToken: string };
    expect(devToken).toMatch(/^[a-f0-9]{64}$/);
    const NEW = 'yeni-parola-456';
    expect((await reset(post('/api/auth/reset', { token: devToken, password: NEW }))).status).toBe(
      200
    );
    // eski oturum artık geçersiz
    expect((await me(get('/api/auth/me', cookie))).status).toBe(401);
    // yeni parola ile giriş
    const relog = await login(post('/api/auth/login', { email: EMAIL, password: NEW }));
    expect(relog.status).toBe(200);
    cookie = cookieOf(relog);
  });

  it('logout: oturumu siler', async () => {
    await logout(post('/api/auth/logout', {}, cookie));
    expect((await me(get('/api/auth/me', cookie))).status).toBe(401);
  });
});
