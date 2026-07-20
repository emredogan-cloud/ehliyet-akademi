/**
 * QIP — Faz 2 · Soru Kalite Analizi (BANK_QUESTİON Part 5).
 *
 * Her soruyu deterministik, ÖLÇÜLEBİLİR sezgisel kurallarla puanlar (0–100). Dış servis yok;
 * aynı giriş → aynı puan. Alt boyutlar Part 5 ile hizalı: dil, dilbilgisi, netlik, çeldirici
 * kalitesi, eğitsel değer, cevap güveni, zorluk uyumu, yineleme riski. "Duplicate Risk" boyutu
 * dış (bankalar-arası) yakın-yineleme sayısını `opts.nearDuplicates` ile alır (bkz. dedup.ts).
 */
import { foldText, type NormalizedQuestion } from '@ea/content-schema';

export interface QualityBreakdown {
  total: number; // 0–100 ağırlıklı
  language: number;
  grammar: number;
  clarity: number;
  distractor: number;
  educationalValue: number;
  answerConfidence: number;
  difficultyFit: number;
  duplicateRisk: number; // 100 = risk yok
  flags: string[];
}

const AMBIGUOUS = ['hepsi', 'hicbiri', 'hicbir']; // "yukarıdakilerin hepsi/hiçbiri" belirsizliği
const clamp = (n: number) => Math.max(0, Math.min(100, Math.round(n)));

/** Tek bir sorunun kalite dökümü. */
export function scoreQuality(
  q: NormalizedQuestion,
  opts: { nearDuplicates?: number } = {}
): QualityBreakdown {
  const flags: string[] = [];
  const stem = q.stem.trim();
  const foldedOpts = q.options.map(foldText);

  // — Dil / mekanik —
  let language = 100;
  if (/\s{2,}/.test(q.stem)) {
    language -= 15;
    flags.push('çift boşluk');
  }
  if (q.stem !== q.stem.trim()) {
    language -= 10;
    flags.push('baş/son boşluk');
  }
  const first = stem[0] ?? '';
  if (first && first !== first.toLocaleUpperCase('tr')) {
    language -= 15;
    flags.push('stem küçük harfle başlıyor');
  }

  // — Dilbilgisi / tutarlılık —
  let grammar = 100;
  if (/\b(lorem|xxx|todo|placeholder|tbd)\b/i.test(q.stem + q.explanation)) {
    grammar -= 60;
    flags.push('yer tutucu metin');
  }
  const caps = q.options.map((o) => {
    const c = o.trim()[0] ?? '';
    return c === c.toLocaleUpperCase('tr');
  });
  if (caps.some(Boolean) && caps.some((c) => !c)) {
    grammar -= 10;
    flags.push('seçenek büyük/küçük harf tutarsız');
  }

  // — Netlik —
  let clarity = 100;
  if (stem.length < 20) {
    clarity -= 30;
    flags.push('stem çok kısa');
  } else if (stem.length > 240) {
    clarity -= 15;
    flags.push('stem çok uzun');
  }
  if (!/[?:]$/.test(stem) && !/[.?:]$/.test(stem)) {
    clarity -= 8;
  }

  // — Çeldirici kalitesi —
  let distractor = 100;
  if (q.options.length < 3) {
    distractor -= 25;
    flags.push('3’ten az seçenek');
  }
  const uniqueOpts = new Set(foldedOpts);
  if (uniqueOpts.size < q.options.length) {
    distractor -= 40;
    flags.push('tekrarlı seçenek');
  }
  const lens = q.options.map((o) => o.trim().length);
  const minL = Math.min(...lens);
  const maxL = Math.max(...lens);
  if (minL > 0 && maxL / minL > 6) {
    distractor -= 12;
    flags.push('seçenek uzunlukları çok dengesiz');
  }
  if (foldedOpts.some((o) => AMBIGUOUS.some((a) => o.includes(a)))) {
    distractor -= 8;
  }

  // — Eğitsel değer —
  let educationalValue = 40;
  if (q.explanation.trim().length >= 40) educationalValue += 25;
  if (q.commonMistakes.length >= 1) educationalValue += 15;
  if (q.learningOutcome) educationalValue += 10;
  if (q.tags.length >= 1) educationalValue += 5;
  if (q.badge) educationalValue += 5;

  // — Cevap güveni —
  let answerConfidence = 100;
  if (q.answerIndex < 0 || q.answerIndex >= q.options.length) {
    answerConfidence = 0;
    flags.push('cevap indeksi geçersiz');
  }
  if (q.explanation.trim().length < 20) {
    answerConfidence -= 20;
    flags.push('açıklama kısa');
  }
  const correct = foldedOpts[q.answerIndex];
  if (correct && foldedOpts.filter((o) => o === correct).length > 1) {
    answerConfidence -= 40;
    flags.push('doğru cevaba özdeş ikinci seçenek');
  }

  // — Zorluk uyumu (esnek; yalnız net uyumsuzluğu cezalandırır) —
  let difficultyFit = 100;
  if (q.difficulty === 'zor' && stem.length < 30 && q.commonMistakes.length === 0) {
    difficultyFit -= 20;
  }
  if (q.difficulty === 'kolay' && stem.length > 220) {
    difficultyFit -= 10;
  }

  // — Yineleme riski (bankalar-arası; dış sinyal) —
  const nd = opts.nearDuplicates ?? 0;
  let duplicateRisk = 100 - Math.min(60, nd * 20);
  if (nd > 0) flags.push(`${nd} yakın-yineleme`);
  duplicateRisk = clamp(duplicateRisk);

  const dims = {
    language: clamp(language),
    grammar: clamp(grammar),
    clarity: clamp(clarity),
    distractor: clamp(distractor),
    educationalValue: clamp(educationalValue),
    answerConfidence: clamp(answerConfidence),
    difficultyFit: clamp(difficultyFit),
    duplicateRisk,
  };

  // Ağırlıklar (toplam 1.0) — cevap güveni + çeldirici + eğitsel değer en ağır.
  const total = clamp(
    dims.answerConfidence * 0.22 +
      dims.distractor * 0.18 +
      dims.educationalValue * 0.16 +
      dims.clarity * 0.14 +
      dims.language * 0.1 +
      dims.grammar * 0.08 +
      dims.duplicateRisk * 0.07 +
      dims.difficultyFit * 0.05
  );

  return { total, ...dims, flags };
}

