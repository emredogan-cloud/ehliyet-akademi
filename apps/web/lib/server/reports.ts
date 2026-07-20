/**
 * QIP — Faz 6 · Soru Bildirimi servis katmanı (BANK_QUESTİON Part 13 — topluluk incelemesi).
 * Kullanıcılar hata/belirsizlik/yanlış cevap bildirir; admin moderasyon kuyruğunda çözer/reddeder.
 */
import { desc, eq } from 'drizzle-orm';
import { getDb, questionReports } from '@ea/db';
import { newId } from './auth';

export const REPORT_KINDS = ['wrong-answer', 'unclear', 'typo', 'suggestion', 'other'] as const;
export type ReportKind = (typeof REPORT_KINDS)[number];
export const REPORT_STATUSES = ['open', 'resolved', 'dismissed'] as const;
export type ReportStatus = (typeof REPORT_STATUSES)[number];

export interface QuestionReport {
  id: string;
  questionId: string;
  kind: string;
  message: string;
  userId: string | null;
  status: string;
  createdAt: Date;
}

export function isReportKind(x: unknown): x is ReportKind {
  return typeof x === 'string' && (REPORT_KINDS as readonly string[]).includes(x);
}
export function isReportStatus(x: unknown): x is ReportStatus {
  return typeof x === 'string' && (REPORT_STATUSES as readonly string[]).includes(x);
}

/** Bir bildirim oluştur. Girdi çağıran (route) tarafından doğrulanmalı. */
export async function createReport(input: {
  questionId: string;
  kind: ReportKind;
  message?: string;
  userId?: string | null;
}): Promise<{ id: string }> {
  const db = await getDb();
  const id = newId();
  await db.insert(questionReports).values({
    id,
    questionId: input.questionId,
    kind: input.kind,
    message: (input.message ?? '').slice(0, 1000),
    userId: input.userId ?? null,
  });
  return { id };
}

/** Bildirimleri listele (opsiyonel durum filtresi), en yeni önce. */
export async function listReports(status?: ReportStatus): Promise<QuestionReport[]> {
  const db = await getDb();
  const rows = status
    ? await db
        .select()
        .from(questionReports)
        .where(eq(questionReports.status, status))
        .orderBy(desc(questionReports.createdAt))
    : await db.select().from(questionReports).orderBy(desc(questionReports.createdAt));
  return rows as QuestionReport[];
}

/** Bir bildirimin durumunu güncelle (çöz/reddet). */
export async function updateReportStatus(id: string, status: ReportStatus): Promise<boolean> {
  const db = await getDb();
  await db.update(questionReports).set({ status }).where(eq(questionReports.id, id));
  return true;
}

/** Açık bildirim sayısı (moderasyon rozeti). */
export async function openReportCount(): Promise<number> {
  return (await listReports('open')).length;
}
