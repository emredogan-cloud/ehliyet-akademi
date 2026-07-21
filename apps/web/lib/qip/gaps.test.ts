import { describe, it, expect } from 'vitest';
import { analyzeGaps } from './gaps';
import { DRIVING_RULES } from './knowledge';
import { SIGNS } from '@/content/signs';

describe('analyzeGaps — boşluk analizi (Faz 3)', () => {
  const g = analyzeGaps();

  it('boşlukları önceliğe göre azalan sıralar', () => {
    expect(g.totalGaps).toBeGreaterThan(0);
    for (let i = 1; i < g.topGaps.length; i++) {
      expect(g.topGaps[i - 1]!.priority).toBeGreaterThanOrEqual(g.topGaps[i]!.priority);
    }
  });

  it('tema kapsamı en ince önce sıralı ve gerçek', () => {
    expect(g.themeCoverage.length).toBeGreaterThan(0);
    for (let i = 1; i < g.themeCoverage.length; i++) {
      expect(g.themeCoverage[i - 1]!.count).toBeLessThanOrEqual(g.themeCoverage[i]!.count);
    }
  });

  it('kural kapsamı tüm kuralları hesaba katar', () => {
    expect(g.ruleCoverage.total).toBe(DRIVING_RULES.length);
    expect(g.ruleCoverage.covered + g.ruleCoverage.uncovered.length).toBe(DRIVING_RULES.length);
  });

  it('işaret kapsamı tutarlı (kapsanan + kapsanmayan = tüm işaretler)', () => {
    expect(g.signCoverage.total).toBe(SIGNS.length);
    expect(g.signCoverage.withQuestions + g.signCoverage.withoutQuestions).toBe(SIGNS.length);
    expect(g.signCoverage.withoutQuestions).toBeGreaterThan(0); // bilinen boşluk
  });

  it('boşluk türleri sayılır', () => {
    const kindSum = Object.values(g.byKind).reduce((a, b) => a + b, 0);
    expect(kindSum).toBe(g.totalGaps);
  });
});
