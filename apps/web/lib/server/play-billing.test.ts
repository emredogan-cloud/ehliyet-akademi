import { describe, it, expect, beforeEach } from 'vitest';
import { generateKeyPairSync } from 'node:crypto';
import {
  createSignedJwt,
  isPlayVerificationConfigured,
  parseServiceAccount,
  resetPlayTokenCache,
  verifyPlayPurchase,
  type HttpFetch,
} from './play-billing';

/** Test için gerçek bir RSA çifti — imzalama yolunun gerçekten çalıştığını görmek için. */
const { privateKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
  publicKeyEncoding: { type: 'spki', format: 'pem' },
});

const SA = {
  client_email: 'play@ehliyet.iam.gserviceaccount.com',
  private_key: privateKey as string,
  token_uri: 'https://oauth2.googleapis.com/token',
};

const ENV = { GOOGLE_PLAY_SA_JSON: JSON.stringify(SA) } as unknown as NodeJS.ProcessEnv;

const PKG = 'com.ehliyetegitim.ehliyet_akademi';
const TOKEN = 'a'.repeat(60); // gerçek Play jetonları uzun ve opaktır

/** Sahte HTTP: önce jeton ucu, sonra Play ucu. Çağrılan URL'leri kaydeder. */
function stubHttp(playStatus: number, playBody: unknown, opts: { authOk?: boolean } = {}) {
  const calls: string[] = [];
  const http: HttpFetch = async (url) => {
    calls.push(url);
    if (url.includes('oauth2.googleapis.com/token')) {
      return opts.authOk === false
        ? { ok: false, status: 401, json: async () => ({}), text: async () => '' }
        : {
            ok: true,
            status: 200,
            json: async () => ({ access_token: 'tok-123', expires_in: 3600 }),
            text: async () => '',
          };
    }
    return {
      ok: playStatus >= 200 && playStatus < 300,
      status: playStatus,
      json: async () => playBody,
      text: async () => JSON.stringify(playBody),
    };
  };
  return { http, calls };
}

beforeEach(() => resetPlayTokenCache());

describe('servis hesabı çözümleme', () => {
  it('geçerli JSON → kimlik döner', () => {
    expect(parseServiceAccount(ENV)?.client_email).toBe(SA.client_email);
    expect(isPlayVerificationConfigured(ENV)).toBe(true);
  });

  it('tanımsız / boş / bozuk JSON → null (yarı yapılandırma yok)', () => {
    for (const raw of [undefined, '', '   ', '{bozuk', '{}', '{"client_email":"a"}']) {
      const env = { GOOGLE_PLAY_SA_JSON: raw } as unknown as NodeJS.ProcessEnv;
      expect(parseServiceAccount(env), `raw=${String(raw)}`).toBeNull();
      expect(isPlayVerificationConfigured(env)).toBe(false);
    }
  });

  it('kaçışlı satır sonları gerçek satır sonuna çevrilir', () => {
    const env = {
      GOOGLE_PLAY_SA_JSON: JSON.stringify({
        client_email: 'a@b.c',
        private_key: '-----BEGIN-----\\nABC\\n-----END-----',
      }),
    } as unknown as NodeJS.ProcessEnv;
    expect(parseServiceAccount(env)?.private_key).toContain('\n');
  });
});

describe('JWT imzalama', () => {
  it('üç parçalı, RS256 başlıklı bir JWT üretir', () => {
    const jwt = createSignedJwt(SA, 1_700_000_000);
    const parts = jwt.split('.');
    expect(parts).toHaveLength(3);
    const header = JSON.parse(Buffer.from(parts[0]!, 'base64url').toString());
    expect(header).toEqual({ alg: 'RS256', typ: 'JWT' });
    const claims = JSON.parse(Buffer.from(parts[1]!, 'base64url').toString());
    expect(claims.iss).toBe(SA.client_email);
    expect(claims.scope).toBe('https://www.googleapis.com/auth/androidpublisher');
    expect(claims.exp - claims.iat).toBe(3600);
    expect(parts[2]!.length).toBeGreaterThan(100); // imza gerçekten üretildi
  });
});

