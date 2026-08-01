/**
 * Soru kalite ölçümü — Ürün Evrimi v1.1 · Faz 1.
 *
 * NEDEN VAR: denetimde bankanın %91,1'inin **soru okunmadan** doğru cevaplanabildiği ölçüldü —
 * "en uzun şıkkı işaretle" stratejisi 1562 sorunun 1423'ünü buluyordu. Geçme barajı %70 olduğuna
 * göre hiç ders çalışmamış bir aday her denemeyi geçiyordu.
 *
 * Kök neden: üreteç, açıklamayı doğru şıkkın İÇİNE yazmıştı (doğru şık ort. 91,9 karakter, yanlış
 * şık 36,9 — 2,49×). Gerçek MEB sorularında şıklar paralel uzunluktadır; doğru cevap çoğu zaman
 * en kısa olandır.
 *
 * Bu dosya kaliteyi HİSSE değil SAYIYA bağlar. Ölçülmeyen bir kalite iddiası, gerileyince kimsenin
 * fark etmediği bir iddiadır.
 */

/** Ölçüm için gereken en az alan — `Question` da `QuestionInput` da uyar. */
export interface ScorableQuestion {
  readonly options: readonly string[];
  readonly answerIndex: number;
}

/** Bir şıkkın "ağırlığı" — boşluk normalize edilir ki biçimlendirme ölçümü kaydırmasın. */
function weigh(option: string): number {
  return option.trim().replace(/\s+/g, ' ').length;
}

/**
 * "Soruyu okumadan en uzun şıkkı işaretle" stratejisi bu soruyu bulur mu?
 *
 * Beraberlik SAYILMAZ: iki şık da en uzunsa strateji hangisini seçeceğini bilemez, yani soru
 * tellalık etmiyordur. Bu, ölçümü kasten kendi aleyhimize değil, gerçekçi tutar.
 */
export function longestOptionWins(q: ScorableQuestion): boolean {
  const lens = q.options.map(weigh);
  const max = Math.max(...lens);
  return lens[q.answerIndex] === max && lens.filter((l) => l === max).length === 1;
}

/** Doğru şıkkın, en uzun ÇELDİRİCİYE oranı. 1,0 = paralel. Denetimde ortalama 2,49×'ti. */
export function answerLengthRatio(q: ScorableQuestion): number {
  const lens = q.options.map(weigh);
  const others = lens.filter((_, i) => i !== q.answerIndex);
  const maxOther = Math.max(...others);
  return maxOther === 0 ? Infinity : (lens[q.answerIndex] ?? 0) / maxOther;
}

/**
 * Şık uzunlukları paralel mi?
 *
 * EŞİK 1,5 — keyfi değil: referans MEB sorularında ölçülen en yüksek oran 1,47 idi
 * ("Topuktan dize kadar" 19 ↔ "Topuktan koltuk altına kadar" 28). 1,5 bunun hemen üstünde durur.
 */
export const PARALLEL_RATIO_LIMIT = 1.5;

export function hasParallelOptions(q: ScorableQuestion): boolean {
  return answerLengthRatio(q) <= PARALLEL_RATIO_LIMIT;
}

export interface BankQualityReport {
  readonly total: number;
  /** "En uzun şıkkı seç" ile doğru bulunan soru sayısı. */
  readonly longestWins: number;
  /** Aynısının oranı (0–1). Rastgele taban çizgisi 0,25. */
  readonly longestWinsRate: number;
  /** Şıkları paralel uzunlukta olan soru sayısı. */
  readonly parallel: number;
  readonly parallelRate: number;
  readonly avgAnswerLength: number;
  readonly avgDistractorLength: number;
  /** avgAnswerLength / avgDistractorLength. Hedef ~1,0. */
  readonly lengthRatio: number;
  /** Cevap konumu dağılımı — A/B/C/D. */
  readonly answerPositions: readonly number[];
}

export function measureBank(questions: readonly ScorableQuestion[]): BankQualityReport {
  const total = questions.length;
  if (total === 0) {
    return {
      total: 0,
      longestWins: 0,
      longestWinsRate: 0,
      parallel: 0,
      parallelRate: 1,
      avgAnswerLength: 0,
      avgDistractorLength: 0,
      lengthRatio: 1,
      answerPositions: [0, 0, 0, 0],
    };
  }

  let longestWins = 0;
  let parallel = 0;
  let answerChars = 0;
  let distractorChars = 0;
  let distractorCount = 0;
  const answerPositions = [0, 0, 0, 0];

  for (const q of questions) {
    if (longestOptionWins(q)) longestWins++;
    if (hasParallelOptions(q)) parallel++;
    if (q.answerIndex < answerPositions.length)
      answerPositions[q.answerIndex] = (answerPositions[q.answerIndex] ?? 0) + 1;
    q.options.forEach((o, i) => {
      if (i === q.answerIndex) answerChars += weigh(o);
      else {
        distractorChars += weigh(o);
        distractorCount++;
      }
    });
  }

  const avgAnswerLength = answerChars / total;
  const avgDistractorLength = distractorCount === 0 ? 0 : distractorChars / distractorCount;

  return {
    total,
    longestWins,
    longestWinsRate: longestWins / total,
    parallel,
    parallelRate: parallel / total,
    avgAnswerLength,
    avgDistractorLength,
    lengthRatio: avgDistractorLength === 0 ? Infinity : avgAnswerLength / avgDistractorLength,
    answerPositions,
  };
}

