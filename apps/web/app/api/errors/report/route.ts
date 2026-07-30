import { json, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { ingestErrors } from '@/lib/server/telemetry';

/**
 * Beta Faz 4 — mobil istemciden gelen hata raporları.
 *
 * Oturum GEREKMEZ: ilk açılışta çöken bir uygulamada henüz oturum yoktur ve tam o çökme en değerli
 * olandır. Doğrulama/sanitizasyon `lib/server/telemetry.ts` içindedir.
 *
 * HIZ SINIRI analitikten DÜŞÜK (20/dk): bir çökme döngüsüne giren cihaz aynı hatayı arka arkaya
 * gönderebilir. Sınır, o cihazın sunucuyu yormasını engeller; gruplama zaten `fingerprint` ile
 * yapıldığı için kaybedilen tekrarların tanısal değeri yoktur.
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'errors', limit: 20, windowMs: 60_000 });
  if (limited) return limited;

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }

  const result = await ingestErrors(req, body);
  return json(result);
});
