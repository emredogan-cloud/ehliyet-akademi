import { describe, it, expect } from 'vitest';
import { validateQip } from './validate';

describe('validateQip — nihai doğrulama (Part 17)', () => {
  const v = validateQip();

  it('bütün denetimleri üretir ve GEÇER (fail yok)', () => {
    const ids = v.checks.map((c) => c.id);
    for (const id of [
      'integrity',
      'duplicates',
      'quality',
      'balance',
      'images',
      'references',
      'graph',
    ]) {
      expect(ids).toContain(id);
    }
    expect(v.passed).toBe(true);
    expect(v.checks.every((c) => c.status !== 'fail')).toBe(true);
  });

  it('yüksek skor (0..100)', () => {
    expect(v.score).toBeGreaterThanOrEqual(85);
    expect(v.score).toBeLessThanOrEqual(100);
  });

  it('bütünlük + referanslar + görseller temiz', () => {
    const byId = new Map(v.checks.map((c) => [c.id, c]));
    expect(byId.get('integrity')!.status).toBe('ok');
    expect(byId.get('references')!.status).toBe('ok'); // 0 bozuk referans
    expect(byId.get('images')!.status).toBe('ok'); // 0 bozuk görsel
    expect(byId.get('duplicates')!.value).toBeLessThan(2); // düşük yineleme oranı
  });
});
