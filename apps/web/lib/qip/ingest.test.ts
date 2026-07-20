import { describe, it, expect } from 'vitest';
import { ingestQuestion, ingestBatch, emptyIngestContext, ingestContextFrom } from './ingest';
import { normalizedQuestions } from './index';

const valid = {
  id: 'qip-test-1',
  subject: 'trafik' as const,
  topic: 'hiz',
  stem: 'Yerleşim yeri içinde otomobil için genel azami hız sınırı kaçtır?',
  options: ['30 km/s', '50 km/s', '70 km/s', '90 km/s'],
  answerIndex: 1,
  explanation: 'Yerleşim yeri içinde otomobiller için genel azami hız sınırı 50 km/s’tir.',
};

describe('ingestQuestion', () => {
  it('geçerli kaydı alır, kaynak atfı + parmak izi ekler', () => {
    const r = ingestQuestion(valid, { origin: 'authored', attribution: 'MEB müfredatı (özgün)' });
    expect(r.ok).toBe(true);
    expect(r.question?.id).toBe('qip-test-1');
    expect(r.question?.source.origin).toBe('authored');
    expect(r.question?.source.attribution).toBe('MEB müfredatı (özgün)');
    expect(r.question?.fingerprint).toMatch(/^[0-9a-f]{8}$/);
    expect(r.question?.category).toBeTruthy();
  });

  it('AI-üretimi kaynağı işaretler (Faz 4 ön koşulu)', () => {
    const r = ingestQuestion(valid, { origin: 'ai-generated', method: 'ai' });
    expect(r.question?.source.origin).toBe('ai-generated');
    expect(r.question?.source.method).toBe('ai');
  });

  it('geçersiz şemayı reddeder', () => {
    const r = ingestQuestion({ id: 'bad', stem: 'x' }, {});
    expect(r.ok).toBe(false);
    expect(r.reason).toBe('schema');
    expect(r.errors && r.errors.length).toBeGreaterThan(0);
  });

  it('answerIndex aralık dışını reddeder (refine)', () => {
    const r = ingestQuestion({ ...valid, answerIndex: 9 }, {});
    expect(r.ok).toBe(false);
    expect(r.reason).toBe('schema');
  });

  it('aynı bağlamda id yinelemesini reddeder', () => {
    const ctx = emptyIngestContext();
    expect(ingestQuestion(valid, {}, ctx).ok).toBe(true);
    const again = ingestQuestion({ ...valid, stem: valid.stem + ' (farklı)' }, {}, ctx);
    expect(again.ok).toBe(false);
    expect(again.reason).toBe('duplicate-id');
  });

  it('aynı içeriği (farklı id, seçenek sırası karışık) parmak iziyle reddeder', () => {
    const ctx = emptyIngestContext();
    expect(ingestQuestion(valid, {}, ctx).ok).toBe(true);
    const shuffled = {
      ...valid,
      id: 'qip-test-1-copy',
      options: ['50 km/s', '30 km/s', '90 km/s', '70 km/s'],
      answerIndex: 0,
    };
    const dup = ingestQuestion(shuffled, {}, ctx);
    expect(dup.ok).toBe(false);
    expect(dup.reason).toBe('duplicate-fingerprint');
  });

  it('reddedilen kayıt bağlamı kirletmez', () => {
    const ctx = emptyIngestContext();
    ingestQuestion({ id: 'bad', stem: 'x' }, {}, ctx);
    expect(ctx.seenIds.size).toBe(0);
    expect(ctx.seenFingerprints.size).toBe(0);
  });
});

describe('ingestBatch + mevcut bankaya karşı dedup', () => {
  it('grup içi yinelemeyi ayıklar', () => {
    const report = ingestBatch([valid, { ...valid, id: 'qip-test-2' }, valid], {});
    expect(report.total).toBe(3);
    expect(report.accepted.length).toBe(1); // 2. kayıt aynı içerik (fp), 3. kayıt aynı id
    expect(report.rejected.length).toBe(2);
  });

  it('mevcut normalleştirilmiş bankaya karşı yeni özgün kayıt kabul edilir', () => {
    const ctx = ingestContextFrom(normalizedQuestions());
    const fresh = {
      id: 'qip-unique-xyz',
      subject: 'motor' as const,
      topic: 'lastik',
      stem: 'Lastik diş derinliği yasal asgari sınırın altına düştüğünde ne yapılmalıdır?',
      options: ['Hemen değiştirilmelidir', 'Görmezden gelinir', 'Havası artırılır'],
      answerIndex: 0,
      explanation: 'Diş derinliği yasal sınırın altındaki lastik güvenli değildir, değiştirilir.',
    };
    const r = ingestQuestion(fresh, { origin: 'authored' }, ctx);
    expect(r.ok).toBe(true);
  });
});
