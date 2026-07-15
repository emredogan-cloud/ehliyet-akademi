import { describe, it, expect } from 'vitest';
import { canAccessLesson, requiredCapability, productForLesson } from './entitlements';

describe('canAccessLesson', () => {
  it('premium olmayan ders her zaman erişilebilir', () => {
    expect(canAccessLesson({ slug: 'trafik-isaretleri', premium: false }, [])).toBe(true);
    expect(canAccessLesson({ slug: 'hiz-takip' }, [])).toBe(true);
  });

  it('premium ders sahiplik yoksa kilitli', () => {
    expect(canAccessLesson({ slug: 'park-manevra', premium: true }, [])).toBe(false);
  });

  it('gerekli yeteneği açan paket sahipliğiyle premium ders açılır', () => {
    // park-manevra → direksiyon-premium → 'premium-direksiyon' paketi
    expect(canAccessLesson({ slug: 'park-manevra', premium: true }, ['premium-direksiyon'])).toBe(
      true
    );
    // komple-b tüm yetenekleri açar
    expect(canAccessLesson({ slug: 'park-manevra', premium: true }, ['komple-b'])).toBe(true);
  });

  it('yanlış paket premium dersi açmaz', () => {
    expect(canAccessLesson({ slug: 'park-manevra', premium: true }, ['premium-soru-bankasi'])).toBe(
      false
    );
  });
});

describe('yetenek + ürün eşlemesi', () => {
  it('premium ders için gerekli yetenek bilinir', () => {
    expect(requiredCapability('park-manevra')).toBe('direksiyon-premium');
    expect(requiredCapability('sollama-serit')).toBe('teori-premium');
    expect(requiredCapability('trafik-isaretleri')).toBeUndefined();
  });

  it('kilit ekranı en uygun ürünü önerir', () => {
    expect(productForLesson('park-manevra')).toBe('premium-direksiyon');
  });
});
