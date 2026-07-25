import { eq } from 'drizzle-orm';
import { getDb, communityProfiles, communityStats, communityAchievements } from '@ea/db';
import { getSessionUser, json, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { clampStats, parseCounters, type StatCounters } from '@/lib/server/community';

/**
 * İstatistik bildirimi (Evolution Faz E8).
 *
 * İstemci ham sayaçlarını bildirir; SUNUCU son sözü söyler: geri gitme yok, pencere başına tavan,
 * çok sık bildirimde artış yok (`lib/server/community.ts` — saf ve ayrıca test edilmiş).
 * Bildirilen ham XP `submitted_xp` alanında saklanır: kabul edilen ile bildirilen arasındaki fark
 * sonradan incelenebilir bir denetim izidir.
 *
 * ÖN KOŞUL: topluluk profili olmalı (yani kullanıcı katılmış olmalı). Profili olmayan kullanıcının
 * istatistiği tutulmaz — veri toplamayı katılıma bağlamak opt-in tasarımın gereğidir.
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'community-stats', limit: 30, windowMs: 60_000 });
  if (limited) return limited;

  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }

  const db = await getDb();
  const [profile] = await db
    .select()
    .from(communityProfiles)
    .where(eq(communityProfiles.userId, user.id))
    .limit(1);
  if (!profile) {
    return json({ error: 'Önce topluluğa katılmalısın.' }, { status: 409 });
  }

  const [current] = await db
    .select()
    .from(communityStats)
    .where(eq(communityStats.userId, user.id))
    .limit(1);

  const incoming = parseCounters(raw);
  const currentCounters: StatCounters | null = current
    ? {
        xp: current.xp,
        streak: current.streak,
        lessons: current.lessons,
        exams: current.exams,
        answered: current.answered,
        accuracy: current.accuracy,
      }
    : null;

  const now = new Date();
  const msSinceLastSubmit = current ? now.getTime() - new Date(current.updatedAt).getTime() : null;
  const result = clampStats({ current: currentCounters, incoming, msSinceLastSubmit });

  await db
    .insert(communityStats)
    .values({
      userId: user.id,
      ...result.next,
      submittedXp: incoming.xp,
      updatedAt: now,
    })
    .onConflictDoUpdate({
      target: communityStats.userId,
      set: { ...result.next, submittedXp: incoming.xp, updatedAt: now },
    });

  // Rozetler: yalnız EKLENİR (geri alınmaz); bilinmeyen/aşırı uzun kimlikler yok sayılır.
  const badges = Array.isArray((raw as { achievements?: unknown })?.achievements)
    ? ((raw as { achievements: unknown[] }).achievements
        .filter((a): a is string => typeof a === 'string' && /^[a-z0-9-]{2,40}$/.test(a))
        .slice(0, 50) as string[])
    : [];
  for (const achievementId of badges) {
    await db
      .insert(communityAchievements)
      .values({ userId: user.id, achievementId, earnedAt: now })
      .onConflictDoNothing();
  }

  return json({
    stats: result.next,
    // Şeffaflık: istemci kısıldığını görebilsin (sessizce farklı veri saklamayız).
    clamped: result.clamped,
    regressed: result.regressed,
  });
});
