import { describe, it, expect } from 'vitest';
import { questionAnalytics, analyticsSummary, type AnalyticsAnswer } from './analytics';

const logs: AnalyticsAnswer[] = [
  {
    questionId: 'q1',
    topic: 'hiz',
    subject: 'trafik',
    correct: true,
    timeMs: 5000,
    chosenIndex: 1,
  },
  {
    questionId: 'q1',
    topic: 'hiz',
    subject: 'trafik',
    correct: false,
    timeMs: 9000,
    chosenIndex: 2,
  },
  {
    questionId: 'q1',
    topic: 'hiz',
    subject: 'trafik',
    correct: false,
    timeMs: 7000,
    chosenIndex: 2,
  },
  { questionId: 'q2', topic: 'fren', subject: 'motor', correct: true },
  { questionId: 'q2', topic: 'fren', subject: 'motor', correct: true },
];

describe('questionAnalytics (Part 12)', () => {
  it('deneme/doğru/yanlış oranı hesaplar', () => {
    const a = questionAnalytics(logs);
    const q1 = a.find((x) => x.questionId === 'q1')!;
    expect(q1.attempts).toBe(3);
    expect(q1.correct).toBe(1);
    expect(q1.wrong).toBe(2);
    expect(q1.correctRate).toBeCloseTo(1 / 3, 5);
    expect(q1.wrongRate).toBeCloseTo(2 / 3, 5);
  });

  it('süre verisi varsa ortalama süre; yoksa undefined', () => {
    const a = questionAnalytics(logs);
    expect(a.find((x) => x.questionId === 'q1')!.avgTimeMs).toBe(7000);
    expect(a.find((x) => x.questionId === 'q2')!.avgTimeMs).toBeUndefined();
  });

  it('en çok seçilen yanlış şık (chosenIndex varsa)', () => {
    const q1 = questionAnalytics(logs).find((x) => x.questionId === 'q1')!;
    expect(q1.mostChosenWrongIndex).toBe(2); // iki kez şık 2 seçilmiş (yanlış)
  });
});

describe('analyticsSummary', () => {
  it('genel oran + konu ustalığı + zorlar + kapsam işaretleri', () => {
    const s = analyticsSummary(logs);
    expect(s.totalAnswers).toBe(5);
    expect(s.uniqueQuestions).toBe(2);
    expect(s.overallCorrectRate).toBeCloseTo(3 / 5, 3);
    expect(s.masteryByTopic.fren).toBe(1);
    expect(s.masteryByTopic.hiz).toBeCloseTo(1 / 3, 2);
    expect(s.hasTiming).toBe(true);
    expect(s.hasChoiceData).toBe(true);
    // q1 (3 deneme) en zor listesinde
    expect(s.hardest[0]?.questionId).toBe('q1');
  });

  it('boş kayıtta güvenli', () => {
    const s = analyticsSummary([]);
    expect(s.totalAnswers).toBe(0);
    expect(s.overallCorrectRate).toBe(0);
    expect(s.hasTiming).toBe(false);
  });
});
