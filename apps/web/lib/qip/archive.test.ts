import { describe, it, expect } from 'vitest';
import { HISTORICAL_SESSIONS, sessionsByYear, historicalSessionById } from './archive';

describe('HISTORICAL_SESSIONS — tarihsel oturum dizini (olgu)', () => {
  it('18 benzersiz oturum, en yeni önce', () => {
    expect(HISTORICAL_SESSIONS.length).toBe(18);
    const ids = HISTORICAL_SESSIONS.map((s) => s.id);
    expect(new Set(ids).size).toBe(18); // benzersiz
    for (let i = 1; i < HISTORICAL_SESSIONS.length; i++) {
      expect(HISTORICAL_SESSIONS[i - 1]!.date >= HISTORICAL_SESSIONS[i]!.date).toBe(true);
    }
  });

  it('her oturumda Türkçe ay etiketi + insan-okur etiket', () => {
    const s = historicalSessionById('2018-02-10')!;
    expect(s).toBeTruthy();
    expect(s.monthLabel).toBe('Şubat');
    expect(s.label).toBe('10 Şubat 2018');
    expect(s.year).toBe(2018);
  });

  it('yıla göre gruplama tutarlı (2015–2018)', () => {
    const groups = sessionsByYear();
    expect(groups.map((g) => g.year)).toEqual([2018, 2017, 2016, 2015]);
    const total = groups.reduce((a, g) => a + g.sessions.length, 0);
    expect(total).toBe(HISTORICAL_SESSIONS.length);
  });

  it('bilinmeyen id → undefined', () => {
    expect(historicalSessionById('1999-01-01')).toBeUndefined();
  });
});
