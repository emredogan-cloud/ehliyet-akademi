import { desc, eq } from 'drizzle-orm';
import { getDb, leaderboardSnapshots } from '@ea/db';
import { getSessionUser, json, guarded } from '@/lib/server/auth';
import { isLicence } from '@/lib/server/community';

/**
 * Geçmiş haftaların dondurulmuş sıralaması (Evolution Faz E10).
 *
 * Anlık görüntüler `lib/server/leaderboard-rollover.ts` tarafından, hafta döndükten SONRAKİ ilk
 * okumada ETKİSİZ-TEKRARLI olarak alınır. Bu uç yalnız OKUR — devri tetiklemez.
 */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const url = new URL(req.url);
  const licenceParam = url.searchParams.get('licence');
  const licence = isLicence(licenceParam) ? licenceParam : 'all';
  const weeksRaw = Number(url.searchParams.get('weeks'));
  const weeks = Number.isFinite(weeksRaw) && weeksRaw > 0 ? Math.min(Math.floor(weeksRaw), 12) : 4;

  const db = await getDb();
  const rows = await db
    .select()
    .from(leaderboardSnapshots)
    .where(eq(leaderboardSnapshots.licence, licence))
    .orderBy(desc(leaderboardSnapshots.weekStart))
    .limit(weeks);

  return json({
    licence,
    weeks: rows.map((r) => ({
      weekStart: r.weekStart,
      rows: r.rows,
      takenAt: r.createdAt,
    })),
  });
});
