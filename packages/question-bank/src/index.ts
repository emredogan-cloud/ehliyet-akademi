/**
 * @ea/question-bank — özgün soru bankası + erişim yardımcıları.
 * ROADMAP Faz 11/12. İçerik hukuku: C.4/E.6 (özgün; kopya yasak).
 */
import { type Question, type Subject, validateBank } from '@ea/content-schema';
import { SEED_QUESTIONS } from './questions';
import { EXTRA_QUESTIONS } from './questions-2';

export { SEED_QUESTIONS, EXTRA_QUESTIONS };

/** Birleşik banka (seed + genişletme; ileride CMS/DB ile birleşir). */
const BANK: Question[] = [...SEED_QUESTIONS, ...EXTRA_QUESTIONS];

/** Tüm banka. */
export function allQuestions(): Question[] {
  return BANK;
}

export function questionById(id: string): Question | undefined {
  return BANK.find((q) => q.id === id);
}

export function questionsBySubject(subject: Subject): Question[] {
  return BANK.filter((q) => q.subject === subject);
}

/** Ders bazlı adet dağılımı (kapsama kontrolü için). */
export function subjectCounts(): Record<string, number> {
  const out: Record<string, number> = {};
  for (const q of BANK) out[q.subject] = (out[q.subject] ?? 0) + 1;
  return out;
}

/** Bankanın bütünlük doğrulaması — testte ve CI verify'de kullanılır. */
export function verifyBank() {
  return validateBank(BANK);
}
