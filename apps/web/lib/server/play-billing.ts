import { createSign } from 'node:crypto';

/**
 * Google Play satın alma doğrulaması — **Android Publisher API v3**.
 *
 * ## Neden bu dosya var
 *
 * Önceki `verifyPlayPurchase`, dört karakterden uzun HER jetona `valid: true` diyordu. Üretim
 * yalnızca `GOOGLE_PLAY_SA_JSON` TANIMSIZ olduğu için güvendeydi: uç 503 dönüyordu. O değişken
 * ayarlandığı anda iskele devreye girer ve **kimliği doğrulanmış herhangi bir kullanıcı dört
 * karakterlik bir dizeyle kendine ömür boyu premium verebilirdi.** Bu dosya o boşluğu kapatır.
 *
 * ## Neden `googleapis` paketi yok
 *
 * `googleapis` onlarca megabaytlık, tüm Google API yüzeyini taşıyan bir pakettir; burada
 * kullanılan uç sayısı **iki**. Bunun yerine resmî REST API'si doğrudan çağrılır ve servis hesabı
 * jetonu Node'un yerleşik `crypto` modülüyle imzalanır. Sonuç: yeni bağımlılık yok, soğuk başlangıç
 * cezası yok, test edilebilirlik tam (taşıma katmanı enjekte edilebilir).
 *
 * ## Ürün türleri
 *
 * · **Tek seferlik** (`komple-ehliyet`) → `purchases.products.get`
 *   `purchaseState`: 0 = satın alındı · 1 = iptal · 2 = beklemede
 * · **Abonelik** (`premium-haftalik`, `premium-aylik`) → `purchases.subscriptionsv2.get`
 *   `subscriptionState`: ACTIVE / IN_GRACE_PERIOD kabul edilir; diğerleri reddedilir.
 *
 * ## Uydurma yok
 *
 * Bu modül hiçbir koşulda sahte bir Google yanıtı üretmez. Kimlik bilgisi yoksa
 * [isPlayVerificationConfigured] `false` döner ve çağıran taraf **fail-closed** davranmak
 * zorundadır.
 */

/** Play'in kabul ettiği satın alma durumu. */
export interface PlayVerdict {
  valid: boolean;
  /** Makine tarafından okunabilir ret sebebi. */
  reason?: string;
  /** Abonelikler için bitiş anı (ms). Tek seferlik üründe `null` — süresiz. */
  expiresAtMs?: number | null;
  /** Play'in döndürdüğü ham durum — günlükleme ve teşhis için. */
  state?: string;
}

/** Servis hesabı JSON'unun kullandığımız alanları. */
export interface PlayServiceAccount {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

/** Test edilebilirlik için tek ağ girişi. `fetch` ile aynı sözleşme. */
export type HttpFetch = (
  url: string,
  init?: { method?: string; headers?: Record<string, string>; body?: string }
) => Promise<{
  ok: boolean;
  status: number;
  json: () => Promise<unknown>;
  text: () => Promise<string>;
}>;

const OAUTH_SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const DEFAULT_TOKEN_URI = 'https://oauth2.googleapis.com/token';
const API_ROOT = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';

/** Kabul edilen abonelik durumları — ödemesiz dönem dâhil, çünkü erişim orada da açıktır. */
const ACTIVE_SUBSCRIPTION_STATES = new Set([
  'SUBSCRIPTION_STATE_ACTIVE',
  'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
]);

/** Doğrulama yapılandırılmış mı? Yapılandırılmamışsa çağıran taraf ASLA grant vermemelidir. */
export function isPlayVerificationConfigured(env: NodeJS.ProcessEnv = process.env): boolean {
  return parseServiceAccount(env) !== null;
}

/**
 * Servis hesabını ortamdan çöz.
 *
 * Bozuk JSON veya eksik alan → `null`. Sessizce "kısmen yapılandırılmış" bir duruma DÜŞMEZ:
 * yarı yapılandırma, doğrulamanın çalıştığı sanılırken çalışmadığı en tehlikeli durumdur.
 */
export function parseServiceAccount(
  env: NodeJS.ProcessEnv = process.env
): PlayServiceAccount | null {
  const raw = env.GOOGLE_PLAY_SA_JSON;
  if (!raw || !raw.trim()) return null;
  try {
    const parsed = JSON.parse(raw) as Partial<PlayServiceAccount>;
    if (!parsed.client_email || !parsed.private_key) return null;
    return {
      client_email: parsed.client_email,
      private_key: parsed.private_key.replace(/\\n/g, '\n'),
      token_uri: parsed.token_uri ?? DEFAULT_TOKEN_URI,
    };
  } catch {
    return null;
  }
}

const b64url = (input: Buffer | string): string =>
  Buffer.from(input).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

/**
 * Servis hesabı için RS256 imzalı JWT üret (OAuth2 JWT-bearer akışı).
 *
 * `nowSec` dışarıdan verilir: `Date.now()` çağıran saf olmayan bir fonksiyon test edilemezdi.
 *
 * ## CodeQL `js/insufficient-password-hash` — YANLIŞ POZİTİF
 *
 * Tarayıcı, `createSign('RSA-SHA256')` çağrısını "parolayı düşük maliyetli bir özetle hash'lemek"
 * sanıyor ve bcrypt/scrypt/PBKDF2 öneriyor. Burada **parola yok ve hash'leme yok**: bu bir
 * DİJİTAL İMZADIR. `sa.private_key` özetlenmez, imzalamak için kullanılır.
 *
 * RS256, Google'ın servis hesabı OAuth2 akışının **zorunlu** algoritmasıdır; yerine bir parola
 * türetme fonksiyonu koymak protokolü tümden bozardı — jeton ucu imzayı doğrulayamaz ve hiçbir
 * satın alma doğrulanamazdı. Uyarı bu gerekçeyle kapatıldı (alert #6, false positive).
 */
export function createSignedJwt(sa: PlayServiceAccount, nowSec: number): string {
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = b64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: OAUTH_SCOPE,
      aud: sa.token_uri ?? DEFAULT_TOKEN_URI,
      iat: nowSec,
      exp: nowSec + 3600,
    })
  );
  const signer = createSign('RSA-SHA256');
  signer.update(`${header}.${claims}`);
  return `${header}.${claims}.${b64url(signer.sign(sa.private_key))}`;
}

