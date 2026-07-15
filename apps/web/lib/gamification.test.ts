import { describe, it, expect } from 'vitest';
import type { AnswerLog, StreakState } from './progress';
import {
  totalXp,
  levelForXp,
  xpToReach,
  dailyGoal,
  weeklyGoal,
  studyHeatmap,
  learningJourney,
  XP,
} from './gamification';

const NOW = new Date('2026-07-15T12:00:00').getTime();
const streak: StreakState = { current: 3, best: 5, lastDay: '2026-07-15' };
function ans(correct: boolean, at: number): AnswerLog {
  return { questionId: 'q', subject: 'trafik', topic: 't', correct, at };
}

describe('XP + seviye', () => {
  it('totalXp gerçek veriden hesaplanır', () => {
    const input = {
      answers: [ans(true, NOW), ans(false, NOW)],
      streak,
      examsFinished: 1,
      lessonsViewed: 2,
    };
    const expected =
      1 * XP.perCorrect +
      1 * XP.perWrong +
      1 * XP.perExam +
      5 * XP.perStreakDay +
      2 * XP.perLessonView;
    expect(totalXp(input)).toBe(expected);
  });

  it('levelForXp eşiklere göre seviye + ilerleme verir', () => {
    expect(levelForXp(0).level).toBe(1);
    expect(levelForXp(xpToReach(2)).level).toBe(2);
    expect(levelForXp(xpToReach(3) - 1).level).toBe(2);
    const l = levelForXp(50); // L1(0)..L2(100) arası
    expect(l.level).toBe(1);
    expect(l.progress).toBeGreaterThan(0);
    expect(l.progress).toBeLessThan(1);
  });
});

describe('hedefler', () => {
  it('günlük hedef bugünkü soruları sayar', () => {
    const answers = [ans(true, NOW), ans(true, NOW - 2 * 86_400_000)]; // biri bugün, biri 2 gün önce
    const g = dailyGoal(answers, 1, NOW);
    expect(g.done).toBe(1);
    expect(g.met).toBe(true);
  });
  it('haftalık hedef son 7 günü sayar', () => {
    const answers = [
      ans(true, NOW),
      ans(true, NOW - 3 * 86_400_000),
      ans(true, NOW - 20 * 86_400_000),
    ];
    const g = weeklyGoal(answers, 10, NOW);
    expect(g.done).toBe(2);
  });
});

describe('ısı haritası', () => {
  it('weeks×7 ızgara döndürür ve bugünün sayımını içerir', () => {
    const grid = studyHeatmap([ans(true, NOW), ans(true, NOW), ans(true, NOW)], 13, NOW);
    expect(grid).toHaveLength(13);
    expect(grid[0]).toHaveLength(7);
    const todayKey = '2026-07-15';
    const cell = grid.flat().find((c) => c.date === todayKey)!;
    expect(cell.count).toBe(3);
    expect(cell.level).toBeGreaterThanOrEqual(1);
  });
});

describe('öğrenme yolculuğu', () => {
  it('adım done bayrakları veriye göre', () => {
    const steps = learningJourney({
      answers: Array.from({ length: 60 }, () => ans(true, NOW)),
      streak,
      examsFinished: 1,
      lessonsViewed: 1,
    });
    expect(steps.find((s) => s.label === 'İlk soruyu çöz')!.done).toBe(true);
    expect(steps.find((s) => s.label === '50 soru çöz')!.done).toBe(true);
    expect(steps.find((s) => s.label === '200 soru çöz')!.done).toBe(false);
  });
});
