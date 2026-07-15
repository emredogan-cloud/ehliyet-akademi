import { describe, it, expect } from 'vitest';
import { LESSONS, lessonBySlug } from './lessons';

/**
 * Program 1 · Bölüm D — ders içi görsel bloklar (callout + karşılaştırma tablosu).
 * Metin-ağırlıklı anlatımın görselleştirildiğini garanti eder.
 */
describe('Ders görsel blokları (Bölüm D)', () => {
  it('çekirdek derslerde callout veya karşılaştırma tablosu bulunur', () => {
    const withVisual = LESSONS.filter((l) => l.sections.some((s) => s.callout || s.compare));
    // En az 5 ders görsel bloklarla zenginleştirilmiş olmalı.
    expect(withVisual.length).toBeGreaterThanOrEqual(5);
  });

  it('trafik-isaretleri dersinde hem callout hem karşılaştırma tablosu var', () => {
    const lesson = lessonBySlug('trafik-isaretleri');
    expect(lesson).toBeDefined();
    const hasCallout = lesson!.sections.some((s) => s.callout);
    const hasCompare = lesson!.sections.some((s) => s.compare);
    expect(hasCallout).toBe(true);
    expect(hasCompare).toBe(true);
  });

  it('callout tonları geçerli değer kümesinden', () => {
    const tones = new Set(['info', 'success', 'warning', 'danger']);
    for (const l of LESSONS) {
      for (const s of l.sections) {
        if (s.callout) expect(tones.has(s.callout.tone)).toBe(true);
      }
    }
  });

  it('karşılaştırma tablosunda her satır başlık sütunu kadar hücre içerir', () => {
    for (const l of LESSONS) {
      for (const s of l.sections) {
        if (s.compare) {
          for (const row of s.compare.rows) {
            expect(row.length).toBe(s.compare.headers.length);
          }
        }
      }
    }
  });
});
