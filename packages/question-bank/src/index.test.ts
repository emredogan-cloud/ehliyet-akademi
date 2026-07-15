import { describe, it, expect } from 'vitest';
import { EXAM_BLUEPRINT } from '@ea/content-schema';
import { allQuestions, verifyBank, questionsBySubject, subjectCounts, questionById } from './index';

const SEED_QUESTIONS = allQuestions();

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

  it('banka TAM e-Sınav dağılımını karşılar (23/12/9/6) — Faz 12/13 gereksinimi', () => {
    const counts = subjectCounts();
    const dist = EXAM_BLUEPRINT.distribution;
    expect(counts['trafik']).toBeGreaterThanOrEqual(dist.trafik);
    expect(counts['ilkyardim']).toBeGreaterThanOrEqual(dist.ilkyardim);
    expect(counts['motor']).toBeGreaterThanOrEqual(dist.motor);
    expect(counts['adab']).toBeGreaterThanOrEqual(dist.adab);
  });

  it('Sprint 3: banka anlamlı biçimde genişledi (≥150 soru, her ders derinleşti)', () => {
    expect(SEED_QUESTIONS.length).toBeGreaterThanOrEqual(150);
    const counts = subjectCounts();
    // Her teorik ders bir sınav-dağılımından fazlasını içerir (çeşitlilik için tampon).
    expect(counts['trafik']).toBeGreaterThanOrEqual(40);
    expect(counts['ilkyardim']).toBeGreaterThanOrEqual(25);
    expect(counts['motor']).toBeGreaterThanOrEqual(25);
    expect(counts['adab']).toBeGreaterThanOrEqual(20);
    expect(counts['pratik']).toBeGreaterThanOrEqual(20);
  });

  it('Sprint 3: zenginleştirilmiş metaveri — yeni sorular whyWrong/objective/tags taşır', () => {
    const enriched = allQuestions().filter(
      (q) => (q.whyWrong?.length ?? 0) > 0 && q.objective && (q.tags?.length ?? 0) > 0
    );
    // En az 140 soru tam zenginleştirilmiş metaveriye sahip (Sprint 3 eklemeleri).
    expect(enriched.length).toBeGreaterThanOrEqual(140);
  });
});
