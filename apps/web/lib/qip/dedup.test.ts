import { describe, it, expect } from 'vitest';
import { Question, baseNormalize } from '@ea/content-schema';
import { tokenSet, jaccard, dedupReport } from './dedup';
import { normalizedQuestions } from './index';

function nq(raw: Record<string, unknown>) {
  return baseNormalize(Question.parse(raw));
}

describe('tokenSet + jaccard', () => {
  it('durak kelimeleri ve kısa jetonları atar', () => {
    const s = tokenSet({
      stem: 'Bu bir hız sınırı sorusudur ve nedir?',
      options: [],
      answerIndex: 0,
    });
    expect(s.has('bir')).toBe(false); // stopword
    expect(s.has('ve')).toBe(false); // stopword
    expect(s.has('nedir')).toBe(false); // stopword
    expect(s.has('hiz')).toBe(true);
    expect(s.has('siniri')).toBe(true);
  });

  it('jaccard sınır durumları', () => {
    expect(jaccard(new Set(['a', 'b']), new Set(['a', 'b']))).toBe(1);
    expect(jaccard(new Set(['a']), new Set(['b']))).toBe(0);
    expect(jaccard(new Set(), new Set(['a']))).toBe(0);
  });
});

describe('dedupReport', () => {
  it('yeniden ifade edilmiş yakın-yinelemeyi yakalar, farklıyı yakalamaz', () => {
    const pool = [
      nq({
        id: 'nd-a',
        subject: 'trafik',
        topic: 'hiz',
        stem: 'Yerleşim yeri içinde otomobil için azami hız sınırı kaç kilometredir?',
        options: ['30 km', '50 km', '70 km'],
        answerIndex: 1,
        explanation: 'Yerleşim yeri içinde azami hız 50 kilometredir; koşullara göre düşürülür.',
      }),
      nq({
        id: 'nd-b',
        // Aynı soru, önemsiz bir durak kelimeyle ("Bir") yeniden ifade edilmiş → yakın-yineleme.
        subject: 'trafik',
        topic: 'hiz',
        stem: 'Bir yerleşim yeri içinde otomobil için azami hız sınırı kaç kilometredir?',
        options: ['30 kilometre', '50 kilometre', '70 kilometre'],
        answerIndex: 1,
        explanation:
          'Bir yerleşim yeri içinde azami hız 50 kilometredir; koşullara göre düşürülür.',
      }),
      nq({
        id: 'distinct-c',
        subject: 'ilkyardim',
        topic: 'kanama',
        stem: 'Dış kanamada ilk uygulanacak temel bası yöntemi hangi bölgeye yapılır peki?',
        options: ['Yara üzerine', 'Karın', 'Ayak'],
        answerIndex: 0,
        explanation: 'Dış kanamada doğrudan yara üzerine baskı uygulanır ve bası sürdürülür.',
      }),
    ];
    const r = dedupReport(pool, 0.82);
    expect(r.nearDuplicatePairs).toBeGreaterThanOrEqual(1);
    const ids = r.topPairs.flatMap((p) => [p.a, p.b]);
    expect(ids).toContain('nd-a');
    expect(ids).toContain('nd-b');
    expect(ids).not.toContain('distinct-c');
    expect(r.nearDuplicateCounts['nd-a']).toBeGreaterThanOrEqual(1);
  });

  it('özdeş içeriği (farklı id) tam yineleme sayar', () => {
    const base = {
      subject: 'motor' as const,
      topic: 'fren',
      stem: 'Fren pedalı boşaldığında sürücünün ilk yapması gereken davranış nedir peki?',
      options: ['El frenini kademeli çek', 'Gaza bas', 'Kontağı kapat'],
      answerIndex: 0,
      explanation: 'Fren boşaldığında motor freni ve el freni ile kademeli olarak yavaşlanır.',
    };
    const r = dedupReport([nq({ ...base, id: 'ex-1' }), nq({ ...base, id: 'ex-2' })]);
    expect(r.exactDuplicateRecords).toBe(1);
    expect(r.exactDuplicateGroups).toBe(1);
  });

  it('tüm banka: tam yineleme yok, oran hesaplanır', () => {
    const r = dedupReport(normalizedQuestions());
    expect(r.total).toBe(normalizedQuestions().length);
    expect(r.exactDuplicateRecords).toBe(0);
    expect(r.duplicateRatePct).toBeGreaterThanOrEqual(0);
    expect(r.duplicateRatePct).toBeLessThan(5); // banka temiz
  });
});
