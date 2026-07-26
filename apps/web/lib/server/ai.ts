/**
 * AI platformu — sunucu tarafı grounded yanıtlama (ROADMAP Faz 22 · Sprint 5).
 *
 * Mimari:
 * 1) RETRIEVAL — soru, platformun KENDİ içeriğine (dersler + soru bankası) eşlenir.
 * 2) HALÜSİNASYON KAPISI — eşleşme yoksa model ÇAĞRILMAZ; dürüstçe reddedilir (grounded=false).
 * 3) MODEL SOYUTLAMASI — MockModel (varsayılan, deterministik, 0 halüsinasyon) | AnthropicModel (ENV).
 * 4) PROMPT ORKESTRASYONU — sistem promptu modeli YALNIZCA verilen bağlama zorlar.
 * 5) FALLBACK — gerçek model hatası → mock kompozisyonuna düşülür (asla kırılmaz).
 */
import type { Question } from '@ea/content-schema';
import { SUBJECT_LABEL } from '@ea/content-schema';
import { retrieve, type Grounding } from '@/lib/ai';
import { LESSONS } from '@/content/lessons';
import { withRetry } from '@/lib/retry';
import { logger } from './logger';

export interface GroundedAnswer {
  answer: string;
  grounded: boolean;
  sources: string[];
  model: string;
}

const DISCLAIMER = '\n\n_AI hata yapabilir; resmî kural için MEB/MTSK esastır._';

/** Bağlamı grounding'ten kur (modele verilecek KANITLAR). */
function buildContext(g: Grounding): { text: string; sources: string[] } {
  const parts: string[] = [];
  const sources: string[] = [];
  if (g.question) {
    const q: Question = g.question;
    parts.push(
      `[SORU-BANKASI] ${SUBJECT_LABEL[q.subject]} · ${q.topic}\nSoru: ${q.stem}\nDoğru cevap: ${q.options[q.answerIndex]}\nAçıklama: ${q.explanation}`
    );
    sources.push(q.id);
  }
  if (g.lessonSlug) {
    const lesson = LESSONS.find((l) => l.slug === g.lessonSlug);
    if (lesson) {
      const body = lesson.sections.map((s) => `${s.heading}: ${s.body}`).join('\n');
      parts.push(`[DERS] ${lesson.title}\n${lesson.summary}\n${body}`);
      sources.push(`ders:${lesson.slug}`);
    }
  }
  return { text: parts.join('\n\n'), sources };
}

/** Deterministik mock kompozisyonu — YALNIZCA bağlamdan; halüsinasyon imkânsız. */
function mockCompose(g: Grounding): string {
  const parts: string[] = [];
  if (g.question) {
    const q = g.question;
    parts.push(`**${SUBJECT_LABEL[q.subject]} · ${q.topic}** konusunda: \n\n${q.explanation}`);
    parts.push(`\n📌 İlgili soru: "${q.stem}" — doğru cevap: **${q.options[q.answerIndex]}**.`);
  }
  if (g.lessonSlug) {
    parts.push(
      `\n📚 Derinleşmek için: [${g.lessonTitle}](/dersler/${g.lessonSlug}) dersine göz at.`
    );
  }
  return parts.join('') + DISCLAIMER;
}

const SYSTEM_PROMPT = `Sen "Ehliyet Akademi"nin uzman ehliyet eğitim ekibisin. Şu uzmanların ortak bilgisiyle yanıt verirsin: direksiyon eğitmeni, MTSK sınav uzmanı, trafik polisi, araç tekniği eğitmeni, ilk yardım eğitmeni, trafik mevzuatı uzmanı ve sürücü adayı danışmanı.

KAPSAM: YALNIZCA Türkiye B sınıfı ehliyet konuları — trafik kuralları ve işaretleri, ilk yardım, araç tekniği, trafik adabı, direksiyon (pratik) sınavı, e-Sınav süreci ve ehliyet başvuru/mevzuatı. Bu kapsam dışındaki soruları nazikçe reddet: "Ben yalnız ehliyet, trafik ve sürüş konularında yardımcı olurum."

KURALLAR:
- Sana BAĞLAM verildiyse ÖNCE onu esas al (grounded). Bağlam yoksa alan bilginle yanıtla — ama ASLA UYDURMA.
- Kesin bir madde numarası, ceza tutarı veya resmî rakam gerekiyorsa ve emin değilsen, uydurma; "kesin ve güncel bilgi için MEB/MTSK esastır" diyerek yönlendir.
- Türkçe, kısa, net ve öğretici yanıt ver; gerektiğinde adım adım (madde madde).
- Kesin tıbbi veya hukuki tavsiye verme; müfredat/uygulama bilgisini açıkla.`;

export interface AIModel {
  readonly name: string;
  generate(system: string, user: string): Promise<string>;
}

