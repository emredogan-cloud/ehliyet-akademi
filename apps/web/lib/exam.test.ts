import { describe, it, expect } from 'vitest';
import { buildExam, scoreExam, shuffle } from './exam';
import { EXAM_BLUEPRINT } from '@ea/content-schema';

/** Deterministik rng (LCG). */
function seeded(seed: number) {
  let s = seed >>> 0;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 2 ** 32;
  };
}

describe('buildExam', () => {
  it('tam blueprint: 50 soru, dağılım 23/12/9/6, baraj 35, süre 45dk', () => {
    const exam = buildExam(seeded(42));
    expect(exam.fullBlueprint).toBe(true);
    expect(exam.questions.length).toBe(EXAM_BLUEPRINT.totalQuestions);
    expect(exam.passCorrect).toBe(EXAM_BLUEPRINT.passCorrect);
    expect(exam.durationSeconds).toBe(EXAM_BLUEPRINT.durationMinutes * 60);
    const bySubject = new Map<string, number>();
    for (const q of exam.questions) bySubject.set(q.subject, (bySubject.get(q.subject) ?? 0) + 1);
    expect(bySubject.get('trafik')).toBe(23);
    expect(bySubject.get('ilkyardim')).toBe(12);
    expect(bySubject.get('motor')).toBe(9);
    expect(bySubject.get('adab')).toBe(6);
  });

  it('soru tekrarı yok (benzersiz id)', () => {
    const exam = buildExam(seeded(7));
    const ids = new Set(exam.questions.map((q) => q.id));
    expect(ids.size).toBe(exam.questions.length);
  });

  it('deterministik rng ile aynı sınav üretilir', () => {
    const a = buildExam(seeded(5)).questions.map((q) => q.id);
    const b = buildExam(seeded(5)).questions.map((q) => q.id);
    expect(a).toEqual(b);
  });

  it('yetersiz havuzda oransal küçültür ve fullBlueprint=false işaretler', () => {
    const tiny = buildExam(
      seeded(1),
      buildExam(seeded(1)).questions.slice(0, 10) // sadece 10 soruluk havuz
    );
    expect(tiny.fullBlueprint).toBe(false);
    expect(tiny.questions.length).toBeLessThan(50);
    expect(tiny.passCorrect).toBeLessThanOrEqual(35);
  });
});

describe('scoreExam', () => {
  it('doğru sayar ve 35 barajına göre geçme kararı verir', () => {
    const exam = buildExam(seeded(3));
    const allCorrect = exam.questions.map((q) => q.answerIndex);
    const res = scoreExam(exam.questions, allCorrect, exam.passCorrect);
    expect(res.correct).toBe(50);
    expect(res.passed).toBe(true);

    const allWrong = exam.questions.map((q) => (q.answerIndex + 1) % q.options.length);
    const res2 = scoreExam(exam.questions, allWrong, exam.passCorrect);
    expect(res2.correct).toBe(0);
    expect(res2.passed).toBe(false);
  });

  it('sınır durumu: tam 35 doğru geçer, 34 kalır', () => {
    const exam = buildExam(seeded(9));
    const answers = exam.questions.map((q, i) =>
      i < 35 ? q.answerIndex : (q.answerIndex + 1) % q.options.length
    );
    expect(scoreExam(exam.questions, answers, 35).passed).toBe(true);
    const answers34 = exam.questions.map((q, i) =>
      i < 34 ? q.answerIndex : (q.answerIndex + 1) % q.options.length
    );
    expect(scoreExam(exam.questions, answers34, 35).passed).toBe(false);
  });

  it('ders bazlı kırılım toplamları tutarlı', () => {
    const exam = buildExam(seeded(11));
    const res = scoreExam(
      exam.questions,
      exam.questions.map(() => null),
      35
    );
    const total = res.perSubject.reduce((a, s) => a + s.total, 0);
    expect(total).toBe(50);
  });
});

describe('shuffle', () => {
  it('elemanları korur', () => {
    const arr = [1, 2, 3, 4, 5];
    const out = shuffle(arr, seeded(2));
    expect(out.slice().sort()).toEqual([1, 2, 3, 4, 5]);
    expect(arr).toEqual([1, 2, 3, 4, 5]); // saf — orijinal değişmez
  });
});