describe('tek seferlik ürün doğrulaması', () => {
  const args = {
    packageName: PKG,
    storeProductId: 'komple_ehliyet',
    purchaseToken: TOKEN,
    kind: 'product' as const,
    env: ENV,
  };

  it('purchaseState=0 → geçerli, süresiz', async () => {
    const { http, calls } = stubHttp(200, { purchaseState: 0 });
    const v = await verifyPlayPurchase({ ...args, http });
    expect(v.valid).toBe(true);
    expect(v.expiresAtMs).toBeNull();
    // Doğru uca gitmiş olmalı: products, subscriptionsv2 DEĞİL.
    expect(calls.some((c) => c.includes('/purchases/products/komple_ehliyet/tokens/'))).toBe(true);
    expect(calls.some((c) => c.includes('subscriptionsv2'))).toBe(false);
  });

  it('purchaseState=1 (iptal) → reddedilir', async () => {
    const { http } = stubHttp(200, { purchaseState: 1 });
    const v = await verifyPlayPurchase({ ...args, http });
    expect(v.valid).toBe(false);
    expect(v.reason).toBe('not_purchased');
  });

  it('purchaseState=2 (beklemede) → reddedilir', async () => {
    const { http } = stubHttp(200, { purchaseState: 2 });
    expect((await verifyPlayPurchase({ ...args, http })).valid).toBe(false);
  });

  it('bilinmeyen jeton (404) → reddedilir', async () => {
    const { http } = stubHttp(404, {});
    const v = await verifyPlayPurchase({ ...args, http });
    expect(v.valid).toBe(false);
    expect(v.reason).toBe('token_not_found');
  });

  it('yanlış paket adı istekte YER ALIR — Google eşleşmezse 404 döner', async () => {
    const { http, calls } = stubHttp(404, {});
    const v = await verifyPlayPurchase({ ...args, packageName: 'com.baska.paket', http });
    expect(v.valid).toBe(false);
    expect(calls.some((c) => c.includes('com.baska.paket'))).toBe(true);
  });

  it('paket adı boşsa ağa hiç çıkılmaz', async () => {
    const { http, calls } = stubHttp(200, { purchaseState: 0 });
    const v = await verifyPlayPurchase({ ...args, packageName: '', http });
    expect(v.valid).toBe(false);
    expect(v.reason).toBe('missing_package');
    expect(calls).toHaveLength(0);
  });
});

describe('kötü biçimli jeton — ağa çıkmadan reddedilir', () => {
  const base = {
    packageName: PKG,
    storeProductId: 'komple_ehliyet',
    kind: 'product' as const,
    env: ENV,
  };

  it.each(['', 'x', 'abcd', 'kisa-jeton-19x'])('jeton %o → malformed_token', async (t) => {
    const { http, calls } = stubHttp(200, { purchaseState: 0 });
    const v = await verifyPlayPurchase({ ...base, purchaseToken: t, http });
    expect(v.valid).toBe(false);
    expect(v.reason).toBe('malformed_token');
    expect(calls, 'kısa jeton için ağ isteği yapılmamalı').toHaveLength(0);
  });
});

