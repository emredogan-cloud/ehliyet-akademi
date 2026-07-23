import { json } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { answerGrounded } from '@/lib/server/ai';

/**
 * Grounded AI yanıtı (Sprint 5; mobil `context` — AI_MOBILE_BEHAVIOR Faz 5). Halüsinasyon kapısı +
 * model soyutlaması + fallback sunucuda. DB gerektirmez. Rate-limited.
 * İstek: { question, context? } · Yanıt: { answer, grounded, sources, model }.
 */
export async function POST(req: Request): Promise<Response> {
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

  // Opsiyonel bağlam (ör. "Bunu açıkla" için bulunduğun ekranın konusu). Soru tokenları korunur
  // (retrieval bozulmaz); bağlam kısa tutulur.
  const context = (body.context ?? '').trim().slice(0, 400);
  const composed = context ? `${q.slice(0, 500)}\n\n[Bağlam: ${context}]` : q.slice(0, 500);

  const result = await answerGrounded(composed);
  return json(result, { headers: { 'cache-control': 'no-store' } });
}
