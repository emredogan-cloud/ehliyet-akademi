import { describe, it, expect } from 'vitest';
import {
  SEED_QUESTIONS,
  verifyBank,
  questionsBySubject,
  subjectCounts,
  questionById,
} from './index';

describe('soru bankası bütünlüğü', () => {
  it('tüm sorular şemaya uygun ve id benzersiz', () => {
    const res = verifyBank();
    if (!res.ok) console.error(res.errors);
    expect(res.ok).toBe(true);
    expect(res.count).toBe(SEED_QUESTIONS.length);
  });

  it('her sorunun doğru cevabı seçenek aralığında', () => {
    for (const q of SEED_QUESTIONS) {
      expect(q.answerIndex).toBeGreaterThanOrEqual(0);
      expect(q.answerIndex).toBeLessThan(q.options.length);
    }
  });

  it('her sorunun anlamlı bir açıklaması var', () => {
    for (const q of SEED_QUESTIONS) {
      expect(q.explanation.length).toBeGreaterThan(15);
    }
  });

  it('dört teorik ders + pratik kapsanıyor', () => {
    const counts = subjectCounts();
    for (const s of ['trafik', 'ilkyardim', 'motor', 'adab', 'pratik'] as const) {
      expect(counts[s] ?? 0).toBeGreaterThan(0);
    }
  });

  it('en ağır ders (trafik) en çok soruya sahip', () => {
    expect(questionsBySubject('trafik').length).toBeGreaterThanOrEqual(
      questionsBySubject('adab').length
    );
  });

  it('id ile erişim çalışır', () => {
    expect(questionById('trafik-001')?.subject).toBe('trafik');
    expect(questionById('yok-boyle')).toBeUndefined();
  });

  it('içerik yönetişimi: her soru kaynak referansı taşır (özgünlük izi)', () => {
    for (const q of SEED_QUESTIONS) {
      expect(q.sourceRef, `${q.id} sourceRef eksik`).toBeTruthy();
    }
  });
});
