/**
 * QIP (Soru Zekâsı Platformu) — Faz 1: içerik-duyarlı normalleştirme.
 * BANK_QUESTİON Part 2 (birleşik şema) + Part 1 (kaynak atıfı).
 *
 * `@ea/content-schema.baseNormalize` uygulama içeriği gerektirmeyen alanları doldurur; bu katman
 * levha/parça/ders çapraz bağlarını (relatedSigns / relatedVehicleParts / relatedLesson) DETERMİNİSTİK
 * ve YÜKSEK-KESİNLİKLİ olarak ekler. Faz 3 (bilgi grafiği) bu bağları genişletir — burada amaç
 * kararlı, yanlış-pozitifi düşük bir taban.
 */
import {
  baseNormalize,
  foldText,
  type NormalizedQuestion,
  type NormalizedQuestionInput,
  type Question,
} from '@ea/content-schema';
import { SIGNS } from '@/content/signs';
import { VEHICLE_PARTS } from '@/content/vehicle';
import { LESSONS } from '@/content/lessons';

/** Bir sorunun aranabilir katlanmış metni (stem + seçenekler + açıklama + etiketler + konu). */
export function searchableText(q: Question): string {
  return foldText([q.stem, ...q.options, q.explanation, ...q.tags, q.topic].join(' '));
}

/** `needle` (katlanmış) ifadesi `haystack` (katlanmış) içinde bütün-kelime olarak geçiyor mu? */
export function containsPhrase(haystack: string, needle: string): boolean {
  if (!needle) return false;
  const esc = needle.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`(^| )${esc}( |$)`).test(haystack);
}

/* --- Bir kez kurulan indeksler (modül yükünde) --- */

/** questionId → lessonSlug (dersin quiz/pratik referanslarından — açık, güvenilir bağ). */
const LESSON_BY_QUESTION: Map<string, string> = (() => {
  const m = new Map<string, string>();
  for (const l of LESSONS) {
    for (const id of [...l.quizQuestionIds, ...l.practiceQuestionIds]) {
      if (!m.has(id)) m.set(id, l.slug);
    }
  }
  return m;
})();

/** Ders → (konu tabanlı yedek eşleme için) katlanmış kelime kümesi. */
const LESSON_WORDS: Array<{ slug: string; subject: string; words: Set<string> }> = LESSONS.map(
  (l) => ({
    slug: l.slug,
    subject: l.subject,
    words: new Set(foldText([l.title, l.summary, ...l.objectives, ...l.tips].join(' ')).split(' ')),
  })
);

/** Levha adı (katlanmış) → id. Adlar özgül olduğundan yüksek-kesinlikli ifade eşleşmesi verir. */
const SIGN_NEEDLES: Array<{ id: string; folded: string }> = SIGNS.map((s) => ({
  id: s.id,
  folded: foldText(s.name),
})).sort((a, b) => b.folded.length - a.folded.length); // uzun ad önce (daha özgül)

/** Araç parçası adı (katlanmış) → id. */
const PART_NEEDLES: Array<{ id: string; folded: string }> = VEHICLE_PARTS.map((p) => ({
  id: p.id,
  folded: foldText(p.name),
})).sort((a, b) => b.folded.length - a.folded.length);

const MAX_LINKS = 6;

/** Konuyu (slug: 'donel-kavsak') bütün-kelime kümesine çevirir. */
function topicWords(topic: string): string[] {
  return foldText(topic.replace(/-/g, ' ')).split(' ').filter(Boolean);
}

/** İlgili dersi çöz: önce açık referans, sonra aynı-ders + konu-kelime kapsaması yedeği. */
export function deriveRelatedLesson(q: Question): string | undefined {
  const explicit = LESSON_BY_QUESTION.get(q.id);
  if (explicit) return explicit;
  const tw = topicWords(q.topic);
  if (tw.length === 0) return undefined;
  for (const l of LESSON_WORDS) {
    if (l.subject !== q.subject) continue;
    if (tw.every((w) => l.words.has(w))) return l.slug;
  }
  return undefined;
}

/** Metinde adı bütün ifade olarak geçen levhalar (özgül ad eşleşmesi; en çok MAX_LINKS). */
export function deriveRelatedSigns(text: string): string[] {
  const out: string[] = [];
  for (const s of SIGN_NEEDLES) {
    if (containsPhrase(text, s.folded)) out.push(s.id);
    if (out.length >= MAX_LINKS) break;
  }
  return out;
}

/** Metinde adı bütün ifade olarak geçen araç parçaları (en çok MAX_LINKS). */
export function deriveRelatedVehicleParts(text: string): string[] {
  const out: string[] = [];
  for (const p of PART_NEEDLES) {
    if (containsPhrase(text, p.folded)) out.push(p.id);
    if (out.length >= MAX_LINKS) break;
  }
  return out;
}

/**
 * Tek bir soruyu tam normalleştir — taban alanlar + içerik çapraz bağları.
 * Saf ve deterministik (aynı giriş → aynı çıktı); indeksler modül düzeyinde bir kez kurulur.
 * `overrides` çapraz-bağ türetmesini geçersiz kılar (ör. ingest kaynak metaverisi enjekte eder).
 */
export function normalizeQuestion(
  q: Question,
  overrides: Partial<NormalizedQuestionInput> = {}
): NormalizedQuestion {
  const text = searchableText(q);
  const relatedSigns = deriveRelatedSigns(text);
  // Parça bağlarını yalnız araç tekniği (motor) sorularında ara → yanlış-pozitifi düşürür.
  const relatedVehicleParts = q.subject === 'motor' ? deriveRelatedVehicleParts(text) : [];
  return baseNormalize(q, {
    relatedLesson: deriveRelatedLesson(q),
    relatedSigns,
    relatedVehicleParts,
    ...overrides,
  });
}
