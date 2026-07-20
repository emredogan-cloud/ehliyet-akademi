/**
 * QIP soru üretimi API entegrasyon testi — admin gate + görsel üretim + inceleme verdi.
 */
import { describe, it, expect, beforeAll } from 'vitest';
import { POST as register } from '@/app/api/auth/register/route';
import { POST as generate } from './route';

const BASE = 'http://test.local';
const post = (path: string, body: unknown, cookie?: string) =>
  new Request(BASE + path, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...(cookie ? { cookie } : {}) },
    body: JSON.stringify(body),
  });
const cookieOf = (r: Response) => (r.headers.get('set-cookie') ?? '').split(';')[0] ?? '';

// İlk kayıt bootstrap admin olur → tek admin çerezini tüm testlerde yeniden kullan.
let cookie = '';
beforeAll(async () => {
  const reg = await register(
    post('/api/auth/register', {
      name: 'Gen Admin',
      email: `gen-admin-${Date.now()}@ea.dev`,
      password: 'gen-parola-123',
    })
  );
  cookie = cookieOf(reg);
});

describe('POST /api/admin/qip/generate', () => {
  it('oturumsuz istek reddedilir', async () => {
    const res = await generate(post('/api/admin/qip/generate', { mode: 'visual' }));
    expect([401, 403]).toContain(res.status);
  });

  it('görsel mod: incelemeden geçmiş görsel sorular döner', async () => {
    const res = await generate(
      post('/api/admin/qip/generate', { mode: 'visual', limit: 6 }, cookie)
    );
    expect(res.status).toBe(200);
    const b = (await res.json()) as {
      mode: string;
      generated: Array<{ image: string | null; ok: boolean; review: string; options: string[] }>;
    };
    expect(b.mode).toBe('visual');
    expect(b.generated.length).toBe(6);
    expect(b.generated.every((g) => g.review === 'draft')).toBe(true);
    expect(b.generated.every((g) => g.image?.startsWith('sign:'))).toBe(true);
    expect(b.generated.every((g) => g.ok)).toBe(true); // görseller incelemeden geçer
  });

  it('llm mod: spec yoksa 400', async () => {
    const res = await generate(post('/api/admin/qip/generate', { mode: 'llm' }, cookie));
    expect(res.status).toBe(400);
  });

  it('llm mod: anahtar yoksa dürüstçe boş (uydurma yok)', async () => {
    const res = await generate(
      post(
        '/api/admin/qip/generate',
        {
          mode: 'llm',
          spec: {
            subject: 'trafik',
            topic: 'hiz',
            concept: 'Hız',
            examples: [
              { stem: 'x?', options: ['a', 'b'], answerIndex: 0, explanation: 'yyyyyyyy' },
            ],
            count: 1,
          },
        },
        cookie
      )
    );
    expect(res.status).toBe(200);
    const b = (await res.json()) as { aiConfigured: boolean; generated: unknown[] };
    expect(b.aiConfigured).toBe(false);
    expect(b.generated).toEqual([]);
  });
});
