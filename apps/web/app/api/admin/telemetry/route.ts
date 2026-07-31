import { requireRole, json, guarded } from '@/lib/server/auth';
import {
  DEFAULT_WINDOW_DAYS,
  dailyActive,
  errorGroups,
  eventCounts,
  productFunnel,
  referralFunnel,
} from '@/lib/server/telemetry-report';

/**
 * Beta Faz 8 — yönetici telemetri özeti (analitik + hata + davet hunisi).
 *
 * Tek uçta toplanır: pano bir sayfada dört soruyu birlikte soruyor ("kaç kişi var", "nerede
 * düşüyorlar", "ne kırılıyor", "davet işe yarıyor mu"). Dört ayrı istek, sayfayı dört ayrı
 * yükleme durumuyla doldururdu ve veriler farklı anlara ait olurdu.
 */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin');
  if (user instanceof Response) return user;

  const url = new URL(req.url);
  const days = Number(url.searchParams.get('days') ?? DEFAULT_WINDOW_DAYS);
  const windowDays = Number.isFinite(days) && days > 0 && days <= 365 ? days : DEFAULT_WINDOW_DAYS;

  return json({
    windowDays,
    events: await eventCounts(windowDays),
    funnel: await productFunnel(windowDays),
    referral: await referralFunnel(windowDays),
    errors: await errorGroups(windowDays),
    daily: await dailyActive(Math.min(windowDays, 30)),
  });
});
