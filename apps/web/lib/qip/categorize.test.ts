import { describe, it, expect } from 'vitest';
import { classify, themeLabel, THEMES, SUBJECT_FALLBACK_THEME } from './categorize';
import { analyzedQuestions } from './index';

describe('classify — akıllı sınıflandırma', () => {
  it('konu jetonundan doğru temayı seçer', () => {
    expect(classify({ subject: 'trafik', topic: 'hiz', tags: [] }).primaryTheme).toBe('hiz-mesafe');
    expect(classify({ subject: 'trafik', topic: 'dur-levhasi', tags: [] }).primaryTheme).toBe(
      'trafik-isaretleri'
    );
    expect(classify({ subject: 'motor', topic: 'fren-bakim', tags: [] }).primaryTheme).toBe('fren');
    expect(classify({ subject: 'ilkyardim', topic: 'kanama', tags: [] }).primaryTheme).toBe(
      'kanama-yara'
    );
  });

  it('ders kapsamı yanlış-pozitifi engeller (hiz-adabi → Adab, Hız teması değil)', () => {
    const c = classify({ subject: 'adab', topic: 'hiz-adabi', tags: [] });
    expect(c.primaryTheme).not.toBe('hiz-mesafe');
    expect(c.primaryTheme).toBe(SUBJECT_FALLBACK_THEME.adab.id);
  });

  it('tam jeton eşleşir, kelime-içi eşleşmez ("far" ≠ "farkindaligi")', () => {
    // engelli-farkindaligi → "far" temasına DÜŞMEZ, yaya-okul temasına gider (engelli).
    const c = classify({ subject: 'adab', topic: 'engelli-farkindaligi', tags: [] });
    expect(c.themes).not.toContain('farlar');
  });

  it('eşleşme yoksa ders yedeğine düşer', () => {
    const c = classify({ subject: 'trafik', topic: 'zzz-bilinmeyen-konu', tags: [] });
    expect(c.primaryTheme).toBe(SUBJECT_FALLBACK_THEME.trafik.id);
    expect(c.themes).toEqual([SUBJECT_FALLBACK_THEME.trafik.id]);
  });

  it('etiketten de sınıflandırabilir', () => {
    const c = classify({ subject: 'trafik', topic: 'genel', tags: ['oncelik'] });
    expect(c.themes).toContain('oncelik');
  });

  it('themeLabel tema ve yedek id’lerini çözer', () => {
    expect(themeLabel('fren')).toBe('Fren Sistemi');
    expect(themeLabel(SUBJECT_FALLBACK_THEME.adab.id)).toBe('Trafik Adabı ve Empati');
    expect(themeLabel('yok-boyle-id')).toBe('yok-boyle-id');
  });

  it('tema id’leri benzersiz', () => {
    const ids = THEMES.map((t) => t.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('tüm banka: her soruya bir primaryTheme atanır', () => {
    const pool = analyzedQuestions();
    expect(pool.every((q) => q.primaryTheme && q.primaryThemeLabel)).toBe(true);
    expect(pool.every((q) => q.themes.length >= 1)).toBe(true);
  });
});
