/**
 * @ea/question-bank — özgün soru bankası + erişim yardımcıları.
 * ROADMAP Faz 11/12. İçerik hukuku: C.4/E.6 (özgün; kopya yasak).
 */
import { type Question, type Subject, validateBank } from '@ea/content-schema';
import { SEED_QUESTIONS } from './questions';

export { SEED_QUESTIONS };

/** Tüm banka (şu an seed; ileride CMS/DB ile birleşir). */
export function allQuestions(): Question[] {
  return SEED_QUESTIONS;
}

export function questionById(id: string): Question | undefined {
  return SEED_QUESTIONS.find((q) => q.id === id);
}

export function questionsBySubject(subject: Subject): Question[] {
  return SEED_QUESTIONS.filter((q) => q.subject === subject);
}

/** Ders bazlı adet dağılımı (kapsama kontrolü için). */
export function subjectCounts(): Record<string, number> {
  const out: Record<string, number> = {};
  for (const q of SEED_QUESTIONS) out[q.subject] = (out[q.subject] ?? 0) + 1;
  return out;
}

/** Bankanın bütünlük doğrulaması — testte ve CI verify'de kullanılır. */
export function verifyBank() {
  return validateBank(SEED_QUESTIONS);
}
