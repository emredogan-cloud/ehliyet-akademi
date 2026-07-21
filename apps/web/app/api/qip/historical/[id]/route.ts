import { guarded, json } from '@/lib/server/auth';
import { historicalExam } from '@/lib/qip';

/**
 * Bir oturum için ÖZGÜN deneme sınavı (tarihe göre tohumlu, MEB formatı). Kopyalanan sınav sorusu
 * DEĞİL — her soru bankamızın özgün içeriğidir. BANK_QUESTİON 2.0 · Faz 6.
 */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const parts = new URL(req.url).pathname.split('/');
  const id = decodeURIComponent(parts[parts.length - 1] ?? '');
  const exam = historicalExam(id);
  if (!exam) return json({ error: 'oturum bulunamadı' }, { status: 404 });
  return json(exam);
});
