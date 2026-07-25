import { and, eq } from 'drizzle-orm';
import { getDb, communityProfiles, communityStats, communityBlocks } from '@ea/db';
import { getSessionUser, json, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import {
  isLicence,
  parsePageSize,
  rankRows,
  weekStartIstanbul,
  type LeaderboardRow,
} from '@/lib/server/community';
import { rolloverIfNeeded } from '@/lib/server/leaderboard-rollover';

/**
 * Sıralama (Evolution Faz E8).
 *
 * GÖRÜNÜRLÜK: yalnız `visibility='public'` profiller listelenir — katılmayan hiç kimse görünmez.
 * ENGELLEME: karşılıklı olarak SUNUCUDA uygulanır; engellediğin ve seni engelleyen kullanıcılar
 * listeden düşer (istemci filtresine güvenilmez).
 * PII: e-posta, gerçek ad, konum DÖNMEZ — yalnız görünen ad, avatar kimliği, XP ve seri.
 *
 * GERÇEK ZAMANLILIK: Vercel sunucusuz ortamında kalıcı WebSocket YOKTUR. Bu uç, ETag ile kısa
 * yoklamaya uygundur; "canlı" olduğu iddia edilmez (roadmap'te belgelenmiş karar).
 */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, {
    bucket: 'community-leaderboard',
    limit: 60,
    windowMs: 60_000,
  });
  if (limited) return limited;

  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const url = new URL(req.url);
  const licenceParam = url.searchParams.get('licence');
  const licence = isLicence(licenceParam) ? licenceParam : null;
  const limit = parsePageSize(url.searchParams.get('limit'));
  const offsetRaw = Number(url.searchParams.get('offset'));
  const offset = Number.isFinite(offsetRaw) && offsetRaw > 0 ? Math.floor(offsetRaw) : 0;

  const db = await getDb();

  // Engelleme çiftleri (her iki yön) — listeden düşecek kimlikler.
  const blockedByMe = await db
    .select({ id: communityBlocks.blockedId })
    .from(communityBlocks)
    .where(eq(communityBlocks.blockerId, user.id));
  const blockedMe = await db
    .select({ id: communityBlocks.blockerId })
    .from(communityBlocks)
    .where(eq(communityBlocks.blockedId, user.id));
  const hidden = new Set<string>([...blockedByMe.map((r) => r.id), ...blockedMe.map((r) => r.id)]);

  const joined = await db
    .select({
      userId: communityProfiles.userId,
      displayName: communityProfiles.displayName,
      avatarId: communityProfiles.avatarId,
      licence: communityProfiles.licence,
      xp: communityStats.xp,
      streak: communityStats.streak,
    })
    .from(communityProfiles)
    .innerJoin(communityStats, eq(communityStats.userId, communityProfiles.userId))
    .where(
      licence
        ? and(eq(communityProfiles.visibility, 'public'), eq(communityProfiles.licence, licence))
        : eq(communityProfiles.visibility, 'public')
    );

  const visible: LeaderboardRow[] = joined.filter((r) => !hidden.has(r.userId));
  const ranked = rankRows(visible);
  const page = ranked.slice(offset, offset + limit);

  // Kullanıcının kendi sırası — sayfada olmasa bile döner (kendini aramak zorunda kalmasın).
  const me = ranked.find((r) => r.userId === user.id) ?? null;

  const currentWeek = weekStartIstanbul(Date.now());
  // Faz E10 — haftalık devir. Zamanlayıcı yok; hafta döndükten sonraki ilk okumada, ETKİSİZ-TEKRARLI
  // olarak bir önceki haftanın sıralaması dondurulur. Başarısız olursa okuma yine de döner.
  await rolloverIfNeeded({
    licence: licence ?? 'all',
    currentWeekStart: currentWeek,
    rows: ranked.map((r) => ({
      userId: r.userId,
      displayName: r.displayName,
      avatarId: r.avatarId,
      xp: r.xp,
    })),
  });

  return json({
    weekStart: currentWeek,
    licence: licence ?? 'all',
    total: ranked.length,
    offset,
    limit,
    rows: page,
    me,
  });
});
