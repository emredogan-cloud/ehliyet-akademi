import { describe, it, expect } from 'vitest';
import {
  newCard,
  review,
  toGrade,
  isDue,
  selectNext,
  computeReadiness,
  statsFromAnswers,
  DAY_MS,
  MIN_EASE,
  type SrsCard,
  type SelectableQuestion,
} from './index';

const T0 = 1_700_000_000_000; // sabit "now" — deterministik

describe('SM-2 review', () => {
  it('yeni kart bugün vadeli, varsayılan ease 2.5', () => {
    const c = newCard('q1', T0);
    expect(c.ease).toBe(2.5);
    expect(c.dueAt).toBe(T0);
    expect(isDue(c, T0)).toBe(true);
  });

  it('ardışık doğru cevaplar aralığı 1 → 6 → büyütür', () => {
    let c = newCard('q1', T0);
    c = review(c, 4, T0);
    expect(c.repetitions).toBe(1);
    expect(c.intervalDays).toBe(1);
    c = review(c, 4, T0 + DAY_MS);
    expect(c.repetitions).toBe(2);
    expect(c.intervalDays).toBe(6);
    c = review(c, 4, T0 + 7 * DAY_MS);
    expect(c.repetitions).toBe(3);
    expect(c.intervalDays).toBeGreaterThan(6); // ~6*ease
  });

  it('başarısız cevap tekrarları sıfırlar, lapse artırır, ease düşürür, ~10dk sonra vadeli', () => {
    let c = newCard('q1', T0);
    c = review(c, 5, T0); // önce ilerlet
    const easeBefore = c.ease;
    c = review(c, 1, T0 + DAY_MS); // başarısız
    expect(c.repetitions).toBe(0);
    expect(c.lapses).toBe(1);
    expect(c.ease).toBeLessThan(easeBefore);
    expect(c.dueAt - (T0 + DAY_MS)).toBeLessThan(DAY_MS); // aynı gün tekrar
  });

  it('ease MIN_EASE altına inmez', () => {
    let c = newCard('q1', T0);
    for (let i = 0; i < 20; i++) c = review(c, 0, T0 + i * DAY_MS);
    expect(c.ease).toBeGreaterThanOrEqual(MIN_EASE);
  });

  it('toGrade eşlemesi', () => {
    expect(toGrade('again')).toBe(1);
    expect(toGrade('good')).toBe(4);
    expect(toGrade('easy')).toBe(5);
  });
});

describe('selectNext (adaptif)', () => {
  const pool: SelectableQuestion[] = [
    { id: 'a', subject: 'trafik', topic: 'isaretler' },
    { id: 'b', subject: 'trafik', topic: 'oncelik' },
    { id: 'c', subject: 'ilkyardim', topic: 'kanama' },
  ];

  it('vadesi geçmiş kartı yeni içeriğin önüne alır', () => {
    const cards = new Map<string, SrsCard>();
    const overdue = newCard('b', T0 - 5 * DAY_MS);
    overdue.repetitions = 2;
    cards.set('b', overdue);
    const sel = selectNext(pool, cards, new Map(), T0, 1);
    expect(sel[0]).toBe('b');
  });

  it('zayıf konuya ağırlık verir', () => {
    const mastery = new Map<string, number>([
      ['isaretler', 0.95],
      ['oncelik', 0.1],
      ['kanama', 0.9],
    ]);
    const sel = selectNext(pool, new Map(), mastery, T0, 1);
    expect(sel[0]).toBe('b'); // en zayıf konu
  });
});

describe('computeReadiness (trafik ışığı)', () => {
  it('boş istatistikte kırmızı ve düşük olasılık', () => {
    const r = computeReadiness([]);
    expect(r.light).toBe('kirmizi');
    expect(r.predictedPassProbability).toBeLessThan(0.2);
  });

  it('yüksek ağırlıklı ustalıkta yeşil ve yüksek olasılık', () => {
    const r = computeReadiness([
      { subject: 'trafik', answered: 20, correct: 20, mastery: 1 },
      { subject: 'ilkyardim', answered: 20, correct: 20, mastery: 1 },
      { subject: 'motor', answered: 20, correct: 20, mastery: 1 },
      { subject: 'adab', answered: 20, correct: 20, mastery: 1 },
    ]);
    expect(r.light).toBe('yesil');
    expect(r.predictedPassProbability).toBeGreaterThan(0.9);
    expect(r.overall).toBeGreaterThan(90);
  });

  it('az veri güven iskontosu uygular (mastery yüksek ama az cevap)', () => {
    const few = computeReadiness([{ subject: 'trafik', answered: 2, correct: 2, mastery: 1 }]);
    const many = computeReadiness([{ subject: 'trafik', answered: 16, correct: 16, mastery: 1 }]);
    expect(few.overall).toBeLessThan(many.overall);
  });

  it('trafik ağırlığı adab’dan yüksektir (dağılım eşleşmesi)', () => {
    const strongTrafik = computeReadiness([
      { subject: 'trafik', answered: 20, correct: 20, mastery: 1 },
      { subject: 'adab', answered: 20, correct: 0, mastery: 0 },
    ]);
    const strongAdab = computeReadiness([
      { subject: 'trafik', answered: 20, correct: 0, mastery: 0 },
      { subject: 'adab', answered: 20, correct: 20, mastery: 1 },
    ]);
    expect(strongTrafik.overall).toBeGreaterThan(strongAdab.overall);
  });
});

describe('statsFromAnswers', () => {
  it('ders ve konu ustalığını doğru hesaplar', () => {
    const { subjects, topicMastery } = statsFromAnswers([
      { subject: 'trafik', topic: 'isaretler', correct: true },
      { subject: 'trafik', topic: 'isaretler', correct: false },
      { subject: 'motor', topic: 'fren', correct: true },
    ]);
    const trafik = subjects.find((s) => s.subject === 'trafik')!;
    expect(trafik.answered).toBe(2);
    expect(trafik.mastery).toBe(0.5);
    expect(topicMastery.get('isaretler')).toBe(0.5);
    expect(topicMastery.get('fren')).toBe(1);
  });
});
