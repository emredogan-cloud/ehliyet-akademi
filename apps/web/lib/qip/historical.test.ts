import { describe, it, expect } from 'vitest';
import {
  historicalIndex,
  historicalExam,
  historicalSessionCount,
  HISTORICAL_LABEL,
} from './historical';
import { EXAM_BLUEPRINT } from '@ea/content-schema';

describe('historical — tarihsel sınav deneyimi (Faz 6)', () => {
  it('indeks yıla göre gruplanmış oturumlar verir', () => {
    const idx = historicalIndex();
    expect(idx.length).toBeGreaterThan(0);
    const total = idx.reduce((a, y) => a + y.sessions.length, 0);
    expect(total).toBe(historicalSessionCount());
  });

  it('bir oturum için MEB formatında ÖZGÜN deneme üretir (deterministik)', () => {
    const idx = historicalIndex();
    const id = idx[0]!.sessions[0]!.id;
    const a = historicalExam(id)!;
    const b = historicalExam(id)!;
    expect(a.label).toBe(HISTORICAL_LABEL);
    expect(a.questions.length).toBe(EXAM_BLUEPRINT.totalQuestions);
    expect(a.questions.map((q) => q.id)).toEqual(b.questions.map((q) => q.id)); // deterministik
    // MEB dağılımı
    expect(a.bySubject.trafik).toBe(EXAM_BLUEPRINT.distribution.trafik);
  });

  it('farklı oturum → farklı sınav', () => {
    const idx = historicalIndex();
    const a = historicalExam(idx[0]!.sessions[0]!.id)!;
    const bId = idx[0]!.sessions[1]?.id ?? idx[1]?.sessions[0]?.id ?? idx[0]!.sessions[0]!.id;
    const b = historicalExam(bId)!;
    if (bId !== idx[0]!.sessions[0]!.id) {
      expect(a.questions.map((q) => q.id)).not.toEqual(b.questions.map((q) => q.id));
    }
  });

  it('bilinmeyen oturum → undefined', () => {
    expect(historicalExam('1999-01-01')).toBeUndefined();
  });
});
