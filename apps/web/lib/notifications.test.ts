import { describe, it, expect } from 'vitest';
import { newCard, type SrsCard } from '@ea/srs-engine';
import type { AnswerLog, StreakState } from './progress';
import { computeNudges } from './notifications';

const NOW = new Date('2026-07-15T12:00:00').getTime();
function ans(at: number): AnswerLog {
  return { questionId: 'q', subject: 'trafik', topic: 't', correct: true, at };
}
function dk(t: number): string {
  const d = new Date(t);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

describe('computeNudges', () => {
  it('seri riski: dün çalışmış, bugün çalışmamış → serini koru', () => {
    const streak: StreakState = { current: 3, best: 3, lastDay: dk(NOW - 86_400_000) };
    const nudges = computeNudges([ans(NOW - 86_400_000)], streak, new Map(), NOW);
    expect(nudges[0]!.id).toBe('streak-risk');
  });

  it('vadesi gelen kart dürtmesi', () => {
    const cards = new Map<string, SrsCard>();
    cards.set('q', newCard('q', NOW - 3 * 86_400_000));
    const streak: StreakState = { current: 0, best: 0, lastDay: '' };
    const nudges = computeNudges([ans(NOW)], streak, cards, NOW);
    expect(nudges.some((n) => n.id === 'due-cards')).toBe(true);
  });

  it('bugün çalışılmadıysa nazik başlangıç; en fazla 3 dürtme', () => {
    const streak: StreakState = { current: 0, best: 0, lastDay: '' };
    const nudges = computeNudges([], streak, new Map(), NOW);
    expect(nudges.some((n) => n.id === 'start-today')).toBe(true);
    expect(nudges.length).toBeLessThanOrEqual(3);
  });
});
