/**
 * QIP ilgili-içerik (öneri) API entegrasyon testi — grafik-güdümlü, halka açık.
 */
import { describe, it, expect } from 'vitest';
import { GET } from './route';

const req = (id: string) => new Request(`http://test.local/api/qip/related/${id}`);

describe('GET /api/qip/related/[id]', () => {
  it('bilinen soru için ilgili içerik döner (kendini dışlar)', async () => {
    const res = await GET(req('trafik-101'));
    expect(res.status).toBe(200);
    const b = (await res.json()) as {
      id: string;
      questions: { ref: string }[];
      lessons: { ref: string }[];
    };
    expect(b.id).toBe('trafik-101');
    expect(Array.isArray(b.questions)).toBe(true);
    expect(b.questions.every((q) => q.ref !== 'trafik-101')).toBe(true);
  });

  it('bilinmeyen soru için boş listeler', async () => {
    const res = await GET(req('yok-boyle-soru'));
    expect(res.status).toBe(200);
    const b = (await res.json()) as { questions: unknown[]; lessons: unknown[] };
    expect(b.questions).toEqual([]);
    expect(b.lessons).toEqual([]);
  });
});
