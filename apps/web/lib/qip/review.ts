/**
 * QIP — Faz 4 · AI İnceleyici (BANK_QUESTİON Part 14).
 *
 * Üretilen HER soru bankaya girmeden önce bu DETERMİNİSTİK kapıdan geçer. Part 14 boyutları:
 * dilbilgisi, cevap doğruluğu (tek doğru), birden çok doğru cevap, eğitsel doğruluk, zorluk,
 * tutarlılık + yineleme (mevcut bankaya karşı). Faz 2 kalite skorunu + Faz 6 dedup ilkelerini
 * yeniden kullanır. Geçemeyen soru REDDEDİLİR — asla otomatik yayımlanmaz.
 */
import { foldText, questionFingerprint, type NormalizedQuestion } from '@ea/content-schema';
import { scoreQuality } from './quality';
import { tokenSet, jaccard } from './dedup';

/** Basit alan sözlüğü — üretilen sorunun sürüş alanında olduğunu doğrulamak için (gevşek). */
const DOMAIN_TERMS = [
  'trafik',
  'arac',
  'surucu',
  'yol',
  'hiz',
  'fren',
  'levha',
  'isaret',
  'kavsak',
  'serit',
  'yaya',
  'lastik',
  'motor',
  'kanama',
  'yaralanma',
  'ilk yardim',
  'ilkyardim',
  'emniyet',
  'kemer',
  'far',
  'sinyal',
  'park',
  'oncelik',
  'direksiyon',
  'sinav',
  'ehliyet',
  'sollama',
  'donus',
  'nabiz',
  'solunum',
  'yanik',
  'kaza',
];

const QUALITY_MIN = 70;
const NEAR_DUP_THRESHOLD = 0.82;

export interface ReviewChecks {
  answerInRange: boolean;
  singleCorrect: boolean; // doğru cevaba özdeş ikinci seçenek YOK
  distinctOptions: boolean;
  qualityOk: boolean;
  notDuplicate: boolean; // ne tam ne yakın yineleme (mevcut bankaya karşı)
  onDomain: boolean;
}

export interface ReviewResult {
  ok: boolean;
  score: number;
  checks: ReviewChecks;
  issues: string[];
}

/** Mevcut bankaya karşı dedup için önceden hesaplanmış bağlam (üretim oturumu boyunca yeniden kullan). */
export interface ReviewContext {
  fingerprints: Set<string>;
  tokenSetsBySubject: Map<string, Array<Set<string>>>;
}

export function buildReviewContext(existing: NormalizedQuestion[]): ReviewContext {
  const fingerprints = new Set<string>();
  const tokenSetsBySubject = new Map<string, Array<Set<string>>>();
  for (const q of existing) {
    fingerprints.add(q.fingerprint);
    const arr = tokenSetsBySubject.get(q.subject) ?? [];
    arr.push(tokenSet(q));
    tokenSetsBySubject.set(q.subject, arr);
  }
  return { fingerprints, tokenSetsBySubject };
}

/** Üretilen bir soruyu incele (deterministik kapı). */
export function reviewGenerated(q: NormalizedQuestion, ctx: ReviewContext): ReviewResult {
  const issues: string[] = [];
  const foldedOpts = q.options.map(foldText);

  const answerInRange = q.answerIndex >= 0 && q.answerIndex < q.options.length;
  if (!answerInRange) issues.push('cevap indeksi aralık dışı');

  const correct = foldedOpts[q.answerIndex];
  const singleCorrect = !!correct && foldedOpts.filter((o) => o === correct).length === 1;
  if (!singleCorrect) issues.push('birden çok doğru cevap (doğruya özdeş seçenek)');

  const distinctOptions = new Set(foldedOpts).size === q.options.length;
  if (!distinctOptions) issues.push('tekrarlı seçenek');

  const quality = scoreQuality(q);
  const qualityOk = quality.total >= QUALITY_MIN;
  if (!qualityOk) issues.push(`kalite düşük (${quality.total} < ${QUALITY_MIN})`);

  // Yineleme: tam parmak izi + yakın (aynı ders)
  const fp = questionFingerprint(q);
  let notDuplicate = !ctx.fingerprints.has(fp);
  if (notDuplicate) {
    const ts = tokenSet(q);
    const peers = ctx.tokenSetsBySubject.get(q.subject) ?? [];
    for (const p of peers) {
      if (jaccard(ts, p) >= NEAR_DUP_THRESHOLD) {
        notDuplicate = false;
        break;
      }
    }
  }
  if (!notDuplicate) issues.push('mevcut bir soruyla yineleme');

  const folded = foldText(`${q.stem} ${q.options.join(' ')} ${q.explanation} ${q.topic}`);
  const onDomain = DOMAIN_TERMS.some((t) => folded.includes(foldText(t)));
  if (!onDomain) issues.push('sürüş alanı dışında görünüyor');

  const checks: ReviewChecks = {
    answerInRange,
    singleCorrect,
    distinctOptions,
    qualityOk,
    notDuplicate,
    onDomain,
  };
  const ok = Object.values(checks).every(Boolean);
  return { ok, score: quality.total, checks, issues };
}
