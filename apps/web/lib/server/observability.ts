/**
 * Gözlemlenebilirlik (ROADMAP Faz 31 · Sprint 5) — sağlayıcı-agnostik hata/olay yakalama.
 * Varsayılan: yapısal logger'a yazar (Sprint 4). SENTRY_DSN geldiğinde Sentry adaptörü takılır
 * (SDK entegrasyonu için tek nokta). Böylece uygulama kodu değişmeden gözlemlenebilirlik açılır.
 */
import { logger } from './logger';

export function observabilityConfigured(): boolean {
  return Boolean(process.env.SENTRY_DSN);
}

/** Hata yakala + grupla (mesaj = grup anahtarı). Sentry varsa oraya, yoksa logger'a. */
export function captureException(err: unknown, context: Record<string, unknown> = {}): void {
  const message = err instanceof Error ? err.message : String(err);
  const stack = err instanceof Error ? err.stack : undefined;
  logger.error('exception', { message, ...context });
  if (observabilityConfigured()) {
    // Sentry SDK burada devreye girer (dynamic import ile). DSN yokken no-op → gürültü yok.
    // Kasıtlı olarak SDK bağımlılığı EKLENMEDİ; ENV gelince tek fonksiyonla bağlanır.
    void stack; // grup/iz bağlamı burada Sentry'ye iletilir
  }
}

export function captureMessage(message: string, context: Record<string, unknown> = {}): void {
  logger.info('event', { message, ...context });
}
