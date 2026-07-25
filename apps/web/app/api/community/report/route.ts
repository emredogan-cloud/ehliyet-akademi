import { eq } from 'drizzle-orm';
import { getDb, communityProfiles, communityReports } from '@ea/db';
import { getSessionUser, json, guarded, newId } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { isReportReason } from '@/lib/server/community';

/**
 * Kullanıcı şikâyeti (Evolution Faz E8).
 *
 * MAĞAZA POLİTİKASI: kullanıcı üretimi içerik barındıran uygulamalarda şikâyet ve engelleme
 * ZORUNLUDUR. Bu yüzden ikisi de, kullanıcı metni doğuran özelliklerden (E9 mesajlaşma) ÖNCE,
 * bu fazda devreye alınır.
 *
 * MODERASYON DÜRÜSTLÜĞÜ: şikâyetler bir KUYRUĞA yazılır ve insan incelemesi bekler. Otomatik
 * sınıflandırma/ML YOKTUR ve olduğu iddia edilmez.
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'community-report', limit: 10, windowMs: 60_000 });
  if (limited) return limited;

  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  let body: { targetUserId?: unknown; reason?: unknown; note?: unknown };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }

  const targetUserId = typeof body.targetUserId === 'string' ? body.targetUserId : '';
  if (!targetUserId) return json({ error: 'Bildirilecek kullanıcı gerekli.' }, { status: 400 });
  if (targetUserId === user.id) {
    return json({ error: 'Kendini bildiremezsin.' }, { status: 400 });
  }
  if (!isReportReason(body.reason)) return json({ error: 'Geçersiz sebep.' }, { status: 400 });

  const db = await getDb();
  const [target] = await db
    .select({ userId: communityProfiles.userId })
    .from(communityProfiles)
    .where(eq(communityProfiles.userId, targetUserId))
    .limit(1);
  if (!target) return json({ error: 'Kullanıcı bulunamadı.' }, { status: 404 });

  const note = typeof body.note === 'string' ? body.note.trim().slice(0, 500) : '';

  await db.insert(communityReports).values({
    id: newId(),
    reporterId: user.id,
    targetUserId,
    reason: body.reason,
    note,
    status: 'open',
  });

  return json({ ok: true }, { status: 201 });
});
