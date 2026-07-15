import { describe, it, expect } from 'vitest';
import { newCard, type SrsCard } from '@ea/srs-engine';
import type { AnswerLog, StreakState } from './progress';
import { learningInsights } from './insights';

const NOW = 1_800_000_000_000;
const streak: StreakState = { current: 4, best: 6, lastDay: '2026-07-15' };
function ans(subject: AnswerLog['subject'], correct: boolean, i: number): AnswerLog {
  return { questionId: `${subject}-${i}`, subject, topic: 't', correct, at: NOW - i * 3600_000 };
}

describe('learningInsights (grounded)', () => {
  it('veri yokken başlangıç içgörüsü', () => {
    const out = learningInsights([], streak, new Map(), NOW);
    expect(out).toHaveLength(1);
    expect(out[0]!.title).toMatch(/Başlangıç/);
  });

  it('en güçlü/zayıf ders + seri + tempo içgörüsü üretir', () => {
    const answers: AnswerLog[] = [
      // trafik güçlü
      ...Array.from({ length: 6 }, (_, i) => ans('trafik', true, i)),
      // adab zayıf
      ...Array.from({ length: 4 }, (_, i) => ans('adab', false, i + 6)),
    ];
    const out = learningInsights(answers, streak, new Map(), NOW);
    const text = out.map((i) => i.title + ' ' + i.detail).join(' ');
    expect(text).toMatch(/En güçlü/);
    expect(text).toMatch(/Odak/);
    expect(text).toMatch(/günlük seri/);
  });

  it('vadesi gelen kart içgörüsü', () => {
    const cards = new Map<string, SrsCard>();
    cards.set('q1', newCard('q1', NOW - 5 * 86_400_000));
    const out = learningInsights([ans('trafik', true, 1)], streak, cards, NOW);
    expect(out.some((i) => /tekrar zamanı/.test(i.title))).toBe(true);
  });
});
