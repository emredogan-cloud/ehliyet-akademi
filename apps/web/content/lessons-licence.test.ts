/**
 * A/D sınıfına özgü ders içeriği — Evolution Faz E5.
 * Web `LESSONS` listesinin DEĞİŞMEDİĞİNİ ve `ALL_LESSONS`'ın yalnız mobil için genişlediğini doğrular.
 */
import { describe, it, expect } from 'vitest';
import { parseLesson } from '@ea/content-schema';
import { ALL_LESSONS, LESSONS, lessonBySlug } from './lessons';
import { LICENCE_LESSONS, MOTO_LESSONS, BUS_LESSONS } from './lessons-licence';

describe('sınıfa özgü dersler (A · D)', () => {
  it('her ders şemadan geçer', () => {
    for (const l of LICENCE_LESSONS) expect(() => parseLesson(l)).not.toThrow();
  });

  it('her ders tek bir sınıfa etiketlidir ve etiketsiz ders içermez', () => {
    for (const l of MOTO_LESSONS) expect(l.licences).toEqual(['a']);
    for (const l of BUS_LESSONS) expect(l.licences).toEqual(['d']);
  });

  it('id/slug benzersizdir ve ortak derslerle çakışmaz', () => {
    const ids = new Set<string>();
    const slugs = new Set<string>();
    for (const l of ALL_LESSONS) {
      expect(ids.has(l.id)).toBe(false);
      expect(slugs.has(l.slug)).toBe(false);
      ids.add(l.id);
      slugs.add(l.slug);
    }
  });

  it('ders numaraları benzersizdir', () => {
    const nos = ALL_LESSONS.map((l) => l.no);
    expect(new Set(nos).size).toBe(nos.length);
  });

  it('web ders kütüphanesi (LESSONS) sınıfa özgü ders TAŞIMAZ — web davranışı korunur', () => {
    expect(LESSONS.every((l) => l.licences.length === 0)).toBe(true);
    expect(ALL_LESSONS.length).toBe(LESSONS.length + LICENCE_LESSONS.length);
    for (const l of LICENCE_LESSONS) expect(lessonBySlug(l.slug)).toBeUndefined();
  });

  it('her sınıfa özgü ders öğrenme değeri taşır (hedef, bölüm, özet, tekrar kartı)', () => {
    for (const l of LICENCE_LESSONS.map(parseLesson)) {
      expect(l.objectives.length).toBeGreaterThanOrEqual(3);
      expect(l.sections.length).toBeGreaterThanOrEqual(3);
      expect(l.keyTakeaways.length).toBeGreaterThanOrEqual(3);
      expect(l.reviewCards.length).toBeGreaterThanOrEqual(2);
      expect(l.mistakes.length).toBeGreaterThanOrEqual(1);
      expect(l.references.length).toBeGreaterThanOrEqual(1);
      // Her bölüm gerçek bir gövde taşır (yer tutucu bölüm yok).
      for (const s of l.sections) expect(s.body.length).toBeGreaterThan(120);
    }
  });

  it('mevzuata dayanan dersler kaynağını referansta gösterir', () => {
    const sureler = LICENCE_LESSONS.find((l) => l.id === 'otobus-takograf-sureler');
    expect(sureler).toBeDefined();
    expect(sureler!.references!.some((r) => r.includes('Karayolları Trafik Yönetmeliği'))).toBe(
      true
    );
    expect(sureler!.references!.some((r) => r.includes('2918'))).toBe(true);
  });

  it('her iki sınıf da eksiksiz bir ders seti alır', () => {
    expect(MOTO_LESSONS.length).toBeGreaterThanOrEqual(5);
    expect(BUS_LESSONS.length).toBeGreaterThanOrEqual(5);
    // Her sınıfın dersleri birden çok konuya yayılır (tek konuya sıkışmış set değil).
    expect(new Set(MOTO_LESSONS.map((l) => l.subject)).size).toBeGreaterThanOrEqual(2);
    expect(new Set(BUS_LESSONS.map((l) => l.subject)).size).toBeGreaterThanOrEqual(2);
  });
});
