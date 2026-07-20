/**
 * QIP — Faz 4 · AI Soru Üretimi (BANK_QUESTİON Part 7). SUNUCU tarafı (Anthropic).
 *
 * Mevcut bankayı temel alarak ÖZGÜN yeni sorular üretir (parafraz DEĞİL): yeni senaryo, ifade,
 * çeldirici; aynı öğrenme kazanımı. Üretilen HER soru zorunlu boru hattından geçer:
 *   model → JSON ayrıştır → şema doğrula → normalleştir(origin:ai-generated, review:draft)
 *   → AI İnceleyici kapısı (Part 14) → mevcut bankaya karşı dedup → KABUL/RET.
 * Asla otomatik yayımlanmaz. Model enjekte edilebilir (deterministik test). Yapılandırma yoksa
 * (ANTHROPIC_API_KEY yok) DÜRÜSTÇE boş döner — uydurma yapılmaz.
 */
import { Question, hash32, type NormalizedQuestion } from '@ea/content-schema';
import { normalizeQuestion } from '@/lib/qip/normalize';
import {
  reviewGenerated,
  buildReviewContext,
  type ReviewContext,
  type ReviewResult,
} from '@/lib/qip/review';
import { normalizedQuestions } from '@/lib/qip';
import { type AIModel, anthropicModel, aiConfigured } from './ai';
import { logger } from './logger';

export interface GenExample {
  stem: string;
  options: string[];
  answerIndex: number;
  explanation: string;
}

export interface GenSpec {
  subject: 'trafik' | 'ilkyardim' | 'motor' | 'adab' | 'pratik';
  topic: string;
  concept: string;
  examples: GenExample[];
  count: number;
}

export interface GenOutcome {
  accepted: Array<{ question: NormalizedQuestion; review: ReviewResult }>;
  rejected: Array<{ id?: string; reason: string; issues?: string[] }>;
  model: string;
}

const GEN_SYSTEM = `Sen bir Türkiye B sınıfı ehliyet SORU YAZARI'sın. Görevin: verilen kavram ve örnek sorulardan yola çıkarak ÖZGÜN, YENİ sorular üretmek. Kurallar:
- Parafraz YAPMA; yeni senaryo, yeni ifade, yeni çeldiriciler kullan ama AYNI öğrenme kazanımını ölç.
- Her sorunun TEK doğru cevabı olsun; çeldiriciler mantıklı ama yanlış olsun.
- Kesinlikle doğru, güncel ve müfredata uygun bilgi kullan; emin değilsen o soruyu üretme.
- Türkçe yaz. SADECE geçerli bir JSON dizisi döndür; başka metin yok.
Her öğe: {"stem": string, "options": string[3..4], "answerIndex": number, "explanation": string, "difficulty": "kolay"|"orta"|"zor", "whyWrong": string[]}.`;

function buildPrompt(spec: GenSpec): string {
  const ex = spec.examples
    .slice(0, 3)
    .map(
      (e, i) =>
        `Örnek ${i + 1}: ${e.stem}\nSeçenekler: ${e.options.join(' | ')}\nDoğru: ${e.options[e.answerIndex]}\nAçıklama: ${e.explanation}`
    )
    .join('\n\n');
  return `KAVRAM: ${spec.concept} (ders: ${spec.subject}, konu: ${spec.topic})\n\nÖRNEK SORULAR:\n${ex}\n\nYukarıdaki kavram için ${spec.count} adet ÖZGÜN yeni soru üret. Sadece JSON dizisi döndür.`;
}

/** Model çıktısından JSON dizisini sağlamca ayıkla (kod bloğu/önek gürültüsüne dayanıklı). */
export function parseModelJson(text: string): unknown[] {
  const start = text.indexOf('[');
  const end = text.lastIndexOf(']');
  if (start === -1 || end === -1 || end <= start) return [];
  try {
    const parsed = JSON.parse(text.slice(start, end + 1));
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

interface RawItem {
  stem?: unknown;
  options?: unknown;
  answerIndex?: unknown;
  explanation?: unknown;
  difficulty?: unknown;
  whyWrong?: unknown;
}

/**
 * Kavram için varyant üret. `opts.model` enjekte edilirse o kullanılır (test); yoksa yapılandırılmış
 * Anthropic. Yapılandırma yoksa boş `unconfigured` döner (uydurma yok).
 */
export async function generateVariants(
  spec: GenSpec,
  opts: { model?: AIModel; ctx?: ReviewContext } = {}
): Promise<GenOutcome> {
  const model = opts.model ?? (aiConfigured() ? anthropicModel() : null);
  if (!model) return { accepted: [], rejected: [], model: 'unconfigured' };

  const ctx = opts.ctx ?? buildReviewContext(normalizedQuestions());
  const accepted: GenOutcome['accepted'] = [];
  const rejected: GenOutcome['rejected'] = [];

  let items: unknown[] = [];
  try {
    const text = await model.generate(GEN_SYSTEM, buildPrompt(spec));
    items = parseModelJson(text);
  } catch (e) {
    logger.warn('qip_generate_model_error', { err: String(e) });
    return { accepted: [], rejected: [{ reason: 'model_error' }], model: model.name };
  }

  const batchFingerprints = new Set<string>();
  for (const item of items.slice(0, Math.max(0, spec.count) + 4)) {
    const it = item as RawItem;
    const stem = typeof it.stem === 'string' ? it.stem.trim() : '';
    const options = Array.isArray(it.options) ? it.options.map((o) => String(o)) : [];
    const id = `gen-${spec.topic}-${hash32(stem + options.join('|'))}`;

    const raw = {
      id,
      subject: spec.subject,
      topic: spec.topic,
      difficulty: it.difficulty ?? 'orta',
      stem,
      options,
      answerIndex: typeof it.answerIndex === 'number' ? it.answerIndex : -1,
      explanation: typeof it.explanation === 'string' ? it.explanation : '',
      whyWrong: Array.isArray(it.whyWrong) ? it.whyWrong.map((w) => String(w)) : [],
      tags: [spec.topic, 'ai-uretim'],
      review: 'draft' as const,
      sourceRef: `AI üretimi — kavram: ${spec.concept}`,
    };

    const parsed = Question.safeParse(raw);
    if (!parsed.success) {
      rejected.push({ id, reason: 'şema', issues: parsed.error.issues.map((e) => e.message) });
      continue;
    }
    const nq = normalizeQuestion(parsed.data, {
      source: {
        origin: 'ai-generated',
        method: 'ai',
        collection: 'ai-uretim',
        attribution: `AI üretimi — ${spec.concept}`,
        license: 'proprietary',
      },
    });
    // Aynı partide birebir tekrarı ele
    if (batchFingerprints.has(nq.fingerprint)) {
      rejected.push({ id, reason: 'parti-içi yineleme' });
      continue;
    }
    const review = reviewGenerated(nq, ctx);
    if (!review.ok) {
      rejected.push({ id, reason: 'inceleme', issues: review.issues });
      continue;
    }
    batchFingerprints.add(nq.fingerprint);
    ctx.fingerprints.add(nq.fingerprint); // sonraki üretimler bunu da yineleme sayar
    accepted.push({ question: nq, review });
  }

  return { accepted, rejected, model: model.name };
}