describe('abonelik doğrulaması', () => {
  const args = {
    packageName: PKG,
    storeProductId: 'premium_haftalik',
    purchaseToken: TOKEN,
    kind: 'subscription' as const,
    env: ENV,
  };
  const future = new Date(Date.now() + 7 * 86_400_000).toISOString();

  it('ACTIVE + bitiş anı → geçerli, süre taşınır', async () => {
    const { http, calls } = stubHttp(200, {
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      lineItems: [{ expiryTime: future }],
    });
    const v = await verifyPlayPurchase({ ...args, http });
    expect(v.valid).toBe(true);
    expect(v.expiresAtMs).toBe(Date.parse(future));
    expect(calls.some((c) => c.includes('/purchases/subscriptionsv2/tokens/'))).toBe(true);
  });

  it('IN_GRACE_PERIOD → kabul edilir (erişim açıktır)', async () => {
    const { http } = stubHttp(200, {
      subscriptionState: 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
      lineItems: [{ expiryTime: future }],
    });
    expect((await verifyPlayPurchase({ ...args, http })).valid).toBe(true);
  });

  it.each([
    'SUBSCRIPTION_STATE_EXPIRED',
    'SUBSCRIPTION_STATE_CANCELED',
    'SUBSCRIPTION_STATE_ON_HOLD',
    'SUBSCRIPTION_STATE_PAUSED',
    'SUBSCRIPTION_STATE_PENDING',
  ])('%s → reddedilir', async (state) => {
    const { http } = stubHttp(200, {
      subscriptionState: state,
      lineItems: [{ expiryTime: future }],
    });
    const v = await verifyPlayPurchase({ ...args, http });
    expect(v.valid).toBe(false);
    expect(v.reason).toBe('subscription_inactive');
  });

  it('etkin ama bitiş anı yoksa REDDEDİLİR — haftalık paket ömür boyu olamaz', async () => {
    const { http } = stubHttp(200, {
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      lineItems: [{}],
    });
    const v = await verifyPlayPurchase({ ...args, http });
    expect(v.valid).toBe(false);
    expect(v.reason).toBe('missing_expiry');
  });
});

describe('fail-closed davranış', () => {
  const args = {
    packageName: PKG,
    storeProductId: 'komple_ehliyet',
    purchaseToken: TOKEN,
    kind: 'product' as const,
  };

  it('kimlik bilgisi yoksa doğrulama BAŞARISIZDIR — "geçerli" değil', async () => {
    const { http } = stubHttp(200, { purchaseState: 0 });
    const v = await verifyPlayPurchase({
      ...args,
      http,
      env: {} as NodeJS.ProcessEnv,
    });
    expect(v.valid).toBe(false);
    expect(v.reason).toBe('verification_not_configured');
  });

  it('jeton alınamazsa (401) reddedilir', async () => {
    const { http } = stubHttp(200, { purchaseState: 0 }, { authOk: false });
    const v = await verifyPlayPurchase({ ...args, http, env: ENV });
    expect(v.valid).toBe(false);
    expect(v.reason).toBe('auth_failed');
  });

  it('ağ hatası "geçerli" sayılmaz', async () => {
    const http: HttpFetch = async (url) => {
      if (url.includes('oauth2')) {
        return {
          ok: true,
          status: 200,
          json: async () => ({ access_token: 't', expires_in: 3600 }),
          text: async () => '',
        };
      }
      throw new Error('ECONNRESET');
    };
    const v = await verifyPlayPurchase({ ...args, http, env: ENV });
    expect(v.valid).toBe(false);
    expect(v.reason).toBe('network_error');
  });

  it('Play 500 dönerse reddedilir', async () => {
    const { http } = stubHttp(500, {});
    const v = await verifyPlayPurchase({ ...args, http, env: ENV });
    expect(v.valid).toBe(false);
    expect(v.reason).toBe('play_error_500');
  });

  it('403 (yetki yok) → auth_failed', async () => {
    const { http } = stubHttp(403, {});
    expect((await verifyPlayPurchase({ ...args, http, env: ENV })).reason).toBe('auth_failed');
  });
});

describe('erişim jetonu önbelleği', () => {
  it('ikinci doğrulamada jeton ucu YENİDEN çağrılmaz', async () => {
    const { http, calls } = stubHttp(200, { purchaseState: 0 });
    const args = {
      packageName: PKG,
      storeProductId: 'komple_ehliyet',
      purchaseToken: TOKEN,
      kind: 'product' as const,
      env: ENV,
      http,
    };
    await verifyPlayPurchase(args);
    await verifyPlayPurchase(args);
    expect(calls.filter((c) => c.includes('oauth2')).length).toBe(1);
  });
});
