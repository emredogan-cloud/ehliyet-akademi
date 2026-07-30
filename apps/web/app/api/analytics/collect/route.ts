import { json, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { ingestAnalytics } from '@/lib/server/telemetry';

/**
 * Beta Faz 3 — mobil istemciden gelen analitik olayları.
 *
 * Oturum GEREKMEZ (misafir kullanım ölçülmeli); oturum varsa olay kullanıcıya bağlanır. Doğrulama,
 * sanitizasyon ve beyaz liste `lib/server/telemetry.ts` içindedir.
 *
 * HIZ SINIRI: bir cihaz normalde dakikada bir parti gönderir (istemci 50'lik partiler hâlinde
 * boşaltır). Otuz, uzun bir çevrimdışı dönemin ardından biriken kuyruğun tek seferde boşalmasına
 * yeter ve kötüye kullanımı anlamsız kılar.
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'analytics', limit: 30, windowMs: 60_000 });
  if (limited) return limited;

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }

  const result = await ingestAnalytics(req, body);
  // 200 döner (kısmen reddedilse de): istemci kuyruğu 4xx'i KALICI hata sayar ve kaydı düşürür.
  // Reddedilenler zaten yazılamaz olduğu için düşürülmeleri doğrudur.
  return json(result);
});
