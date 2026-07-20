/**
 * QIP Soru Zekâsı API entegrasyon testi — admin gate + gerçek zekâ özeti (PGlite bellek-içi).
 */
import { describe, it, expect } from 'vitest';
import { POST as register } from '@/app/api/auth/register/route';
import { GET as qipGet } from './route';

const BASE = 'http://test.local';

function post(path: string, body: unknown): Request {
  return new Request(BASE + path, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}
function get(path: string, cookie?: string): Request {
  return new Request(BASE + path, { headers: cookie ? { cookie } : {} });
}
const cookieOf = (r: Response) => (r.headers.get('set-cookie') ?? '').split(';')[0] ?? '';

describe('GET /api/admin/qip', () => {
  it('oturumsuz istek reddedilir', async () => {
    const res = await qipGet(get('/api/admin/qip'));
    expect([401, 403]).toContain(res.status);
  });

  it('admin için gerçek zekâ özeti döner (sınıflandırma + kalite + yineleme)', async () => {
    // İlk kayıt bootstrap admin olur (test ortamı).
    const reg = await register(
      post('/api/auth/register', {
        name: 'QIP Admin',
        email: `qip-admin-${Date.now()}@ea.dev`,
        password: 'qip-parola-123',
      })
    );
    const cookie = cookieOf(reg);
    expect(cookie).toBeTruthy();

    const res = await qipGet(get('/api/admin/qip', cookie));
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      intelligence: {
        coverage: { total: number };
        classifiedByTheme: number;
        themeDistribution: unknown[];
        quality: { count: number; avg: number };
        dedup: { total: number; exactDuplicateRecords: number };
        graph: { nodeCount: number; edgeCount: number };
        families: { totalFamilies: number };
      };
    };
    const q = body.intelligence;
    expect(q.coverage.total).toBeGreaterThan(1000);
    expect(q.classifiedByTheme).toBeGreaterThan(0);
    expect(q.themeDistribution.length).toBeGreaterThan(0);
    expect(q.quality.count).toBe(q.coverage.total);
    expect(q.dedup.exactDuplicateRecords).toBe(0);
    expect(q.graph.nodeCount).toBeGreaterThan(q.coverage.total);
    expect(q.graph.edgeCount).toBeGreaterThan(0);
    expect(q.families.totalFamilies).toBeGreaterThan(0);
  });
});
