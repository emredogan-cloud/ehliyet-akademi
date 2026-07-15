/**
 * Çalışma zekâsı (ROADMAP Faz 22/35 · Sprint 3) — kişiselleştirilmiş, KANITA DAYALI rehberlik.
 * Tüm çıktılar platformun KENDİ içeriğinden (dersler + soru bankası + cevap geçmişi + SRS kartları)
 * türetilir; tahmin/halüsinasyon yoktur. Saf ve test edilebilir: girdi olarak cevap/kart alır.
 */
import {
  SUBJECT_LABEL,
  THEORY_SUBJECTS,
  type Subject,
  type TheorySubject,
  type Lesson,
} from '@ea/content-schema';
import { allQuestions, questionById } from '@ea/question-bank';
import {
  statsFromAnswers,
  computeReadiness,
  selectNext,
  isDue,
  type SrsCard,
  type SelectableQuestion,
  type TrafficLight,
} from '@ea/srs-engine';
import { LESSONS } from '@/content/lessons';
import type { AnswerLog } from './progress';

/* ---------- ders ↔ soru/konu indeksleri (bir kez kurulur) ---------- */

const LESSON_BY_QUESTION = new Map<string, Lesson>();
for (const l of LESSONS) {
  for (const qid of [...l.quizQuestionIds, ...l.practiceQuestionIds]) {
    if (!LESSON_BY_QUESTION.has(qid)) LESSON_BY_QUESTION.set(qid, l);
  }
}

/** Bir dersi kapsayan ilk ders (numara sırasına göre). */
export function lessonForSubject(subject: Subject): Lesson | undefined {
  return LESSONS.filter((l) => l.subject === subject).sort((a, b) => a.no - b.no)[0];
}

/** Bir konuya en uygun dersi bul: önce o konudan soruyu referanslayan ders, yoksa ders konusu. */
export function lessonForTopic(topic: string, subject: Subject): Lesson | undefined {
  // Konudan bir soru bul; o soru bir derste geçiyorsa o dersi tercih et.
  const q = allQuestions().find((x) => x.topic === topic && x.subject === subject);
  if (q) {
    const byQ = LESSON_BY_QUESTION.get(q.id);
    if (byQ) return byQ;
  }
  return lessonForSubject(subject);
}

/* ---------- zayıf konular ---------- */

export interface WeakTopic {
  topic: string;
  subject: Subject;
  mastery: number; // 0..1
  answered: number;
  lessonSlug?: string;
  lessonTitle?: string;
}

/**
 * Cevap geçmişinden en zayıf konuları çıkarır (ustalık artan sırada).
 * `minAnswered`: gürültüyü azaltmak için en az bu kadar denenmiş konular sayılır.
 */
export function weakTopics(
  answers: AnswerLog[],
  opts: { minAnswered?: number; limit?: number } = {}
): WeakTopic[] {
  const minAnswered = opts.minAnswered ?? 2;
  const limit = opts.limit ?? 6;
  const byTopic = new Map<string, { subject: Subject; answered: number; correct: number }>();
  for (const a of answers) {
    const cur = byTopic.get(a.topic) ?? { subject: a.subject, answered: 0, correct: 0 };
    cur.answered += 1;
    if (a.correct) cur.correct += 1;
    byTopic.set(a.topic, cur);
  }
  const rows: WeakTopic[] = [];
  for (const [topic, v] of byTopic) {
    if (v.answered < minAnswered) continue;
    const mastery = v.correct / v.answered;
    if (mastery >= 0.85) continue; // ustalaşılmış konuları atla
    const lesson = lessonForTopic(topic, v.subject);
    rows.push({
      topic,
      subject: v.subject,
      mastery,
      answered: v.answered,
      lessonSlug: lesson?.slug,
      lessonTitle: lesson?.title,
    });
  }
  rows.sort((a, b) => a.mastery - b.mastery || b.answered - a.answered);
  return rows.slice(0, limit);
}

/* ---------- kişiselleştirilmiş tekrar seti ---------- */

/** Vadesi gelen kartlar + zayıf konu soruları → adaptif tekrar için soru id listesi. */
export function personalizedReview(
  answers: AnswerLog[],
  cards: Map<string, SrsCard>,
  now: number,
  limit = 10
): string[] {
  const { topicMastery } = statsFromAnswers(answers);
  const pool: SelectableQuestion[] = allQuestions().map((q) => ({
    id: q.id,
    subject: q.subject,
    topic: q.topic,
  }));
  return selectNext(pool, cards, topicMastery, now, limit);
}

