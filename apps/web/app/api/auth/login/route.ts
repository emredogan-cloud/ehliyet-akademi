import { eq } from 'drizzle-orm';
import { getDb, users } from '@ea/db';
import { verifyPassword, createSession, sessionSetCookie, json, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';

export const POST = guarded(async (req: Request): Promise<Response> => {
  // Kimlik-doldurma/parola brute-force savunması (register/forgot/verify ile aynı).
  const limited = checkRateLimit(req, { bucket: 'login', limit: 8, windowMs: 60_000 });
  if (limited) return limited;

  let body: { email?: string; password?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const email = (body.email ?? '').trim().toLowerCase();
  const password = (body.password ?? '').slice(0, 200); // aşırı uzun parola scryptSync'i yormasın (L4)

  const db = await getDb();
  const rows = await db.select().from(users).where(eq(users.email, email));
  const user = rows[0];
  // Zamanlama sızıntısını azaltmak için kullanıcı yoksa da sahte doğrulama yapılır.
  const ok = user
    ? verifyPassword(password, user.passwordHash)
    : (verifyPassword(password, 'scrypt$00$00'), false);
  if (!user || !ok) return json({ error: 'E-posta veya parola hatalı.' }, { status: 401 });

  const token = await createSession(db, user.id, req.headers.get('user-agent') ?? '');
  return json(
    { user: { id: user.id, email: user.email, name: user.name } },
    { setCookie: sessionSetCookie(token) }
  );
});
