import { describe, it, expect } from 'vitest';
import { buildDynamicExam } from './exam';
import { normalizedById } from './index';

describe('buildDynamicExam — dinamik sınav (Part 10)', () => {
  it('varsayılan: ~50 soru, MEB ağırlıklı dağılım, deterministik', () => {
    const a = buildDynamicExam({ seed: 5 });
    const b = buildDynamicExam({ seed: 5 });
    expect(a.count).toBeGreaterThanOrEqual(45);
    expect(a.count).toBeLessThanOrEqual(52);
    expect(a.bySubject.trafik ?? 0).toBeGreaterThan(a.bySubject.adab ?? 0); // trafik ağırlıklı
    expect(b.questions.map((q) => q.id)).toEqual(a.questions.map((q) => q.id)); // deterministik
  });

  it('farklı seed → farklı sınav (benzersiz hisset)', () => {
    const a = buildDynamicExam({ seed: 1 }).questions.map((q) => q.id);
    const b = buildDynamicExam({ seed: 999 }).questions.map((q) => q.id);
    expect(a).not.toEqual(b);
  });

  it('aynı kavram (aile) tekrarı yok', () => {
    const ex = buildDynamicExam({ seed: 7, count: 40, avoidSameFamily: true });
    expect(ex.uniqueFamilies).toBe(ex.count); // her soru farklı aileden
  });

  it('aynı görsel tekrarı yok', () => {
    const ex = buildDynamicExam({ seed: 3, noRepeatImage: true });
    expect(ex.repeatedImages).toBe(0);
  });

  it('seçenekler karıştırılır ama doğru cevap korunur', () => {
    const ex = buildDynamicExam({ seed: 12, count: 30, randomizeChoices: true });
    for (const q of ex.questions) {
      const orig = normalizedById(q.id)!;
      // karıştırılmış sınavdaki doğru şık metni, orijinal doğru şık metnine eşit
      expect(q.options[q.answerIndex]).toBe(orig.options[orig.answerIndex]);
      // seçenek çoklu kümesi aynı
      expect([...q.options].sort()).toEqual([...orig.options].sort());
    }
  });

  it('açık konu karışımı sayılara saygı gösterir', () => {
    const ex = buildDynamicExam({ seed: 2, subjects: { motor: 5, ilkyardim: 3 } });
    expect(ex.bySubject.motor).toBe(5);
    expect(ex.bySubject.ilkyardim).toBe(3);
    expect(ex.bySubject.trafik ?? 0).toBe(0);
  });
});
