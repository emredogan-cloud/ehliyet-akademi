/**
 * QIP — Faz 5 · Adaptif Öğrenme (BANK_QUESTİON Part 11).
 *
 * Cevap geçmişinden zayıf konuları çıkarır ve seçimi onlara AĞIRLIKLANDIRIR (zayıf konu → daha çok
 * soru); güçlü konularda tekrarı azaltır. Ailelerden (Faz 3) YENİ varyant sunar — aynı soruyu tekrar
 * etmeden aynı kavramı çalıştırır. Saf/deterministik (seed). Faz 12 analitiği ile aynı girdi tipi.
 */
import { analyzedQuestions, type AnalyzedQuestion } from './index';
import { seededRng, type Rng } from './visual';
import type { AnalyticsAnswer } from './analytics';

function shuffle<T>(arr: T[], rng: Rng): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j]!, a[i]!];
  }
  return a;
}

export interface WeakTopicStat {
  topic: string;
  subject?: string;
  mastery: number; // 0..1
  answered: number;
}

export interface AdaptiveOptions {
  count?: number;
  answers: AnalyticsAnswer[];
  pool?: AnalyzedQuestion[];
  seed?: number;
  /** Daha önce cevaplanmış soruları ele (varsayılan açık) → aynı kavramda YENİ varyant. */
  excludeAnswered?: boolean;
  /** Zayıf konulara ayrılan hedef oran (0..1, varsayılan 0.7). */
  weakFocus?: number;
}

export interface AdaptivePlan {
  questions: AnalyzedQuestion[];
  weakTopics: WeakTopicStat[];
  /** Seçilenlerin zayıf konulara denk gelen oranı (gerçek). */
  focusRatio: number;
}

/** Cevap geçmişinden zayıf konular (ustalık artan sırada). */
export function weakTopicsFrom(answers: AnalyticsAnswer[], minAnswered = 2): WeakTopicStat[] {
  const agg = new Map<string, { a: number; c: number; subject?: string }>();
  for (const l of answers) {
    if (!l.topic) continue;
    const t = agg.get(l.topic) ?? { a: 0, c: 0, subject: l.subject };
    t.a++;
    if (l.correct) t.c++;
    agg.set(l.topic, t);
  }
  return [...agg.entries()]
    .map(([topic, v]) => ({ topic, subject: v.subject, mastery: v.c / v.a, answered: v.a }))
    .filter((w) => w.answered >= minAnswered && w.mastery < 0.85)
    .sort((x, y) => x.mastery - y.mastery || y.answered - x.answered);
}

/** Adaptif soru seti kur. */
export function adaptiveSelect(opts: AdaptiveOptions): AdaptivePlan {
  const count = opts.count ?? 20;
  const rng = seededRng(opts.seed ?? 1);
  const pool = opts.pool ?? analyzedQuestions();
  const excludeAnswered = opts.excludeAnswered ?? true;
  const weakFocus = Math.min(1, Math.max(0, opts.weakFocus ?? 0.7));
  const answered = new Set(opts.answers.map((a) => a.questionId));
  const weak = weakTopicsFrom(opts.answers);

  const used = new Set<string>();
  const chosen: AnalyzedQuestion[] = [];
  const weakTopicSet = new Set(weak.map((w) => w.topic));
  const take = (q: AnalyzedQuestion) => {
    if (!used.has(q.id)) {
      used.add(q.id);
      chosen.push(q);
    }
  };

  // Zayıf konu odağı — her zayıf konudan pay al (en zayıfa daha çok).
  const weakTarget = Math.round(count * weakFocus);
  const topN = weak.slice(0, 5);
  const perTopic = topN.length ? Math.max(1, Math.ceil(weakTarget / topN.length)) : 0;
  for (const w of topN) {
    if (chosen.length >= weakTarget) break;
    const cands = shuffle(
      pool.filter((q) => q.topic === w.topic && (!w.subject || q.subject === w.subject)),
      rng
    );
    let added = 0;
    for (const q of cands) {
      if (added >= perTopic || chosen.length >= weakTarget) break;
      if (excludeAnswered && answered.has(q.id)) continue; // YENİ varyant
      take(q);
      added++;
    }
  }

  // Kalanı keşifle doldur — önce cevaplanmamış, sonra (gerekirse) herhangi.
  const rest = shuffle(pool, rng);
  for (const q of rest) {
    if (chosen.length >= count) break;
    if (used.has(q.id)) continue;
    if (excludeAnswered && answered.has(q.id)) continue;
    take(q);
  }
  for (const q of rest) {
    if (chosen.length >= count) break;
    if (used.has(q.id)) continue;
    take(q);
  }

  const finalQs = chosen.slice(0, count);
  const inWeak = finalQs.filter((q) => weakTopicSet.has(q.topic)).length;
  return {
    questions: finalQs,
    weakTopics: weak.slice(0, 6),
    focusRatio: finalQs.length ? Math.round((inWeak / finalQs.length) * 100) / 100 : 0,
  };
}
