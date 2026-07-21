/**
 * QIP 2.0 — İçerik Genişletme · Faz 6 · Tarihsel Sınav Deneyimi.
 *
 * Gerçek MEB e-Sınav oturum TARİHLERİNİ (olgu, `archive.ts`) gezilebilir kılar; her oturum için
 * KOPYALANMIŞ sınav sorularını DEĞİL, o oturumun tarihine göre tohumlanmış ÖZGÜN bir deneme sınavı
 * (dinamik sınav üreticisi) sunar. Etiket açıktır: "MEB formatında hazırlanmış özgün deneme sınavı".
 * Asla resmî sınav kâğıdı ima edilmez.
 */
import { EXAM_BLUEPRINT } from '@ea/content-schema';
import {
  HISTORICAL_SESSIONS,
  sessionsByYear,
  historicalSessionById,
  type HistoricalSession,
} from './archive';
import { buildDynamicExam } from './exam';
import { seedFromDate } from './collections';

/** Kullanıcıya gösterilecek zorunlu etiket. */
export const HISTORICAL_LABEL = 'MEB formatında hazırlanmış özgün deneme sınavı';

export interface HistoricalExamQuestion {
  id: string;
  subject: string;
  stem: string;
  options: string[];
  answerIndex: number;
  explanation: string;
}

export interface HistoricalExam {
  session: HistoricalSession;
  label: string;
  blueprint: typeof EXAM_BLUEPRINT;
  bySubject: Record<string, number>;
  questions: HistoricalExamQuestion[];
}

/** Yıla göre gruplanmış oturum indeksi (liste ekranı). */
export function historicalIndex(): Array<{ year: number; sessions: HistoricalSession[] }> {
  return sessionsByYear();
}

/** Toplam tarihsel oturum sayısı. */
export function historicalSessionCount(): number {
  return HISTORICAL_SESSIONS.length;
}

/**
 * Bir oturum için ÖZGÜN deneme sınavı — oturum tarihine göre tohumlanır (o tarih için hep aynı,
 * tarihler arası farklı), MEB dağılımına (23/12/9/6) uygun, zorluğu dengeli, kavram/görsel tekrarsız.
 */
export function historicalExam(id: string): HistoricalExam | undefined {
  const session = historicalSessionById(id);
  if (!session) return undefined;
  const exam = buildDynamicExam({
    seed: seedFromDate(session.date),
    count: EXAM_BLUEPRINT.totalQuestions,
    difficultyBalance: true,
  });
  return {
    session,
    label: HISTORICAL_LABEL,
    blueprint: EXAM_BLUEPRINT,
    bySubject: exam.bySubject,
    questions: exam.questions.map((q) => ({
      id: q.id,
      subject: q.subject,
      stem: q.stem,
      options: q.options,
      answerIndex: q.answerIndex,
      explanation: q.explanation,
    })),
  };
}
