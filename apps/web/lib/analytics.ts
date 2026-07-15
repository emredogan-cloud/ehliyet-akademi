/**
 * Analitik (ROADMAP Faz 23 · Sprint 5) — tipli olay sözlüğü + GİZLİLİK-BİLİNÇLİ sağlayıcı katmanı.
 * Sağlayıcılar (GA4 / Clarity / PostHog) YALNIZCA (a) ilgili ENV anahtarı set + (b) kullanıcı
 * analitik rızası verdiyse yüklenir (Sprint 4 çerez rızası). Anahtar/rıza yoksa: console no-op.
 * KVKK: PII gönderilmez; olaylar anonim kullanım verisidir.
 */

export type AnalyticsEvent =
  | { name: 'diagnostic_completed'; props: { correct: number; total: number; overall: number } }
  | { name: 'exam_finished'; props: { correct: number; total: number; passed: boolean } }
  | {
      name: 'practice_session_completed';
      props: { correct: number; total: number; streak: number };
    }
  | { name: 'purchase_completed'; props: { productId: string; priceTRY: number } }
  | { name: 'checkout_started'; props: { productId: string } }
  | { name: 'premium_locked_viewed'; props: { slug: string } }
  | { name: 'lesson_viewed'; props: { slug: string; premium: boolean } }
  | { name: 'signup_completed'; props: Record<string, never> }
  | { name: 'feature_used'; props: { feature: string } }
  | { name: 'drop_off'; props: { step: string } }
  | { name: 'ai_question_asked'; props: { grounded: boolean; action?: string } };

export interface AnalyticsSink {
  track(e: AnalyticsEvent): void;
}

class ConsoleSink implements AnalyticsSink {
  track(e: AnalyticsEvent): void {
    if (typeof console !== 'undefined') console.debug('[analytics]', e.name, e.props);
  }
}

/** Yüklü sağlayıcılara (window.gtag / posthog / clarity) ileten sink. */
class ProviderSink implements AnalyticsSink {
  track(e: AnalyticsEvent): void {
    if (typeof window === 'undefined') return;
    const w = window as unknown as {
      gtag?: (...a: unknown[]) => void;
      posthog?: { capture: (n: string, p: unknown) => void };
      clarity?: (...a: unknown[]) => void;
    };
    try {
      w.gtag?.('event', e.name, e.props);
      w.posthog?.capture(e.name, e.props);
      w.clarity?.('event', e.name);
    } catch {
      /* analitik asla ürünü kırmaz */
    }
  }
}

let sinks: AnalyticsSink[] = [new ConsoleSink()];

export function setSink(s: AnalyticsSink): void {
  sinks = [s];
}
/** Gerçek sağlayıcı sink'ini ekle (AnalyticsLoader yükleme sonrası çağırır). */
export function addProviderSink(): void {
  sinks.push(new ProviderSink());
}

export function track(e: AnalyticsEvent): void {
  for (const s of sinks) {
    try {
      s.track(e);
    } catch {
      /* analitik asla ürünü kırmaz */
    }
  }
}

/* ---------- sağlayıcı yapılandırması (gizlilik-bilinçli) ---------- */

export interface AnalyticsConfig {
  ga4?: string;
  clarity?: string;
  posthog?: string;
  posthogHost?: string;
}

export function analyticsConfig(): AnalyticsConfig {
  return {
    ga4: process.env.NEXT_PUBLIC_GA_ID,
    clarity: process.env.NEXT_PUBLIC_CLARITY_ID,
    posthog: process.env.NEXT_PUBLIC_POSTHOG_KEY,
    posthogHost: process.env.NEXT_PUBLIC_POSTHOG_HOST,
  };
}

/**
 * Etkin sağlayıcılar (saf, test edilebilir): YALNIZCA rıza + ilgili ENV varsa.
 * Rıza yoksa boş liste → hiçbir izleyici yüklenmez (gizlilik-öncelikli).
 */
export function enabledProviders(
  consentAnalytics: boolean,
  cfg: AnalyticsConfig = analyticsConfig()
): string[] {
  if (!consentAnalytics) return [];
  const out: string[] = [];
  if (cfg.ga4) out.push('ga4');
  if (cfg.clarity) out.push('clarity');
  if (cfg.posthog) out.push('posthog');
  return out;
}
