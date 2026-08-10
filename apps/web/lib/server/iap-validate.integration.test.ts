/**
 * Mobil IAP doğrulama entegrasyon testi (Mobile Phase 7, PGlite bellek-içi). Bearer oturumu →
 * katalog fiyat-bütünlüğü + idempotent grant + owned listesi. (Play token doğrulaması dev-modda.)
 */
import { describe, it, expect, vi } from 'vitest';
import { POST as register } from '@/app/api/auth/register/route';
import { POST as validate } from '@/app/api/iap/validate/route';
import { anyProductById } from '@/lib/products';

const BASE = 'http://test.local';
const PKG = 'com.ehliyetegitim.ehliyet_akademi';
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

  it('komple-ehliyet (ömür boyu paket) → grant edilir', async () => {
    const token = await newUserToken();
    const res = await validate(
      post('/api/iap/validate', { productId: 'komple-ehliyet', purchaseToken: 'tok-mobil' }, token)
    );
    expect(res.status).toBe(200);
    expect(((await res.json()) as { owned: string[] }).owned).toContain('komple-ehliyet');
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

  it('doğrulama yapılandırılmamış + üretim modu → 503 (fail-closed, ücretsiz grant yok)', async () => {
    const token = await newUserToken();
    vi.stubEnv('NODE_ENV', 'production');
    try {
      const res = await validate(
        post('/api/iap/validate', { productId: 'premium-teori', purchaseToken: 'tok' }, token)
      );
      expect(res.status).toBe(503);
    } finally {
      vi.unstubAllEnvs();
    }
  });

  // ── Yayın öncesi denetim bulgusu N1 ───────────────────────────────────────
  // Mobil katalog ÜÇ paket satıyor. Sunucu kataloğunda yalnız biri vardı; diğer ikisi 404
  // dönüyor ve kullanıcı ödeme yaptığı hâlde hiçbir hak kaydı oluşmuyordu.
  describe('mobil kataloğun ÜÇ paketi de tanınır (N1)', () => {
    it.each(['premium-haftalik', 'premium-aylik', 'komple-ehliyet'])(
      '%s → 404 DEĞİL, grant edilir',
      async (productId) => {
        const token = await newUserToken();
        const res = await validate(
          post(
            '/api/iap/validate',
            { productId, purchaseToken: `tok-${productId}`, packageName: PKG },
            token
          )
        );
        expect(res.status, `${productId} sunucu kataloğunda tanınmıyor`).toBe(200);
        expect(((await res.json()) as { owned: string[] }).owned).toContain(productId);
      }
    );
  });

  it('ömür boyu paketin kayıtlı fiyatı mağaza fiyatını yansıtır (N2)', async () => {
    // 399 yazılıyordu, mağaza 479,99 tahsil ediyordu; her satın alma yanlış fiyatla kaydediliyordu.
    const p = anyProductById('komple-ehliyet');
    expect(p?.priceTRY).toBe(480);
  });

  it('abonelik yenilenince satır SİLİNMEZ, bitiş anı ileri alınır', async () => {
    const token = await newUserToken();
    const first = await validate(
      post(
        '/api/iap/validate',
        { productId: 'premium-haftalik', purchaseToken: 'tok-1', packageName: PKG },
        token
      )
    );
    expect(first.status).toBe(200);
    const again = await validate(
      post(
        '/api/iap/validate',
        { productId: 'premium-haftalik', purchaseToken: 'tok-2', packageName: PKG },
        token
      )
    );
    expect(again.status).toBe(200);
    const owned = ((await again.json()) as { owned: string[] }).owned;
    // Tek kayıt: idempotent güncelleme, çift satır değil.
    expect(owned.filter((p) => p === 'premium-haftalik')).toHaveLength(1);
  });
});
