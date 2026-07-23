/**
 * Mobil AI Koç entegrasyon testi (Faz 5). `/api/ai/ask` grounded yanıt döner ve opsiyonel `context`
 * alanını kabul eder (geriye dönük uyumlu). Model sağlayıcıya değil (anahtar yoksa gate/mock) bağlıdır.
 */
import { describe, it, expect } from 'vitest';
import { POST as ask } from '@/app/api/ai/ask/route';

const BASE = 'http://test.local';
const post = (body: unknown) =>
  new Request(`${BASE}/api/ai/ask`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });

type Answer = { answer: string; grounded: boolean; sources: string[]; model: string };

describe('mobil AI Koç /api/ai/ask', () => {
  it('geçerli soru → 200 + { answer, grounded, sources, model }', async () => {
    const res = await ask(post({ question: 'Kırmızı ışıkta ne yapmalıyım?' }));
    expect(res.status).toBe(200);
    const body = (await res.json()) as Answer;
    expect(typeof body.answer).toBe('string');
    expect(body.answer.length).toBeGreaterThan(0);
    expect(typeof body.grounded).toBe('boolean');
    expect(Array.isArray(body.sources)).toBe(true);
    expect(typeof body.model).toBe('string');
  });

  it('opsiyonel context alanı kabul edilir (geriye dönük uyumlu) → 200', async () => {
    const res = await ask(post({ question: 'Bunu açıkla', context: 'Kaygan yol trafik işareti' }));
    expect(res.status).toBe(200);
    const body = (await res.json()) as Answer;
    expect(body.answer.length).toBeGreaterThan(0);
  });

  it('çok kısa soru → 400', async () => {
    const res = await ask(post({ question: 'a' }));
    expect(res.status).toBe(400);
  });
});