export interface QualitySummary {
  count: number;
  avg: number;
  min: number;
  max: number;
  below70: number;
  below50: number;
  flagged: number;
  /** Bayrak → adet (en sık önce sıralanabilir). */
  flagHistogram: Record<string, number>;
  /** 10’luk kovalar: '0-9'…'90-100'. */
  distribution: Record<string, number>;
}

/** Banka geneli kalite özeti — GERÇEK sayılar (pano + testler). */
export function qualitySummary(breakdowns: QualityBreakdown[]): QualitySummary {
  const n = breakdowns.length;
  const flagHistogram: Record<string, number> = {};
  const distribution: Record<string, number> = {};
  let sum = 0;
  let min = 100;
  let max = 0;
  let below70 = 0;
  let below50 = 0;
  let flagged = 0;
  for (const b of breakdowns) {
    sum += b.total;
    if (b.total < min) min = b.total;
    if (b.total > max) max = b.total;
    if (b.total < 70) below70++;
    if (b.total < 50) below50++;
    if (b.flags.length > 0) flagged++;
    for (const f of b.flags) flagHistogram[f] = (flagHistogram[f] ?? 0) + 1;
    const bucket = `${Math.min(90, Math.floor(b.total / 10) * 10)}-${Math.min(90, Math.floor(b.total / 10) * 10) + (b.total >= 100 ? 10 : 9)}`;
    distribution[bucket] = (distribution[bucket] ?? 0) + 1;
  }
  return {
    count: n,
    avg: n ? Math.round(sum / n) : 0,
    min: n ? min : 0,
    max,
    below70,
    below50,
    flagged,
    flagHistogram,
    distribution,
  };
}
