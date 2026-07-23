/**
 * Mobil IAP doğrulama entegrasyon testi (Mobile Phase 7, PGlite bellek-içi). Bearer oturumu →
 * katalog fiyat-bütünlüğü + idempotent grant + owned listesi. (Play token doğrulaması dev-modda.)
 */
import { describe, it, expect } from 'vitest';
import { POST as register } from '@/app/api/auth/register/route';
import { POST as validate } from '@/app/api/iap/validate/route';

const BASE = 'http://test.local';
const post = (path: string, body: unknown, token?: string) =>
  new Request(BASE + path, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  });

async function newUserToken(): Promise<string> {
  const reg = await register(
    post('/api/auth/register', {
      name: 'IAP',
      email: `iap-${Date.now()}-${Math.floor(Math.random() * 1e6)}@ea.dev`,
      password: 'iap-parola-123',
    })
  );
  return ((await reg.json()) as { token: string }).token;
}

describe('mobil IAP /api/iap/validate', () => {
  it('geçerli satın alma → grant + owned döner; idempotent', async () => {
    const token = await newUserToken();
    const res = await validate(
      post(
        '/api/iap/validate',
        {
          productId: 'premium-teori',
          purchaseToken: 'play-token-abc',
          packageName: 'com.ehliyetegitim.ehliyet_akademi',
        },
        token
      )
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as { ok: boolean; owned: string[] };
    expect(body.ok).toBe(true);
    expect(body.owned).toContain('premium-teori');

    // aynı ürün tekrar → idempotent (tek kayıt)
    const again = await validate(
      post(
        '/api/iap/validate',
        { productId: 'premium-teori', purchaseToken: 'play-token-abc' },
        token
      )
    );
    const b2 = (await again.json()) as { owned: string[] };
    expect(b2.owned.filter((p) => p === 'premium-teori')).toHaveLength(1);
  });

  it('komple-b → tüm yetenekleri kapsayan ürün grant edilir', async () => {
    const token = await newUserToken();
    const res = await validate(
      post('/api/iap/validate', { productId: 'komple-b', purchaseToken: 'tok-komple' }, token)
    );
    expect(res.status).toBe(200);
    expect(((await res.json()) as { owned: string[] }).owned).toContain('komple-b');
  });

  it('bilinmeyen ürün → 404', async () => {
    const token = await newUserToken();
    const res = await validate(
      post('/api/iap/validate', { productId: 'yok', purchaseToken: 't' }, token)
    );
    expect(res.status).toBe(404);
  });

  it('token yoksa → 400', async () => {
    const token = await newUserToken();
    const res = await validate(post('/api/iap/validate', { productId: 'premium-teori' }, token));
    expect(res.status).toBe(400);
  });

  it('oturum yoksa → 401', async () => {
    const res = await validate(
      post('/api/iap/validate', { productId: 'premium-teori', purchaseToken: 't' })
    );
    expect(res.status).toBe(401);
  });
});
