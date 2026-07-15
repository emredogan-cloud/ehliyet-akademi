/**
 * Sır/ortam doğrulaması (ROADMAP Faz 30 · Sprint 5). Üretimde eksik/zayıf yapılandırmayı UYARIR
 * (fatal değil — mock politikası: uygulama yine çalışır). Saf `checkEnv` test edilebilir.
 */
import { logger } from './logger';

export interface EnvCheckResult {
  ok: boolean;
  warnings: string[];
}

export function checkEnv(env: NodeJS.ProcessEnv = process.env): EnvCheckResult {
  const warnings: string[] = [];
  const isProd = Boolean(env.VERCEL || env.NODE_ENV === 'production');
  if (isProd) {
    if (!env.DATABASE_URL)
      warnings.push('DATABASE_URL yok — hesap/satın alma uçları dostane 503 döner.');
    if (!env.RESEND_API_KEY)
      warnings.push('RESEND_API_KEY yok — e-posta gönderilmez (console/devToken).');
    if (!env.NEXT_PUBLIC_SITE_URL)
      warnings.push('NEXT_PUBLIC_SITE_URL yok — e-posta bağlantıları göreli olur.');
    // Ödeme kısmen yapılandırıldıysa webhook sırrı ZORUNLU (aksi halde tahsilat doğrulanamaz).
    if (env.LEMONSQUEEZY_API_KEY && !env.LEMONSQUEEZY_WEBHOOK_SECRET)
      warnings.push(
        'LEMONSQUEEZY_API_KEY var ama LEMONSQUEEZY_WEBHOOK_SECRET yok — webhook doğrulanamaz!'
      );
  }
  return { ok: warnings.length === 0, warnings };
}

/** Başlangıçta çağrılır (instrumentation) — uyarıları yapısal loglara yazar. */
export function logEnvChecks(): void {
  const r = checkEnv();
  if (r.ok) {
    logger.info('env_check_ok', {});
    return;
  }
  for (const w of r.warnings) logger.warn('env_check', { warning: w });
}