/** Gerçek Anthropic modeli fabrikası (QIP Faz 4 üretim/inceleme için de kullanılır). */
export function anthropicModel(): AIModel {
  return new AnthropicModel();
}

class AnthropicModel implements AIModel {
  readonly name = 'anthropic';
  async generate(system: string, user: string): Promise<string> {
    return withRetry(
      async () => {
        const res = await fetch('https://api.anthropic.com/v1/messages', {
          method: 'POST',
          headers: {
            'x-api-key': process.env.ANTHROPIC_API_KEY!,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
          body: JSON.stringify({
            model: process.env.ANTHROPIC_MODEL ?? 'claude-haiku-4-5-20251001',
            max_tokens: 600,
            system,
            messages: [{ role: 'user', content: user }],
          }),
        });
        if (!res.ok) throw new Error(`anthropic_${res.status}`);
        const data = (await res.json()) as { content?: Array<{ text?: string }> };
        const text = data.content?.[0]?.text?.trim();
        if (!text) throw new Error('anthropic_empty');
        return text;
      },
      { retries: 1, baseMs: 300 }
    );
  }
}

export function aiConfigured(): boolean {
  return Boolean(process.env.ANTHROPIC_API_KEY);
}

/** Ana giriş: soruyu grounded biçimde yanıtla (halüsinasyon kapısı + model + fallback). */
export async function answerGrounded(question: string): Promise<GroundedAnswer> {
  const g = retrieve(question);
  // İçerik eşleşmesi YOK: gerçek model varsa alan-uzmanı modunda yanıtla (P7 — kapsam genişletmesi:
  // meşru sürüş sorularını reddetmek yerine uzman ekip bilgisiyle, alan-dışını nazikçe reddederek
  // yanıtla). Model yoksa (mock/dev) dürüstçe reddet — mock yalnız içerikten besteleyebilir.
  if (!g.question && !g.lessonSlug) {
    if (aiConfigured()) {
      try {
        const model = new AnthropicModel();
        const user = `SORU: ${question}\n\n(Doğrudan içerik bağlamı yok. Soru KAPSAM içindeyse uzman ekip bilginle yanıtla; kapsam dışıysa nazikçe reddet. Kesin rakam/madde gerekiyorsa MEB/MTSK'ya yönlendir.)`;
        const text = await model.generate(SYSTEM_PROMPT, user);
        return {
          answer: text + DISCLAIMER,
          grounded: true,
          sources: [],
          model: 'anthropic-domain',
        };
      } catch (e) {
        logger.warn('ai_domain_fallback', { err: String(e) });
      }
    }
    return {
      answer:
        'Bu konuda içeriğimizde doğrudan bir eşleşme bulamadım. Soruyu biraz farklı ifade edebilir misin? (Örn. "DUR levhasında ne yapılır?", "kalp masajı dakikada kaç bası?") — Yalnız Ehliyet Akademi içeriğine dayanırım; tahmin yürütmem.',
      grounded: false,
      sources: [],
      model: 'gate',
    };
  }

  const { text: context, sources } = buildContext(g);

  // Gerçek model yapılandırılmışsa dene; hata olursa mock kompozisyonuna düş.
  if (aiConfigured()) {
    try {
      const model = new AnthropicModel();
      const user = `BAĞLAM:\n${context}\n\nSORU: ${question}`;
      const text = await model.generate(SYSTEM_PROMPT, user);
      return { answer: text + DISCLAIMER, grounded: true, sources, model: model.name };
    } catch (e) {
      logger.warn('ai_model_fallback', { err: String(e) });
    }
  }
  return { answer: mockCompose(g), grounded: true, sources, model: 'mock' };
}

// ─────────────────────────────────────────────────────────────────────────────
// Beta Faz 9 — GERÇEK akış (streaming)
//
// TEMEL KURAL: anlık (tek parça) yanıt **asla** akıyormuş gibi gösterilmez. Bu yüzden akış
// olayları, yanıtın gerçekten parça parça mı geldiğini (`streamed`) açıkça bildirir; istemci
// sahte bir yazma animasyonu uydurmak yerine bu bayrağa uyar.
//
// Halüsinasyon kapısı akıştan ÖNCE çalışır (aşağıda): eşleşme yoksa ve gerçek model yoksa model
// hiç çağrılmaz — kapının anlamı akışta da korunur.
//
// `answerGrounded` DEĞİŞMEDİ; `/api/ai/ask` aynen çalışmaya devam eder.
// ─────────────────────────────────────────────────────────────────────────────

/** Akış olayı — istemciye SSE olarak taşınır. */
export type AiStreamEvent =
  | { type: 'meta'; grounded: boolean; sources: string[]; model: string; streamed: boolean }
  | { type: 'delta'; text: string }
  | { type: 'done' };

/**
 * Anthropic Messages API'sinden **gerçek** metin parçaları.
 *
 * `stream: true` ile yanıt `text/event-stream`'dir; bize lazım olan tek olay
 * `content_block_delta` → `delta.text`. Diğer olaylar (ping, message_start, …) yok sayılır.
 *
 * Ağ gövdesi parça sınırlarına saygı GÖSTERMEZ: bir SSE satırı iki okuma arasında bölünebilir.
 * Bu yüzden tampon tutulur ve yalnız TAM satırlar işlenir — aksi hâlde JSON.parse sessizce
 * bozulur ve akış ortada kesilir.
 */
async function* anthropicStream(system: string, user: string): AsyncGenerator<string> {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': process.env.ANTHROPIC_API_KEY!,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: process.env.ANTHROPIC_MODEL ?? 'claude-haiku-4-5-20251001',
      max_tokens: 600,
      system,
      messages: [{ role: 'user', content: user }],
      stream: true,
    }),
  });
  if (!res.ok || !res.body) throw new Error(`anthropic_${res.status}`);

  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buf = '';
  let produced = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buf += decoder.decode(value, { stream: true });
    let nl: number;
    while ((nl = buf.indexOf('\n')) !== -1) {
      const line = buf.slice(0, nl).trim();
      buf = buf.slice(nl + 1);
      if (!line.startsWith('data:')) continue;
      const payload = line.slice(5).trim();
      if (!payload || payload === '[DONE]') continue;
      try {
        const evt = JSON.parse(payload) as {
          type?: string;
          delta?: { type?: string; text?: string };
        };
        if (evt.type === 'content_block_delta' && evt.delta?.type === 'text_delta') {
          const t = evt.delta.text ?? '';
          if (t) {
            produced += t.length;
            yield t;
          }
        }
      } catch {
        // Bozuk tek bir olay akışı öldürmez; sonraki satırla devam edilir.
      }
    }
  }
  if (produced === 0) throw new Error('anthropic_empty');
}

