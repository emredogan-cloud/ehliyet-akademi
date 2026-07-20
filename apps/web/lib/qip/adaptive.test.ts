import { describe, it, expect } from 'vitest';
import { adaptiveSelect, weakTopicsFrom } from './adaptive';
import { analyzedQuestions } from './index';
import type { AnalyticsAnswer } from './analytics';

// 'hiz' konusunda çok yanlış (zayıf), 'fren' konusunda hep doğru (güçlü).
function history(): AnalyticsAnswer[] {
  const logs: AnalyticsAnswer[] = [];
  const hizIds = analyzedQuestions()
    .filter((q) => q.subject === 'trafik' && q.topic === 'hiz')
    .slice(0, 4);
  for (const q of hizIds) {
    logs.push({ questionId: q.id, subject: 'trafik', topic: 'hiz', correct: false });
    logs.push({ questionId: q.id, subject: 'trafik', topic: 'hiz', correct: false });
  }
  const frenIds = analyzedQuestions()
    .filter((q) => q.subject === 'motor' && q.topic === 'fren')
    .slice(0, 3);
  for (const q of frenIds) {
    logs.push({ questionId: q.id, subject: 'motor', topic: 'fren', correct: true });
    logs.push({ questionId: q.id, subject: 'motor', topic: 'fren', correct: true });
  }
  return logs;
}

describe('weakTopicsFrom (Part 11)', () => {
  it('zayıf konuları ustalık artan sırada verir; güçlüyü atlar', () => {
    const w = weakTopicsFrom(history());
    expect(w.some((t) => t.topic === 'hiz')).toBe(true);
    expect(w.some((t) => t.topic === 'fren')).toBe(false); // %100 ustalık → atlanır
    expect(w[0]!.mastery).toBeLessThan(0.85);
  });
});

describe('adaptiveSelect', () => {
  it('seçimi zayıf konulara ağırlıklandırır', () => {
    const plan = adaptiveSelect({ answers: history(), count: 20, seed: 1, weakFocus: 0.7 });
    expect(plan.questions.length).toBe(20);
    expect(plan.weakTopics.some((t) => t.topic === 'hiz')).toBe(true);
    expect(plan.focusRatio).toBeGreaterThan(0.3); // belirgin zayıf-konu odağı
  });

  it('cevaplanmış soruları eler → aynı kavramda YENİ varyant', () => {
    const h = history();
    const answered = new Set(h.map((a) => a.questionId));
    const plan = adaptiveSelect({ answers: h, count: 20, seed: 2, excludeAnswered: true });
    expect(plan.questions.every((q) => !answered.has(q.id))).toBe(true);
  });

  it('deterministik (aynı seed → aynı plan)', () => {
    const a = adaptiveSelect({ answers: history(), count: 15, seed: 9 });
    const b = adaptiveSelect({ answers: history(), count: 15, seed: 9 });
    expect(a.questions.map((q) => q.id)).toEqual(b.questions.map((q) => q.id));
  });

  it('geçmiş yoksa da çalışır (keşif)', () => {
    const plan = adaptiveSelect({ answers: [], count: 10, seed: 1 });
    expect(plan.questions.length).toBe(10);
    expect(plan.weakTopics).toEqual([]);
  });
});
