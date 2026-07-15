import { describe, it, expect } from 'vitest';
import { answerGrounded, aiConfigured } from './ai';
import { runEval } from './ai-eval';

describe('answerGrounded (grounding + halüsinasyon kapısı)', () => {
  it('ENV yokken mock model kullanılır', () => {
    expect(aiConfigured()).toBe(false);
  });

  it('konu-içi soru grounded yanıtlanır + kaynak taşır', async () => {
    const r = await answerGrounded('DUR levhasında ne yapılır?');
    expect(r.grounded).toBe(true);
    expect(r.sources.length).toBeGreaterThan(0);
    expect(r.model).toBe('mock');
    expect(r.answer).toMatch(/MEB\/MTSK/);
  });

  it('konu-dışı soru REDDEDİLİR (grounded=false, model çağrılmaz)', async () => {
    const r = await answerGrounded('Bitcoin fiyatı ne kadar?');
    expect(r.grounded).toBe(false);
    expect(r.sources).toHaveLength(0);
    expect(r.model).toBe('gate');
    expect(r.answer).toMatch(/eşleşme bulamadım/);
  });
});

describe('AI değerlendirme veri kümesi (hallucination prevention)', () => {
  it('mock sağlayıcıda %100 doğruluk — konu-içi grounded, konu-dışı refusal', async () => {
    const res = await runEval();
    if (res.failures.length) console.error(res.failures);
    expect(res.accuracy).toBe(1);
    expect(res.total).toBeGreaterThanOrEqual(10);
  });
});
