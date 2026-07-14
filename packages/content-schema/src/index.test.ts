import { describe, it, expect } from 'vitest';
import { Question, validateBank, EXAM_BLUEPRINT, BADGE_LABEL, SUBJECT_LABEL } from './index';

const good = {
  id: 'trafik-001',
  subject: 'trafik',
  topic: 'isaretler',
  stem: 'Kırmızı zeminli sekizgen "DUR" levhasında ne yapılır?',
  options: ['Yavaşlanır', 'Tam durulur ve öncelik verilir', 'Korna çalınır'],
  answerIndex: 1,
  explanation: 'DUR levhasında araç tam durmalı ve geçiş hakkı olana öncelik vermelidir.',
  badge: 'official',
};

describe('Question şeması', () => {
  it('geçerli soruyu kabul eder ve varsayılanları doldurur', () => {
    const q = Question.parse(good);
    expect(q.difficulty).toBe('orta');
    expect(q.review).toBe('draft');
  });

  it('answerIndex options aralığı dışındaysa reddeder', () => {
    const r = Question.safeParse({ ...good, answerIndex: 9 });
    expect(r.success).toBe(false);
  });

  it('boş seçenek listesini reddeder', () => {
    const r = Question.safeParse({ ...good, options: ['tek'] });
    expect(r.success).toBe(false);
  });
});

describe('validateBank', () => {
  it('tekrar eden id yakalar', () => {
    const res = validateBank([good, { ...good }]);
    expect(res.ok).toBe(false);
    expect(res.errors.join()).toMatch(/tekrar eden id/);
  });

  it('geçerli bankayı onaylar', () => {
    const res = validateBank([good, { ...good, id: 'trafik-002' }]);
    expect(res.ok).toBe(true);
    expect(res.count).toBe(2);
  });
});

describe('EXAM_BLUEPRINT (MEB dağılımı)', () => {
  it('dağılım toplamı 50 ve baraj 35', () => {
    const d = EXAM_BLUEPRINT.distribution;
    expect(d.trafik + d.ilkyardim + d.motor + d.adab).toBe(EXAM_BLUEPRINT.totalQuestions);
    expect(EXAM_BLUEPRINT.totalQuestions).toBe(50);
    expect(EXAM_BLUEPRINT.passCorrect).toBe(35);
    expect(EXAM_BLUEPRINT.durationMinutes).toBe(45);
  });
});

describe('etiketler', () => {
  it('rozet ve ders etiketleri Türkçe', () => {
    expect(BADGE_LABEL.official).toBe('Resmî Kural');
    expect(SUBJECT_LABEL.ilkyardim).toBe('İlk Yardım Bilgisi');
  });
});
