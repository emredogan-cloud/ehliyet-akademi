/**
 * Beta Faz 9 — akan (streaming) AI ucu: `/api/ai/ask/stream`.
 *
 * Bu testin ASIL konusu "akış çalışıyor mu" değil, **dürüstlük**: tek parça gelen bir yanıt asla
 * akıyormuş gibi bildirilmemeli. Yol haritası şartı birebir budur.
 */
import { describe, it, expect, vi, afterEach } from 'vitest';
import { POST as askStream } from '@/app/api/ai/ask/stream/route';
import { POST as ask } from '@/app/api/ai/ask/route';

const BASE = 'http://test.local';
const post = (body: unknown, path = '/api/ai/ask/stream') =>
  new Request(`${BASE}${path}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });

type Evt = { type: string; [k: string]: unknown };

async function readEvents(res: Response): Promise<Evt[]> {
  const text = await res.text();
  return text
    .split('\n\n')
    .map((b) => b.trim())
    .filter((b) => b.startsWith('data:'))
    .map((b) => JSON.parse(b.slice(5).trim()) as Evt);
}

/** Anthropic SSE gövdesini taklit eder — parçalar SATIR SINIRINDA bölünmez (gerçek hayattaki gibi). */
function fakeAnthropicSse(chunks: string[]): Response {
  const body = new ReadableStream<Uint8Array>({
    start(c) {
      const enc = new TextEncoder();
      c.enqueue(enc.encode('event: message_start\ndata: {"type":"message_start"}\n\n'));
      let carry = '';
      for (const t of chunks) {
        const line = `data: ${JSON.stringify({
          type: 'content_block_delta',
          delta: { type: 'text_delta', text: t },
        })}\n\n`;
        // Kasten ORTADAN böl: tampon mantığı sınanmazsa gerçek ağda sessizce bozulur.
        const cut = Math.floor(line.length / 2);
        c.enqueue(enc.encode(carry + line.slice(0, cut)));
        carry = line.slice(cut);
      }
      c.enqueue(new TextEncoder().encode(carry + 'data: [DONE]\n\n'));
      c.close();
    },
  });
  return new Response(body, { status: 200 });
}

afterEach(() => {
  vi.unstubAllGlobals();
  vi.unstubAllEnvs();
});

describe('/api/ai/ask/stream — dürüst akış', () => {
  it('model YOKSA tek parça döner ve bunu streamed:false ile BİLDİRİR', async () => {
    vi.stubEnv('ANTHROPIC_API_KEY', '');
    const res = await askStream(post({ question: 'Kırmızı ışıkta ne yapmalıyım?' }));
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toContain('text/event-stream');

    const evts = await readEvents(res);
    const meta = evts.find((e) => e.type === 'meta')!;
    expect(meta).toBeDefined();
    expect(meta.streamed).toBe(false);

    // Sahte akış olmadığının ÖLÇÜSÜ: tek bir delta.
    const deltas = evts.filter((e) => e.type === 'delta');
    expect(deltas).toHaveLength(1);
    expect((deltas[0]!.text as string).length).toBeGreaterThan(0);
    expect(evts.at(-1)!.type).toBe('done');
  });

  it('model VARSA parçalar tek tek akar ve streamed:true bildirilir', async () => {
    vi.stubEnv('ANTHROPIC_API_KEY', 'test-key');
    vi.stubGlobal('fetch', async () => fakeAnthropicSse(['Kırmızı ', 'ışıkta ', 'durulur.']));

    const evts = await readEvents(await askStream(post({ question: 'Kırmızı ışık ne demek?' })));
    const meta = evts.find((e) => e.type === 'meta')!;
    expect(meta.streamed).toBe(true);

    const deltas = evts.filter((e) => e.type === 'delta').map((e) => e.text as string);
    // Üç model parçası + sonda eklenen uyarı.
    expect(deltas.length).toBeGreaterThanOrEqual(4);
    expect(deltas.slice(0, 3).join('')).toBe('Kırmızı ışıkta durulur.');
    expect(deltas.at(-1)).toContain('MEB/MTSK');
    expect(evts.at(-1)!.type).toBe('done');
  });

  it('meta İLK olaydır — kaynaklar yanıtın sonu beklenmeden gösterilebilir', async () => {
    vi.stubEnv('ANTHROPIC_API_KEY', '');
    const evts = await readEvents(
      await askStream(post({ question: 'DUR levhasında ne yapılır?' }))
    );
    expect(evts[0]!.type).toBe('meta');
    expect(Array.isArray(evts[0]!.sources)).toBe(true);
  });

  it('akış İLK baytta patlarsa "akıyor" DENMEZ — tek parçaya düşülür', async () => {
    vi.stubEnv('ANTHROPIC_API_KEY', 'test-key');
    vi.stubGlobal('fetch', async () => new Response('nope', { status: 500 }));

    const evts = await readEvents(
      await askStream(post({ question: 'Kırmızı ışıkta ne yapmalıyım?' }))
    );
    const meta = evts.find((e) => e.type === 'meta')!;
    expect(meta.streamed).toBe(false);
    expect(evts.filter((e) => e.type === 'delta')).toHaveLength(1);
  });

  it('akış ORTADA koparsa elde edilen metin korunur ve akış düzgün kapanır', async () => {
    vi.stubEnv('ANTHROPIC_API_KEY', 'test-key');
    vi.stubGlobal('fetch', async () => {
      // DİKKAT: `enqueue` + hemen `error` KULLANILMAZ — `error()` kuyruğu boşaltır, yani parça
      // okuyucuya hiç ulaşmaz ve test "akış hiç başlamadı" durumunu ölçmüş olur. Gerçek "ortada
      // kopma"yı modellemek için parça İLK çekimde verilir, hata İKİNCİ çekimde gelir.
      let pulls = 0;
      const body = new ReadableStream<Uint8Array>({
        pull(c) {
          pulls += 1;
          if (pulls === 1) {
            c.enqueue(
              new TextEncoder().encode(
                `data: ${JSON.stringify({
                  type: 'content_block_delta',
                  delta: { type: 'text_delta', text: 'Yarım ' },
                })}\n\n`
              )
            );
            return;
          }
          c.error(new Error('network_died'));
        },
      });
      return new Response(body, { status: 200 });
    });

    const evts = await readEvents(await askStream(post({ question: 'Kırmızı ışık ne demek?' })));
    expect(evts.find((e) => e.type === 'meta')!.streamed).toBe(true);
    const deltas = evts.filter((e) => e.type === 'delta').map((e) => e.text as string);
    expect(deltas[0]).toBe('Yarım ');
    expect(evts.at(-1)!.type).toBe('done');
  });

  it('çok kısa soru → 400 (tek parça uçla aynı sözleşme)', async () => {
    const res = await askStream(post({ question: 'a' }));
    expect(res.status).toBe(400);
  });

  it('MEVCUT tek parça uç bozulmadı', async () => {
    vi.stubEnv('ANTHROPIC_API_KEY', '');
    const res = await ask(post({ question: 'Kırmızı ışıkta ne yapmalıyım?' }, '/api/ai/ask'));
    expect(res.status).toBe(200);
    const body = (await res.json()) as { answer: string; model: string };
    expect(body.answer.length).toBeGreaterThan(0);
    expect(res.headers.get('content-type')).toContain('application/json');
  });
});
