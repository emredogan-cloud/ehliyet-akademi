import { and, eq, or } from 'drizzle-orm';
import {
  getDb,
  communityProfiles,
  communityStats,
  communityAchievements,
  communityBlocks,
} from '@ea/db';
import { getSessionUser, json, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { avatarUrlFor } from '@/lib/server/community';

/**
 * Başka bir kullanıcının topluluk profili (Evolution Faz E8).
 *
 * Görünürlük kuralları SUNUCUDA uygulanır ve hepsi 404 ile aynı cevabı verir — böylece "gizli mi
 * yoksa engellenmiş mi" bilgisi sızmaz:
 * - profil yoksa,
 * - profil `private` ise,
 * - taraflardan biri diğerini engellemişse.
 *
 * PII DÖNMEZ: e-posta, gerçek ad veya konum yoktur.
 */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'community-user', limit: 60, windowMs: 60_000 });
  if (limited) return limited;

  const viewer = await getSessionUser(req);
  if (!viewer) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  // NOT: `guarded` yalnız `req`'i iletir (ekstra Next context argümanını GEÇİRMEZ), bu yüzden
  // kimlik yol üzerinden okunur — mevcut `[id]` uçlarındaki desenin aynısı.
  const parts = new URL(req.url).pathname.split('/');
  const targetId = decodeURIComponent(parts[parts.length - 1] ?? '');
  if (!targetId) return json({ error: 'Kullanıcı bulunamadı.' }, { status: 404 });

  const db = await getDb();

  // Her iki yönde engelleme → yok say (404).
  const blocks = await db
    .select({ blockerId: communityBlocks.blockerId })
    .from(communityBlocks)
    .where(
      or(
        and(eq(communityBlocks.blockerId, viewer.id), eq(communityBlocks.blockedId, targetId)),
        and(eq(communityBlocks.blockerId, targetId), eq(communityBlocks.blockedId, viewer.id))
      )
    );
  if (blocks.length > 0) return json({ error: 'Kullanıcı bulunamadı.' }, { status: 404 });

  const [profile] = await db
    .select()
    .from(communityProfiles)
    .where(eq(communityProfiles.userId, targetId))
    .limit(1);

  // Kendi profilin gizli olsa da görünür; başkasınınki yalnız public ise.
  const isSelf = targetId === viewer.id;
  if (!profile || (profile.visibility !== 'public' && !isSelf)) {
    return json({ error: 'Kullanıcı bulunamadı.' }, { status: 404 });
  }

  const [stats] = await db
    .select()
    .from(communityStats)
    .where(eq(communityStats.userId, targetId))
    .limit(1);
  const badges = await db
    .select({ achievementId: communityAchievements.achievementId })
    .from(communityAchievements)
    .where(eq(communityAchievements.userId, targetId));

  return json({
    profile: {
      userId: profile.userId,
      displayName: profile.displayName,
      avatarId: profile.avatarId,
      avatarUrl: avatarUrlFor(profile.avatarMediaId),
      licence: profile.licence,
    },
    stats: stats
      ? {
          xp: stats.xp,
          streak: stats.streak,
          lessons: stats.lessons,
          exams: stats.exams,
          answered: stats.answered,
          accuracy: stats.accuracy,
        }
      : { xp: 0, streak: 0, lessons: 0, exams: 0, answered: 0, accuracy: 0 },
    achievements: badges.map((b) => b.achievementId),
    isSelf,
  });
});
