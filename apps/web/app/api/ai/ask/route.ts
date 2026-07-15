import { json } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { answerGrounded } from '@/lib/server/ai';

/**
 * Grounded AI yanıtı (Sprint 5). Halüsinasyon kapısı + model soyutlaması + fallback sunucuda.
 * DB gerektirmez. Rate-limited. Yanıt: { answer, grounded, sources, model }.
 */
export async function POST(req: Request): Promise<Response> {
  const limited = checkRateLimit(req, { bucket: 'ai', limit: 20, windowMs: 60_000 });
  if (limited) return limited;

  let body: { question?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const q = (body.question ?? '').trim();
  if (q.length < 3) return json({ error: 'Soru çok kısa.' }, { status: 400 });

  const result = await answerGrounded(q.slice(0, 500));
  return json(result, { headers: { 'cache-control': 'no-store' } });
}
