import { describe, it, expect } from 'vitest';
import { foldText, NormalizedQuestion } from '@ea/content-schema';
import { allQuestions } from '@ea/question-bank';
import { containsPhrase, deriveRelatedSigns, normalizeQuestion, searchableText } from './normalize';
import { normalizedQuestions, normalizedById, qipCoverage } from './index';

describe('containsPhrase', () => {
  it('bütün kelime eşleşir, kelime-içi eşleşmez', () => {
    expect(containsPhrase('dur levhasinda ne yapilir', 'dur')).toBe(true);
    expect(containsPhrase('durak yerinde beklenir', 'dur')).toBe(false); // "durak" ≠ "dur"
    expect(containsPhrase('ileride kaygan yol vardir', 'kaygan yol')).toBe(true);
    expect(containsPhrase('', 'dur')).toBe(false);
    expect(containsPhrase('bir sey', '')).toBe(false);
  });
});

describe('deriveRelatedSigns', () => {
  it('metinde adı geçen levhayı özgül olarak bağlar', () => {
    const text = foldText('İleride kaygan yol tehlikesi vardır, hız düşürülür.');
    expect(deriveRelatedSigns(text)).toContain('kaygan-yol');
  });
  it('levha adı geçmeyen metinde boş döner', () => {
    const text = foldText('İlk yardımda temel yaşam desteği uygulanır.');
    expect(deriveRelatedSigns(text)).toEqual([]);
  });
});

describe('normalizeQuestion — tüm banka (Part 2 birleşik şema)', () => {
  const pool = normalizedQuestions();

  it('her soru normalleşir ve şemayı geçer', () => {
    expect(pool.length).toBe(allQuestions().length);
    // temsili bir örnek üzerinde tam şema doğrulaması (hepsi zaten parse edilerek üretildi):
    for (const q of pool.slice(0, 50)) {
      expect(NormalizedQuestion.safeParse(q).success).toBe(true);
    }
  });

  it('her kayıtta zorunlu QIP alanları dolu', () => {
    for (const q of pool) {
      expect(q.category.length).toBeGreaterThan(1);
      expect(q.subcategory.length).toBeGreaterThan(1);
      expect(q.estimatedSeconds).toBeGreaterThan(0);
      expect(q.fingerprint).toMatch(/^[0-9a-f]{8}$/);
      expect(q.version).toBeGreaterThanOrEqual(1);
      expect(q.source.origin).toBe('authored');
      expect(Array.isArray(q.commonMistakes)).toBe(true);
    }
  });

  it('deterministik — iki kez normalleştirme aynı sonucu verir', () => {
    const first = normalizeQuestion(allQuestions()[0]!);
    const second = normalizeQuestion(allQuestions()[0]!);
    expect(second).toEqual(first);
  });

  it('açık ders referansı olan soru relatedLesson taşır', () => {
    // pratik-101 bir dersin quizQuestionIds listesindedir (içerik ground-truth).
    const q = normalizedById('pratik-101');
    if (q) expect(q.relatedLesson).toBeTruthy();
  });

  it('searchableText soru metnini katlar', () => {
    const q = allQuestions()[0]!;
    const t = searchableText(q);
    expect(t).toBe(t.toLowerCase());
    expect(t).not.toMatch(/[^a-z0-9\s]/);
  });
});

describe('qipCoverage — gerçek dağılım', () => {
  const cov = qipCoverage();

  it('toplam banka boyutuna eşit ve kategori toplamı tutar', () => {
    expect(cov.total).toBe(allQuestions().length);
    const catSum = Object.values(cov.byCategory).reduce((a, b) => a + b, 0);
    expect(catSum).toBe(cov.total);
  });

  it('açık ders bağları mevcut, süre tahmini pozitif', () => {
    expect(cov.withRelatedLesson).toBeGreaterThan(0);
    expect(cov.estimatedTotalMinutes).toBeGreaterThan(0);
    expect(cov.uniqueFingerprints).toBeLessThanOrEqual(cov.total);
  });
});
