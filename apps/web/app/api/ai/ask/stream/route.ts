import { json } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { answerGroundedStream } from '@/lib/server/ai';

/**
 * Beta Faz 9 — grounded AI yanıtının **akan** sürümü (SSE).
 *
 * `/api/ai/ask` (tek parça) AYNEN DURUYOR: mevcut istemciler ve entegrasyonlar kırılmaz. Bu uç
 * yalnız akışı destekleyen istemciler içindir.
 *
 * Olaylar: `meta` (grounded · sources · model · **streamed**) → `delta`* → `done`.
 * `streamed:false` geldiğinde yanıt tek parçadır; istemci **sahte yazma animasyonu üretmez**.
 */
export async function POST(req: Request): Promise<Response> {
  // Aynı kova: akış, hız sınırını atlatmanın bir yolu OLMAMALI.
  const limited = checkRateLimit(req, { bucket: 'ai', limit: 20, windowMs: 60_000 });
  if (limited) return limited;

  let body: { question?: string; context?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const q = (body.question ?? '').trim();
  if (q.length < 3) return json({ error: 'Soru çok kısa.' }, { status: 400 });

  const context = (body.context ?? '').trim().slice(0, 400);
  const composed = context ? `${q.slice(0, 500)}\n\n[Bağlam: ${context}]` : q.slice(0, 500);

  const encoder = new TextEncoder();
  const stream = new ReadableStream<Uint8Array>({
    async start(controller) {
      try {
        for await (const evt of answerGroundedStream(composed)) {
          controller.enqueue(encoder.encode(`data: ${JSON.stringify(evt)}\n\n`));
        }
      } catch {
        // Üretim tarafı beklenmedik biçimde patlarsa istemci asılı kalmasın.
        controller.enqueue(
          encoder.encode(`data: ${JSON.stringify({ type: 'error', error: 'stream_failed' })}\n\n`)
        );
      } finally {
        controller.close();
      }
    },
  });

  return new Response(stream, {
    headers: {
      'content-type': 'text/event-stream; charset=utf-8',
      'cache-control': 'no-store, no-transform',
      connection: 'keep-alive',
      // Ters vekil arabelleklemesi akışı anlamsız kılar (hepsi sonda gelir).
      'x-accel-buffering': 'no',
    },
  });
}
