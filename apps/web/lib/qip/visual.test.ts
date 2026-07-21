import { describe, it, expect } from 'vitest';
import { NormalizedQuestion } from '@ea/content-schema';
import { SIGNS } from '@/content/signs';
import { VEHICLE_PARTS } from '@/content/vehicle';
import {
  generateSignQuestions,
  signMeaningQuestion,
  seededRng,
  generatePartQuestions,
  generateVisualQuestions,
} from './visual';
import { reviewGenerated, buildReviewContext } from './review';
import { normalizedQuestions } from './index';

describe('generateSignQuestions — görsel soru üretimi (Part 8)', () => {
  it('her işaret için şema-geçerli görsel soru üretir (image ref + doğru anlam)', () => {
    const qs = generateSignQuestions();
    expect(qs.length).toBe(SIGNS.length);
    for (const q of qs.slice(0, 40)) {
      expect(NormalizedQuestion.safeParse(q).success).toBe(true);
      expect(q.image).toMatch(/^sign:/);
      expect(q.tags).toContain('gorsel');
      expect(q.review).toBe('draft');
      // doğru seçenek gerçek bir işaretin anlamı
      const meaning = q.options[q.answerIndex]!;
      expect(SIGNS.some((s) => s.meaning === meaning)).toBe(true);
      // seçenekler benzersiz
      expect(new Set(q.options).size).toBe(q.options.length);
    }
  });

  it('deterministik — aynı işaret aynı soruyu verir', () => {
    const sign = SIGNS[0]!;
    const a = signMeaningQuestion(sign, seededRng(42));
    const b = signMeaningQuestion(sign, seededRng(42));
    expect(a).toEqual(b);
  });

  it('doğru seçenek işaretin anlamıdır, çeldiriciler farklı anlamlar', () => {
    const sign = SIGNS.find((s) => s.category === 'yasak') ?? SIGNS[0]!;
    const q = signMeaningQuestion(sign, seededRng(7));
    expect(q.options[q.answerIndex]).toBe(sign.meaning);
    const distractors = q.options.filter((_, i) => i !== q.answerIndex);
    expect(distractors).not.toContain(sign.meaning);
  });

  it('üretilen görsel soruların çoğu AI İnceleyici’den geçer', () => {
    const ctx = buildReviewContext(normalizedQuestions());
    const qs = generateSignQuestions();
    const passed = qs.filter((q) => reviewGenerated(q, ctx).ok).length;
    // Çoğunluk geçmeli (bazıları mevcut işaret sorularıyla yineleme olabilir → dürüst).
    expect(passed).toBeGreaterThan(qs.length * 0.6);
  });
});

describe('generatePartQuestions — araç parçası görsel soruları (Faz 5)', () => {
  it('her parça için şema-geçerli görsel soru (image ref + doğru ad)', () => {
    const qs = generatePartQuestions();
    expect(qs.length).toBe(VEHICLE_PARTS.length);
    for (const q of qs.slice(0, 30)) {
      expect(NormalizedQuestion.safeParse(q).success).toBe(true);
      expect(q.image).toMatch(/^(part:|asset:)/);
      expect(q.tags).toContain('gorsel');
      expect(q.subject).toBe('motor');
      const name = q.options[q.answerIndex]!;
      expect(VEHICLE_PARTS.some((p) => p.name === name)).toBe(true);
      expect(new Set(q.options).size).toBe(q.options.length);
    }
  });

  it('generateVisualQuestions işaret + parça birleşir', () => {
    const all = generateVisualQuestions();
    expect(all.length).toBe(SIGNS.length + VEHICLE_PARTS.length);
  });
});
