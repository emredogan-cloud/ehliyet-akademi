import { requireRole, json, guarded } from '@/lib/server/auth';
import { type NormalizedQuestion } from '@ea/content-schema';
import {
  generateSignQuestions,
  reviewGenerated,
  buildReviewContext,
  normalizedQuestions,
  type ReviewResult,
} from '@/lib/qip';
import { generateVariants, type GenSpec } from '@/lib/server/qip-generate';
import { aiConfigured } from '@/lib/server/ai';

interface Body {
  mode?: 'visual' | 'llm';
  limit?: number;
  spec?: GenSpec;
}

function slim(q: NormalizedQuestion, review: ReviewResult) {
  return {
    id: q.id,
    stem: q.stem,
    options: q.options,
    answerIndex: q.answerIndex,
    explanation: q.explanation,
    image: q.image ?? null,
    review: q.review,
    ok: review.ok,
    issues: review.issues,
    score: review.score,
  };
}

/**
 * QIP soru üretimi (admin). BANK_QUESTİON Part 7/8/14.
 * - mode 'visual' (varsayılan): işaret kataloğundan görsel sorular üret + AI İnceleyici verdi
 *   (deterministik; API anahtarı gerekmez).
 * - mode 'llm': Anthropic ile kavram varyantları üret (yapılandırma gerektirir). Üretilenler
 *   ASLA otomatik yayımlanmaz — hepsi review:'draft' ve inceleme kapısından geçer.
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin', 'editor');
  if (user instanceof Response) return user;

  let body: Body = {};
  try {
    body = (await req.json()) as Body;
  } catch {
    /* boş gövde → varsayılan görsel mod */
  }
  const mode = body.mode ?? 'visual';
  const ctx = buildReviewContext(normalizedQuestions());

  if (mode === 'llm') {
    if (!body.spec) return json({ error: 'spec gerekli' }, { status: 400 });
    if (!aiConfigured())
      return json({ mode, aiConfigured: false, generated: [], note: 'ANTHROPIC_API_KEY yok' });
    const out = await generateVariants(body.spec, { ctx });
    return json({
      mode,
      aiConfigured: true,
      model: out.model,
      generated: out.accepted.map((a) => slim(a.question, a.review)),
      rejected: out.rejected,
    });
  }

  // visual
  const limit = Math.min(Math.max(1, body.limit ?? 12), 40);
  const qs = generateSignQuestions().slice(0, limit);
  return json({
    mode: 'visual',
    aiConfigured: aiConfigured(),
    generated: qs.map((q) => slim(q, reviewGenerated(q, ctx))),
  });
});
