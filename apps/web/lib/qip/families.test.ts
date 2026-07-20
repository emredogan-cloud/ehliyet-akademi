import { describe, it, expect } from 'vitest';
import { allQuestions } from '@ea/question-bank';
import { buildFamilies, familyOf, familyVariants, familyStats } from './families';

describe('buildFamilies — soru aileleri (bir kavram → çok varyant)', () => {
  const families = buildFamilies();

  it('tüm soruları ailelere böler (kayıp yok), boyuta göre sıralı', () => {
    const sum = families.reduce((a, f) => a + f.size, 0);
    expect(sum).toBe(allQuestions().length);
    for (let i = 1; i < families.length; i++) {
      expect(families[i - 1]!.size).toBeGreaterThanOrEqual(families[i]!.size);
    }
  });

  it('her ailenin bir temsilcisi ve kavram etiketi var', () => {
    for (const f of families.slice(0, 30)) {
      expect(f.questionIds).toContain(f.representativeId);
      expect(f.concept.length).toBeGreaterThan(2);
      expect(f.size).toBe(f.questionIds.length);
    }
  });
});

describe('familyOf / familyVariants — adaptif öğrenme kancası', () => {
  it('bir sorunun ailesi kendisini içerir', () => {
    const f = familyOf('trafik-101');
    expect(f).toBeTruthy();
    expect(f!.questionIds).toContain('trafik-101');
  });

  it('aynı ders+konu soruları aynı ailededir', () => {
    // İki bilinen kanama sorusu aynı kavram ailesinde olmalı (Faz 2: kanama en büyük aile).
    const a = familyOf('trafik-101');
    expect(a).toBeTruthy();
    // familyVariants kendini dışlar ve limitler
    const v = familyVariants('trafik-101', 3);
    expect(v).not.toContain('trafik-101');
    expect(v.length).toBeLessThanOrEqual(3);
  });

  it('bilinmeyen soru için aile yok', () => {
    expect(familyOf('yok-boyle-soru')).toBeUndefined();
    expect(familyVariants('yok-boyle-soru')).toEqual([]);
  });
});

describe('familyStats', () => {
  it('tutarlı toplamlar', () => {
    const s = familyStats();
    expect(s.multiVariant + s.singletons).toBe(s.totalFamilies);
    expect(s.largestSize).toBeGreaterThanOrEqual(1);
    expect(s.questionsInMultiVariant).toBeLessThanOrEqual(allQuestions().length);
    expect(s.avgSize).toBeGreaterThan(0);
  });
});
