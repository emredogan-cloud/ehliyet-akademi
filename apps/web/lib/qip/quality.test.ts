import { describe, it, expect } from 'vitest';
import { Question, baseNormalize } from '@ea/content-schema';
import { scoreQuality, qualitySummary } from './quality';
import { analyzedQuestions } from './index';

function nq(raw: Record<string, unknown>) {
  return baseNormalize(Question.parse(raw));
}

const goodRaw = {
  id: 'q-good',
  subject: 'trafik',
  topic: 'hiz',
  difficulty: 'orta',
  stem: 'Yerleşim yeri içinde otomobil için genel azami hız sınırı nedir?',
  options: ['30 km/s', '50 km/s', '70 km/s', '90 km/s'],
  answerIndex: 1,
  explanation:
    'Yerleşim yeri içinde otomobiller için genel azami hız sınırı 50 km/s’tir; koşullara göre daha da düşürülür.',
  objective: 'Yerleşim yeri hız sınırını bilmek.',
  whyWrong: ['30 çok düşüktür ve genel sınır değildir.', '70 ve 90 yerleşim dışı içindir.'],
  tags: ['hiz'],
  badge: 'official',
};

describe('scoreQuality', () => {
  it('iyi yazılmış soru yüksek puan alır ve bayraksızdır', () => {
    const b = scoreQuality(nq(goodRaw));
    expect(b.total).toBeGreaterThanOrEqual(90);
    expect(b.flags).toEqual([]);
    expect(b.answerConfidence).toBe(100);
  });

  it('tekrarlı seçenek + özdeş doğru cevap düşük puan + bayrak', () => {
    const b = scoreQuality(
      nq({
        ...goodRaw,
        id: 'q-dupopt',
        options: ['50 km/s', '50 km/s', '70 km/s'],
        answerIndex: 0,
      })
    );
    expect(b.flags).toContain('tekrarlı seçenek');
    expect(b.flags).toContain('doğru cevaba özdeş ikinci seçenek');
    expect(b.total).toBeLessThan(goodRaw.options.length ? 90 : 100);
    expect(b.distractor).toBeLessThan(70);
  });

  it('kısa stem + kısa açıklama bayrak alır', () => {
    const b = scoreQuality(
      nq({
        id: 'q-short',
        subject: 'trafik',
        topic: 'hiz',
        stem: 'Hız nedir?', // < 20
        options: ['A uzun seçenek', 'B uzun seçenek'],
        answerIndex: 0,
        explanation: 'Kısa açık.', // < 20
      })
    );
    expect(b.flags).toContain('stem çok kısa');
    expect(b.flags).toContain('açıklama kısa');
    expect(b.total).toBeLessThan(95);
  });

  it('yer tutucu metni dilbilgisini düşürür', () => {
    const b = scoreQuality(
      nq({
        ...goodRaw,
        id: 'q-ph',
        stem: 'Bu bir TODO placeholder sorusudur ve tamamlanmamıştır?',
      })
    );
    expect(b.flags).toContain('yer tutucu metin');
    expect(b.grammar).toBeLessThan(60);
  });

  it('qualitySummary gerçek dağılım üretir', () => {
    const analyzed = analyzedQuestions();
    const s = qualitySummary(analyzed.map((q) => q.quality));
    expect(s.count).toBe(analyzed.length);
    expect(s.avg).toBeGreaterThan(0);
    expect(s.avg).toBeLessThanOrEqual(100);
    expect(s.min).toBeLessThanOrEqual(s.max);
    const bucketSum = Object.values(s.distribution).reduce((a, b) => a + b, 0);
    expect(bucketSum).toBe(s.count);
  });
});
