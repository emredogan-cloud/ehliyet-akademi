import { eq } from 'drizzle-orm';
import { getDb, users, passwordResetTokens, sessions } from '@ea/db';
import { hashPassword, sha256, json } from '@/lib/server/auth';

export async function POST(req: Request): Promise<Response> {
  let body: { token?: string; password?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const token = body.token ?? '';
  const password = body.password ?? '';
  if (password.length < 8)
    return json({ error: 'Parola en az 8 karakter olmalı.' }, { status: 400 });

  const db = await getDb();
  const rows = await db
    .select()
    .from(passwordResetTokens)
    .where(eq(passwordResetTokens.tokenHash, sha256(token)));
  const row = rows[0];
  if (!row || row.expiresAt.getTime() < Date.now())
    return json({ error: 'Token geçersiz veya süresi dolmuş.' }, { status: 400 });

  await db
    .update(users)
    .set({ passwordHash: hashPassword(password) })
    .where(eq(users.id, row.userId));
  // Güvenlik: tüm sıfırlama tokenları ve mevcut oturumlar iptal (yeniden giriş gerekir).
  await db.delete(passwordResetTokens).where(eq(passwordResetTokens.userId, row.userId));
  await db.delete(sessions).where(eq(sessions.userId, row.userId));
  return json({ ok: true });
}
