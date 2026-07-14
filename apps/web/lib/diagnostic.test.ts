import { describe, it, expect } from 'vitest';
import { pickDiagnostic } from './diagnostic';
import { allQuestions } from '@ea/question-bank';

describe('pickDiagnostic', () => {
  it('deterministik — aynı girdi aynı çıktı', () => {
    const a = pickDiagnostic(8);
    const b = pickDiagnostic(8);
    expect(a.map((q) => q.id)).toEqual(b.map((q) => q.id));
  });

  it('istenen boyutu aşmaz ve dört teorik dersten örnekler', () => {
    const picked = pickDiagnostic(8);
    expect(picked.length).toBeLessThanOrEqual(8);
    const subjects = new Set(picked.map((q) => q.subject));
    // Bankada dört teorik ders de var → en az trafik + bir diğeri gelmeli
    expect(subjects.has('trafik')).toBe(true);
    expect(subjects.size).toBeGreaterThanOrEqual(2);
  });

  it('pratik sorularını tanıya katmaz (yalnız teorik)', () => {
    const picked = pickDiagnostic(8);
    expect(picked.every((q) => q.subject !== 'pratik')).toBe(true);
  });

  it('en ağır ders trafik en az bir soruyla temsil edilir', () => {
    const picked = pickDiagnostic(8, allQuestions());
    expect(picked.filter((q) => q.subject === 'trafik').length).toBeGreaterThanOrEqual(1);
  });
});
