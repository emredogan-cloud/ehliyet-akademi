/**
 * @ea/question-bank — özgün soru bankası + erişim yardımcıları.
 * ROADMAP Faz 11/12. İçerik hukuku: C.4/E.6 (özgün; kopya yasak).
 *
 * Sprint 3: banka konu başına genişletildi (145 yeni özgün soru). Ham kayıtlar YÜKLENİRKEN
 * Zod ile parse edilir → varsayılanlar (whyWrong/tags) dolar ve bozuk içerik anında yakalanır.
 */
import {
  parseQuestion,
  validateBank,
  type Question,
  type QuestionInput,
  type Subject,
} from '@ea/content-schema';
import { SEED_QUESTIONS } from './questions';
import { EXTRA_QUESTIONS } from './questions-2';
import { TRAFIK_QUESTIONS } from './questions-trafik';
import { TRAFIK_QUESTIONS_2 } from './questions-trafik-2';
import { TRAFIK_QUESTIONS_4 } from './questions-trafik-4';
import { TRAFIK_QUESTIONS_5 } from './questions-trafik-5';
import { TRAFIK_QUESTIONS_6 } from './questions-trafik-6';
import { TRAFIK_QUESTIONS_7 } from './questions-trafik-7';
import { ILKYARDIM_QUESTIONS } from './questions-ilkyardim';
import { ILKYARDIM_QUESTIONS_2 } from './questions-ilkyardim-2';
import { ILKYARDIM_QUESTIONS_3 } from './questions-ilkyardim-3';
import { ILKYARDIM_QUESTIONS_4 } from './questions-ilkyardim-4';
import { ILKYARDIM_QUESTIONS_5 } from './questions-ilkyardim-5';
import { ILKYARDIM_QUESTIONS_6 } from './questions-ilkyardim-6';
import { ILKYARDIM_QUESTIONS_7 } from './questions-ilkyardim-7';
import { MOTOR_QUESTIONS } from './questions-motor';
import { MOTOR_QUESTIONS_2 } from './questions-motor-2';
import { MOTOR_QUESTIONS_3 } from './questions-motor-3';
import { MOTOR_QUESTIONS_4 } from './questions-motor-4';
import { MOTOR_QUESTIONS_5 } from './questions-motor-5';
import { MOTOR_QUESTIONS_6 } from './questions-motor-6';
import { MOTOR_QUESTIONS_7 } from './questions-motor-7';
import { ADAB_QUESTIONS } from './questions-adab';
import { ADAB_QUESTIONS_2 } from './questions-adab-2';
import { ADAB_QUESTIONS_3 } from './questions-adab-3';
import { ADAB_QUESTIONS_4 } from './questions-adab-4';
import { ADAB_QUESTIONS_5 } from './questions-adab-5';
import { ADAB_QUESTIONS_6 } from './questions-adab-6';
import { ADAB_QUESTIONS_7 } from './questions-adab-7';
import { PRATIK_QUESTIONS } from './questions-pratik';
import { PRATIK_QUESTIONS_2 } from './questions-pratik-2';
import { PRATIK_QUESTIONS_3 } from './questions-pratik-3';
import { PRATIK_QUESTIONS_4 } from './questions-pratik-4';
import { PRATIK_QUESTIONS_5 } from './questions-pratik-5';
import { PRATIK_QUESTIONS_6 } from './questions-pratik-6';
import { PRATIK_QUESTIONS_7 } from './questions-pratik-7';

export { SEED_QUESTIONS, EXTRA_QUESTIONS };

/** Ham kayıtlar (seed + genişletmeler). İleride CMS/DB ile birleşir. */
const RAW: QuestionInput[] = [
  ...SEED_QUESTIONS,
  ...EXTRA_QUESTIONS,
  ...TRAFIK_QUESTIONS,
  ...TRAFIK_QUESTIONS_2,
  ...TRAFIK_QUESTIONS_4,
  ...TRAFIK_QUESTIONS_5,
  ...TRAFIK_QUESTIONS_6,
  ...TRAFIK_QUESTIONS_7,
  ...ILKYARDIM_QUESTIONS,
  ...ILKYARDIM_QUESTIONS_2,
  ...ILKYARDIM_QUESTIONS_3,
  ...ILKYARDIM_QUESTIONS_4,
  ...ILKYARDIM_QUESTIONS_5,
  ...ILKYARDIM_QUESTIONS_6,
  ...ILKYARDIM_QUESTIONS_7,
  ...MOTOR_QUESTIONS,
  ...MOTOR_QUESTIONS_2,
  ...MOTOR_QUESTIONS_3,
  ...MOTOR_QUESTIONS_4,
  ...MOTOR_QUESTIONS_5,
  ...MOTOR_QUESTIONS_6,
  ...MOTOR_QUESTIONS_7,
  ...ADAB_QUESTIONS,
  ...ADAB_QUESTIONS_2,
  ...ADAB_QUESTIONS_3,
  ...ADAB_QUESTIONS_4,
  ...ADAB_QUESTIONS_5,
  ...ADAB_QUESTIONS_6,
  ...ADAB_QUESTIONS_7,
  ...PRATIK_QUESTIONS,
  ...PRATIK_QUESTIONS_2,
  ...PRATIK_QUESTIONS_3,
  ...PRATIK_QUESTIONS_4,
  ...PRATIK_QUESTIONS_5,
  ...PRATIK_QUESTIONS_6,
  ...PRATIK_QUESTIONS_7,
];

/** Doğrulanmış, varsayılanları dolu banka (yükleme anında parse — bozuk içerik build'i kırar). */
const BANK: Question[] = RAW.map(parseQuestion);

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

/** Konu bazlı adet dağılımı (Sprint 3 kapsama raporu için). */
export function topicCounts(): Record<string, number> {
  const out: Record<string, number> = {};
  for (const q of BANK) out[q.topic] = (out[q.topic] ?? 0) + 1;
  return out;
}

/** Bankanın bütünlük doğrulaması — testte ve CI verify'de kullanılır. */
export function verifyBank() {
  return validateBank(RAW);
}
