/**
 * Google ID token doğrulaması — SAF mantık (Beta Faz 2).
 *
 * NEDEN SUNUCUDA: istemcinin "ben şu kullanıcıyım" iddiasına güvenilemez. Uygulama değiştirilerek
 * herhangi bir e-posta iddia edilebilir. Tek güvenilir kanıt, Google'ın imzaladığı ID token'ın
 * BURADA doğrulanmasıdır.
 *
 * Bu dosyada ağ çağrısı YOKTUR: JWKS'i çağıran taraf getirir, çözümleme ve iddia (claim)
 * doğrulaması burada yapılır → doğrudan test edilir (E8'den beri süren "saf katman" deseni).
 */

/** Google'ın kabul ettiği iki `iss` değeri. */
export const GOOGLE_ISSUERS = ['accounts.google.com', 'https://accounts.google.com'] as const;

export interface GoogleIdTokenClaims {
  iss: string;
  aud: string;
  sub: string;
  exp: number;
  iat?: number;
  email?: string;
  email_verified?: boolean | string;
  name?: string;
  picture?: string;
}

export type VerifyFailure =
  | 'malformed'
  | 'bad-signature'
  | 'bad-issuer'
  | 'bad-audience'
  | 'expired'
  | 'email-missing'
  | 'email-unverified';

export type VerifyResult =
  { ok: true; claims: GoogleIdTokenClaims } | { ok: false; reason: VerifyFailure };

/** base64url → UTF-8 metin. */
function decodeSegment(segment: string): string | null {
  try {
    const padded = segment.replace(/-/g, '+').replace(/_/g, '/');
    return Buffer.from(padded, 'base64').toString('utf8');
  } catch {
    return null;
  }
}

/**
 * JWT'nin başlığını ve gövdesini **doğrulamadan** çözümler.
 *
 * DİKKAT: bu fonksiyon tek başına GÜVENLİ DEĞİLDİR. Yalnız `kid` okumak ve biçim kontrolü için
 * kullanılır; kabul kararı [verifyGoogleClaims] + imza doğrulamasıyla verilir.
 */
export function decodeJwtUnsafe(
  token: string
): { header: Record<string, unknown>; claims: GoogleIdTokenClaims } | null {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const headerRaw = decodeSegment(parts[0]!);
  const claimsRaw = decodeSegment(parts[1]!);
  if (!headerRaw || !claimsRaw) return null;
  try {
    const header = JSON.parse(headerRaw) as Record<string, unknown>;
    const claims = JSON.parse(claimsRaw) as GoogleIdTokenClaims;
    if (typeof claims?.aud !== 'string' || typeof claims?.iss !== 'string') return null;
    return { header, claims };
  } catch {
    return null;
  }
}

/**
 * İddiaları doğrular. **İmza doğrulaması ayrıdır** — çağıran taraf onu yapıp sonucu buraya
 * `signatureValid` ile bildirir.
 *
 * `nowSeconds` dışarıdan verilir → test belirlenimci olur.
 */
export function verifyGoogleClaims(args: {
  claims: GoogleIdTokenClaims;
  audience: string;
  signatureValid: boolean;
  nowSeconds: number;
  /** Saat kayması payı; Google'ın önerdiği aralık. */
  clockSkewSeconds?: number;
}): VerifyResult {
  const { claims, audience, signatureValid, nowSeconds, clockSkewSeconds = 60 } = args;

  if (!signatureValid) return { ok: false, reason: 'bad-signature' };

  if (!GOOGLE_ISSUERS.includes(claims.iss as (typeof GOOGLE_ISSUERS)[number])) {
    return { ok: false, reason: 'bad-issuer' };
  }

  // `aud` BİZİM sunucu istemcimiz olmalı. Başka bir uygulamanın token'ı buraya geçmemeli —
  // aksi hâlde başka bir Google uygulamasının kullanıcısı bizim hesabımıza girebilirdi.
  if (claims.aud !== audience) return { ok: false, reason: 'bad-audience' };

  if (typeof claims.exp !== 'number' || claims.exp + clockSkewSeconds <= nowSeconds) {
    return { ok: false, reason: 'expired' };
  }

  const email = (claims.email ?? '').trim().toLowerCase();
  if (!email) return { ok: false, reason: 'email-missing' };

  // Google `email_verified`'ı bazen dizgi ("true") olarak gönderir.
  const verified = claims.email_verified === true || claims.email_verified === 'true';
  if (!verified) return { ok: false, reason: 'email-unverified' };

  return { ok: true, claims: { ...claims, email } };
}

/** Kullanıcıya gösterilecek Türkçe hata karşılıkları (durum sızdırmadan). */
export function failureMessage(reason: VerifyFailure): string {
  switch (reason) {
    case 'email-unverified':
      return 'Google hesabının e-postası doğrulanmamış.';
    case 'expired':
      return 'Giriş isteğinin süresi doldu. Tekrar dene.';
    default:
      // Diğer bütün nedenler AYNI mesajı verir: hangi kontrolün düştüğü saldırgana bilgi vermez.
      return 'Google ile giriş doğrulanamadı.';
  }
}

/**
 * Google hesabından görünen ad türetir. Ad yoksa e-postanın yerel kısmından üretilir;
 * boş ad kaydedilmez.
 */
export function displayNameFrom(claims: GoogleIdTokenClaims): string {
  const name = (claims.name ?? '').trim();
  if (name) return name.slice(0, 80);
  const local = (claims.email ?? '').split('@')[0] ?? '';
  return (local || 'Sürücü adayı').slice(0, 80);
}
