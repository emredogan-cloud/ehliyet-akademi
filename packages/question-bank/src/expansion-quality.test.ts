import { describe, expect, it } from 'vitest';
import {
  absoluteOnlyInDistractors,
  hasParallelOptions,
  isLazyOption,
  longestOptionWins,
  measureBank,
  testWiseGuessWins,
} from '@ea/content-schema';
import { allQuestions } from './index';
import { GENISLETME_QUESTIONS_2 } from './questions-genisletme-2';

/**
 * GENİŞLETME KALİTE SÖZLEŞMESİ — Premium Kalite Programı · Faz 2.
 *
 * Bu programın en kolay düşülen tuzağı şu: Faz 1'de 494 sorunun şıkları elden geçirilip
 * tellalık %91,1'den rastgele tabana indiriliyor, sonra Faz 2'de eklenen yeni sorular aynı
 * özeni görmediği için metrik sessizce geri gidiyor. Nitekim bu dosyadaki sorular ilk
 * yazıldığında 43 sorunun 16'sı "en uzun şıkkı seç" ile bilinebiliyordu ve mandal bunu
 * anında yakaladı.
 *
 * Buradaki testler, YENİ eklenen içeriğin bankanın ortalamasını bozmamasını değil,
 * ondan DAHA İYİ doğmasını zorunlu kılar. Ölçüt bankaya göredir; mutlak bir sayı değil,
 * "eklenen şey mevcudu kötüleştirmesin" ilkesidir.
 */
describe('genişletme kalite sözleşmesi (Faz 2)', () => {
  const bank = measureBank(allQuestions());
  const fresh = GENISLETME_QUESTIONS_2;

  it('genişletme gerçekten eklendi ve bankada görünüyor', () => {
    expect(fresh.length).toBeGreaterThanOrEqual(40);
    const ids = new Set(allQuestions().map((q) => q.id));
    for (const q of fresh) expect(ids.has(q.id)).toBe(true);
  });

  it('hiçbir yeni soru "en uzun şıkkı seç" ile bilinemez', () => {
    const telling = fresh.filter(longestOptionWins).map((q) => q.id);
    expect(telling).toEqual([]);
  });

  it('her yeni soruda şıklar paralel uzunlukta', () => {
    const uneven = fresh.filter((q) => !hasParallelOptions(q)).map((q) => q.id);
    expect(uneven).toEqual([]);
  });

  it('mutlak ifade yeni sorularda yalnız çeldiricilerde birikmiyor', () => {
    // Bankanın kendisi bu ölçütte %15,5; yeni içerik bunun ALTINDA kalmalı.
    const flagged = fresh.filter(absoluteOnlyInDistractors);
    expect(flagged.length / fresh.length).toBeLessThan(bank.absoluteOnlyRate);
  });

  it('birleşik sınav tekniği yeni sorularda banka ortalamasının altında', () => {
    const guessable = fresh.filter(testWiseGuessWins);
    expect(guessable.length / fresh.length).toBeLessThan(bank.testWiseRate);
  });

  it('içeriksiz şık yok', () => {
    const lazy = fresh.filter((q) => q.options.some(isLazyOption)).map((q) => q.id);
    expect(lazy).toEqual([]);
  });

  it('her yeni soru gerekçe ve kazanım taşıyor — üretim değil, yazım', () => {
    for (const q of fresh) {
      expect(q.options).toHaveLength(4);
      expect(q.explanation.length).toBeGreaterThan(60);
      expect(q.whyWrong?.length ?? 0).toBeGreaterThan(0);
      expect(q.objective?.length ?? 0).toBeGreaterThan(10);
      expect(q.tags?.length ?? 0).toBeGreaterThanOrEqual(2);
    }
  });

  it('Faz 0 denetiminde SIFIR olan konular artık kapsanıyor', () => {
    const topics = new Set(fresh.map((q) => q.topic));
    // Denetimde ölçülen boşluklar: ESP/ASR 0 · bagaj 0 · römork 1 · motosiklet 3 ·
    // motor bölmesi 1 · araç içi kumandalar (başlık yok) · ABS 4
    for (const t of [
      'esp-savrulma-onleyici',
      'cekis-kontrol',
      'bagaj-yuk-yerlesimi',
      'romork-cekme',
      'motosiklet-guvenlik',
      'motor-bolmesi',
      'arac-ici-kumandalar',
      'abs-fren',
    ])
      expect(topics.has(t)).toBe(true);
  });
});