/** Erişim jetonu önbelleği — jeton bir saat geçerlidir, her istekte yenilemek israftır. */
let tokenCache: { token: string; expiresAtMs: number } | null = null;

/** Test yalıtımı: önbelleği sıfırla. */
export function resetPlayTokenCache(): void {
  tokenCache = null;
}

async function getAccessToken(
  sa: PlayServiceAccount,
  http: HttpFetch,
  nowMs: number
): Promise<string | null> {
  if (tokenCache && tokenCache.expiresAtMs > nowMs + 60_000) return tokenCache.token;

  const assertion = createSignedJwt(sa, Math.floor(nowMs / 1000));
  const res = await http(sa.token_uri ?? DEFAULT_TOKEN_URI, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }).toString(),
  });
  if (!res.ok) return null;

  const body = (await res.json()) as { access_token?: string; expires_in?: number };
  if (!body.access_token) return null;

  tokenCache = {
    token: body.access_token,
    expiresAtMs: nowMs + (body.expires_in ?? 3600) * 1000,
  };
  return body.access_token;
}

export interface VerifyArgs {
  packageName: string;
  /** Play Store ürün kimliği (alt çizgili biçim, ör. `komple_ehliyet`). */
  storeProductId: string;
  purchaseToken: string;
  /** Abonelik mi, tek seferlik ürün mü. */
  kind: 'subscription' | 'product';
  http?: HttpFetch;
  nowMs?: number;
  env?: NodeJS.ProcessEnv;
}

/**
 * Satın almayı Google'a sor.
 *
 * Ağ/kimlik hatalarında **`valid: false`** döner — "doğrulayamadım" ile "geçerli" asla
 * karıştırılmaz. Bu, bu dosyanın var oluş sebebidir.
 */
export async function verifyPlayPurchase(args: VerifyArgs): Promise<PlayVerdict> {
  const {
    packageName,
    storeProductId,
    purchaseToken,
    kind,
    http = globalThis.fetch as unknown as HttpFetch,
    nowMs = Date.now(),
    env = process.env,
  } = args;

  if (!purchaseToken || purchaseToken.length < 20) {
    // Gerçek Play jetonları uzun, opak dizelerdir. Kısa bir dize ağa çıkmadan reddedilir.
    return { valid: false, reason: 'malformed_token' };
  }
  if (!packageName) return { valid: false, reason: 'missing_package' };

  const sa = parseServiceAccount(env);
  if (!sa) return { valid: false, reason: 'verification_not_configured' };

  const token = await getAccessToken(sa, http, nowMs);
  if (!token) return { valid: false, reason: 'auth_failed' };

  const path =
    kind === 'subscription'
      ? `${API_ROOT}/${encodeURIComponent(packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`
      : `${API_ROOT}/${encodeURIComponent(packageName)}/purchases/products/${encodeURIComponent(storeProductId)}/tokens/${encodeURIComponent(purchaseToken)}`;

  let res: Awaited<ReturnType<HttpFetch>>;
  try {
    res = await http(path, { headers: { authorization: `Bearer ${token}` } });
  } catch {
    return { valid: false, reason: 'network_error' };
  }

  if (res.status === 404) return { valid: false, reason: 'token_not_found' };
  if (res.status === 401 || res.status === 403) return { valid: false, reason: 'auth_failed' };
  if (!res.ok) return { valid: false, reason: `play_error_${res.status}` };

  const body = (await res.json()) as Record<string, unknown>;

  if (kind === 'product') {
    // purchaseState: 0 satın alındı · 1 iptal · 2 beklemede
    const state = body.purchaseState;
    if (state !== 0) {
      return { valid: false, reason: 'not_purchased', state: String(state) };
    }
    return { valid: true, expiresAtMs: null, state: 'purchased' };
  }

  const subState = typeof body.subscriptionState === 'string' ? body.subscriptionState : '';
  if (!ACTIVE_SUBSCRIPTION_STATES.has(subState)) {
    return { valid: false, reason: 'subscription_inactive', state: subState };
  }

  // subscriptionsv2 → lineItems[].expiryTime (RFC3339). En geç bitiş anı alınır.
  const lineItems = Array.isArray(body.lineItems) ? body.lineItems : [];
  let expiresAtMs: number | null = null;
  for (const li of lineItems) {
    const t = (li as { expiryTime?: string }).expiryTime;
    if (!t) continue;
    const ms = Date.parse(t);
    if (!Number.isNaN(ms) && (expiresAtMs === null || ms > expiresAtMs)) expiresAtMs = ms;
  }
  if (expiresAtMs === null) {
    // Etkin bir abonelikte bitiş anı olmaması beklenmez. Süresiz kabul etmek, haftalık bir paketi
    // ömür boyu erişime çevirirdi — reddetmek doğru taraftır.
    return { valid: false, reason: 'missing_expiry', state: subState };
  }

  return { valid: true, expiresAtMs, state: subState };
}