/** Şu an vadesi gelmiş kart sayısı. */
export function dueCount(cards: Map<string, SrsCard>, now: number): number {
  let n = 0;
  for (const c of cards.values()) if (isDue(c, now)) n += 1;
  return n;
}

/* ---------- adaptif çalışma planı ---------- */

export type StepKind = 'lesson' | 'practice' | 'review' | 'exam';
export interface StudyStep {
  kind: StepKind;
  title: string;
  detail: string;
  href: string;
  subject?: Subject;
}
export interface StudyPlan {
  summary: string;
  focus: Array<{ subject: TheorySubject; mastery: number }>;
  dueCount: number;
  steps: StudyStep[];
}

const KIND_LABEL: Record<StepKind, string> = {
  lesson: 'Ders',
  practice: 'Alıştırma',
  review: 'Tekrar',
  exam: 'Deneme',
};
export function stepKindLabel(k: StepKind): string {
  return KIND_LABEL[k];
}

/**
 * Verilere göre uyarlanan, sıralı bir çalışma planı üretir:
 * 1) vadesi gelen SRS tekrarları, 2) en zayıf derslerin dersi + alıştırması, 3) deneme sınavı.
 * Yeni kullanıcıya (veri yok) mantıklı bir başlangıç planı verir.
 */
export function buildStudyPlan(
  answers: AnswerLog[],
  cards: Map<string, SrsCard>,
  now: number
): StudyPlan {
  const { subjects } = statsFromAnswers(answers);
  const masteryBySubject = new Map<Subject, number>();
  const answeredBySubject = new Map<Subject, number>();
  for (const s of subjects) {
    masteryBySubject.set(s.subject, s.mastery);
    answeredBySubject.set(s.subject, s.answered);
  }

  // Teorik dersleri ustalık + veri güvenine göre sırala (zayıf/az veri önce).
  const focusAll = THEORY_SUBJECTS.map((subject) => {
    const answered = answeredBySubject.get(subject) ?? 0;
    const mastery = masteryBySubject.get(subject) ?? 0;
    // Öncelik (küçük = önce): kanıtlanmış zayıf ders (düşük ustalık) en acil; hiç çalışılmamış
    // ders orta öncelik (kapsanmamış); çalışılmış-güçlü ders en sona. Böylece aktif başarısızlık
    // öğrenilmemiş dersten önce gelir.
    const priority = answered < 3 ? 0.4 : mastery;
    return { subject, mastery, answered, priority };
  }).sort((a, b) => a.priority - b.priority);

  const due = dueCount(cards, now);
  const steps: StudyStep[] = [];

  // 1) Vadesi gelen tekrar
  if (due > 0) {
    steps.push({
      kind: 'review',
      title: `${due} kart tekrar zamanı`,
      detail: 'Unutmadan önce tekrar et — aralıklı tekrar kalıcılığı artırır.',
      href: '/calis?mod=tekrar',
    });
  }

  // 2) En zayıf iki teorik ders: ders → alıştırma
  for (const f of focusAll.slice(0, 2)) {
    const lesson = lessonForSubject(f.subject);
    const label = SUBJECT_LABEL[f.subject];
    if (lesson) {
      steps.push({
        kind: 'lesson',
        subject: f.subject,
        title: `${label}: ${lesson.title}`,
        detail:
          f.answered < 3
            ? 'Bu derse henüz yeterince çalışmadın — temelden başla.'
            : `Ustalık %${Math.round(f.mastery * 100)} — dersle güçlendir.`,
        href: `/dersler/${lesson.slug}`,
      });
    }
    steps.push({
      kind: 'practice',
      subject: f.subject,
      title: `${label} alıştırması`,
      detail: 'Akıllı çalışma bu dersten zayıf konuları önceliklendirir.',
      href: '/calis',
    });
  }

  // 3) Deneme sınavı (gerçek format)
  steps.push({
    kind: 'exam',
    title: 'Deneme sınavı çöz',
    detail: '50 soru · 45 dk · gerçek dağılım. Hazırlığını ölç.',
    href: '/deneme-sinavi',
  });

  const focus = focusAll.slice(0, 2).map((f) => ({ subject: f.subject, mastery: f.mastery }));
  const totalAnswered = answers.length;
  const summary =
    totalAnswered === 0
      ? 'Henüz veri yok. Kısa bir tanı denemesiyle başla; plan sana göre güncellenecek.'
      : `${SUBJECT_LABEL[focus[0]!.subject]} ve ${SUBJECT_LABEL[focus[1]!.subject]} şu an en çok gelişime açık dersler. Plan bunlara odaklanıyor.`;

  return { summary, focus, dueCount: due, steps };
}

