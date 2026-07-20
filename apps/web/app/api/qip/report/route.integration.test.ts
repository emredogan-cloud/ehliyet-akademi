/**
 * QIP soru bildirimi + moderasyon entegrasyon testi (Part 13, PGlite bellek-içi).
 */
import { describe, it, expect, beforeAll } from 'vitest';
import { POST as register } from '@/app/api/auth/register/route';
import { POST as report } from './route';
import { GET as listReportsRoute, PATCH as patchReport } from '@/app/api/admin/reports/route';

const BASE = 'http://test.local';
const post = (path: string, body: unknown, cookie?: string) =>
  new Request(BASE + path, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...(cookie ? { cookie } : {}) },
    body: JSON.stringify(body),
  });
const patch = (path: string, body: unknown, cookie?: string) =>
  new Request(BASE + path, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json', ...(cookie ? { cookie } : {}) },
    body: JSON.stringify(body),
  });
const get = (path: string, cookie?: string) =>
  new Request(BASE + path, { headers: cookie ? { cookie } : {} });
const cookieOf = (r: Response) => (r.headers.get('set-cookie') ?? '').split(';')[0] ?? '';

let adminCookie = '';
beforeAll(async () => {
  const reg = await register(
    post('/api/auth/register', {
      name: 'Rapor Admin',
      email: `rapor-admin-${Date.now()}@ea.dev`,
      password: 'rapor-parola-123',
    })
  );
  adminCookie = cookieOf(reg);
});

describe('Soru bildirimi + moderasyon', () => {
  it('anonim bildirim kabul edilir', async () => {
    const res = await report(
      post('/api/qip/report', { questionId: 'trafik-101', kind: 'unclear', message: 'belirsiz' })
    );
    expect(res.status).toBe(200);
    const b = (await res.json()) as { ok: boolean; id: string };
    expect(b.ok).toBe(true);
    expect(b.id).toBeTruthy();
  });

  it('geçersiz kind reddedilir (400)', async () => {
    const res = await report(post('/api/qip/report', { questionId: 'trafik-101', kind: 'yok' }));
    expect(res.status).toBe(400);
  });

  it('moderasyon: admin listeler, çözer; oturumsuz reddedilir', async () => {
    // yeni bir bildirim oluştur
    const created = await report(
      post('/api/qip/report', { questionId: 'trafik-999', kind: 'wrong-answer', message: 'yanlış' })
    );
    const { id } = (await created.json()) as { id: string };

    // oturumsuz liste → reddedilir
    const noAuth = await listReportsRoute(get('/api/admin/reports'));
    expect([401, 403]).toContain(noAuth.status);

    // admin açık listede görür
    const list = await listReportsRoute(get('/api/admin/reports?status=open', adminCookie));
    expect(list.status).toBe(200);
    const lb = (await list.json()) as { reports: Array<{ id: string; questionId: string }> };
    expect(lb.reports.some((r) => r.id === id && r.questionId === 'trafik-999')).toBe(true);

    // çöz
    const upd = await patchReport(
      patch('/api/admin/reports', { id, status: 'resolved' }, adminCookie)
    );
    expect(upd.status).toBe(200);
    expect(((await upd.json()) as { ok: boolean }).ok).toBe(true);

    // artık açık listede yok
    const list2 = await listReportsRoute(get('/api/admin/reports?status=open', adminCookie));
    const lb2 = (await list2.json()) as { reports: Array<{ id: string }> };
    expect(lb2.reports.some((r) => r.id === id)).toBe(false);
  });
});
