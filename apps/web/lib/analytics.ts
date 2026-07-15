/**
 * Analitik olay sözlüğü (ROADMAP Faz 23) — tipli, tek kaynak.
 * Sink: ENV yoksa no-op/console (mock politikası); PostHog anahtarı gelince gerçek sink takılır.
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
  | { name: 'ai_question_asked'; props: { grounded: boolean } };

export interface AnalyticsSink {
  track(e: AnalyticsEvent): void;
}

class ConsoleSink implements AnalyticsSink {
  track(e: AnalyticsEvent): void {
    // Geliştirmede görünür, üretimde sessiz no-op'a yakın (console.debug).
    if (typeof console !== 'undefined') console.debug('[analytics]', e.name, e.props);
  }
}

let sink: AnalyticsSink = new ConsoleSink();

/** Test/gerçek sağlayıcı enjeksiyonu. */
export function setSink(s: AnalyticsSink): void {
  sink = s;
}

export function track(e: AnalyticsEvent): void {
  try {
    sink.track(e);
  } catch {
    /* analitik asla ürünü kırmaz */
  }
}
