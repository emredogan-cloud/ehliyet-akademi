/**
 * AI + sağlık uçları entegrasyon testi (Sprint 5).
 */
import { describe, it, expect } from 'vitest';
import { POST as aiAsk } from '@/app/api/ai/ask/route';
import { GET as health } from '@/app/api/health/route';

const BASE = 'http://test.local';
function post(path: string, body: unknown): Request {
  return new Request(BASE + path, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

describe('/api/ai/ask (grounded)', () => {
  it('konu-içi soru 200 + grounded=true', async () => {
    const r = await aiAsk(post('/api/ai/ask', { question: 'DUR levhasında ne yapılır?' }));
    expect(r.status).toBe(200);
    const d = (await r.json()) as { grounded: boolean; sources: string[] };
    expect(d.grounded).toBe(true);
    expect(d.sources.length).toBeGreaterThan(0);
  });

  it('konu-dışı soru 200 + grounded=false (reddedilir)', async () => {
    const r = await aiAsk(post('/api/ai/ask', { question: 'Bitcoin fiyatı ne kadar?' }));
    const d = (await r.json()) as { grounded: boolean };
    expect(d.grounded).toBe(false);
  });

  it('çok kısa soru 400', async () => {
    expect((await aiAsk(post('/api/ai/ask', { question: 'a' }))).status).toBe(400);
  });
});

describe('/api/health', () => {
  it('200 + status ok + servis durumu', () => {
    const r = health();
    expect(r.status).toBe(200);
  });
  it('gövde status ok içerir', async () => {
    const d = (await health().json()) as {
      status: string;
      db: string;
      email: string;
      payments: string;
    };
    expect(d.status).toBe('ok');
    expect(['pglite', 'configured', 'unconfigured']).toContain(d.db);
  });
});
