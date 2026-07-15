/**
 * e-Sınav oluşturucu (ROADMAP Faz 13) — gerçek MEB formatı:
 * 50 soru · 45 dk · dağılım 23/12/9/6 · baraj 35 doğru.
 * rng enjekte edilebilir (deterministik test için).
 */
import { EXAM_BLUEPRINT, THEORY_SUBJECTS, type Question } from '@ea/content-schema';
import { allQuestions } from '@ea/question-bank';

export type Rng = () => number;

/** Fisher–Yates (rng enjekteli, saf). */
export function shuffle<T>(arr: T[], rng: Rng): T[] {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    const tmp = a[i]!;
    a[i] = a[j]!;
    a[j] = tmp;
  }
  return a;
}

export interface BuiltExam {
  questions: Question[];
  /** Banka her dersi tam karşılıyorsa true (aksi hâlde oransal küçültülmüş). */
  fullBlueprint: boolean;
  durationSeconds: number;
  passCorrect: number;
}

/**
 * Dağılıma birebir uyan sınav kur. Banka bir derste yetersizse o dersten
 * eldeki kadar alınır ve `fullBlueprint=false` işaretlenir (dürüst etiketleme).
 */
export function buildExam(rng: Rng = Math.random, pool: Question[] = allQuestions()): BuiltExam {
  const dist = EXAM_BLUEPRINT.distribution;
  const out: Question[] = [];
  let full = true;
  for (const subject of THEORY_SUBJECTS) {
    const want = dist[subject];
    const avail = shuffle(
      pool.filter((q) => q.subject === subject),
      rng
    );
    if (avail.length < want) full = false;
    out.push(...avail.slice(0, want));
  }
  const scale = out.length / EXAM_BLUEPRINT.totalQuestions;
  return {
    questions: shuffle(out, rng),
    fullBlueprint: full,
    durationSeconds: EXAM_BLUEPRINT.durationMinutes * 60,
    passCorrect: full ? EXAM_BLUEPRINT.passCorrect : Math.ceil(EXAM_BLUEPRINT.passCorrect * scale),
  };
}

export interface ExamResult {
  correct: number;
  total: number;
  passed: boolean;
  perSubject: Array<{ subject: string; correct: number; total: number }>;
}

export function scoreExam(
  questions: Question[],
  answers: Array<number | null>,
  passCorrect: number
): ExamResult {
  let correct = 0;
  const bySubject = new Map<string, { correct: number; total: number }>();
  questions.forEach((q, i) => {
    const s = bySubject.get(q.subject) ?? { correct: 0, total: 0 };
    s.total += 1;
    if (answers[i] === q.answerIndex) {
      correct += 1;
      s.correct += 1;
    }
    bySubject.set(q.subject, s);
  });
  return {
    correct,
    total: questions.length,
    passed: correct >= passCorrect,
    perSubject: [...bySubject.entries()].map(([subject, v]) => ({ subject, ...v })),
  };
}
