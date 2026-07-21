/**
 * QIP 2.0 — İçerik Genişletme · Faz 7 · Sürekli Büyüme (milestone takibi).
 *
 * Bankanın gerçek boyutunu ve milestone'lara (3000/5000/10000/20000) ilerlemeyi ölçer. GERÇEK
 * sayılar — abartma yok. Ölçeklenebilir katman: özgün yazım + AI üretimi (prod anahtarı) + görsel
 * üretici; hepsi zorunlu QIP hattından (normalize→…→AI review→draft) geçer.
 */
import { allQuestions } from '@ea/question-bank';
import { SIGNS } from '@/content/signs';
import { VEHICLE_PARTS } from '@/content/vehicle';

export const MILESTONES = [3000, 5000, 10000, 20000];

export interface GrowthReport {
  /** Bankadaki gerçek (kalıcı) soru sayısı. */
  current: number;
  /** Faz 4'te eklenen özgün genişletme soruları (id 'gen-…' ile başlayan, kalıcı). */
  authoredExpansion: number;
  /** İstek üzerine üretilebilir görsel soru (işaret + parça) — banka kaynağına yazılmaz. */
  visualGeneratable: number;
  milestones: number[];
  /** Aşılmamış ilk milestone (hepsi aşıldıysa null). */
  nextMilestone: number | null;
  toNext: number;
  /** Bir sonraki milestone'a ilerleme yüzdesi (önceki milestone tabanlı). */
  progressPct: number;
}

export function bankGrowth(): GrowthReport {
  const current = allQuestions().length;
  const authoredExpansion = allQuestions().filter((q) => q.id.startsWith('gen-')).length;
  const visualGeneratable = SIGNS.length + VEHICLE_PARTS.length;

  const next = MILESTONES.find((m) => m > current) ?? null;
  const prev = [0, ...MILESTONES].filter((m) => m <= current).pop() ?? 0;
  const progressPct = next !== null ? Math.round(((current - prev) / (next - prev)) * 100) : 100;

  return {
    current,
    authoredExpansion,
    visualGeneratable,
    milestones: MILESTONES,
    nextMilestone: next,
    toNext: next !== null ? next - current : 0,
    progressPct,
  };
}
