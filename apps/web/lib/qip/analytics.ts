/**
 * QIP — Faz 5 · Soru Analitiği (BANK_QUESTİON Part 12).
 *
 * Cevap kayıtlarından soru-düzeyi metrikler: doğru/yanlış oranı, deneme (popülerlik), ortalama süre
 * ve en çok seçilen yanlış şık. Saf/deterministik. NOT: mevcut `AnswerLog` yalnız doğruluk+zaman
 * damgası tutar; `avgTimeMs` ve `mostChosenWrongIndex` yalnız kayıtta `timeMs`/`chosenIndex` VARSA
 * hesaplanır (ileriye dönük uyumlu) — yoksa dürüstçe atlanır (uydurma yok).
 */

/** Analitik girdisi — AnswerLog ile uyumlu, opsiyonel zenginleştirme alanları. */
export interface AnalyticsAnswer {
  questionId: string;
  subject?: string;
  topic?: string;
  correct: boolean;
  at?: number;
  /** Kullanıcının seçtiği şık indeksi (varsa → en-çok-seçilen-yanlış). */
  chosenIndex?: number;
  /** Soruya harcanan süre (ms) (varsa → ortalama süre). */
  timeMs?: number;
}

export interface QuestionAnalytics {
  questionId: string;
  attempts: number;
  correct: number;
  wrong: number;
  correctRate: number; // 0..1
  wrongRate: number; // 0..1
  avgTimeMs?: number;
  mostChosenWrongIndex?: number;
}

/** Soru-düzeyi analitik (deneme sırasına göre kararlı). */
export function questionAnalytics(logs: AnalyticsAnswer[]): QuestionAnalytics[] {
  const byQ = new Map<
    string,
    {
      attempts: number;
      correct: number;
      timeSum: number;
      timeCount: number;
      wrongChoices: Map<number, number>;
    }
  >();
  for (const l of logs) {
    const cur = byQ.get(l.questionId) ?? {
      attempts: 0,
      correct: 0,
      timeSum: 0,
      timeCount: 0,
      wrongChoices: new Map<number, number>(),
    };
    cur.attempts++;
    if (l.correct) cur.correct++;
    if (typeof l.timeMs === 'number' && l.timeMs >= 0) {
      cur.timeSum += l.timeMs;
      cur.timeCount++;
    }
    if (!l.correct && typeof l.chosenIndex === 'number') {
      cur.wrongChoices.set(l.chosenIndex, (cur.wrongChoices.get(l.chosenIndex) ?? 0) + 1);
    }
    byQ.set(l.questionId, cur);
  }
  const out: QuestionAnalytics[] = [];
  for (const [questionId, v] of byQ) {
    const wrong = v.attempts - v.correct;
    let mostChosenWrongIndex: number | undefined;
    let best = 0;
    for (const [idx, c] of v.wrongChoices) {
      if (c > best) {
        best = c;
        mostChosenWrongIndex = idx;
      }
    }
    out.push({
      questionId,
      attempts: v.attempts,
      correct: v.correct,
      wrong,
      correctRate: v.attempts ? v.correct / v.attempts : 0,
      wrongRate: v.attempts ? wrong / v.attempts : 0,
      avgTimeMs: v.timeCount ? Math.round(v.timeSum / v.timeCount) : undefined,
      mostChosenWrongIndex,
    });
  }
  return out;
}

export interface AnalyticsSummary {
  totalAnswers: number;
  uniqueQuestions: number;
  overallCorrectRate: number;
  /** Konu → ustalık (doğru oranı). */
  masteryByTopic: Record<string, number>;
  /** En düşük doğru oranlı sorular (en az 3 deneme). */
  hardest: Array<{ questionId: string; correctRate: number; attempts: number }>;
  /** Süre/şık verisi var mı (dürüst kapsam işareti). */
  hasTiming: boolean;
  hasChoiceData: boolean;
}

/** Banka geneli analitik özeti — GERÇEK sayılar (pano/rapor/testler). */
export function analyticsSummary(logs: AnalyticsAnswer[]): AnalyticsSummary {
  const perQ = questionAnalytics(logs);
  const totalAnswers = logs.length;
  const correct = logs.filter((l) => l.correct).length;
  const topicAgg = new Map<string, { a: number; c: number }>();
  for (const l of logs) {
    if (!l.topic) continue;
    const t = topicAgg.get(l.topic) ?? { a: 0, c: 0 };
    t.a++;
    if (l.correct) t.c++;
    topicAgg.set(l.topic, t);
  }
  const masteryByTopic: Record<string, number> = {};
  for (const [topic, v] of topicAgg) masteryByTopic[topic] = Math.round((v.c / v.a) * 100) / 100;

  const hardest = perQ
    .filter((q) => q.attempts >= 3)
    .sort((a, b) => a.correctRate - b.correctRate)
    .slice(0, 10)
    .map((q) => ({ questionId: q.questionId, correctRate: q.correctRate, attempts: q.attempts }));

  return {
    totalAnswers,
    uniqueQuestions: perQ.length,
    overallCorrectRate: totalAnswers ? Math.round((correct / totalAnswers) * 1000) / 1000 : 0,
    masteryByTopic,
    hardest,
    hasTiming: logs.some((l) => typeof l.timeMs === 'number'),
    hasChoiceData: logs.some((l) => typeof l.chosenIndex === 'number'),
  };
}
