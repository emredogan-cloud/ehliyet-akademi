import { timingSafeEqual } from 'node:crypto';
import { getDb } from '@ea/db';
import { json, guarded } from '@/lib/server/auth';
import { logger } from '@/lib/server/logger';
import { purgeExpiredData, retentionBacklog } from '@/lib/server/retention-purge';

/**
 * Saklama süresi temizleme işi — `vercel.json` içindeki cron her gün 03:20 UTC'de çağırır.
 *
 * ## GÜVENLİK — fail-closed
 *
 * `CRON_SECRET` ayarlı DEĞİLSE uç **hiçbir şey silmez** ve 503 döner. Açık bir uçta veri silen
 * bir iş, internetteki herkese "sil" düğmesi vermek olurdu. Vercel Cron, isteği
 * `Authorization: Bearer <CRON_SECRET>` başlığıyla gönderir.
 *
 * Karşılaştırma sabit zamanlıdır; uzunluk farkı bile zamanlama üzerinden sızmasın diye önce
 * uzunluk eşitliği kontrol edilir.
 *
 * ## GET neden silme yapıyor
 *
 * Vercel Cron yalnız GET gönderir. Yan etkili bir GET normalde yanlıştır; burada kabul
 * edilebilir olmasının nedeni ucun **yalnız sırrı bilene** açık olması ve işin **idempotent**
 * olmasıdır — ikinci çağrı silinecek yeni bir şey bulamaz.
 */

function authorized(req: Request): boolean {
  const secret = process.env.CRON_SECRET ?? '';
  if (!secret) return false;
  const header = (req.headers.get('authorization') ?? '').trim();
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : header;
  const a = Buffer.from(token);
  const b = Buffer.from(secret);
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

export const GET = guarded(async (req: Request): Promise<Response> => {
  if (!process.env.CRON_SECRET) {
    return json({ error: 'Temizleme işi yapılandırılmadı.' }, { status: 503 });
  }
  if (!authorized(req)) return json({ error: 'Yetkisiz.' }, { status: 401 });

  const db = await getDb();
  // Önce ölçüm, sonra silme: kaç kaydın süresi geçmişti sorusunun cevabı silmeden sonra alınamaz.
  const backlog = await retentionBacklog(db);
  const purged = await purgeExpiredData(db);

  logger.info('retention_purge', { backlog, purged });
  return json({ ok: true, purged });
});
