import { getDb } from '@ea/db';
import { json, guarded, requireRole } from '@/lib/server/auth';
import { listReferrals, voidReferral } from '@/lib/server/referrals';

/**
 * Faz 8 — YÖNETİCİ davet yüzeyi.
 *
 * "Admin manageable" şartının karşılığı: davetleri görebilmek ve sahte olanı iptal edebilmek.
 * Ödülleri geri almak BİLİNÇLİ olarak yok — verilmiş bir erişimi geri çekmek iyi niyetli
 * kullanıcıyı da vurabilir ve elle karar gerektirir (bkz. `voidReferral` notu).
 */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const guard = await requireRole(req, 'admin');
  if (guard instanceof Response) return guard;
  const db = await getDb();
  return json({ referrals: await listReferrals(db) });
});

export const POST = guarded(async (req: Request): Promise<Response> => {
  const guard = await requireRole(req, 'admin');
  if (guard instanceof Response) return guard;

  let body: { referralId?: string; reason?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  if (!body.referralId) return json({ error: 'referralId gerekli.' }, { status: 400 });

  const db = await getDb();
  const ok = await voidReferral(db, body.referralId, body.reason ?? 'admin');
  if (!ok) return json({ error: 'Davet bulunamadı.' }, { status: 404 });
  return json({ ok: true });
});
