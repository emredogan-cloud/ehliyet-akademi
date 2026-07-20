/**
 * QIP AI üretim boru hattı testi — enjekte edilmiş STUB model (deterministik, canlı LLM yok).
 */
import { describe, it, expect } from 'vitest';
import type { AIModel } from './ai';
import { generateVariants, parseModelJson, type GenSpec } from './qip-generate';
import { buildReviewContext } from '@/lib/qip';

const GOOD = [
  {
    stem: 'Şehir dışı bölünmüş kara yolunda otomobil için genel azami hız sınırı kaç kilometredir?',
    options: ['90 kilometre', '110 kilometre', '120 kilometre'],
    answerIndex: 1,
    explanation:
      'Şehir dışı bölünmüş yollarda otomobil için genel azami hız 110 kilometredir; koşullara göre düşürülür.',
    difficulty: 'orta',
    whyWrong: ['90 bölünmemiş yollar içindir.', '120 yalnız otoyollarda geçerlidir.'],
  },
  {
    stem: 'Trafik ışığında sarı yanarken sürücünün doğru davranışı ne olmalıdır kısaca?',
    options: ['Hızlanarak geçer', 'Durmaya hazırlanır ve güvenliyse durur', 'Korna çalar'],
    answerIndex: 1,
    explanation:
      'Sarı ışıkta sürücü durmaya hazırlanır; güvenle durabiliyorsa durur, aksi hâlde kavşağı güvenle boşaltır.',
    difficulty: 'kolay',
    whyWrong: ['Hızlanmak tehlikelidir.', 'Korna gereksizdir.'],
  },
];

function stub(payload: unknown): AIModel {
  return { name: 'stub', generate: async () => JSON.stringify(payload) };
}

const spec: GenSpec = {
  subject: 'trafik',
  topic: 'hiz',
  concept: 'Hız sınırları',
  examples: [
    {
      stem: 'Yerleşim yerinde azami hız?',
      options: ['30', '50', '70'],
      answerIndex: 1,
      explanation: 'Yerleşim yerinde 50.',
    },
  ],
  count: 2,
};

describe('parseModelJson', () => {
  it('kod bloğu/önek gürültüsüne dayanıklı', () => {
    expect(parseModelJson('```json\n[{"a":1}]\n```')).toEqual([{ a: 1 }]);
    expect(parseModelJson('İşte sonuç: [1, 2] son.')).toEqual([1, 2]);
    expect(parseModelJson('dizi yok')).toEqual([]);
    expect(parseModelJson('{"a":1}')).toEqual([]);
  });
});

describe('generateVariants — boru hattı (parse→şema→normalleştir→inceleme→dedup)', () => {
  const emptyCtx = () => buildReviewContext([]);

  it('özgün geçerli soruları KABUL eder (origin ai-generated, review draft)', async () => {
    const out = await generateVariants(spec, { model: stub(GOOD), ctx: emptyCtx() });
    expect(out.accepted.length).toBe(2);
    for (const a of out.accepted) {
      expect(a.question.source.origin).toBe('ai-generated');
      expect(a.question.review).toBe('draft');
      expect(a.review.ok).toBe(true);
      expect(a.question.id).toMatch(/^gen-hiz-/);
    }
  });

  it('şema-geçersiz öğeyi REDDEDER', async () => {
    const bad = [{ stem: 'x', options: ['a'], answerIndex: 0, explanation: 'y' }];
    const out = await generateVariants(spec, { model: stub(bad), ctx: emptyCtx() });
    expect(out.accepted.length).toBe(0);
    expect(out.rejected[0]?.reason).toBe('şema');
  });

  it('parti-içi birebir yinelemeyi REDDEDER', async () => {
    const out = await generateVariants(spec, { model: stub([GOOD[0], GOOD[0]]), ctx: emptyCtx() });
    expect(out.accepted.length).toBe(1);
    expect(out.rejected.some((r) => r.reason === 'parti-içi yineleme')).toBe(true);
  });

  it('mevcut bankaya karşı yineleme incelemede REDDEDİLİR', async () => {
    // GOOD[0]'ı önce mevcut kabul et → ikinci üretim onu yineleme sayar.
    const ctx = emptyCtx();
    await generateVariants(spec, { model: stub([GOOD[0]]), ctx });
    const out = await generateVariants(spec, { model: stub([GOOD[0]]), ctx });
    expect(out.accepted.length).toBe(0);
    expect(out.rejected.some((r) => r.reason === 'inceleme')).toBe(true);
  });

  it('model yapılandırılmamışsa DÜRÜSTÇE boş döner (uydurma yok)', async () => {
    // Test ortamında ANTHROPIC_API_KEY yok → model null.
    const out = await generateVariants(spec);
    expect(out.model).toBe('unconfigured');
    expect(out.accepted).toEqual([]);
  });
});