/**
 * Kalite kapısı eşikleri.
 *
 * `maxLongestWinsRate` — kapının kalbi. Rastgele taban %25; %40, ölçüm gürültüsüne yer bırakırken
 * tellalığı bitiren eşik. Denetim başlangıcı %91,1 idi.
 *
 * Eşikler yalnız İYİLEŞME yönünde değiştirilir. Kapıyı geçmek için eşiği gevşetmek, kapıyı
 * kaldırmakla aynı şeydir.
 */
export const QUALITY_GATE = {
  maxLongestWinsRate: 0.4,
  minParallelRate: 0.6,
  maxLengthRatio: 1.5,
  /** Cevap konumu, dörtte birden bu kadar sapabilir (0,08 = ±%8 puan). */
  maxAnswerPositionSkew: 0.08,
} as const;

/**
 * MANDAL (ratchet) — CI'ın BUGÜN dayattığı tavan.
 *
 * `QUALITY_GATE` varılacak hedef; mandal ise şu an ulaşılmış en iyi değer. Denetim %91,1 ile
 * başladı, 1228 sorunun şıkkı elden geçirilmesi gereken bir borç. Bu borç tek oturumda
 * kapanmaz; mandal, kapanana kadar GERİ GİTMEYİ imkânsız kılar.
 *
 * KURAL: mandal yalnız AŞAĞI çekilir. Testi geçirmek için yukarı çekmek, kapıyı kaldırmakla
 * aynı şeydir — o zaman düzeltilecek şey mandal değil, sorulardır.
 */
export const QUALITY_RATCHET = {
  maxLongestWinsRate: 0.321,
  minParallelRate: 0.795,
  maxLengthRatio: 1.384,
  maxAnswerPositionSkew: 0.044,
} as const;

export interface GateFailure {
  readonly metric: string;
  readonly actual: number;
  readonly limit: number;
  readonly message: string;
}

/**
 * Kapıyı uygula — geçerse boş dizi, kalırsa her ihlal için bir kayıt.
 *
 * `limits` verilmezse HEDEF eşikler kullanılır. CI mandalı (`QUALITY_RATCHET`) geçirir;
 * hedefe ne kadar kaldığını ayrı bir test raporlar.
 */
export function checkQualityGate(
  report: BankQualityReport,
  limits: typeof QUALITY_GATE | typeof QUALITY_RATCHET = QUALITY_GATE
): GateFailure[] {
  const out: GateFailure[] = [];
  const pct = (x: number) => `%${(x * 100).toFixed(1)}`;

  if (report.longestWinsRate > limits.maxLongestWinsRate)
    out.push({
      metric: 'longestWinsRate',
      actual: report.longestWinsRate,
      limit: limits.maxLongestWinsRate,
      message:
        `Soruların ${pct(report.longestWinsRate)}'i "en uzun şıkkı seç" ile ` +
        `soru okunmadan bilinebiliyor (sınır ${pct(limits.maxLongestWinsRate)}). ` +
        `Doğru şıkka açıklama yazılmış olabilir — açıklama 'explanation' alanına aittir.`,
    });

  if (report.parallelRate < limits.minParallelRate)
    out.push({
      metric: 'parallelRate',
      actual: report.parallelRate,
      limit: limits.minParallelRate,
      message:
        `Yalnız ${pct(report.parallelRate)} soruda şıklar paralel uzunlukta ` +
        `(en az ${pct(limits.minParallelRate)} olmalı).`,
    });

  if (report.lengthRatio > limits.maxLengthRatio)
    out.push({
      metric: 'lengthRatio',
      actual: report.lengthRatio,
      limit: limits.maxLengthRatio,
      message:
        `Doğru şık ortalama ${report.avgAnswerLength.toFixed(1)} karakter, çeldirici ` +
        `${report.avgDistractorLength.toFixed(1)} — oran ${report.lengthRatio.toFixed(2)}× ` +
        `(sınır ${limits.maxLengthRatio}×).`,
    });

  const expected = report.total / 4;
  report.answerPositions.forEach((count, i) => {
    const skew = Math.abs(count - expected) / report.total;
    if (skew > limits.maxAnswerPositionSkew)
      out.push({
        metric: `answerPosition[${'ABCD'[i]}]`,
        actual: skew,
        limit: limits.maxAnswerPositionSkew,
        message:
          `${'ABCD'[i]} şıkkı ${count} kez doğru (beklenen ~${expected.toFixed(0)}); ` +
          `sapma ${pct(skew)}.`,
      });
  });

  return out;
}

/** İnsan okunur özet — testte ve denetim betiğinde aynı çıktı. */
export function formatQualityReport(report: BankQualityReport): string {
  const pct = (x: number) => `%${(x * 100).toFixed(1)}`;
  return [
    `soru: ${report.total}`,
    `"en uzun şıkkı seç": ${report.longestWins} (${pct(report.longestWinsRate)}) — rastgele %25`,
    `paralel şıklı: ${report.parallel} (${pct(report.parallelRate)})`,
    `ort. doğru ${report.avgAnswerLength.toFixed(1)} / çeldirici ${report.avgDistractorLength.toFixed(1)} = ${report.lengthRatio.toFixed(2)}×`,
    `cevap konumu: ${report.answerPositions.join(' / ')}`,
  ].join('\n');
}
