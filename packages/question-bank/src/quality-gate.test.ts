import { describe, expect, it } from 'vitest';
import {
  checkQualityGate,
  formatQualityReport,
  measureBank,
  QUALITY_GATE,
  QUALITY_RATCHET,
} from '@ea/content-schema';
import { allQuestions } from './index';

/**
 * BANKA KALİTE KAPISI — Ürün Evrimi v1.1 · Faz 1.
 *
 * Denetimde bankanın %91,1'i "soruyu okumadan en uzun şıkkı seç" ile doğru cevaplanabiliyordu.
 * Geçme barajı %70; yani hiç çalışmamış bir aday her denemeyi geçiyordu. Bu test, o kusurun
 * geri gelmesini imkânsız kılar.
 *
 * Kapı KALIRSA yapılacak şey eşiği gevşetmek DEĞİLDİR: doğru şıkka yazılmış açıklamayı
 * `explanation` alanına taşımak, ya da çeldiricileri doğru şıkla paralel uzunlukta yazmaktır.
 */
describe('banka kalite kapısı', () => {
  const report = measureBank(allQuestions());

  it('ölçüm özeti', () => {
    console.warn(formatQualityReport(report));
    expect(report.total).toBeGreaterThan(1500);
  });

  /** CI'ın dayattığı sınır: MANDAL. Geri gitmek imkânsız. */
  it('mandal tutuyor — hiçbir ölçüt geriye gitmedi', () => {
    expect(
      checkQualityGate(report, QUALITY_RATCHET)
        .map((f) => f.message)
        .join('\n')
    ).toBe('');
  });

  /** Mandal gereğinden gevşek kalmasın: ulaşılan değer mandala yakınsa mandal AŞAĞI çekilmeli. */
  it('mandal ulaşılan değere yakın (gevşek bırakılmamış)', () => {
    expect(report.longestWinsRate).toBeLessThanOrEqual(QUALITY_RATCHET.maxLongestWinsRate);
    expect(QUALITY_RATCHET.maxLongestWinsRate - report.longestWinsRate).toBeLessThan(0.02);
  });

  /** Hedefe kalan yol — bilgi amaçlı, kırmızıya düşürmez. */
  it('hedefe kalan mesafe raporlanır', () => {
    const gap = report.longestWinsRate - QUALITY_GATE.maxLongestWinsRate;
    if (gap > 0) {
      const remaining = Math.ceil(gap * report.total);
      console.warn(
        `HEDEFE KALAN: "en uzun şıkkı seç" %${(report.longestWinsRate * 100).toFixed(1)} → ` +
          `hedef %${(QUALITY_GATE.maxLongestWinsRate * 100).toFixed(0)}; ` +
          `yaklaşık ${remaining} sorunun şıkları daha elden geçirilmeli.`
      );
    }
    expect(report.longestWinsRate).toBeLessThanOrEqual(QUALITY_RATCHET.maxLongestWinsRate);
  });
});
