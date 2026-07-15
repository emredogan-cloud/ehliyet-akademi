/**
 * Sunucu auth çekirdeği (Sprint 1 / ADR-004 güncel):
 * - Parola: node:crypto scrypt (bağımlılıksız, güçlü KDF)
 * - Oturum: DB-destekli rastgele token (yalnız SHA-256 hash'i saklanır) → çok-cihaz doğal
 * - Çerez: httpOnly + SameSite=Lax (+prod'da Secure)
 * Route handler'lar Request/Response ile çalışır (framework-bağımsız, testlenebilir).
 */
import { randomBytes, randomUUID, scryptSync, timingSafeEqual, createHash } from 'node:crypto';
import { eq } from 'drizzle-orm';
import { getDb, users, sessions, type Db } from '@ea/db';

export const SESSION_COOKIE = 'ea_session';
const SESSION_DAYS = 30;

/* ---------- parola ---------- */
export function hashPassword(pw: string): string {
  const salt = randomBytes(16).toString('hex');
  const hash = scryptSync(pw, salt, 64, { N: 16384, r: 8, p: 1 }).toString('hex');
  return `scrypt$${salt}$${hash}`;
}
export function verifyPassword(pw: string, stored: string): boolean {
  const [algo, salt, hash] = stored.split('$');
  if (algo !== 'scrypt' || !salt || !hash) return false;
  const calc = scryptSync(pw, salt, 64, { N: 16384, r: 8, p: 1 });
  const ref = Buffer.from(hash, 'hex');
  return calc.length === ref.length && timingSafeEqual(calc, ref);
}

/* ---------- token ---------- */
export function newToken(): string {
  return randomBytes(32).toString('hex');
}
export function sha256(s: string): string {
  return createHash('sha256').update(s).digest('hex');
}

/* ---------- çerez ---------- */
export function sessionSetCookie(token: string): string {
  const maxAge = SESSION_DAYS * 86400;
  const secure = process.env.NODE_ENV === 'production' ? '; Secure' : '';
  return `${SESSION_COOKIE}=${token}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${maxAge}${secure}`;
}
export function sessionClearCookie(): string {
  return `${SESSION_COOKIE}=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0`;
}
export function readSessionToken(req: Request): string | null {
  const cookie = req.headers.get('cookie') ?? '';
  const m = cookie.match(new RegExp(`(?:^|;\\s*)${SESSION_COOKIE}=([a-f0-9]{64})`));
  return m?.[1] ?? null;
}

/* ---------- oturum yaşam döngüsü ---------- */
export async function createSession(db: Db, userId: string, userAgent: string): Promise<string> {
  const token = newToken();
  await db.insert(sessions).values({
    tokenHash: sha256(token),
    userId,
    userAgent: userAgent.slice(0, 200),
    expiresAt: new Date(Date.now() + SESSION_DAYS * 86400000),
  });
  return token;
}

export interface SessionUser {
  id: string;
  email: string;
  name: string;
  role: 'user' | 'editor' | 'admin';
}

export async function getSessionUser(req: Request): Promise<SessionUser | null> {
  const token = readSessionToken(req);
  if (!token) return null;
  const db = await getDb();
  const rows = await db
    .select({
      id: users.id,
      email: users.email,
      name: users.name,
      role: users.role,
      expiresAt: sessions.expiresAt,
    })
    .from(sessions)
    .innerJoin(users, eq(users.id, sessions.userId))
    .where(eq(sessions.tokenHash, sha256(token)));
  const row = rows[0];
  if (!row) return null;
  if (row.expiresAt.getTime() < Date.now()) {
    await db.delete(sessions).where(eq(sessions.tokenHash, sha256(token)));
    return null;
  }
  return { id: row.id, email: row.email, name: row.name, role: row.role as SessionUser['role'] };
}

export async function destroySession(req: Request): Promise<void> {
  const token = readSessionToken(req);
  if (!token) return;
  const db = await getDb();
  await db.delete(sessions).where(eq(sessions.tokenHash, sha256(token)));
}

/* ---------- yardımcılar ---------- */
export function json(data: unknown, init?: ResponseInit & { setCookie?: string }): Response {
  const headers = new Headers(init?.headers);
  headers.set('content-type', 'application/json; charset=utf-8');
  if (init?.setCookie) headers.set('set-cookie', init.setCookie);
  return new Response(JSON.stringify(data), { ...init, headers });
}

export function validEmail(e: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(e);
}

export function newId(): string {
  return randomUUID();
}

/** RBAC (Sprint 2): rol kapısı — yetki yoksa Response döner. */
export async function requireRole(
  req: Request,
  ...roles: Array<SessionUser['role']>
): Promise<SessionUser | Response> {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });
  if (!roles.includes(user.role))
    return json({ error: 'Bu işlem için yetkin yok.' }, { status: 403 });
  return user;
}

/** DB yapılandırılmadıysa (prod'da DATABASE_URL bekleniyor) 500 yerine net 503 döndür. */
export function guarded(handler: (req: Request) => Promise<Response>) {
  return async (req: Request): Promise<Response> => {
    try {
      return await handler(req);
    } catch (e) {
      if (e instanceof Error && e.message === 'DB_NOT_CONFIGURED') {
        return json(
          {
            error:
              'Hesap sistemi kurulum aşamasında (veritabanı bağlantısı bekleniyor). Uygulamanın geri kalanı hesapsız da tamamen çalışır.',
          },
          { status: 503 }
        );
      }
      throw e;
    }
  };
}
