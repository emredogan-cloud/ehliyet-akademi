import { describe, it, expect } from 'vitest';
import { SIGNS, signById } from './signs';
import { SIGN_CONFUSIONS, confusionsFor, questionsForSign, allSignIds } from './sign-extras';
import { GLYPH_IDS } from '@/components/signs/TrafficSign';

describe('işaret genişletmesi (Program 2 · Faz 6)', () => {
  it('katalog ≥120 işaret, kimlikler benzersiz', () => {
    expect(SIGNS.length).toBeGreaterThanOrEqual(120);
    const ids = new Set(SIGNS.map((s) => s.id));
    expect(ids.size).toBe(SIGNS.length);
  });

  it('her işaretin görseli çözülür: glyph GLYPHS içinde VEYA glyphText/özel şekil', () => {
    const glyphs = new Set(GLYPH_IDS);
    for (const s of SIGNS) {
      if (s.glyph) {
        expect(glyphs.has(s.glyph), `${s.id} → bilinmeyen glyph '${s.glyph}'`).toBe(true);
      } else {
        const special =
          s.shape === 'octagon' || s.shape === 'inv-triangle' || s.shape === 'diamond';
        expect(Boolean(s.glyphText) || special, `${s.id}: glyph/glyphText yok`).toBe(true);
      }
    }
  });

  it('eğitim alanları dolu ve dersler çözülür', async () => {
    const { lessonBySlug } = await import('./lessons');
    for (const s of SIGNS) {
      expect(s.meaning.length, s.id).toBeGreaterThan(15);
      expect(s.memoryTip.length, s.id).toBeGreaterThan(8);
      expect(['çok yüksek', 'yüksek', 'orta']).toContain(s.examImportance);
      expect(s.keywords.length, s.id).toBeGreaterThanOrEqual(2);
      if (s.relatedLessonSlug) {
        expect(lessonBySlug(s.relatedLessonSlug), `${s.id} → ${s.relatedLessonSlug}`).toBeDefined();
      }
    }
  });

  it('karıştırılan çiftler katalogda çözülür, kendine işaret etmez', () => {
    expect(SIGN_CONFUSIONS.length).toBeGreaterThanOrEqual(5);
    for (const c of SIGN_CONFUSIONS) {
      expect(signById(c.a), c.a).toBeDefined();
      expect(signById(c.b), c.b).toBeDefined();
      expect(c.a).not.toBe(c.b);
      expect(c.difference.length).toBeGreaterThan(20);
    }
    expect(confusionsFor('dur').some((x) => x.other.id === 'yol-ver')).toBe(true);
  });

  it('işaret→soru eşlemesi grounded çalışır (DUR için soru bulunur)', () => {
    const dur = signById('dur')!;
    const qs = questionsForSign(dur);
    expect(qs.length).toBeGreaterThanOrEqual(1);
    expect(allSignIds().length).toBe(SIGNS.length);
  });
});
