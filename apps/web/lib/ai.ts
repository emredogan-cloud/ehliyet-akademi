/**
 * AI Koç (ROADMAP Faz 22) — sağlayıcı-agnostik arayüz.
 * Varsayılan: MockAIProvider — cevaplarını YALNIZ kendi içeriğimizden (soru bankası +
 * dersler) türetir: retrieval-tabanlı, deterministik, halüsinasyon = 0.
 * Gerçek sağlayıcı (Anthropic) yalnız ENV ile takılır; grounding + doğrulayıcı Faz 22'de.
 */
import type { Question } from '@ea/content-schema';
import { SUBJECT_LABEL } from '@ea/content-schema';
import { allQuestions } from '@ea/question-bank';
import { LESSONS } from '@/content/lessons';

export interface AIMessage {
  role: 'user' | 'assistant';
  text: string;
}

export interface AIProvider {
  readonly name: string;
  ask(question: string): Promise<string>;
}

/** Türkçe-normalize arama anahtarı. */
function norm(s: string): string {
  return s
    .toLocaleLowerCase('tr')
    .replace(/[çğıöşü]/g, (c) => ({ ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u' })[c] ?? c)
    .replace(/[^a-z0-9\s]/g, ' ');
}

// Genel Türkçe dolgu/soru sözcükleri — grounding sinyali taşımaz (halüsinasyon kapısı için genişletildi).
const STOPWORDS = new Set([
  'nedir',
  'nasil',
  'kac',
  'hangi',
  'icin',
  'gerekir',
  'yapilir',
  'bir',
  've',
  'ile',
  'mi',
  'mu',
  'kadar',
  'zaman',
  'gibi',
  'daha',
  'cok',
  'sonra',
  'once',
  'neden',
  'nerede',
  'neresi',
  'kimdir',
  'kim',
  'olan',
  'olarak',
  'var',
  'yok',
  'ise',
  'ne',
  'bu',
  'su',
  'her',
  'hem',
  'ama',
  'veya',
  'yani',
  'gore',
  'ister',
  'istiyorum',
  'oner',
  'onerir',
  'nezaman',
]);

function tokens(s: string): string[] {
  return norm(s)
    .split(/\s+/)
    .filter((t) => t.length > 2 && !STOPWORDS.has(t));
}

/**
 * Önek-duyarlı belirteç eşleşmesi (Türkçe sondan-eklemeli morfoloji için).
 * qt ile herhangi bir içerik belirteci ct, en az 3 karakterlik ortak ÖNEK paylaşıyorsa eşleşir
 * (biri diğerinin önekiyse). Böylece "levha/levhanın" eşleşir ama "maçı" ↔ "amacı" gibi
 * kelime-ORTASI rastlantısal alt-dize eşleşmeleri elenir.
 */
interface MatchStats {
  score: number;
  /** Eşleşen ayrı sorgu token sayısı. */
  count: number;
  /** Eşleşen en uzun sorgu token'ı (özgüllük göstergesi). */
  maxLen: number;
}

function scoreTokens(qs: string[], hayTokens: string[]): MatchStats {
  let score = 0;
  let count = 0;
  let maxLen = 0;
  for (const qt of qs) {
    for (const ct of hayTokens) {
      const shared = Math.min(qt.length, ct.length);
      if (shared >= 3 && (ct.startsWith(qt) || qt.startsWith(ct))) {
        score += qt.length;
        count += 1;
        if (qt.length > maxLen) maxLen = qt.length;
        break;
      }
    }
  }
  return { score, count, maxLen };
}

/**
 * Grounding eşiği: tek bir kısa rastlantısal kelime ("otel", "maç") konu-DIŞI bir
 * isteği grounded yapmamalı. Grounding için ya ≥2 ayrı token eşleşmeli ya da tek
 * eşleşen token yeterince özgül olmalı (≥6 harf). Bu, halüsinasyon kapısını korur.
 */
function qualifies(m: MatchStats): boolean {
  return m.count >= 2 || m.maxLen >= 6;
}

export interface Grounding {
  question?: Question;
  lessonSlug?: string;
  lessonTitle?: string;
}

/** İçerik-tabanlı eşleme: en alakalı soru + ders (saf; test edilebilir). */
export function retrieve(query: string): Grounding {
  const qs = tokens(query);
  if (!qs.length) return {};
  let bestQ: { q: Question; score: number } | null = null;
  for (const q of allQuestions()) {
    const hay = tokens(q.stem + ' ' + q.topic + ' ' + q.explanation);
    const m = scoreTokens(qs, hay);
    if (qualifies(m) && (!bestQ || m.score > bestQ.score)) bestQ = { q, score: m.score };
  }
  let bestL: { slug: string; title: string; score: number } | null = null;
  for (const l of LESSONS) {
    const hay = tokens(
      l.title + ' ' + l.summary + ' ' + l.sections.map((s) => s.heading + ' ' + s.body).join(' ')
    );
    const m = scoreTokens(qs, hay);
    if (qualifies(m) && (!bestL || m.score > bestL.score))
      bestL = { slug: l.slug, title: l.title, score: m.score };
  }
  return {
    question: bestQ?.q,
    lessonSlug: bestL?.slug,
    lessonTitle: bestL?.title,
  };
}

/** Mock koç: retrieval sonucunu insancıl, kaynaklı bir yanıta dönüştürür. */
export class MockAIProvider implements AIProvider {
  readonly name = 'mock';
  async ask(question: string): Promise<string> {
    const g = retrieve(question);
    if (!g.question && !g.lessonSlug) {
      return 'Bu konuda içeriğimizde doğrudan bir eşleşme bulamadım. Soruyu biraz farklı ifade edebilir misin? (Örn. "DUR levhasında ne yapılır?", "hararet ikazı yanınca ne yapmalıyım?") — Ben cevaplarımı yalnız Ehliyet Akademi içeriğine dayandırırım; tahmin yürütmem.';
    }
    const parts: string[] = [];
    if (g.question) {
      const q = g.question;
      parts.push(
        `**${SUBJECT_LABEL[q.subject]} · ${q.topic}** konusunda şunu söyleyebilirim:\n\n${q.explanation}`
      );
      parts.push(`\n📌 İlgili soru: "${q.stem}" — doğru cevap: **${q.options[q.answerIndex]}**.`);
    }
    if (g.lessonSlug) {
      parts.push(
        `\n📚 Derinleşmek için: [${g.lessonTitle}](/dersler/${g.lessonSlug}) dersine göz at.`
      );
    }
    parts.push('\n\n_AI hata yapabilir; resmî kural için MEB/MTSK kaynakları esastır._');
    return parts.join('');
  }
}

export function getAIProvider(): AIProvider {
  // İleride: NEXT_PUBLIC_AI_PROVIDER === 'anthropic' → gerçek adaptör (sunucu tarafı).
  return new MockAIProvider();
}
