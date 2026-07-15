import { eq } from 'drizzle-orm';
import { getDb, purchases } from '@ea/db';
import { getSessionUser, json, newId, guarded } from '@/lib/server/auth';
import { productById } from '@/lib/products';

/** Sahiplik listesi (restore purchases — Epic 3). */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });
  const db = await getDb();
  const rows = await db
    .select({
      productId: purchases.productId,
      priceTRY: purchases.priceTRY,
      at: purchases.createdAt,
    })
    .from(purchases)
    .where(eq(purchases.userId, user.id));
  return json({ purchases: rows });
});

/**
 * Tek-seferlik satın alma (sunucu-taraflı sahiplik).
 * Şu an mock sağlayıcı: fiyat kataloğu SUNUCUDA doğrulanır (fiyat-bütünlüğü kuralı) ve
 * sahiplik kalıcı yazılır. Gerçek sağlayıcıda bu uç, webhook doğrulamasıyla beslenecek.
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  let body: { productId?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const product = productById(body.productId ?? '');
  if (!product) return json({ error: 'Ürün bulunamadı.' }, { status: 404 });

  const db = await getDb();
  try {
    await db.insert(purchases).values({
      id: newId(),
      userId: user.id,
      productId: product.id,
      priceTRY: product.priceTRY,
      provider: 'mock',
    });
  } catch {
    // unique(user,product) — zaten sahip: idempotent davran.
  }
  const rows = await db
    .select({ productId: purchases.productId })
    .from(purchases)
    .where(eq(purchases.userId, user.id));
  return json({ ok: true, owned: rows.map((r) => r.productId) });
});