/** Tek cümlelik "sırada ne var" önerisi (panel/AI için). */
export function nextStudySuggestion(
  answers: AnswerLog[],
  cards: Map<string, SrsCard>,
  now: number
): StudyStep {
  const plan = buildStudyPlan(answers, cards, now);
  return plan.steps[0]!;
}

/* ---------- sohbet biçimlendiricileri (grounded, test edilebilir) ---------- */

const DISCLAIMER =
  '\n\n_Bu rehber senin çalışma verilerinden üretilir; resmî kural için MEB/MTSK esastır._';

/** Zayıf konuları sohbet mesajına dönüştürür (kaynak: cevap geçmişin). */
export function formatWeakTopics(weak: WeakTopic[]): string {
  if (weak.length === 0) {
    return 'Henüz zayıf konu çıkaracak kadar veri yok. Kısa bir tanı denemesi veya birkaç alıştırma çöz; sonra en çok gelişime açık konularını buradan gösteririm.';
  }
  const lines = weak.map((w) => {
    const link = w.lessonSlug ? ` → [${w.lessonTitle}](/dersler/${w.lessonSlug})` : '';
    return `- **${w.topic}** (${SUBJECT_LABEL[w.subject]}) — ustalık %${Math.round(w.mastery * 100)}${link}`;
  });
  return `Cevap geçmişine göre en çok gelişime açık konuların:\n\n${lines.join('\n')}${DISCLAIMER}`;
}

/** Çalışma planını sohbet mesajına dönüştürür. */
export function formatStudyPlan(plan: StudyPlan): string {
  const lines = plan.steps.map(
    (s, i) =>
      `${i + 1}. **${stepKindLabel(s.kind)} — ${s.title}**\n   ${s.detail} · [aç](${s.href})`
  );
  return `${plan.summary}\n\n${lines.join('\n')}${DISCLAIMER}`;
}

/* ---------- sınav hazırlığı analizi ---------- */

export interface ReadinessAnalysis {
  overall: number; // 0..100
  light: TrafficLight;
  predictedPassProbability: number; // 0..1
  message: string;
  weakest: WeakTopic[];
}

/** Cevap geçmişinden sınav hazırlığı analizi (ağırlıklı ustalık + en zayıf konular). */
export function examReadinessAnalysis(answers: AnswerLog[]): ReadinessAnalysis {
  const { subjects } = statsFromAnswers(answers);
  const r = computeReadiness(subjects);
  return {
    overall: r.overall,
    light: r.light,
    predictedPassProbability: r.predictedPassProbability,
    message: r.message,
    weakest: weakTopics(answers, { minAnswered: 1, limit: 3 }),
  };
}

/** Sınav hazırlığı analizini sohbet mesajına dönüştürür (grounded). */
export function formatReadinessAnalysis(a: ReadinessAnalysis): string {
  const lightLabel =
    a.light === 'yesil' ? '🟢 Yeşil' : a.light === 'sari' ? '🟡 Sarı' : '🔴 Kırmızı';
  const lines = [
    `**Hazırlık skorun: %${a.overall}** (${lightLabel}) · tahmini geçme olasılığı %${Math.round(a.predictedPassProbability * 100)}.`,
    a.message,
  ];
  if (a.weakest.length) {
    lines.push(
      '\nEn çok gelişime açık konular: ' +
        a.weakest.map((w) => `**${w.topic}** (%${Math.round(w.mastery * 100)})`).join(', ') +
        '.'
    );
  }
  return lines.join('\n') + DISCLAIMER;
}

/** Yanlış cevabın KANITA DAYALI açıklaması — soru açıklaması + çeldirici notu + ders bağlantısı. */
export interface WrongAnswerExplain {
  correct: string;
  explanation: string;
  whyWrong: string[];
  chosenWasCorrect: boolean;
  lessonSlug?: string;
  lessonTitle?: string;
  objective?: string;
}
export function explainWrongAnswer(
  questionId: string,
  chosenIndex: number
): WrongAnswerExplain | null {
  const q = questionById(questionId);
  if (!q) return null;
  const lesson = LESSON_BY_QUESTION.get(q.id) ?? lessonForTopic(q.topic, q.subject);
  return {
    correct: q.options[q.answerIndex] ?? '',
    explanation: q.explanation,
    whyWrong: q.whyWrong ?? [],
    chosenWasCorrect: chosenIndex === q.answerIndex,
    lessonSlug: lesson?.slug,
    lessonTitle: lesson?.title,
    objective: q.objective,
  };
}
