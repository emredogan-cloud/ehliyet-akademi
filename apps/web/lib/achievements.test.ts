import { describe, it, expect } from 'vitest';
import { computeAchievements, earnedCount } from './achievements';

const base = {
  streakCurrent: 0,
  streakBest: 0,
  totalAnswers: 0,
  correctAnswers: 0,
  examsFinished: 0,
  packsOwned: 0,
};

describe('başarılar', () => {
  it('sıfır durumda hiçbiri kazanılmaz', () => {
    expect(earnedCount(computeAchievements(base))).toBe(0);
  });

  it('ilk cevap → İlk Adım', () => {
    const list = computeAchievements({ ...base, totalAnswers: 1, correctAnswers: 1 });
    expect(list.find((a) => a.id === 'ilk-adim')?.earned).toBe(true);
  });

  it('doğruluk rozeti min-soru eşiği ister', () => {
    // 5/5 doğru ama 20 soru altı → kazanılmaz
    const few = computeAchievements({ ...base, totalAnswers: 5, correctAnswers: 5 });
    expect(few.find((a) => a.id === 'keskin-nisanci')?.earned).toBe(false);
    const many = computeAchievements({ ...base, totalAnswers: 25, correctAnswers: 21 });
    expect(many.find((a) => a.id === 'keskin-nisanci')?.earned).toBe(true);
  });

  it('seri rozetleri en-iyi seriyle çalışır', () => {
    const l = computeAchievements({ ...base, streakBest: 7 });
    expect(l.find((a) => a.id === 'seri-3')?.earned).toBe(true);
    expect(l.find((a) => a.id === 'seri-7')?.earned).toBe(true);
  });
});