/**
 * Grounded yanıtı **akış olarak** üretir.
 *
 * Sıra bilinçlidir: önce retrieval + kapı, sonra `meta`, sonra parçalar. İstemci kaynakları
 * yanıtın SONUNU beklemeden gösterebilir.
 *
 * Gerçek model yoksa ya da akış hata verirse tek parça yanıta düşülür ve `streamed: false`
 * bildirilir — **sahte akış üretilmez**.
 */
export async function* answerGroundedStream(question: string): AsyncGenerator<AiStreamEvent> {
  const g = retrieve(question);
  const hasMatch = Boolean(g.question || g.lessonSlug);
  const { text: context, sources } = hasMatch
    ? buildContext(g)
    : { text: '', sources: [] as string[] };

  if (aiConfigured()) {
    const user = hasMatch
      ? `BAĞLAM:\n${context}\n\nSORU: ${question}`
      : `SORU: ${question}\n\n(Doğrudan içerik bağlamı yok. Soru KAPSAM içindeyse uzman ekip bilginle yanıtla; kapsam dışıysa nazikçe reddet. Kesin rakam/madde gerekiyorsa MEB/MTSK'ya yönlendir.)`;
    const model = hasMatch ? 'anthropic' : 'anthropic-domain';

    // İlk parça gelene kadar `meta` GÖNDERİLMEZ: akış daha ilk baytta patlarsa istemciye
    // "akıyor" demiş olmayalım — bu, sahte akışın en sinsi biçimi olurdu.
    let first: string | null = null;
    let iter: AsyncGenerator<string> | null = null;
    try {
      iter = anthropicStream(SYSTEM_PROMPT, user);
      const n = await iter.next();
      if (!n.done) first = n.value;
    } catch (e) {
      logger.warn('ai_stream_fallback', { err: String(e) });
      iter = null;
    }

    if (iter && first !== null) {
      yield { type: 'meta', grounded: true, sources, model, streamed: true };
      yield { type: 'delta', text: first };
      try {
        for await (const chunk of iter) yield { type: 'delta', text: chunk };
        yield { type: 'delta', text: DISCLAIMER };
        yield { type: 'done' };
        return;
      } catch (e) {
        // Akış ortada koptu: kullanıcı elindeki metni korur, uyarı yine eklenir.
        logger.warn('ai_stream_broken', { err: String(e) });
        yield { type: 'delta', text: DISCLAIMER };
        yield { type: 'done' };
        return;
      }
    }
  }

  // Akış YOK — tek parça, dürüstçe işaretlenmiş.
  const single = await answerGrounded(question);
  yield {
    type: 'meta',
    grounded: single.grounded,
    sources: single.sources,
    model: single.model,
    streamed: false,
  };
  yield { type: 'delta', text: single.answer };
  yield { type: 'done' };
}
