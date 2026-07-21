/**
 * QIP (Soru Zekâsı Platformu) — Faz 1 genel giriş noktası.
 * Tüm bankayı birleşik şemaya (NormalizedQuestion) normalleştirir + kapsama raporu üretir.
 * BANK_QUESTİON Part 1/2/15. Bkz. QUESTION_PLATFORM_WORKFLOW.md.
 */
import { allQuestions } from '@ea/question-bank';
import { type NormalizedQuestion } from '@ea/content-schema';
import { normalizeQuestion } from './normalize';
import { classify, SUBJECT_FALLBACK_THEME, themeLabel } from './categorize';
import {
  scoreQuality,
  qualitySummary,
  type QualityBreakdown,
  type QualitySummary,
} from './quality';
import { dedupReport, type DedupReport } from './dedup';
import { graphStats, type GraphStats } from './graph';
import { familyStats, type FamilyStats } from './families';
import { validateQip, type QipValidation } from './validate';

export * from './normalize';
export * from './ingest';
export * from './categorize';
export * from './quality';
export * from './dedup';
export * from './graph';
export * from './families';
export * from './review';
export * from './visual';
export * from './exam';
export * from './collections';
export * from './analytics';
export * from './adaptive';
export * from './validate';
export * from './archive';
export * from './knowledge';
export * from './gaps';

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

/* ================= Faz 2 — analiz katmanı (sınıflandırma + kalite) ================= */

/** Normalleştirilmiş soru + Faz 2 zekâsı (tema sınıflandırması + kalite dökümü). */
export interface AnalyzedQuestion extends NormalizedQuestion {
  primaryTheme: string;
  primaryThemeLabel: string;
  themes: string[];
  quality: QualityBreakdown;
}

const FALLBACK_THEME_IDS = new Set(Object.values(SUBJECT_FALLBACK_THEME).map((t) => t.id));

let _analyzed: AnalyzedQuestion[] | null = null;
let _dedup: DedupReport | null = null;

/** Banka geneli yineleme raporu (bir kez hesaplanır — dedup, analiz katmanının pahalı adımı). */
export function bankDedup(): DedupReport {
  if (!_dedup) _dedup = dedupReport(normalizedQuestions());
  return _dedup;
}

/**
 * Tüm banka, Faz 2 analiziyle (bir kez hesaplanır). `subcategory` tema etiketiyle inceltilir,
 * `qualityScore` (Faz 1'de rezerve) doldurulur; ham `topic` alanı korunur.
 */
export function analyzedQuestions(): AnalyzedQuestion[] {
  if (_analyzed) return _analyzed;
  const pool = normalizedQuestions();
  const dd = bankDedup();
  _analyzed = pool.map((q) => {
    const c = classify(q);
    const quality = scoreQuality(q, { nearDuplicates: dd.nearDuplicateCounts[q.id] ?? 0 });
    return {
      ...q,
      subcategory: c.primaryLabel,
      qualityScore: quality.total,
      primaryTheme: c.primaryTheme,
      primaryThemeLabel: c.primaryLabel,
      themes: c.themes,
      quality,
    };
  });
  return _analyzed;
}

export interface QipIntelligence {
  coverage: QipCoverage;
  categoryDistribution: Record<string, number>;
  themeDistribution: Array<{ id: string; label: string; count: number }>;
  /** Ders yedeğine düşmeden bir özel temaya atanan soru sayısı. */
  classifiedByTheme: number;
  quality: QualitySummary;
  dedup: DedupReport;
  graph: GraphStats;
  families: FamilyStats;
  validation: QipValidation;
}

/** Faz 2 zekâ özeti — pano + rapor + testler için GERÇEK sayılar. */
export function qipIntelligence(): QipIntelligence {
  const analyzed = analyzedQuestions();
  const coverage = qipCoverage();
  const categoryDistribution: Record<string, number> = {};
  const themeCounts = new Map<string, number>();
  let classifiedByTheme = 0;
  for (const q of analyzed) {
    categoryDistribution[q.category] = (categoryDistribution[q.category] ?? 0) + 1;
    themeCounts.set(q.primaryTheme, (themeCounts.get(q.primaryTheme) ?? 0) + 1);
    if (!FALLBACK_THEME_IDS.has(q.primaryTheme)) classifiedByTheme++;
  }
  const themeDistribution = [...themeCounts.entries()]
    .map(([id, count]) => ({ id, label: themeLabel(id), count }))
    .sort((a, b) => b.count - a.count);
  return {
    coverage,
    categoryDistribution,
    themeDistribution,
    classifiedByTheme,
    quality: qualitySummary(analyzed.map((q) => q.quality)),
    dedup: bankDedup(),
    graph: graphStats(),
    families: familyStats(),
    validation: validateQip(),
  };
}
