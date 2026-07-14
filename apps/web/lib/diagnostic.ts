/**
 * Tanı denemesi soru seçimi (aktivasyon anı — ROADMAP Faz 6/8).
 * Deterministik ve dengeli: e-Sınav dağılımına (23/12/9/6) orantılı, banka elverdiğince.
 * Deterministik olması SSG + hidrasyon tutarlılığı için önemlidir.
 */
import { EXAM_BLUEPRINT, THEORY_SUBJECTS, type Question, type Subject } from '@ea/content-schema';
import { allQuestions } from '@ea/question-bank';

/** Tanı için, dağılıma orantılı ~`size` teorik soru seç (deterministik). */
export function pickDiagnostic(size = 8, pool: Question[] = allQuestions()): Question[] {
  const dist = EXAM_BLUEPRINT.distribution;
  const out: Question[] = [];
  for (const subject of THEORY_SUBJECTS) {
    const weight = dist[subject] / EXAM_BLUEPRINT.totalQuestions;
    const want = Math.max(1, Math.round(size * weight));
    const available = pool.filter((q) => q.subject === subject);
    out.push(...available.slice(0, want));
  }
  return out.slice(0, size);
}

/** Bir cevap kaydı (client → readiness hesaplaması). */
export interface AnswerRecord {
  questionId: string;
  subject: Subject;
  topic: string;
  correct: boolean;
}
