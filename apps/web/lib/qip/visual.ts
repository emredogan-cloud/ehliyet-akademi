/**
 * QIP — Faz 4 · Görsel Soru Üretimi (BANK_QUESTİON Part 8).
 *
 * Doğrulanmış trafik işareti kataloğundan (121 özgün işaret) şema-geçerli GÖRSEL sorular üretir:
 * "aşağıdaki işaretin anlamı nedir?" — işaret görseli soruyu taşır, seçenekler anlamlardır,
 * çeldiriciler AYNI kategoriden seçilir (öğretici zorluk). Deterministik (tohumlu RNG enjekte
 * edilebilir). Üretilenler `review:'draft'` + `image` ref taşır; kaynak = doğrulanmış katalog.
 * `visual-quiz.ts` geçici oyun turları üretir; bu modül BANKAYA girebilecek kalıcı sorular üretir.
 */
import { Question, type NormalizedQuestion } from '@ea/content-schema';
import { SIGNS, CATEGORY_LABEL, type TrafficSign } from '@/content/signs';
import { VEHICLE_PARTS, SYSTEM_LABEL, type VehiclePart } from '@/content/vehicle';
import { normalizeQuestion } from './normalize';

export type Rng = () => number;

/** Tohumlu deterministik PRNG (mulberry32) — varsayılan üretim kararlı olsun diye. */
export function seededRng(seed: number): Rng {
  let a = seed >>> 0;
  return () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function shuffle<T>(arr: T[], rng: Rng): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j]!, a[i]!];
  }
  return a;
}

/** Tek bir işaret için görsel "anlamı nedir?" sorusu (şema-geçerli, image ref'li). */
export function signMeaningQuestion(sign: TrafficSign, rng: Rng): NormalizedQuestion {
  const sameCat = SIGNS.filter((s) => s.category === sign.category && s.id !== sign.id);
  const others = SIGNS.filter((s) => s.category !== sign.category && s.id !== sign.id);
  // Çeldirici anlamlar: önce aynı kategori, gerekirse diğerleri (benzersiz anlam).
  const pool = [...shuffle(sameCat, rng), ...shuffle(others, rng)];
  const distractors: string[] = [];
  const seen = new Set([sign.meaning]);
  for (const s of pool) {
    if (distractors.length >= 3) break;
    if (!seen.has(s.meaning)) {
      seen.add(s.meaning);
      distractors.push(s.meaning);
    }
  }
  const options = shuffle([sign.meaning, ...distractors], rng);
  const answerIndex = options.indexOf(sign.meaning);

  const raw = {
    id: `gen-gorsel-${sign.id}`,
    subject: 'trafik' as const,
    topic: 'isaretler',
    difficulty: 'kolay' as const,
    stem: 'Aşağıda gösterilen trafik işareti ne anlama gelir?',
    options,
    answerIndex,
    explanation: `Bu işaret "${sign.name}" işaretidir: ${sign.meaning} ${sign.memoryTip}`,
    tags: ['gorsel', 'isaret', sign.category],
    badge: 'official' as const,
    review: 'draft' as const,
    objective: `${CATEGORY_LABEL[sign.category]} grubundaki "${sign.name}" işaretini görselinden tanımak.`,
    sourceRef: 'Özgün — doğrulanmış trafik işareti kataloğundan üretildi',
  };
  const q = Question.parse(raw);
  return normalizeQuestion(q, {
    image: `sign:${sign.id}`,
    relatedSigns: [sign.id],
    relatedLesson: sign.relatedLessonSlug,
    source: {
      origin: 'authored',
      method: 'curriculum',
      collection: 'gorsel-isaret',
      attribution: 'Doğrulanmış trafik işareti kataloğu (özgün)',
      license: 'proprietary',
    },
  });
}

/**
 * Görsel işaret sorularını üret. `signIds` verilmezse tüm katalog. Deterministik: her işaret
 * kendi tohumuyla üretilir (sıra/altküme değişse de aynı soru).
 */
export function generateSignQuestions(signIds?: string[]): NormalizedQuestion[] {
  const targets = signIds ? SIGNS.filter((s) => signIds.includes(s.id)) : SIGNS;
  return targets.map((s, i) => signMeaningQuestion(s, seededRng(hashSeed(s.id) + i)));
}

/** İşaret id'sinden kararlı tohum. */
function hashSeed(s: string): number {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

/* ================= Faz 5 · Görsel Genişletme — Araç parçaları ================= */

/**
 * Tek bir araç parçası için görsel "hangi parçadır?" sorusu (şema-geçerli, image ref'li).
 * Çeldiriciler AYNI sistemden (motor bölmesi/kabin/dış) seçilir. Mevcut fotoğraf varsa image olur.
 */
export function partIdentifyQuestion(part: VehiclePart, rng: Rng): NormalizedQuestion {
  const sameSystem = VEHICLE_PARTS.filter((p) => p.system === part.system && p.id !== part.id);
  const others = VEHICLE_PARTS.filter((p) => p.system !== part.system && p.id !== part.id);
  const pool = [...shuffle(sameSystem, rng), ...shuffle(others, rng)];
  const distractors: string[] = [];
  const seen = new Set([part.name]);
  for (const p of pool) {
    if (distractors.length >= 3) break;
    if (!seen.has(p.name)) {
      seen.add(p.name);
      distractors.push(p.name);
    }
  }
  const options = shuffle([part.name, ...distractors], rng);
  const answerIndex = options.indexOf(part.name);

  const raw = {
    id: `gen-parca-${part.id}`,
    subject: 'motor' as const,
    topic: 'motor-parcalari',
    difficulty: 'kolay' as const,
    stem: 'Görselde gösterilen araç parçası/bileşeni hangisidir?',
    options,
    answerIndex,
    explanation: `Bu bileşen "${part.name}" (${SYSTEM_LABEL[part.system]}) parçasıdır: ${part.desc}`,
    tags: ['gorsel', 'arac-parca', part.system],
    badge: 'instructor' as const,
    review: 'draft' as const,
    objective: `"${part.name}" araç bileşenini görselinden tanımak.`,
    sourceRef: 'Özgün — doğrulanmış araç bileşeni kataloğundan üretildi',
  };
  const q = Question.parse(raw);
  return normalizeQuestion(q, {
    image: part.photo ? `asset:${part.photo}` : `part:${part.id}`,
    relatedVehicleParts: [part.id],
    relatedLesson: part.relatedLessonSlug,
    source: {
      origin: 'authored',
      method: 'curriculum',
      collection: 'gorsel-parca',
      attribution: 'Doğrulanmış araç bileşeni kataloğu (özgün)',
      license: 'proprietary',
    },
  });
}

/** Araç parçası görsel sorularını üret (deterministik, tohumlu). */
export function generatePartQuestions(partIds?: string[]): NormalizedQuestion[] {
  const targets = partIds ? VEHICLE_PARTS.filter((p) => partIds.includes(p.id)) : VEHICLE_PARTS;
  return targets.map((p, i) => partIdentifyQuestion(p, seededRng(hashSeed(p.id) + i)));
}

/** Tüm görsel sorular (işaret + parça) — Faz 5 birleşik üretim. */
export function generateVisualQuestions(): NormalizedQuestion[] {
  return [...generateSignQuestions(), ...generatePartQuestions()];
}
