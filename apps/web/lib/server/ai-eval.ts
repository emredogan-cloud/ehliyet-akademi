/**
 * AI değerlendirme veri kümesi (ROADMAP Faz 22 · Sprint 5) — halüsinasyon önleme kanıtı.
 * Konu-içi sorular grounded yanıtlanmalı; konu-DIŞI sorular REDDEDİLMELİ (grounded=false).
 * `runEval` bunu ölçer; birim testi mock sağlayıcıda %100 doğruluk bekler.
 */
import { answerGrounded } from './ai';

export interface EvalCase {
  q: string;
  expect: 'grounded' | 'refusal';
}

export const AI_EVAL_CASES: EvalCase[] = [
  // Konu-içi (grounded olmalı) — platform içeriğiyle eşleşir
  { q: 'DUR levhasında ne yapılır?', expect: 'grounded' },
  { q: 'Yerleşim yeri içinde otomobil hız sınırı kaçtır?', expect: 'grounded' },
  { q: 'Kalp masajı dakikada kaç bası olmalı?', expect: 'grounded' },
  { q: 'Hararet ikazı yanarsa ne yapmalıyım?', expect: 'grounded' },
  { q: 'Sağdan gelen aracın önceliği nedir?', expect: 'grounded' },
  { q: 'Rampada geri kaymamak için ne yapılır?', expect: 'grounded' },
  // Konu-dışı (reddedilmeli) — platform içeriğiyle eşleşmez
  { q: 'Bitcoin fiyatı ne kadar?', expect: 'refusal' },
  { q: 'Elon Musk kimdir?', expect: 'refusal' },
  { q: 'Real Madrid maçı ne zaman oynanacak?', expect: 'refusal' },
  { q: 'Bana tatil için otel öner', expect: 'refusal' },
];

export interface EvalResult {
  total: number;
  passed: number;
  accuracy: number;
  failures: Array<{ q: string; expected: string; got: string }>;
}

export async function runEval(cases: EvalCase[] = AI_EVAL_CASES): Promise<EvalResult> {
  const failures: EvalResult['failures'] = [];
  let passed = 0;
  for (const c of cases) {
    const r = await answerGrounded(c.q);
    const got = r.grounded ? 'grounded' : 'refusal';
    if (got === c.expect) passed += 1;
    else failures.push({ q: c.q, expected: c.expect, got });
  }
  return { total: cases.length, passed, accuracy: passed / cases.length, failures };
}
