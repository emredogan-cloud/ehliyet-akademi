/**
 * Çalışma zekâsı testleri — zayıf konu tespiti, adaptif plan, kişisel tekrar, yanlış-açıklama.
 */
import { describe, it, expect } from 'vitest';
import { newCard, type SrsCard } from '@ea/srs-engine';
import type { AnswerLog } from './progress';
import {
  weakTopics,
  buildStudyPlan,
  personalizedReview,
  explainWrongAnswer,
  formatWeakTopics,
  formatStudyPlan,
  lessonForSubject,
  dueCount,
} from './study';

const NOW = 1_800_000_000_000;

function ans(subject: AnswerLog['subject'], topic: string, correct: boolean, i = 0): AnswerLog {
  return { questionId: `${subject}-${topic}-${i}`, subject, topic, correct, at: NOW - i };
}

describe('weakTopics', () => {
  it('en zayıf konuyu önce, ustalaşılanı hariç tutar', () => {
    const answers: AnswerLog[] = [
      // hiz: 1/4 doğru → zayıf
      ans('trafik', 'hiz', true, 1),
      ans('trafik', 'hiz', false, 2),
      ans('trafik', 'hiz', false, 3),
      ans('trafik', 'hiz', false, 4),
      // isaretler: 5/5 doğru → ustalaşılmış, hariç
      ...[5, 6, 7, 8, 9].map((i) => ans('trafik', 'isaretler', true, i)),
      // oncelik: 2/3 → orta
      ans('trafik', 'oncelik', true, 10),
      ans('trafik', 'oncelik', true, 11),
      ans('trafik', 'oncelik', false, 12),
    ];
    const weak = weakTopics(answers, { minAnswered: 2 });
    expect(weak[0]!.topic).toBe('hiz'); // en zayıf ilk
    expect(weak.map((w) => w.topic)).not.toContain('isaretler'); // ustalaşılmış hariç
    expect(weak[0]!.mastery).toBeCloseTo(0.25, 5);
  });

  it('yetersiz denenmiş konuyu (minAnswered altı) saymaz', () => {
    const weak = weakTopics([ans('motor', 'fren', false, 1)], { minAnswered: 2 });
    expect(weak).toHaveLength(0);
  });
});

describe('buildStudyPlan', () => {
  it('veri yokken makul başlangıç planı (ders + alıştırma + deneme)', () => {
    const plan = buildStudyPlan([], new Map(), NOW);
    expect(plan.summary).toMatch(/veri yok/i);
    const kinds = plan.steps.map((s) => s.kind);
    expect(kinds).toContain('lesson');
    expect(kinds).toContain('practice');
    expect(kinds).toContain('exam');
  });

  it('vadesi gelen kart varsa ilk adım tekrardır', () => {
    const cards = new Map<string, SrsCard>();
    cards.set('trafik-001', newCard('trafik-001', NOW - 10 * 86_400_000)); // vadesi geçmiş
    const plan = buildStudyPlan([ans('trafik', 'hiz', false, 1)], cards, NOW);
    expect(plan.dueCount).toBeGreaterThan(0);
    expect(plan.steps[0]!.kind).toBe('review');
  });

  it('planın odağı en zayıf derslere yönelir', () => {
    const answers: AnswerLog[] = [
      // adab çok zayıf
      ans('adab', 'ofke', false, 1),
      ans('adab', 'ofke', false, 2),
      ans('adab', 'empati', false, 3),
      // trafik güçlü
      ...[4, 5, 6].map((i) => ans('trafik', 'hiz', true, i)),
    ];
    const plan = buildStudyPlan(answers, new Map(), NOW);
    expect(plan.focus.map((f) => f.subject)).toContain('adab');
  });
});

describe('personalizedReview + dueCount', () => {
  it('vadesi gelen + zayıf konu sorularından id listesi üretir', () => {
    const cards = new Map<string, SrsCard>();
    cards.set('trafik-001', newCard('trafik-001', NOW - 5 * 86_400_000));
    const ids = personalizedReview([ans('trafik', 'isaretler', false, 1)], cards, NOW, 8);
    expect(ids.length).toBeGreaterThan(0);
    expect(ids.length).toBeLessThanOrEqual(8);
    expect(dueCount(cards, NOW)).toBe(1);
  });
});

describe('explainWrongAnswer', () => {
  it('bilinen soru için doğru cevap + açıklama döndürür', () => {
    const e = explainWrongAnswer('trafik-001', 0);
    expect(e).not.toBeNull();
    expect(e!.explanation.length).toBeGreaterThan(10);
    expect(typeof e!.correct).toBe('string');
    expect(e!.chosenWasCorrect).toBe(false); // trafik-001 doğru index 1
  });

  it('bilinmeyen soru için null', () => {
    expect(explainWrongAnswer('yok-boyle-000', 0)).toBeNull();
  });
});

describe('biçimlendiriciler', () => {
  it('formatWeakTopics kaynak uyarısı içerir', () => {
    const weak = weakTopics([ans('trafik', 'hiz', false, 1), ans('trafik', 'hiz', false, 2)], {
      minAnswered: 2,
    });
    const msg = formatWeakTopics(weak);
    expect(msg).toMatch(/MEB\/MTSK/);
    expect(msg).toMatch(/hiz/);
  });

  it('formatStudyPlan adımları numaralar', () => {
    const msg = formatStudyPlan(buildStudyPlan([], new Map(), NOW));
    expect(msg).toMatch(/1\./);
  });
});

describe('ders eşlemeleri', () => {
  it('her teorik ders için bir ders bulunur', () => {
    for (const s of ['trafik', 'ilkyardim', 'motor', 'adab'] as const) {
      expect(lessonForSubject(s)).toBeTruthy();
    }
  });
});
