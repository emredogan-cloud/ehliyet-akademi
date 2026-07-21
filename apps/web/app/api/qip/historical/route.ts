import { guarded, json } from '@/lib/server/auth';
import { historicalIndex, HISTORICAL_LABEL } from '@/lib/qip';

/**
 * Tarihsel sınav indeksi — gerçek MEB oturum tarihleri (olgu), yıla göre gruplu. Her oturum ÖZGÜN
 * bir deneme sınavına açılır (kopya sınav değil). BANK_QUESTİON 2.0 · Faz 6.
 */
export const GET = guarded(async (): Promise<Response> => {
  return json({ label: HISTORICAL_LABEL, years: historicalIndex() });
});
