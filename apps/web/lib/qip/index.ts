/**
 * QIP (Soru Zekâsı Platformu) — Faz 1 genel giriş noktası.
 * Tüm bankayı birleşik şemaya (NormalizedQuestion) normalleştirir + kapsama raporu üretir.
 * BANK_QUESTİON Part 1/2/15. Bkz. QUESTION_PLATFORM_WORKFLOW.md.
 */
import { allQuestions } from '@ea/question-bank';
import { type NormalizedQuestion } from '@ea/content-schema';
import { normalizeQuestion } from './normalize';

export * from './normalize';
export * from './ingest';

let _cache: NormalizedQuestion[] | null = null;
let _byId: Map<string, NormalizedQuestion> | null = null;

/** Tüm banka, birleşik şemada (bir kez hesaplanır, bellek-içi önbelleğe alınır). */
export function normalizedQuestions(): NormalizedQuestion[] {
  if (!_cache) _cache = allQuestions().map((q) => normalizeQuestion(q));
  return _cache;
}

export function normalizedById(id: string): NormalizedQuestion | undefined {
  if (!_byId) _byId = new Map(normalizedQuestions().map((q) => [q.id, q]));
  return _byId.get(id);
}

export interface QipCoverage {
  total: number;
  byCategory: Record<string, number>;
  bySubject: Record<string, number>;
  byDifficulty: Record<string, number>;
  withRelatedLesson: number;
  withRelatedSigns: number;
  withRelatedVehicleParts: number;
  withLearningOutcome: number;
  uniqueFingerprints: number;
  /** Aynı parmak izini paylaşan grup sayısı (>1). */
  duplicateFingerprintGroups: number;
  /** Fazladan (ilk kayıt hariç) yinelenen kayıt sayısı. */
  duplicateRecords: number;
  estimatedTotalMinutes: number;
}

/** Normalleştirme kapsama/dağılım raporu — GERÇEK sayılar (rapor + testlerde kullanılır). */
export function qipCoverage(pool: NormalizedQuestion[] = normalizedQuestions()): QipCoverage {
  const byCategory: Record<string, number> = {};
  const bySubject: Record<string, number> = {};
  const byDifficulty: Record<string, number> = {};
  const fpCounts = new Map<string, number>();
  let withRelatedLesson = 0;
  let withRelatedSigns = 0;
  let withRelatedVehicleParts = 0;
  let withLearningOutcome = 0;
  let totalSeconds = 0;

  for (const q of pool) {
    byCategory[q.category] = (byCategory[q.category] ?? 0) + 1;
    bySubject[q.subject] = (bySubject[q.subject] ?? 0) + 1;
    byDifficulty[q.difficulty] = (byDifficulty[q.difficulty] ?? 0) + 1;
    if (q.relatedLesson) withRelatedLesson++;
    if (q.relatedSigns.length > 0) withRelatedSigns++;
    if (q.relatedVehicleParts.length > 0) withRelatedVehicleParts++;
    if (q.learningOutcome) withLearningOutcome++;
    totalSeconds += q.estimatedSeconds;
    fpCounts.set(q.fingerprint, (fpCounts.get(q.fingerprint) ?? 0) + 1);
  }

  let duplicateFingerprintGroups = 0;
  let duplicateRecords = 0;
  for (const c of fpCounts.values()) {
    if (c > 1) {
      duplicateFingerprintGroups++;
      duplicateRecords += c - 1;
    }
  }

  return {
    total: pool.length,
    byCategory,
    bySubject,
    byDifficulty,
    withRelatedLesson,
    withRelatedSigns,
    withRelatedVehicleParts,
    withLearningOutcome,
    uniqueFingerprints: fpCounts.size,
    duplicateFingerprintGroups,
    duplicateRecords,
    estimatedTotalMinutes: Math.round(totalSeconds / 60),
  };
}
