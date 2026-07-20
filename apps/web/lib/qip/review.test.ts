import { describe, it, expect } from 'vitest';
import { Question, baseNormalize } from '@ea/content-schema';
import { reviewGenerated, buildReviewContext } from './review';
import { normalizedQuestions, normalizedById } from './index';

function nq(raw: Record<string, unknown>) {
  return baseNormalize(Question.parse(raw));
}

const ctx = buildReviewContext(normalizedQuestions());

const freshGood = {
  id: 'gen-test-good',
  subject: 'trafik',
  topic: 'hiz',
  difficulty: 'orta',
  stem: 'Otoyolda otomobiller için ülkemizde uygulanan genel azami hız sınırı kaç km/s’tir?',
  options: ['100 km/s', '120 km/s', '140 km/s', '90 km/s'],
  answerIndex: 1,
  explanation:
    'Ülkemizde otoyolda otomobiller için genel azami hız sınırı 120 km/s’tir; koşullara göre düşürülür.',
  objective: 'Otoyol azami hız sınırını bilmek.',
  whyWrong: ['100 ve 140 genel sınır değildir.', '90 şehirlerarası bölünmüş yol içindir.'],
  tags: ['hiz', 'otoyol'],
  badge: 'official',
};

describe('reviewGenerated — AI İnceleyici kapısı', () => {
  it('özgün, kaliteli, yinelenmeyen soruyu KABUL eder', () => {
    const r = reviewGenerated(nq(freshGood), ctx);
    expect(r.ok).toBe(true);
    expect(r.checks.singleCorrect).toBe(true);
    expect(r.checks.notDuplicate).toBe(true);
    expect(r.checks.onDomain).toBe(true);
    expect(r.checks.qualityOk).toBe(true);
  });

  it('mevcut banka sorusunu (yineleme) REDDEDER', () => {
    const existing = normalizedById('trafik-101');
    expect(existing).toBeTruthy();
    const r = reviewGenerated(existing!, ctx);
    expect(r.checks.notDuplicate).toBe(false);
    expect(r.ok).toBe(false);
  });

  it('birden çok doğru cevabı (özdeş seçenek) REDDEDER', () => {
    const r = reviewGenerated(
      nq({
        ...freshGood,
        id: 'gen-test-multi',
        options: ['120 km/s', '120 km/s', '90 km/s'],
        answerIndex: 0,
      }),
      ctx
    );
    expect(r.checks.singleCorrect).toBe(false);
    expect(r.checks.distinctOptions).toBe(false);
    expect(r.ok).toBe(false);
  });

  it('sürüş alanı dışındaki soruyu REDDEDER', () => {
    const r = reviewGenerated(
      nq({
        id: 'gen-test-offdomain',
        subject: 'trafik',
        topic: 'yemek',
        stem: 'Bir pastanın fırında pişmesi yaklaşık kaç dakika sürer peki acaba?',
        options: ['20 dakika', '40 dakika', '60 dakika'],
        answerIndex: 1,
        explanation: 'Pasta fırında yaklaşık kırk dakikada güzelce pişer ve kabarır.',
      }),
      ctx
    );
    expect(r.checks.onDomain).toBe(false);
    expect(r.ok).toBe(false);
  });
});
