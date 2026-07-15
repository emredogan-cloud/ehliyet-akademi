/**
 * Sunucu başlangıç enstrümantasyonu (ROADMAP Faz 31 · Sprint 5).
 * Node runtime'da açılışta ortam/sır doğrulamasını loglar. Gözlemlenebilirlik (Sentry) init
 * noktası da burasıdır (SENTRY_DSN geldiğinde SDK burada başlatılır).
 */
export async function register(): Promise<void> {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    const { logEnvChecks } = await import('./lib/server/env-check');
    logEnvChecks();
  }
}
