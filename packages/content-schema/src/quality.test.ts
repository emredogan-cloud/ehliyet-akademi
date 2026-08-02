import { describe, expect, it } from 'vitest';
import {
  answerLengthRatio,
  checkQualityGate,
  hasParallelOptions,
  longestOptionWins,
  measureBank,
  QUALITY_GATE,
  absoluteOnlyInDistractors,
  isLazyOption,
  shortestOptionWins,
  testWiseGuessWins,
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
    const telling = Array.from({ length: 40 }, () =>
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

/**
 * Premium Kalite Programı · Faz 1 — kapının GENİŞLETİLMİŞ ölçütleri.
 *
 * Bu blok tek bir fikri koruyor: "soruyu okumadan kazanılan pay" tek bir ölçütle bitmez.
 * Uzunluk düzeltilince sıra mutlak ifadeye, o düzelince ikisinin BİLEŞİMİNE gelir.
 */
describe('kalite kapısı — sınav tekniği ölçütleri', () => {
  const q = (options: string[], answerIndex: number) => ({ options, answerIndex });

  it('en kısa şık kazanıyorsa yakalanır — ters tellalık', () => {
    expect(
      shortestOptionWins(q(['Evet', 'Uzunca bir çeldirici metni', 'Bir diğeri', 'Üçüncüsü'], 0))
    ).toBe(true);
    expect(shortestOptionWins(q(['Aynı', 'Aynı', 'Uzun bir metin', 'Bir diğeri'], 0))).toBe(false);
  });

  it('mutlak ifade yalnız çeldiricilerdeyse tellalık sayılır', () => {
    expect(
      absoluteOnlyInDistractors(
        q(['Duruma göre değişir', 'Asla yapılmaz', 'Her zaman yapılır', 'Kesinlikle yasaktır'], 0)
      )
    ).toBe(true);
    // Doğru şıkta da geçiyorsa taktik işe yaramaz — tellalık yok.
    expect(
      absoluteOnlyInDistractors(q(['Asla yapılmaz', 'Bazen yapılır', 'Sık yapılır', 'Nadiren'], 0))
    ).toBe(false);
  });

  it('içeriksiz şıklar tanınır', () => {
    expect(isLazyOption('Hiçbiri')).toBe(true);
    expect(isLazyOption(' Fark etmez ')).toBe(true);
    expect(isLazyOption('Kırmızı ışıkta durmak')).toBe(false);
  });

  it('BİRLEŞİK teknik: mutlakları eleyip en uzunu seçmek doğruya götürüyorsa yakalanır', () => {
    // Doğru şık en uzun DEĞİL; ama mutlak ifadeliler elenince en uzun o kalıyor.
    const tricky = q(
      [
        'Bu şık kesinlikle her zaman geçerli olan çok uzun bir ifadedir',
        'Hızı azaltıp durmaya hazır olmak gerekir',
        'Kısa',
        'Daha kısa',
      ],
      1
    );
    expect(longestOptionWins(tricky)).toBe(false);
    expect(testWiseGuessWins(tricky)).toBe(true);
  });

  it('hedef SIFIR değil rastgele taban — alt sınır da kapıda', () => {
    // Doğru şık hiçbir zaman en uzun değilse "en uzunu ele" stratejisi pay verir.
    const inverted = Array.from({ length: 40 }, () =>
      q(['Kısa cevap', 'Bu çok daha uzun bir çeldirici metnidir', 'Orta uzunlukta', 'Yine orta'], 0)
    );
    const failures = checkQualityGate(measureBank(inverted));
    expect(failures.some((f) => f.metric === 'longestWinsRate(alt)')).toBe(true);
    expect(QUALITY_GATE.minLongestWinsRate).toBeGreaterThan(0);
    expect(QUALITY_GATE.minLongestWinsRate).toBeLessThan(0.25);
  });

  it('içeriksiz şık kapıda sıfır tolerans', () => {
    expect(QUALITY_GATE.maxLazyOptions).toBe(0);
  });
});
