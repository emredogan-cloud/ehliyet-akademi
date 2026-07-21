import { describe, it, expect } from 'vitest';
import { bankGrowth, MILESTONES } from './growth';
import { allQuestions } from '@ea/question-bank';

describe('bankGrowth — milestone takibi (Faz 7)', () => {
  const g = bankGrowth();

  it('gerçek banka boyutunu raporlar', () => {
    expect(g.current).toBe(allQuestions().length);
    expect(g.current).toBeGreaterThan(1534); // Faz 4 genişletmesinden sonra
    expect(g.authoredExpansion).toBeGreaterThan(0);
    expect(g.visualGeneratable).toBeGreaterThan(150);
  });

  it('bir sonraki milestone ve ilerleme tutarlı', () => {
    expect(MILESTONES).toContain(g.nextMilestone);
    expect(g.nextMilestone).toBeGreaterThan(g.current);
    expect(g.toNext).toBe(g.nextMilestone! - g.current);
    expect(g.progressPct).toBeGreaterThanOrEqual(0);
    expect(g.progressPct).toBeLessThanOrEqual(100);
  });
});
