import { describe, it, expect } from 'vitest';
import { SIGNS, filterSigns, signById, signsByCategory } from './signs';

describe('trafik işaretleri kataloğu', () => {
  it('yeterli sayıda işaret + benzersiz id', () => {
    expect(SIGNS.length).toBeGreaterThanOrEqual(40);
    const ids = new Set(SIGNS.map((s) => s.id));
    expect(ids.size).toBe(SIGNS.length);
  });

  it('her işaret zorunlu alanları taşır', () => {
    for (const s of SIGNS) {
      expect(s.name.length).toBeGreaterThan(1);
      expect(s.meaning.length).toBeGreaterThan(10);
      expect(s.memoryTip.length).toBeGreaterThan(4);
      expect(s.keywords.length).toBeGreaterThan(0);
      // görsel: ya glyph ya glyphText ya özel şekil (octagon/inv-triangle) olmalı
      const hasVisual =
        Boolean(s.glyph) ||
        Boolean(s.glyphText) ||
        ['octagon', 'inv-triangle', 'diamond'].includes(s.shape);
      expect(hasVisual, s.id).toBe(true);
    }
  });

  it('tüm ana kategoriler temsil edilir', () => {
    const counts = signsByCategory();
    for (const c of ['tehlike', 'yasak', 'mecburiyet', 'bilgi', 'oncelik'] as const) {
      expect(counts[c] ?? 0, c).toBeGreaterThan(0);
    }
  });
});

describe('filterSigns', () => {
  it('kategoriye göre süzer', () => {
    const tehlike = filterSigns('', 'tehlike');
    expect(tehlike.every((s) => s.category === 'tehlike')).toBe(true);
    expect(tehlike.length).toBeGreaterThan(0);
  });
  it('TR-normalize arama (aksan duyarsız)', () => {
    expect(filterSigns('hiz', 'all').some((s) => s.id.startsWith('azami-hiz'))).toBe(true);
    expect(filterSigns('HIZ', 'all').length).toBe(filterSigns('hiz', 'all').length);
    expect(filterSigns('dur', 'all').some((s) => s.id === 'dur')).toBe(true);
  });
  it('eşleşme yoksa boş', () => {
    expect(filterSigns('qqzzxx', 'all')).toHaveLength(0);
  });
  it('signById çalışır', () => {
    expect(signById('dur')?.name).toBe('DUR');
    expect(signById('yok')).toBeUndefined();
  });
});
