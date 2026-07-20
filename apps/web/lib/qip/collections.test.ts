import { describe, it, expect } from 'vitest';
import { examCollections, collectionById, seedFromDate } from './collections';
import { normalizedById } from './index';

describe('examCollections — otomatik koleksiyonlar (Part 16)', () => {
  const cols = examCollections({ daySeed: seedFromDate('2026-07-21') });
  const byId = new Map(cols.map((c) => [c.id, c]));

  it('beklenen koleksiyonları üretir', () => {
    for (const id of [
      'gunun-sinavi',
      'haftanin-sinavi',
      'baslangic',
      'zor-sorular',
      'sadece-isaretler',
      'sadece-motor',
      'sadece-ilkyardim',
      'en-cok-yanilan',
      'rastgele-50',
      'ai-challenge',
    ]) {
      expect(byId.has(id)).toBe(true);
      expect(byId.get(id)!.count).toBeGreaterThan(0);
    }
  });

  it('Günün Sınavı 50 soru; Rastgele 50 = 50', () => {
    expect(byId.get('gunun-sinavi')!.count).toBe(50);
    expect(byId.get('rastgele-50')!.count).toBe(50);
  });

  it('içerik filtreleri doğru (Motor/İşaret/Zor)', () => {
    for (const id of byId.get('sadece-motor')!.questionIds) {
      expect(normalizedById(id)!.subject).toBe('motor');
    }
    for (const id of byId.get('zor-sorular')!.questionIds) {
      expect(normalizedById(id)!.difficulty).toBe('zor');
    }
    for (const id of byId.get('sadece-ilkyardim')!.questionIds) {
      expect(normalizedById(id)!.subject).toBe('ilkyardim');
    }
  });

  it('deterministik (aynı tohum → aynı koleksiyon)', () => {
    const a = examCollections({ daySeed: 123 });
    const b = examCollections({ daySeed: 123 });
    expect(a.map((c) => c.questionIds)).toEqual(b.map((c) => c.questionIds));
  });

  it('seedFromDate kararlı ve tarihe duyarlı', () => {
    expect(seedFromDate('2026-07-21')).toBe(seedFromDate('2026-07-21'));
    expect(seedFromDate('2026-07-21')).not.toBe(seedFromDate('2026-07-22'));
  });

  it('collectionById çözümler', () => {
    expect(collectionById('sadece-motor', { daySeed: 1 })?.label).toBe('Yalnız Araç Tekniği');
    expect(collectionById('yok', {})).toBeUndefined();
  });

  it('istatistik verilince En Çok Yanılan yanlış oranına göre sıralanır', () => {
    const stats = [
      {
        questionId: 'trafik-101',
        attempts: 10,
        correct: 1,
        wrong: 9,
        correctRate: 0.1,
        wrongRate: 0.9,
      },
      {
        questionId: 'trafik-102',
        attempts: 10,
        correct: 9,
        wrong: 1,
        correctRate: 0.9,
        wrongRate: 0.1,
      },
    ];
    const c = collectionById('en-cok-yanilan', { stats });
    expect(c!.questionIds[0]).toBe('trafik-101'); // en yüksek yanlış oranı önce
  });
});
