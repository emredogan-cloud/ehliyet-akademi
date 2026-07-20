/**
 * QIP koleksiyonlar API entegrasyon testi — halka açık, gerçek koleksiyonlar.
 */
import { describe, it, expect } from 'vitest';
import { GET } from './route';

describe('GET /api/qip/collections', () => {
  it('otomatik koleksiyonları gerçek sayılarla döner', async () => {
    const res = await GET(new Request('http://test.local/api/qip/collections'));
    expect(res.status).toBe(200);
    const b = (await res.json()) as {
      date: string;
      collections: Array<{ id: string; count: number; sample: unknown[] }>;
    };
    expect(b.date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(b.collections.length).toBeGreaterThanOrEqual(10);
    expect(b.collections.every((c) => c.count > 0)).toBe(true);
    const day = b.collections.find((c) => c.id === 'gunun-sinavi');
    expect(day?.count).toBe(50);
    expect(Array.isArray(day?.sample)).toBe(true);
  });
});
