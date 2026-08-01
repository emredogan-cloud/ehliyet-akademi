import { describe, expect, it } from 'vitest';
import {
  answerLengthRatio,
  checkQualityGate,
  hasParallelOptions,
  longestOptionWins,
  measureBank,
  QUALITY_GATE,
} from './quality';

/** Ürün Evrimi v1.1 · Faz 1 — kalite ölçerinin KENDİSİNİN testi.
 *
 * Ölçer yanlışsa banka düzeltmesi de yanlış yere koşar. Önce cetveli doğrula. */

const q = (options: string[], answerIndex: number) => ({ options, answerIndex });

describe('longestOptionWins', () => {
  it('doğru şık tek başına en uzunsa tellalık vardır', () => {
    expect(
      longestOptionWins(q(['Kısa', 'Bu şık diğerlerinden çok daha uzun', 'Kısa', 'Kısa'], 1))
    ).toBe(true);
  });

  it('doğru şık en kısaysa tellalık yoktur', () => {
    // Referans MEB sorusu: "…genel adı nedir?" → doğru cevap "Araç" (en kısa).
    expect(longestOptionWins(q(['Ticari taşıt', 'Arazi taşıtı', 'Taşıt katarı', 'Araç'], 3))).toBe(
      false
    );
  });

  it('BERABERLİK tellalık sayılmaz — strateji hangisini seçeceğini bilemez', () => {
    expect(longestOptionWins(q(['aaaa', 'bbbb', 'cccc', 'dddd'], 0))).toBe(false);
  });

  it('boşluk farkı ölçümü kaydırmaz', () => {
    expect(longestOptionWins(q(['ab', '  a   b  ', 'abc', 'abcd'], 1))).toBe(false);
  });
});

describe('answerLengthRatio', () => {
  it('doğru şıkkı en uzun ÇELDİRİCİYLE karşılaştırır', () => {
    // doğru 20, en uzun çeldirici 10 → 2×
    expect(answerLengthRatio(q(['0123456789', 'x', 'y', '01234567890123456789'], 3))).toBeCloseTo(
      2
    );
  });

  it('paralel şıklar sınırı geçmez', () => {
    // Referanstaki en yüksek gerçek oran 1,47 idi — sınırın altında kalmalı.
    expect(
      hasParallelOptions(
        q(
          [
            'Topuktan dize kadar',
            'Dizden kalçaya kadar',
            'Topuktan kalçaya kadar',
            'Topuktan koltuk altına kadar',
          ],
          3
        )
      )
    ).toBe(true);
  });

  it('açıklama yazılmış şık paralel sayılmaz', () => {
    expect(
      hasParallelOptions(
        q(
          [
            'Radyatör fanı',
            'Yakıt pompası',
            'Debriyaj baskı rulmanı (bilyası); yalnızca pedala basıldığında yük altına girdiği için aşındığında sesi bu anlarda duyulur',
            'Ön cam sileceği',
          ],
          2
        )
      )
    ).toBe(false);
  });
});

describe('measureBank', () => {
  it('boş banka çökmez', () => {
    expect(measureBank([]).total).toBe(0);
  });

  it('oranları ve cevap dağılımını sayar', () => {
    const r = measureBank([
      q(['aaaa', 'bb', 'cc', 'dd'], 0),
      q(['aa', 'bbbb', 'cc', 'dd'], 1),
      q(['aa', 'bb', 'cccc', 'dd'], 2),
      q(['aa', 'bb', 'cc', 'dddd'], 3),
    ]);
    expect(r.total).toBe(4);
    expect(r.longestWins).toBe(4);
    expect(r.longestWinsRate).toBe(1);
    expect(r.answerPositions).toEqual([1, 1, 1, 1]);
  });
});

describe('checkQualityGate', () => {
  it('sağlıklı banka kapıyı geçer', () => {
    const healthy = Array.from({ length: 40 }, (_, i) =>
      q(['Birinci seçenek', 'İkinci seçenek', 'Üçüncü seçenek', 'Dördüncü seçenek'], i % 4)
    );
    expect(checkQualityGate(measureBank(healthy))).toEqual([]);
  });

  it('tellal banka kapıda KALIR ve nedeni söylenir', () => {
    const telling = Array.from({ length: 40 }, (_, i) =>
      q(
        [
          'Kısa',
          'Kısa',
          'Kısa',
          'Bu şık açıklama içerdiği için çok daha uzun ve hemen belli oluyor',
        ],
        3
      )
    );
    const failures = checkQualityGate(measureBank(telling));
    expect(failures.some((f) => f.metric === 'longestWinsRate')).toBe(true);
    expect(failures.find((f) => f.metric === 'longestWinsRate')!.message).toContain('explanation');
  });

  it('cevap konumu dengesizliği yakalanır', () => {
    const skewed = Array.from({ length: 40 }, () =>
      q(['Birinci seçenek', 'İkinci seçenek', 'Üçüncü seçenek', 'Dördüncü seçenek'], 1)
    );
    expect(
      checkQualityGate(measureBank(skewed)).some((f) => f.metric.startsWith('answerPosition'))
    ).toBe(true);
  });

  it('eşikler yalnız iyileşme yönünde gevşetilebilir — kapı gerçekten bağlayıcı', () => {
    // Kapıyı geçmek için eşiği yükseltmek, kapıyı kaldırmakla aynı şey. Sabit burada kilitli.
    expect(QUALITY_GATE.maxLongestWinsRate).toBeLessThanOrEqual(0.4);
    expect(QUALITY_GATE.minParallelRate).toBeGreaterThanOrEqual(0.6);
  });
});
