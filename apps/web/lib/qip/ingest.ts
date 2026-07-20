/**
 * QIP — Faz 1: soru alım (ingestion) hattı. BANK_QUESTİON Part 1.
 *
 * İÇERİK HUKUKU (kritik): Telif korumalı üçüncü taraf soru bankaları/siteleri KOPYALANMAZ.
 * Bu hat, özgün (authored) veya AI-üretimi (Faz 4, review:draft) ya da açık lisanslı/kamuya açık
 * kaynaklardan gelen kayıtları — kaynak atfı ile — şemaya normalleştirip tekilleştirerek alır.
 * "Discovery" bu yüzden bir tarama botu değil, DENETLENEBİLİR bir alım kapasitesidir.
 *
 * Hat saf ve deterministiktir: durum (görülen id/parmak izi) çağırana ait bir `IngestContext`te
 * tutulur; böylece toplu içe aktarım ve testler yan etkisizdir.
 */
import {
  Question as QuestionSchema,
  questionFingerprint,
  QuestionSource,
  type NormalizedQuestion,
  type QuestionSource as QuestionSourceT,
} from '@ea/content-schema';
import { normalizeQuestion } from './normalize';

export type IngestReason = 'schema' | 'duplicate-id' | 'duplicate-fingerprint';

export interface IngestResult {
  ok: boolean;
  question?: NormalizedQuestion;
  reason?: IngestReason;
  errors?: string[];
}

/** Alım oturumu durumu — çağıran sahiplenir (toplu içe aktarım için tekrar kullanılır). */
export interface IngestContext {
  seenIds: Set<string>;
  seenFingerprints: Set<string>;
}

/** Mevcut normalleştirilmiş bankadan bir alım bağlamı kur (yeni kayıtları buna göre dedup et). */
export function ingestContextFrom(existing: NormalizedQuestion[]): IngestContext {
  return {
    seenIds: new Set(existing.map((q) => q.id)),
    seenFingerprints: new Set(existing.map((q) => q.fingerprint)),
  };
}

export function emptyIngestContext(): IngestContext {
  return { seenIds: new Set(), seenFingerprints: new Set() };
}

/**
 * Tek bir ham kaydı al: şema doğrula → parmak izi → dedup → normalleştir (kaynak atfı ile).
 * Başarılıysa `ctx` güncellenir (id + parmak izi eklenir). Reddedilirse `ctx` değişmez.
 */
export function ingestQuestion(
  raw: unknown,
  source: Partial<QuestionSourceT>,
  ctx: IngestContext = emptyIngestContext()
): IngestResult {
  const parsed = QuestionSchema.safeParse(raw);
  if (!parsed.success) {
    return { ok: false, reason: 'schema', errors: parsed.error.issues.map((e) => e.message) };
  }
  const q = parsed.data;
  if (ctx.seenIds.has(q.id)) return { ok: false, reason: 'duplicate-id' };

  const fp = questionFingerprint(q);
  if (ctx.seenFingerprints.has(fp)) return { ok: false, reason: 'duplicate-fingerprint' };

  const src = QuestionSource.parse({ origin: 'authored', method: 'authored', ...source });
  const question = normalizeQuestion(q, { source: src, fingerprint: fp });

  ctx.seenIds.add(q.id);
  ctx.seenFingerprints.add(fp);
  return { ok: true, question };
}

export interface BatchIngestReport {
  accepted: NormalizedQuestion[];
  rejected: Array<{ index: number; id?: string; reason: IngestReason; errors?: string[] }>;
  total: number;
}

/** Bir grup ham kaydı sırayla al; kabul/ret özetiyle döner (deterministik). */
export function ingestBatch(
  raws: unknown[],
  source: Partial<QuestionSourceT>,
  ctx: IngestContext = emptyIngestContext()
): BatchIngestReport {
  const accepted: NormalizedQuestion[] = [];
  const rejected: BatchIngestReport['rejected'] = [];
  raws.forEach((raw, index) => {
    const r = ingestQuestion(raw, source, ctx);
    if (r.ok && r.question) accepted.push(r.question);
    else
      rejected.push({
        index,
        id: (raw as { id?: string })?.id,
        reason: r.reason ?? 'schema',
        errors: r.errors,
      });
  });
  return { accepted, rejected, total: raws.length };
}
