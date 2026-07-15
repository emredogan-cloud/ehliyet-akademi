/**
 * Ticaret/hesap entegrasyon testleri (Sprint 4) — checkout, webhook grant + idempotency,
 * makbuz reddi, e-posta doğrulama, hesap silme (PGlite bellek-içi).
 */
import { describe, it, expect } from 'vitest';
import { POST as register } from '@/app/api/auth/register/route';
import { POST as checkout } from '@/app/api/checkout/route';
import { POST as webhook } from '@/app/api/webhooks/lemonsqueezy/route';
import { POST as verify } from '@/app/api/auth/verify/route';
import { GET as purchasesGet } from '@/app/api/purchases/route';
import { DELETE as accountDelete } from '@/app/api/account/route';
import { GET as me } from '@/app/api/auth/me/route';

const BASE = 'http://test.local';
const T = Date.now();
function post(path: string, body: unknown, cookie?: string): Request {
  return new Request(BASE + path, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...(cookie ? { cookie } : {}) },
    body: JSON.stringify(body),
  });
}
function raw(path: string, body: string): Request {
  return new Request(BASE + path, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body,
  });
}
function del(path: string, cookie?: string): Request {
  return new Request(BASE + path, { method: 'DELETE', headers: cookie ? { cookie } : {} });
}
function get(path: string, cookie?: string): Request {
  return new Request(BASE + path, { headers: cookie ? { cookie } : {} });
}
const cookieOf = (r: Response) => (r.headers.get('set-cookie') ?? '').split(';')[0] ?? '';

let cookie = '';
let userId = '';

describe('checkout + webhook (Epic 1)', () => {
  it('kayıt olur, çerez alır', async () => {
    const r = await register(
      post('/api/auth/register', {
        email: `buyer-${T}@ea.dev`,
        password: 'parola-123',
        name: 'Buyer',
      })
    );
    expect(r.status).toBe(201);
    userId = ((await r.json()) as { user: { id: string } }).user.id;
    cookie = cookieOf(r);
  });

  it('checkout mock modu döner (girişli)', async () => {
    const r = await checkout(post('/api/checkout', { productId: 'premium-teori' }, cookie));
    expect(r.status).toBe(200);
    expect(((await r.json()) as { mode: string }).mode).toBe('mock');
  });

  it('checkout oturumsuz 401; bilinmeyen ürün 404', async () => {
    expect((await checkout(post('/api/checkout', { productId: 'premium-teori' }))).status).toBe(
      401
    );
    expect((await checkout(post('/api/checkout', { productId: 'yok' }, cookie))).status).toBe(404);
  });

  it('webhook (mock) sahiplik verir; tekrar gönderim idempotent', async () => {
    const body = JSON.stringify({
      productId: 'komple-b',
      userId,
      orderId: `ord-${T}`,
      totalTRY: 449,
    });
    const r1 = await webhook(raw('/api/webhooks/lemonsqueezy', body));
    expect(r1.status).toBe(200);
    const r2 = await webhook(raw('/api/webhooks/lemonsqueezy', body));
    expect(((await r2.json()) as { duplicate?: boolean }).duplicate).toBe(true);

    const owned = (await (await purchasesGet(get('/api/purchases', cookie))).json()) as {
      purchases: Array<{ productId: string }>;
    };
    expect(owned.purchases.some((p) => p.productId === 'komple-b')).toBe(true);
  });

  it('webhook geçersiz makbuz (fiyat uyuşmazlığı) 400', async () => {
    const body = JSON.stringify({
      productId: 'premium-teori',
      userId,
      orderId: `bad-${T}`,
      totalTRY: 1,
    });
    expect((await webhook(raw('/api/webhooks/lemonsqueezy', body))).status).toBe(400);
  });

  it('webhook eksik sipariş verisi → 200 ignore', async () => {
    const r = await webhook(raw('/api/webhooks/lemonsqueezy', JSON.stringify({ foo: 'bar' })));
    expect(r.status).toBe(200);
    expect(((await r.json()) as { ignored?: boolean }).ignored).toBe(true);
  });
});

describe('e-posta doğrulama (Epic 2)', () => {
  it('oturumlu istek devToken üretir; token ile doğrulanır', async () => {
    const sendRes = await verify(post('/api/auth/verify', {}, cookie));
    expect(sendRes.status).toBe(200);
    const token = ((await sendRes.json()) as { devToken?: string }).devToken;
    expect(token).toBeTruthy();
    const confirm = await verify(post('/api/auth/verify', { token }));
    expect(((await confirm.json()) as { verified?: boolean }).verified).toBe(true);
    // geçersiz token reddedilir
    expect((await verify(post('/api/auth/verify', { token: 'yok' }))).status).toBe(400);
  });
});

describe('hesap silme (Epic 3)', () => {
  it('hesabı siler; sonrasında oturum düşer', async () => {
    const r = await accountDelete(del('/api/account', cookie));
    expect(r.status).toBe(200);
    // aynı çerezle me artık kullanıcı döndürmez
    const meRes = await me(get('/api/auth/me', cookie));
    const body = (await meRes.json()) as { user: unknown };
    expect(body.user).toBeFalsy();
  });
});
