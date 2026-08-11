import { and, inArray, lt, sql, type SQL } from 'drizzle-orm';
import { analyticsEvents, communityReports, errorReports, type Db } from '@ea/db';
import { retentionDays } from '@/lib/retention';

/**
 * Saklama sürelerini UYGULAYAN iş.
 *
 * Politika `lib/retention.ts` dosyasında; burası onu sadece **çalıştırır**. Ayrı durmalarının
 * nedeni: politika istemci tarafında da render edilir (yasal sayfalar), temizleme ise yalnız
 * sunucuda ve veritabanı bağlantısıyla çalışır.
 *
 * ## Neden bir iş gerekiyordu
 *
 * Yayımlanmış bir sayfada "365 gün sonra siliyoruz" yazıp silmemek, hiç süre yazmamaktan daha
 * kötüdür: ilki yanlış beyandır. Bu dosya, sayfadaki cümlenin karşılığıdır.
 *
 * ## `now` neden parametre
 *
 * Test, "366 gün önce" bir kaydın silindiğini ve "364 gün önce" olanın KALDIĞINI kanıtlamak
 * zorunda. Fonksiyon `Date.now()` okusaydı bu sınır davranışı test edilemezdi.
 *
 * ## Neden `.returning()` kullanılmıyor
 *
 * `Db` iki sürücünün birleşim tipidir (`NodePgDatabase | PgliteDatabase`) ve birleşim üzerinde
 * `.returning(projection)` aşırı yüklemesi çözülmüyor. Bunun yerine silmeden ÖNCE sayılır —
 * zaten raporlamak istediğimiz sayı da budur ve `retentionBacklog` ile aynı yüklemi paylaşır.
 */

export interface PurgeResult {
  analyticsEvents: number;
  errorReports: number;
  communityReports: number;
}

/** Kapanmış sayılan şikâyet durumları — `open` olan İNCELEMEDEDİR ve silinmez. */
const CLOSED_REPORT_STATUSES = ['reviewed', 'dismissed'] as const;

function cutoff(now: Date, days: number): Date {
  return new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
}

type EnvLike = Record<string, string | undefined>;

/**
 * Silinecek satırları seçen yüklemler — **tek tanım**.
 *
 * Sayma ve silme aynı yüklemi paylaşmalı; ayrı yazılsalardı biri değişip diğeri değişmediğinde
 * rapor edilen sayı ile silinen sayı sessizce ayrışırdı.
 */
function predicates(now: Date, env: EnvLike) {
  // `received_at` kullanılır, `at` DEĞİL: `at` cihazın saatidir ve yanlış ayarlanmış bir telefon
  // 2030 tarihli olay gönderebilir. Sunucunun kendi damgası tek güvenilir zaman kaynağıdır.
  return {
    analytics: lt(analyticsEvents.receivedAt, cutoff(now, retentionDays('analytics', env))),
    errors: lt(errorReports.receivedAt, cutoff(now, retentionDays('errorReports', env))),
    moderation: and(
      lt(communityReports.createdAt, cutoff(now, retentionDays('moderation', env))),
      inArray(communityReports.status, [...CLOSED_REPORT_STATUSES])
    ) as SQL,
  };
}

async function countWhere(
  db: Db,
  table: typeof analyticsEvents | typeof errorReports | typeof communityReports,
  where: SQL
): Promise<number> {
  const rows = await db
    .select({ n: sql<number>`count(*)::int` })
    .from(table)
    .where(where);
  return rows[0]?.n ?? 0;
}

/**
 * Süresi dolmuş kayıtları sil.
 *
 * Dönen sayılar, silinmeden hemen önce ölçülen satır sayılarıdır.
 */
export async function purgeExpiredData(
  db: Db,
  now: Date = new Date(),
  env: EnvLike = process.env
): Promise<PurgeResult> {
  const p = predicates(now, env);
  const result: PurgeResult = {
    analyticsEvents: await countWhere(db, analyticsEvents, p.analytics),
    errorReports: await countWhere(db, errorReports, p.errors),
    communityReports: await countWhere(db, communityReports, p.moderation),
  };

  await db.delete(analyticsEvents).where(p.analytics);
  await db.delete(errorReports).where(p.errors);
  await db.delete(communityReports).where(p.moderation);

  return result;
}

/**
 * Temizleme işi için ölçüm: her sınıfta kaç kayıt saklama sınırının DIŞINDA kaldı.
 *
 * İş çalışmadıysa bu sayılar büyür — yani sessiz bir "cron kurulmamış" arızasını görünür kılar.
 */
export async function retentionBacklog(
  db: Db,
  now: Date = new Date(),
  env: EnvLike = process.env
): Promise<PurgeResult> {
  const p = predicates(now, env);
  return {
    analyticsEvents: await countWhere(db, analyticsEvents, p.analytics),
    errorReports: await countWhere(db, errorReports, p.errors),
    communityReports: await countWhere(db, communityReports, p.moderation),
  };
}
