import { eq } from 'drizzle-orm';
import { getDb, purchases } from '@ea/db';
import { getSessionUser, json, newId, guarded } from '@/lib/server/auth';
import { productById } from '@/lib/products';
import { paymentConfigured } from '@/lib/server/checkout';
import { getEmailProvider, purchaseConfirmationEmail } from '@/lib/server/email';
import { rewardExpiries } from '@/lib/server/referrals';
import { hasActiveReward } from '@/lib/referrals';

/** Davet ödülünün açtığı ürün — katalogdaki tek premium paket. */
const REFERRAL_REWARD_PRODUCT_ID = 'komple-ehliyet';

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

  // Faz 8 — ETKİN davet ödülü sahipliğe eklenir.
  //
  // Ödül `purchases` tablosuna YAZILMAZ: orada süre kavramı yok (ömür boyu tek ürün) ve süresi
  // dolmuş bir ödül orada kalıcı bir satın alma gibi görünürdü. Bunun yerine sahiplik burada
  // TÜRETİLİR; süre dolduğu an erişim kendiliğinden kapanır. Mobil taraf tek satır değişmeden
  // premium görür — sahiplik zaten bu uçtan okunuyor.
  const now = new Date();
  const expiries = await rewardExpiries(db, user.id);
  const owned = rows.map((r) => r.productId);
  if (hasActiveReward(expiries, now) && !owned.includes(REFERRAL_REWARD_PRODUCT_ID)) {
    const active = expiries.filter((e) => e > now).sort((a, b) => b.getTime() - a.getTime());
    rows.push({ productId: REFERRAL_REWARD_PRODUCT_ID, priceTRY: 0, at: active[0]! });
  }
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

  // GÜVENLİK (LCP): gerçek ödeme sağlayıcısı yapılandırıldığında doğrudan grant KAPALIDIR —
  // sahiplik yalnız ödeme webhook'u ile yazılır. Mock modda (yerel/dev/e2e) eski akış korunur.
  if (paymentConfigured()) {
    return json(
      { error: 'Gerçek ödeme aktif — satın alma, ödeme sayfası üzerinden yapılır.' },
      { status: 409 }
    );
  }

  let body: { productId?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const product = productById(body.productId ?? '');
  if (!product) return json({ error: 'Ürün bulunamadı.' }, { status: 404 });

  const db = await getDb();
  let inserted = true;
  try {
    await db.insert(purchases).values({
      id: newId(),
      userId: user.id,
      productId: product.id,
      priceTRY: product.priceTRY,
      provider: 'mock',
    });
  } catch {
    inserted = false; // unique(user,product) — zaten sahip: idempotent davran.
  }
  if (inserted) {
    await getEmailProvider()
      .send(user.email, purchaseConfirmationEmail(product.title, product.priceTRY))
      .catch(() => {});
  }
  const rows = await db
    .select({ productId: purchases.productId })
    .from(purchases)
    .where(eq(purchases.userId, user.id));
  return json({ ok: true, owned: rows.map((r) => r.productId) });
});
