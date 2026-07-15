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
]);

function tokens(s: string): string[] {
  return norm(s)
    .split(/\s+/)
    .filter((t) => t.length > 2 && !STOPWORDS.has(t));
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
    const hay = norm(q.stem + ' ' + q.topic + ' ' + q.explanation);
    let score = 0;
    for (const t of qs) if (hay.includes(t)) score += t.length;
    if (score > 0 && (!bestQ || score > bestQ.score)) bestQ = { q, score };
  }
  let bestL: { slug: string; title: string; score: number } | null = null;
  for (const l of LESSONS) {
    const hay = norm(
      l.title + ' ' + l.summary + ' ' + l.sections.map((s) => s.heading + ' ' + s.body).join(' ')
    );
    let score = 0;
    for (const t of qs) if (hay.includes(t)) score += t.length;
    if (score > 0 && (!bestL || score > bestL.score))
      bestL = { slug: l.slug, title: l.title, score };
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
