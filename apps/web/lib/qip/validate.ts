/**
 * QIP — Faz 6 · Nihai Doğrulama (BANK_QUESTİON Part 17).
 *
 * Bütün zekâ katmanları üzerinde bütünlük denetimi: veritabanı bütünlüğü, yineleme oranı, soru
 * kalitesi, kategori dengesi, bozuk görseller, bozuk referanslar, bilgi grafiği tutarlılığı.
 * Saf/deterministik; GERÇEK sayılar. QUESTION_INTELLIGENCE_REPORT.md ve admin panosunu besler.
 */
import { allQuestions } from '@ea/question-bank';
import { NormalizedQuestion } from '@ea/content-schema';
import { SIGNS } from '@/content/signs';
import { VEHICLE_PARTS } from '@/content/vehicle';
import { LESSONS } from '@/content/lessons';
import { normalizedQuestions, bankDedup, analyzedQuestions } from './index';
import { qualitySummary } from './quality';
import { graphStats } from './graph';

export interface ValidationCheck {
  id: string;
  label: string;
  status: 'ok' | 'warn' | 'fail';
  detail: string;
  value?: number;
}

export interface QipValidation {
  score: number; // 0..100 (ok=1, warn=0.5, fail=0)
  passed: boolean; // hiç 'fail' yok
  checks: ValidationCheck[];
}

/** Nihai doğrulama — tüm bankaya karşı. */
export function validateQip(): QipValidation {
  const checks: ValidationCheck[] = [];
  const bank = normalizedQuestions();
  const analyzed = analyzedQuestions();

  // 1) Veritabanı bütünlüğü — hepsi normalleşir + şema geçerli + zorunlu alanlar dolu.
  const rawCount = allQuestions().length;
  let schemaFail = 0;
  for (const q of bank) {
    if (!NormalizedQuestion.safeParse(q).success) schemaFail++;
  }
  checks.push({
    id: 'integrity',
    label: 'Veritabanı bütünlüğü',
    status: bank.length === rawCount && schemaFail === 0 ? 'ok' : 'fail',
    detail:
      bank.length === rawCount && schemaFail === 0
        ? `${bank.length} soru normalleşti, şema geçerli`
        : `${schemaFail} şema hatası / sayı uyuşmazlığı`,
    value: bank.length,
  });

  // 2) Yineleme oranı.
  const dd = bankDedup();
  const dupStatus = dd.exactDuplicateRecords > 0 ? 'fail' : dd.duplicateRatePct > 2 ? 'warn' : 'ok';
  checks.push({
    id: 'duplicates',
    label: 'Yineleme oranı',
    status: dupStatus,
    detail: `tam ${dd.exactDuplicateRecords}, yakın çift ${dd.nearDuplicatePairs}, oran %${dd.duplicateRatePct}`,
    value: dd.duplicateRatePct,
  });

  // 3) Soru kalitesi.
  const qs = qualitySummary(analyzed.map((q) => q.quality));
  const qStatus = qs.below50 > 0 ? 'fail' : qs.below70 > 0 ? 'warn' : 'ok';
  checks.push({
    id: 'quality',
    label: 'Soru kalitesi',
    status: qStatus,
    detail: `ort ${qs.avg}, 70 altı ${qs.below70}, 50 altı ${qs.below50}`,
    value: qs.avg,
  });

  // 4) Kategori dengesi — hiçbir ders boş/aşırı düşük değil.
  const bySubject: Record<string, number> = {};
  for (const q of bank) bySubject[q.subject] = (bySubject[q.subject] ?? 0) + 1;
  const minSubject = Math.min(...Object.values(bySubject));
  checks.push({
    id: 'balance',
    label: 'Kategori dengesi',
    status: Object.keys(bySubject).length >= 4 && minSubject >= 20 ? 'ok' : 'warn',
    detail: Object.entries(bySubject)
      .map(([s, n]) => `${s}:${n}`)
      .join(' · '),
    value: Object.keys(bySubject).length,
  });

  // 5) Bozuk görseller — image ref eden soruların hedefi mevcut mu (bankada image yok → 0).
  const signIds = new Set(SIGNS.map((s) => s.id));
  let brokenImages = 0;
  for (const q of bank) {
    if (q.image && q.image.startsWith('sign:') && !signIds.has(q.image.slice(5))) brokenImages++;
  }
  checks.push({
    id: 'images',
    label: 'Bozuk görseller',
    status: brokenImages === 0 ? 'ok' : 'fail',
    detail: brokenImages === 0 ? 'bozuk görsel referansı yok' : `${brokenImages} bozuk görsel`,
    value: brokenImages,
  });

  // 6) Bozuk referanslar — relatedLesson/Signs/VehicleParts gerçek içeriğe işaret ediyor mu.
  const lessonSlugs = new Set(LESSONS.map((l) => l.slug));
  const partIds = new Set(VEHICLE_PARTS.map((p) => p.id));
  let brokenRefs = 0;
  for (const q of bank) {
    if (q.relatedLesson && !lessonSlugs.has(q.relatedLesson)) brokenRefs++;
    for (const s of q.relatedSigns) if (!signIds.has(s)) brokenRefs++;
    for (const p of q.relatedVehicleParts) if (!partIds.has(p)) brokenRefs++;
  }
  checks.push({
    id: 'references',
    label: 'Bozuk referanslar',
    status: brokenRefs === 0 ? 'ok' : 'fail',
    detail: brokenRefs === 0 ? 'tüm çapraz bağlar geçerli' : `${brokenRefs} bozuk referans`,
    value: brokenRefs,
  });

  // 7) Bilgi grafiği tutarlılığı — düğüm/kenar sayımları tutarlı, sarkan kenar yok.
  const g = graphStats();
  const nodeSum = Object.values(g.byNodeType).reduce((a, b) => a + b, 0);
  checks.push({
    id: 'graph',
    label: 'Bilgi grafiği tutarlılığı',
    status: nodeSum === g.nodeCount && g.edgeCount > 0 ? 'ok' : 'fail',
    detail: `${g.nodeCount} düğüm, ${g.edgeCount} kenar, ort. derece ${g.avgQuestionDegree}`,
    value: g.nodeCount,
  });

  const weight = (s: ValidationCheck['status']) => (s === 'ok' ? 1 : s === 'warn' ? 0.5 : 0);
  const score = Math.round(
    (checks.reduce((a, c) => a + weight(c.status), 0) / checks.length) * 100
  );
  const passed = checks.every((c) => c.status !== 'fail');
  return { score, passed, checks };
}
