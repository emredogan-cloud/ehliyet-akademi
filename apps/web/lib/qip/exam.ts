/**
 * QIP — Faz 5 · Dinamik Sınav Üreticisi (BANK_QUESTİON Part 10).
 *
 * Kısıt-tabanlı benzersiz sınav: adet + konu karışımı + zorluk dengesi, AYNI KAVRAM (aile) tekrarı
 * YOK, AYNI GÖRSEL tekrarı YOK, seçenekler karıştırılmış (randomized). Tohumla (seed) her sınav
 * "benzersiz" hissettirir ama deterministiktir (test). Faz 2 analizini + Faz 3 ailelerini kullanır.
 */
import { EXAM_BLUEPRINT, THEORY_SUBJECTS, type Subject } from '@ea/content-schema';
import { analyzedQuestions, type AnalyzedQuestion } from './index';
import { familyOf } from './families';
import { seededRng, type Rng } from './visual';

function shuffle<T>(arr: T[], rng: Rng): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j]!, a[i]!];
  }
  return a;
}

export interface DynamicExamOptions {
  count?: number;
  /** Açık konu(ders) karışımı; verilmezse MEB dağılımı (23/12/9/6) `count`e ölçeklenir. */
  subjects?: Partial<Record<Subject, number>>;
  /** Zorluğu kolay/orta/zor arasında dengeleyerek seç. */
  difficultyBalance?: boolean;
  /** Aynı görseli iki kez kullanma. */
  noRepeatImage?: boolean;
  /** Aynı kavram ailesinden iki soru alma (varsayılan açık). */
  avoidSameFamily?: boolean;
  /** Seçenek sırasını karıştır (varsayılan açık). */
  randomizeChoices?: boolean;
  pool?: AnalyzedQuestion[];
  seed?: number;
}

export interface DynamicExam {
  questions: AnalyzedQuestion[];
  count: number;
  bySubject: Record<string, number>;
  byDifficulty: Record<string, number>;
  uniqueFamilies: number;
  repeatedImages: number;
  seed: number;
}

/** MEB dağılımını hedef adede ölçekle. */
function scaledTargets(count: number): Record<Subject, number> {
  const d = EXAM_BLUEPRINT.distribution;
  const total = EXAM_BLUEPRINT.totalQuestions;
  const out = {} as Record<Subject, number>;
  for (const s of THEORY_SUBJECTS) out[s] = Math.max(1, Math.round((d[s] / total) * count));
  out.pratik = 0;
  return out;
}

/** Seçenekleri karıştır, answerIndex'i yeniden eşle (yeni kopya). */
function withShuffledChoices(q: AnalyzedQuestion, rng: Rng): AnalyzedQuestion {
  const order = shuffle(
    q.options.map((_, i) => i),
    rng
  );
  return {
    ...q,
    options: order.map((i) => q.options[i]!),
    answerIndex: order.indexOf(q.answerIndex),
  };
}

/**
 * Dinamik sınav kur. Deterministik (seed). Aynı aile/görsel tekrarını atlar; yetersizse eldeki
 * kadar alır (dürüst). Seçenekleri karıştırır.
 */
export function buildDynamicExam(opts: DynamicExamOptions = {}): DynamicExam {
  const count = opts.count ?? EXAM_BLUEPRINT.totalQuestions;
  const seed = opts.seed ?? 1;
  const rng = seededRng(seed);
  const avoidSameFamily = opts.avoidSameFamily ?? true;
  const noRepeatImage = opts.noRepeatImage ?? true;
  const randomize = opts.randomizeChoices ?? true;
  const pool = opts.pool ?? analyzedQuestions();

  const targets = opts.subjects
    ? ({ ...({} as Record<Subject, number>), ...opts.subjects } as Record<Subject, number>)
    : scaledTargets(count);

  const usedFamilies = new Set<string>();
  const usedImages = new Set<string>();
  const chosen: AnalyzedQuestion[] = [];
  let repeatedImages = 0;

  for (const subject of Object.keys(targets) as Subject[]) {
    const want = targets[subject] ?? 0;
    if (want <= 0) continue;
    let candidates = shuffle(
      pool.filter((q) => q.subject === subject),
      rng
    );
    // Zorluk dengesi: kolay/orta/zor öbeklerini dönüşümlü ör (round-robin).
    if (opts.difficultyBalance) candidates = interleaveByDifficulty(candidates, rng);

    let taken = 0;
    for (const q of candidates) {
      if (taken >= want) break;
      const fam = avoidSameFamily ? familyOf(q.id)?.id : undefined;
      if (fam && usedFamilies.has(fam)) continue;
      if (noRepeatImage && q.image && usedImages.has(q.image)) continue;
      chosen.push(q);
      taken++;
      if (fam) usedFamilies.add(fam);
      if (q.image) usedImages.add(q.image);
    }
  }

  const finalQs = shuffle(chosen, rng).map((q) => (randomize ? withShuffledChoices(q, rng) : q));

  const bySubject: Record<string, number> = {};
  const byDifficulty: Record<string, number> = {};
  const fams = new Set<string>();
  const imgs = new Set<string>();
  for (const q of finalQs) {
    bySubject[q.subject] = (bySubject[q.subject] ?? 0) + 1;
    byDifficulty[q.difficulty] = (byDifficulty[q.difficulty] ?? 0) + 1;
    const f = familyOf(q.id)?.id;
    if (f) fams.add(f);
    if (q.image) {
      if (imgs.has(q.image)) repeatedImages++;
      imgs.add(q.image);
    }
  }

  return {
    questions: finalQs,
    count: finalQs.length,
    bySubject,
    byDifficulty,
    uniqueFamilies: fams.size,
    repeatedImages,
    seed,
  };
}

/** Zorluk öbeklerini dönüşümlü diz (dengeli zorluk dağılımı). */
function interleaveByDifficulty(qs: AnalyzedQuestion[], rng: Rng): AnalyzedQuestion[] {
  const buckets: Record<string, AnalyzedQuestion[]> = {
    kolay: shuffle(
      qs.filter((q) => q.difficulty === 'kolay'),
      rng
    ),
    orta: shuffle(
      qs.filter((q) => q.difficulty === 'orta'),
      rng
    ),
    zor: shuffle(
      qs.filter((q) => q.difficulty === 'zor'),
      rng
    ),
  };
  const order = ['kolay', 'orta', 'zor'];
  const out: AnalyzedQuestion[] = [];
  let added = true;
  while (added) {
    added = false;
    for (const d of order) {
      const b = buckets[d]!;
      if (b.length) {
        out.push(b.shift()!);
        added = true;
      }
    }
  }
  return out;
}
