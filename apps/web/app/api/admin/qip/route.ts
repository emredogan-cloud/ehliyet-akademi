import { requireRole, json, guarded } from '@/lib/server/auth';
import { qipIntelligence } from '@/lib/qip';

/**
 * Soru Zekâsı (QIP) özeti — akıllı sınıflandırma + kalite analizi + yineleme tespiti (admin/editor).
 * BANK_QUESTİON Part 4/5/6. Tüm sayılar GERÇEK (bankadan deterministik hesaplanır).
 */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin', 'editor');
  if (user instanceof Response) return user;
  return json({ intelligence: qipIntelligence() });
});
