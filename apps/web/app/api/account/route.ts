import { eq } from 'drizzle-orm';
import { getDb, users } from '@ea/db';
import { getSessionUser, json, guarded, sessionClearCookie } from '@/lib/server/auth';
import { logger } from '@/lib/server/logger';

/**
 * Hesabı sil (Sprint 4 — KVKK m.7 / GDPR "silme hakkı"). Kullanıcı satırı silinir;
 * FK ON DELETE CASCADE ile oturumlar, satın almalar, durum ve tokenlar da silinir.
 * Oturum çerezi temizlenir.
 */
export const DELETE = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const db = await getDb();
  await db.delete(users).where(eq(users.id, user.id));
  logger.info('account_deleted', { userId: user.id });
  return json({ ok: true }, { setCookie: sessionClearCookie() });
});
