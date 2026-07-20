import { guarded, json } from '@/lib/server/auth';
import { examCollections, seedFromDate, seedFromWeek, normalizedById } from '@/lib/qip';

/**
 * Otomatik sınav koleksiyonları — halka açık katalog (BANK_QUESTİON Part 16). Günün/haftanın tohumu
 * sunucu tarihinden türetilir → gün içinde sabit, günden güne farklı. Yalnız halka açık içerik.
 */
export const GET = guarded(async (): Promise<Response> => {
  const today = new Date().toISOString().slice(0, 10);
  const cols = examCollections({
    daySeed: seedFromDate(today),
    weekSeed: seedFromWeek(today),
  });
  return json({
    date: today,
    collections: cols.map((c) => ({
      id: c.id,
      label: c.label,
      description: c.description,
      emoji: c.emoji,
      count: c.count,
      sample: c.questionIds.slice(0, 3).map((id) => {
        const q = normalizedById(id);
        return { id, stem: q?.stem ?? id };
      }),
    })),
  });
});
