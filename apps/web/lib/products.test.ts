import { describe, it, expect } from 'vitest';
import { PRODUCTS, productById, capabilitiesOf, hasCapability } from './products';

describe('ürün kataloğu (tek-seferlik model)', () => {
  it('kullanıcı direktifindeki paketler mevcut', () => {
    for (const id of [
      'premium-teori',
      'premium-direksiyon',
      'simulator-paketi',
      'premium-soru-bankasi',
      'komple-b',
    ]) {
      expect(productById(id), id).toBeTruthy();
    }
  });

  it('hiçbir üründe yinelenen faturalama ima eden alan yok (tek fiyat)', () => {
    for (const p of PRODUCTS) {
      expect(p.priceTRY).toBeGreaterThan(0);
      // Model gereği ay/yıl fiyat alanları YOK — tip düzeyinde de yok; metinlerde de olmamalı.
      const text = (p.title + p.blurb + p.features.join(' ')).toLowerCase();
      expect(text.includes('aylık')).toBe(false);
      expect(text.includes('abonelik')).toBe(false);
    }
  });

  it('komple-b tüm yetenekleri verir (lifetime unlock)', () => {
    const caps = capabilitiesOf(['komple-b']);
    expect(caps.has('sinirsiz-deneme')).toBe(true);
    expect(caps.has('teori-premium')).toBe(true);
    expect(caps.has('ai-sinirsiz')).toBe(true);
  });

  it('tek paket yalnız kendi yeteneğini verir', () => {
    expect(hasCapability(['simulator-paketi'], 'sinirsiz-deneme')).toBe(true);
    expect(hasCapability(['simulator-paketi'], 'teori-premium')).toBe(false);
    expect(hasCapability([], 'sinirsiz-deneme')).toBe(false);
  });

  it('bilinmeyen ürün id yok sayılır', () => {
    expect(capabilitiesOf(['yok-boyle']).size).toBe(0);
  });
});
