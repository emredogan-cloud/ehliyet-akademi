/**
 * Mobil soru bankası entegrasyon testi (Mobile Phase 4). Gerçek route handler'ı çağırır; sayı,
 * yalın şema, sınav blueprint'i ve ETag/304 önbellek davranışını doğrular.
 */
import { describe, it, expect } from 'vitest';
import { GET as bank } from '@/app/api/mobile/question-bank/route';
import { allQuestions } from '@ea/question-bank';
import { EXAM_BLUEPRINT } from '@ea/content-schema';

const BASE = 'http://test.local';
const get = (headers?: Record<string, string>) =>
  new Request(`${BASE}/api/mobile/question-bank`, { headers });

type Body = {
  version: string;
  count: number;
  blueprint: typeof EXAM_BLUEPRINT;
  questions: Array<{
    id: string;
    subject: string;
    stem: string;
    options: string[];
    answerIndex: number;
    explanation: string;
  }>;
};

describe('mobil soru bankası', () => {
  it('200 döner; tüm bankayı ve blueprint döner; answerIndex geçerli', async () => {
    const res = bank(get());
    expect(res.status).toBe(200);
    const body = (await res.json()) as Body;

    expect(body.count).toBe(allQuestions().length);
    expect(body.questions).toHaveLength(allQuestions().length);
    expect(body.blueprint.totalQuestions).toBe(50);
    expect(body.blueprint.passCorrect).toBe(35);

    for (const q of body.questions) {
      expect(q.options.length).toBeGreaterThanOrEqual(2);
      expect(q.answerIndex).toBeGreaterThanOrEqual(0);
      expect(q.answerIndex).toBeLessThan(q.options.length);
      expect(q.stem.length).toBeGreaterThan(0);
      expect(q.explanation.length).toBeGreaterThan(0);
    }
  });

  it('theory dersleri blueprint dağılımını karşılayacak kadar soru içerir', async () => {
    const body = (await bank(get()).json()) as Body;
    const bySubject = new Map<string, number>();
    for (const q of body.questions) bySubject.set(q.subject, (bySubject.get(q.subject) ?? 0) + 1);
    for (const [subject, want] of Object.entries(EXAM_BLUEPRINT.distribution)) {
      expect(bySubject.get(subject) ?? 0).toBeGreaterThanOrEqual(want);
    }
  });

  it('sürüm + ETag verir; eşleşen If-None-Match → 304', async () => {
    const first = bank(get());
    const etag = first.headers.get('etag');
    const body = (await first.json()) as Body;
    expect(etag).toBe(`"${body.version}"`);
    expect(body.version).toMatch(/^[a-f0-9]{16}$/);

    const second = bank(get({ 'if-none-match': etag! }));
    expect(second.status).toBe(304);
    expect(await second.text()).toBe('');
  });
});
