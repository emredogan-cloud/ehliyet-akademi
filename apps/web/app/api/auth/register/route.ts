import { eq, sql } from 'drizzle-orm';
import { getDb, users, emailVerificationTokens } from '@ea/db';
import {
  hashPassword,
  createSession,
  sessionSetCookie,
  newToken,
  sha256,
  json,
  validEmail,
  newId,
  guarded,
} from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { getEmailProvider, welcomeEmail, verificationEmail } from '@/lib/server/email';
import { logger } from '@/lib/server/logger';

export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'register', limit: 8, windowMs: 60_000 });
  if (limited) return limited;

  let body: { email?: string; password?: string; name?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const email = (body.email ?? '').trim().toLowerCase();
  const password = body.password ?? '';
  const name = (body.name ?? '').trim().slice(0, 80);

  if (!validEmail(email)) return json({ error: 'Geçerli bir e-posta girin.' }, { status: 400 });
  if (password.length < 8)
    return json({ error: 'Parola en az 8 karakter olmalı.' }, { status: 400 });

  const db = await getDb();
  const existing = await db.select({ id: users.id }).from(users).where(eq(users.email, email));
  if (existing.length)
    return json({ error: 'Bu e-posta ile zaten bir hesap var.' }, { status: 409 });

  // Rol bootstrap (Sprint 2): ADMIN_EMAILS listesindeyse veya sistemde hiç admin yoksa → admin.
  const adminEmails = (process.env.ADMIN_EMAILS ?? '')
    .split(',')
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
  // ADMIN_EMAIL_PATTERN: regex allowlist (ör. kurumsal alan adı ".*@sirket.com$").
  const pattern = process.env.ADMIN_EMAIL_PATTERN;
  const patternMatch = pattern
    ? (() => {
        try {
          return new RegExp(pattern).test(email);
        } catch {
          return false;
        }
      })()
    : false;
  let role: 'user' | 'admin' = adminEmails.includes(email) || patternMatch ? 'admin' : 'user';
  // GÜVENLİK (C2): "sistemde admin yoksa ilk kayıt admin olur" bootstrap'ı YALNIZ geliştirmede.
  // Üretimde bir saldırgan bu yarışı kazanıp admin olabilirdi → üretimde admin YALNIZ açık
  // allowlist (ADMIN_EMAILS / ADMIN_EMAIL_PATTERN) ile atanır; owner admini seed/atamalı.
  if (role === 'user' && process.env.NODE_ENV !== 'production') {
    const admins = await db
      .select({ n: sql<number>`count(*)` })
      .from(users)
      .where(eq(users.role, 'admin'));
    if (Number(admins[0]?.n ?? 0) === 0) role = 'admin'; // ilk kullanıcı kurulum admini (yalnız dev)
  }

  const id = newId();
  await db.insert(users).values({ id, email, name, passwordHash: hashPassword(password), role });
  const token = await createSession(db, id, req.headers.get('user-agent') ?? '');

  // Hoş geldin + e-posta doğrulama (best-effort; e-posta servisi yoksa yalnız loglanır).
  const verifyToken = newToken();
  try {
    await db.insert(emailVerificationTokens).values({
      tokenHash: sha256(verifyToken),
      userId: id,
      expiresAt: new Date(Date.now() + 24 * 3600_000),
    });
    const base = process.env.NEXT_PUBLIC_SITE_URL ?? '';
    const provider = getEmailProvider();
    await provider.send(email, welcomeEmail(name)).catch(() => {});
    await provider
      .send(email, verificationEmail(`${base}/dogrula?token=${verifyToken}`))
      .catch(() => {});
  } catch (e) {
    logger.warn('register_email_failed', { err: String(e) });
  }

  return json(
    { user: { id, email, name, role } },
    { status: 201, setCookie: sessionSetCookie(token) }
  );
});
