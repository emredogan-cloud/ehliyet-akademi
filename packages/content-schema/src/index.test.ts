import { describe, it, expect } from 'vitest';
import {
  Question,
  validateBank,
  EXAM_BLUEPRINT,
  BADGE_LABEL,
  SUBJECT_LABEL,
  canTransition,
  validatePayload,
  foldText,
  hash32,
  questionFingerprint,
  baseNormalize,
  NormalizedQuestion,
  QIP_CATEGORY_BY_SUBJECT,
  EST_SECONDS_BY_DIFFICULTY,
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

describe('QIP Faz 1 — normalleştirme', () => {
  it('foldText: Türkçe karakter + noktalama + boşluk kanonikleştirir', () => {
    expect(foldText('Şoför, "DUR" levhası!')).toBe('sofor dur levhasi');
    expect(foldText('  İki   Boşluk ')).toBe('iki bosluk');
    // görünüşte farklı ama katlanınca eş metinler:
    expect(foldText('Hız Sınırı')).toBe(foldText('hiz  siniri'));
  });

  it('hash32: deterministik ve giriş değişince değişir', () => {
    expect(hash32('abc')).toBe(hash32('abc'));
    expect(hash32('abc')).not.toBe(hash32('abd'));
    expect(hash32('abc')).toMatch(/^[0-9a-f]{8}$/);
  });

  it('questionFingerprint: seçenek sırasından bağımsız, içerik değişince değişir', () => {
    const a = { stem: 'Kırmızı ışıkta ne yapılır?', options: ['Durulur', 'Geçilir', 'Hızlanılır'] };
    const b = { stem: 'Kırmızı ışıkta ne yapılır?', options: ['Geçilir', 'Hızlanılır', 'Durulur'] };
    const c = { stem: 'Sarı ışıkta ne yapılır?', options: ['Durulur', 'Geçilir', 'Hızlanılır'] };
    expect(questionFingerprint(a)).toBe(questionFingerprint(b)); // sıra bağımsız
    expect(questionFingerprint(a)).not.toBe(questionFingerprint(c)); // stem farklı
  });

  it('baseNormalize: Part 2 birleşik şemayı doldurur (geriye dönük uyumlu)', () => {
    const q = Question.parse({
      id: 'motor-999',
      subject: 'motor',
      topic: 'fren',
      difficulty: 'zor',
      stem: 'Fren pedalı boşaldığında ilk yapılması gereken nedir?',
      options: ['Motoru durdur', 'El frenini kademeli çek', 'Gaza bas'],
      answerIndex: 1,
      explanation: 'Fren boşaldığında motor freni ve el freni ile kademeli yavaşlanır.',
      objective: 'Fren arızasında güvenli durma refleksini kavramak.',
      whyWrong: ['Motoru aniden durdurmak direksiyon/fren desteğini keser.'],
      sourceRef: 'Resmî MEB müfredatı (özgün)',
    });
    const n = baseNormalize(q);
    expect(NormalizedQuestion.safeParse(n).success).toBe(true);
    expect(n.category).toBe(QIP_CATEGORY_BY_SUBJECT.motor);
    expect(n.subcategory).toBe('fren');
    expect(n.learningOutcome).toBe(q.objective);
    expect(n.commonMistakes).toEqual(q.whyWrong);
    expect(n.estimatedSeconds).toBe(EST_SECONDS_BY_DIFFICULTY.zor);
    expect(n.source.origin).toBe('authored');
    expect(n.source.attribution).toBe('Resmî MEB müfredatı (özgün)');
    expect(n.fingerprint).toBe(questionFingerprint(q));
    expect(n.version).toBe(1);
  });

  it('baseNormalize: overrides (uygulama katmanı cross-link enjeksiyonu) uygulanır', () => {
    const q = Question.parse({
      id: 'trafik-999',
      subject: 'trafik',
      topic: 'isaretler',
      stem: 'DUR levhası ne anlama gelir ve ne yapılır?',
      options: ['Yavaşla', 'Tam dur ve öncelik ver', 'Korna çal'],
      answerIndex: 1,
      explanation: 'DUR levhasında araç tam durur ve geçiş hakkı olana öncelik verir.',
    });
    const n = baseNormalize(q, {
      relatedSigns: ['dur'],
      relatedLesson: 'trafik-isaretleri',
      image: '/assets/signs/dur.webp',
      source: { origin: 'authored', method: 'curriculum', license: 'proprietary' },
    });
    expect(n.relatedSigns).toEqual(['dur']);
    expect(n.relatedLesson).toBe('trafik-isaretleri');
    expect(n.image).toBe('/assets/signs/dur.webp');
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
