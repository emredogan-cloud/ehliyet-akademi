import { describe, it, expect } from 'vitest';
import {
  Question,
  validateBank,
  EXAM_BLUEPRINT,
  BADGE_LABEL,
  SUBJECT_LABEL,
  canTransition,
  validatePayload,
} from './index';

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

describe('Sprint 2 — CMS sözleşmeleri', () => {
  it('iş akışı: yalnız izinli geçişler', () => {
    expect(canTransition('draft', 'in_review')).toBe(true);
    expect(canTransition('in_review', 'approved')).toBe(true);
    expect(canTransition('approved', 'published')).toBe(true);
    expect(canTransition('published', 'retired')).toBe(true);
    expect(canTransition('draft', 'published')).toBe(false); // onaysız yayın YOK
    expect(canTransition('published', 'draft')).toBe(false);
    expect(canTransition('retired', 'draft')).toBe(true); // yeniden çalışmaya açılabilir
  });

  it('validatePayload: türe göre doğrular; hataları listeler', () => {
    expect(validatePayload('question', { stem: 'x' }).ok).toBe(false);
    const okQ = validatePayload('question', {
      id: 'cms-q-1',
      subject: 'trafik',
      topic: 'isaretler',
      stem: 'CMS üzerinden eklenen deneme sorusu?',
      options: ['A', 'B', 'C'],
      answerIndex: 1,
      explanation: 'Bu bir CMS doğrulama testidir; açıklama yeterince uzun.',
    });
    expect(okQ.ok).toBe(true);
    expect(validatePayload('article', { title: 'kısa' }).ok).toBe(false);
    expect(
      validatePayload('article', {
        title: 'Ehliyet sınavına nasıl hazırlanılır?',
        summary: 'Adım adım hazırlık rehberi.',
        body: 'Bu makale sınav hazırlığının temel adımlarını anlatır ve yeterince uzundur.',
      }).ok
    ).toBe(true);
    expect(validatePayload('yok', {}).ok).toBe(false);
  });
});
