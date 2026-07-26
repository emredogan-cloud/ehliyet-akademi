import { createPublicKey, createVerify } from 'node:crypto';
import { eq } from 'drizzle-orm';
import { getDb, users } from '@ea/db';
import { createSession, sessionSetCookie, json, guarded, newId } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import {
  decodeJwtUnsafe,
  displayNameFrom,
  failureMessage,
  verifyGoogleClaims,
  type VerifyFailure,
} from '@/lib/server/google-verify';

/**
 * Google ile giriş (Beta Faz 2).
 *
 * İstemci `idToken` gönderir; burada Google'ın açık anahtarlarıyla DOĞRULANIR ve mevcut sistemin
 * **Bearer oturumuna** çevrilir. Yeni bir oturum sistemi getirilmez — var olana bir giriş kapısı
 * eklenir (e-posta/parola yolu olduğu gibi durur).
 *
 * GÜVENLİK: doğrulama olmadan e-postaya güvenmek, istemciyi değiştiren birinin herhangi bir
 * hesaba girmesi demekti. Kabul kararı `lib/server/google-verify.ts` (saf, 21 testli) ile verilir.
 */

const JWKS_URL = 'https://www.googleapis.com/oauth2/v3/certs';

interface Jwk {
  kid: string;
  n: string;
  e: string;
  alg?: string;
  kty?: string;
}

/** JWKS önbelleği — her giriş isteğinde Google'a gitmemek için. */
let jwksCache: { keys: Jwk[]; fetchedAt: number } | null = null;
const JWKS_TTL_MS = 60 * 60 * 1000;

async function getJwks(): Promise<Jwk[]> {
  const now = Date.now();
  if (jwksCache && now - jwksCache.fetchedAt < JWKS_TTL_MS) return jwksCache.keys;
  const res = await fetch(JWKS_URL);
  if (!res.ok) throw new Error('JWKS alınamadı');
  const body = (await res.json()) as { keys: Jwk[] };
  jwksCache = { keys: body.keys ?? [], fetchedAt: now };
  return jwksCache.keys;
}

/** RS256 imzasını JWK ile doğrular. */
function verifySignature(token: string, jwk: Jwk): boolean {
  const [headerB64, payloadB64, signatureB64] = token.split('.');
  if (!headerB64 || !payloadB64 || !signatureB64) return false;
  try {
    const key = createPublicKey({ key: { kty: 'RSA', n: jwk.n, e: jwk.e }, format: 'jwk' });
    const verifier = createVerify('RSA-SHA256');
    verifier.update(`${headerB64}.${payloadB64}`);
    verifier.end();
    return verifier.verify(key, Buffer.from(signatureB64, 'base64url'));
  } catch {
    return false;
  }
}

export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'auth-google', limit: 10, windowMs: 60_000 });
  if (limited) return limited;

  const audience = process.env.GOOGLE_SERVER_CLIENT_ID ?? '';
  if (!audience) {
    // Yapılandırma eksikse DÜRÜST 503 — sahte bir başarı döndürülmez.
    return json({ error: 'Google ile giriş bu sunucuda yapılandırılmadı.' }, { status: 503 });
  }

  let body: { idToken?: unknown };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const idToken = typeof body.idToken === 'string' ? body.idToken : '';
  if (!idToken) return json({ error: failureMessage('malformed') }, { status: 401 });

  const decoded = decodeJwtUnsafe(idToken);
  if (!decoded) return json({ error: failureMessage('malformed') }, { status: 401 });

  // İmza: token'ın `kid`'ine karşılık gelen Google anahtarıyla doğrulanır.
  let signatureValid = false;
  try {
    const kid = typeof decoded.header.kid === 'string' ? decoded.header.kid : '';
    const jwk = (await getJwks()).find((k) => k.kid === kid);
    if (jwk) signatureValid = verifySignature(idToken, jwk);
  } catch {
    // Google'a ulaşılamadıysa giriş REDDEDİLİR; doğrulanmamış token kabul edilmez.
    return json({ error: 'Google doğrulama servisine ulaşılamadı. Tekrar dene.' }, { status: 503 });
  }

  const result = verifyGoogleClaims({
    claims: decoded.claims,
    audience,
    signatureValid,
    nowSeconds: Math.floor(Date.now() / 1000),
  });
  if (!result.ok) {
    return json({ error: failureMessage(result.reason as VerifyFailure) }, { status: 401 });
  }

  const email = result.claims.email!;
  const db = await getDb();
  const existing = (await db.select().from(users).where(eq(users.email, email)).limit(1))[0];

  let userId: string;
  let name: string;
  if (existing) {
    // HESAP BİRLEŞTİRME: aynı e-posta ile daha önce parolayla kaydolmuş kullanıcı, Google ile de
    // girebilir. Ayrı bir hesap AÇILMAZ — aksi hâlde ilerleme ikiye bölünürdü.
    userId = existing.id;
    name = existing.name;
  } else {
    userId = newId();
    name = displayNameFrom(result.claims);
    await db.insert(users).values({
      id: userId,
      email,
      name,
      // Parola girişi YOK: bu hesap yalnız Google ile açılır. Doğrulanamayan bir hash konur ki
      // `verifyPassword` her zaman false dönsün.
      passwordHash: 'google$no-password',
      // Google e-postayı zaten doğruladı (verifyGoogleClaims bunu şart koşuyor).
      emailVerified: true,
    });
  }

  const token = await createSession(db, userId, req.headers.get('user-agent') ?? '');
  return json(
    { user: { id: userId, email, name }, token },
    { status: existing ? 200 : 201, setCookie: sessionSetCookie(token) }
  );
});
