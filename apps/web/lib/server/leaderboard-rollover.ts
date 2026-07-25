import { eq } from 'drizzle-orm';
import { getDb, leaderboardSnapshots } from '@ea/db';
import { orderSnapshotRows, shouldSnapshot, snapshotId, type SnapshotRow } from './groups';
import { previousWeekStart } from './community';

/**
 * Haftalık sıralama devri (Evolution Faz E10).
 *
 * ZAMANLAYICI YOK. Vercel'de bu proje için cron sağlanmadı; devir, hafta döndükten SONRAKİ İLK
 * OKUMADA tembel olarak yapılır. Bu, DÜRÜSTÇE bir yaklaşımdır ve sınırı şudur:
 * anlık görüntü, "hafta bittiği an" değil, **hafta döndükten sonraki ilk okuma anındaki** duruma
 * karşılık gelir. Kimse okumazsa görüntü de alınmaz.
 *
 * BELİRLENİMCİLİK iki katmanla sağlanır:
 *  1. `orderSnapshotRows` — XP azalan, eşitlikte `userId` artan (veritabanı dönüş sırasına bağlı DEĞİL).
 *  2. `id = hafta:sınıf` + benzersiz dizin + `onConflictDoNothing` → aynı hafta için ikinci bir
 *     görüntü ASLA yazılmaz; eşzamanlı iki istek yarışsa bile sonuç tektir.
 *
 * Okuma yolunu yavaşlatmamak için: yalnız görüntü YOKSA yazılır ve hata yutulur — devir
 * başarısız olursa sıralama yine de döner (devir bir sonraki okumada yeniden denenir).
 */
export async function rolloverIfNeeded(args: {
  licence: string;
  currentWeekStart: string;
  rows: SnapshotRow[];
}): Promise<{ taken: boolean; weekStart: string | null }> {
  const prevWeek = previousWeekStart(args.currentWeekStart);
  const id = snapshotId(prevWeek, args.licence);

  try {
    const db = await getDb();
    const existing = await db
      .select({ id: leaderboardSnapshots.id })
      .from(leaderboardSnapshots)
      .where(eq(leaderboardSnapshots.id, id))
      .limit(1);

    if (!shouldSnapshot(prevWeek, args.currentWeekStart, existing.length > 0)) {
      return { taken: false, weekStart: null };
    }
    // Boş bir hafta dondurulmaz — anlamsız satır bırakmaz.
    if (args.rows.length === 0) return { taken: false, weekStart: null };

    await db
      .insert(leaderboardSnapshots)
      .values({
        id,
        weekStart: prevWeek,
        licence: args.licence,
        rows: orderSnapshotRows(args.rows),
      })
      .onConflictDoNothing();
    return { taken: true, weekStart: prevWeek };
  } catch {
    // Devir, sıralamayı okumayı ENGELLEMEZ.
    return { taken: false, weekStart: null };
  }
}
