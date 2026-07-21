/**
 * QIP tarihsel sınav API entegrasyon testi — özgün deneme, kopya sınav değil.
 */
import { describe, it, expect } from 'vitest';
import { GET as indexGet } from './route';
import { GET as examGet } from './[id]/route';

const req = (path: string) => new Request(`http://test.local${path}`);

describe('GET /api/qip/historical', () => {
  it('yıla göre oturum indeksi + özgün-deneme etiketi', async () => {
    const res = await indexGet(req('/api/qip/historical'));
    expect(res.status).toBe(200);
    const b = (await res.json()) as {
      label: string;
      years: Array<{ year: number; sessions: unknown[] }>;
    };
    expect(b.label).toContain('özgün deneme');
    expect(b.years.length).toBeGreaterThan(0);
  });
});

describe('GET /api/qip/historical/[id]', () => {
  it('bir oturum için 50 soruluk özgün deneme döner', async () => {
    const res = await examGet(req('/api/qip/historical/2018-02-10'));
    expect(res.status).toBe(200);
    const b = (await res.json()) as {
      label: string;
      questions: unknown[];
      bySubject: Record<string, number>;
    };
    expect(b.label).toContain('özgün deneme');
    expect(b.questions.length).toBe(50);
    expect(b.bySubject.trafik).toBe(23);
  });

  it('bilinmeyen oturum → 404', async () => {
    const res = await examGet(req('/api/qip/historical/1999-01-01'));
    expect(res.status).toBe(404);
  });
});
