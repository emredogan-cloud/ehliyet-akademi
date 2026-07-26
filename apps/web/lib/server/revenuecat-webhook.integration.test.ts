/**
 * RevenueCat webhook entegrasyon testi (Beta Faz 13 — Faz 3 kararının kapanışı).
 *
 * Bu ucun ASIL riski işlevsellik değil, **güvenliktir**: internetteki herkes POST atabilir.
 * Bu yüzden testlerin çoğu "kim yazamaz" sorusunu ölçer.
 */
import { describe, it, expect, vi, afterEach } from 'vitest';
import { createHmac } from 'node:crypto';
import { POST as register } from '@/app/api/auth/register/route';
import { GET as me } from '@/app/api/auth/me/route';
import { POST as rcWebhook } from '@/app/api/iap/revenuecat/route';

const BASE = 'http://test.local';
const SECRET = 'rc-test-secret';

const post = (body: unknown, auth?: string) =>
  new Request(BASE + '/api/iap/revenuecat', {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...(auth ? { authorization: auth } : {}) },
    body: JSON.stringify(body),
  });

async function newUser(): Promise<{ id: string; token: string }> {
  const reg = await register(
    new Request(BASE + '/api/auth/register', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        name: 'RC',
        email: `rc-${Date.now()}-${Math.floor(Math.random() * 1e6)}@ea.dev`,
        password: 'rc-parola-123',
      }),
    })
  );
  const token = ((await reg.json()) as { token: string }).token;
  const who = await me(
    new Request(BASE + '/api/auth/me', { headers: { authorization: `Bearer ${token}` } })
  );
  const { user } = (await who.json()) as { user: { id: string } };
  return { id: user.id, token };
}

const event = (userId: string, type = 'INITIAL_PURCHASE') => ({
  event: {
    type,
    app_user_id: userId,
    product_id: 'premium-teori',
    transaction_id: 'rc-tx-1',
  },
});

async function owned(token: string): Promise<string[]> {
  const { GET } = await import('@/app/api/purchases/route');
  const res = await GET(
    new Request(BASE + '/api/purchases', { headers: { authorization: `Bearer ${token}` } })
  );
  // `/api/purchases` `{ purchases: [{ productId, … }] }` döner — `owned` alanı YOKTUR.
  const body = (await res.json()) as { purchases?: Array<{ productId: string }> };
  return (body.purchases ?? []).map((p) => p.productId);
}

afterEach(() => vi.unstubAllEnvs());

describe('/api/iap/revenuecat — güvenlik', () => {
  it('SIR AYARLI DEĞİLSE hiçbir şey yazmaz (fail-closed, 503)', async () => {
    vi.stubEnv('REVENUECAT_WEBHOOK_SECRET', '');
    const u = await newUser();
    const res = await rcWebhook(post(event(u.id), 'Bearer whatever'));
    expect(res.status).toBe(503);
    expect(await owned(u.token)).toEqual([]);
  });

  it('yanlış sırla 401 — ve sahiplik VERİLMEZ', async () => {
    vi.stubEnv('REVENUECAT_WEBHOOK_SECRET', SECRET);
    const u = await newUser();
    const res = await rcWebhook(post(event(u.id), 'Bearer yanlis-sir'));
    expect(res.status).toBe(401);
    expect(await owned(u.token)).toEqual([]);
  });

  it('başlık HİÇ yoksa 401', async () => {
    vi.stubEnv('REVENUECAT_WEBHOOK_SECRET', SECRET);
    const u = await newUser();
    expect((await rcWebhook(post(event(u.id)))).status).toBe(401);
  });

  it('HMAC imzası da kabul edilir (sha256=…)', async () => {
    vi.stubEnv('REVENUECAT_WEBHOOK_SECRET', SECRET);
    const u = await newUser();
    const body = event(u.id);
    const raw = JSON.stringify(body);
    const sig = createHmac('sha256', SECRET).update(raw).digest('hex');
    const res = await rcWebhook(
      new Request(BASE + '/api/iap/revenuecat', {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `sha256=${sig}` },
        body: raw,
      })
    );
    expect(res.status).toBe(200);
    expect(await owned(u.token)).toContain('premium-teori');
  });

  it('BOZUK HMAC reddedilir', async () => {
    vi.stubEnv('REVENUECAT_WEBHOOK_SECRET', SECRET);
    const u = await newUser();
    const res = await rcWebhook(post(event(u.id), 'sha256=' + 'a'.repeat(64)));
    expect(res.status).toBe(401);
    expect(await owned(u.token)).toEqual([]);
  });
});

describe('/api/iap/revenuecat — davranış', () => {
  it('geçerli olay sahiplik yazar', async () => {
    vi.stubEnv('REVENUECAT_WEBHOOK_SECRET', SECRET);
    const u = await newUser();
    const res = await rcWebhook(post(event(u.id), `Bearer ${SECRET}`));
    expect(res.status).toBe(200);
    expect(await owned(u.token)).toContain('premium-teori');
  });

  it('AYNI olay iki kez gelirse kopya sahiplik OLUŞMAZ', async () => {
    vi.stubEnv('REVENUECAT_WEBHOOK_SECRET', SECRET);
    const u = await newUser();
    await rcWebhook(post(event(u.id), `Bearer ${SECRET}`));
    await rcWebhook(post(event(u.id), `Bearer ${SECRET}`));
    const list = await owned(u.token);
    expect(list.filter((p) => p === 'premium-teori')).toHaveLength(1);
  });

  it('İPTAL/BİTİŞ olayları sahiplik ÜRETMEZ ama 200 döner', async () => {
    // 2xx dönmezse RevenueCat saatlerce yeniden dener; bu yüzden "yok sayıldı" da 200'dür.
    vi.stubEnv('REVENUECAT_WEBHOOK_SECRET', SECRET);
    const u = await newUser();
    const res = await rcWebhook(post(event(u.id, 'CANCELLATION'), `Bearer ${SECRET}`));
    expect(res.status).toBe(200);
    expect(await owned(u.token)).toEqual([]);
  });

  it('BİLİNMEYEN kullanıcı (anonim RC kimliği) yazmaz, 200 döner', async () => {
    vi.stubEnv('REVENUECAT_WEBHOOK_SECRET', SECRET);
    const body = {
      event: {
        type: 'INITIAL_PURCHASE',
        app_user_id: '$RCAnonymousID:abc',
        product_id: 'premium-teori',
      },
    };
    const res = await rcWebhook(post(body, `Bearer ${SECRET}`));
    expect(res.status).toBe(200);
    expect((await res.json()).ignored).toBe('unknown_user');
  });

  it('BİLİNMEYEN ürün yazmaz, 200 döner', async () => {
    vi.stubEnv('REVENUECAT_WEBHOOK_SECRET', SECRET);
    const u = await newUser();
    const body = {
      event: { type: 'INITIAL_PURCHASE', app_user_id: u.id, product_id: 'olmayan-urun' },
    };
    const res = await rcWebhook(post(body, `Bearer ${SECRET}`));
    expect(res.status).toBe(200);
    expect(await owned(u.token)).toEqual([]);
  });

  it('bozuk gövde → 400', async () => {
    vi.stubEnv('REVENUECAT_WEBHOOK_SECRET', SECRET);
    const res = await rcWebhook(
      new Request(BASE + '/api/iap/revenuecat', {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${SECRET}` },
        body: '{bozuk',
      })
    );
    expect(res.status).toBe(400);
  });
});
