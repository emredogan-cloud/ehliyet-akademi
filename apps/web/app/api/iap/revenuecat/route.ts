import { createHmac, timingSafeEqual } from 'node:crypto';
import { eq } from 'drizzle-orm';
import { getDb, purchases, users } from '@ea/db';
import { json, newId, guarded } from '@/lib/server/auth';
import { anyProductById } from '@/lib/products';

/**
 * RevenueCat webhook — **sunucu köprüsü** (Beta Faz 3 kararının kapanışı).
 *
 * NEDEN AYRI BİR UÇ: RevenueCat Flutter SDK'sı ham Play `purchaseToken`'ını **sunmaz**
 * (`StoreTransaction` yalnız `transactionIdentifier` taşır). Bu yüzden RevenueCat yolu mevcut
 * `POST /api/iap/validate` ucunu **yeniden kullanamaz**; doğru köprü webhook'tur
 * (RevenueCat → sunucumuz). Bu, `BillingServerBridge.revenueCatWebhook` ile kodda da açıkça
 * bildirilmişti; bu dosya o sözün karşılığıdır.
 *
 * GÜVENLİK — fail-closed: `REVENUECAT_WEBHOOK_SECRET` ayarlı DEĞİLSE uç hiçbir şey yazmaz ve
 * 503 döner. Aksi hâlde internetteki herkes bu uca POST atıp kendine premium verebilirdi.
 *
 * DOĞRULAMA: RevenueCat, panoda tanımlanan değeri `Authorization` başlığında **olduğu gibi**
 * gönderir. İki biçim de kabul edilir:
 *   · düz paylaşılan sır (`Authorization: <secret>` veya `Bearer <secret>`),
 *   · HMAC-SHA256 imzası (`Authorization: sha256=<hex>`) — gövde üzerinden hesaplanır.
 * Karşılaştırma **sabit zamanlıdır** (`timingSafeEqual`); uzunluk farkı bile sızıntı olmasın diye
 * önce uzunluk eşitlenir.
 *
 * IDEMPOTENT: aynı olay iki kez gelirse ikinci yazma `unique(user, product)` kısıtına takılır ve
 * sessizce yutulur — RevenueCat tekrar denemeleri kopya sahiplik üretmez.
 */

function configured(): boolean {
  return Boolean(process.env.REVENUECAT_WEBHOOK_SECRET);
}

/** Sabit zamanlı dize karşılaştırması. */
function safeEqual(a: string, b: string): boolean {
  const ab = Buffer.from(a);
  const bb = Buffer.from(b);
  if (ab.length !== bb.length) return false;
  return timingSafeEqual(ab, bb);
}

function authorized(req: Request, raw: string): boolean {
  const secret = process.env.REVENUECAT_WEBHOOK_SECRET ?? '';
  if (!secret) return false;
  const header = (req.headers.get('authorization') ?? '').trim();
  if (!header) return false;

  if (header.startsWith('sha256=')) {
    const digest = createHmac('sha256', secret).update(raw).digest('hex');
    return safeEqual(header.slice(7), digest);
  }
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : header;
  return safeEqual(token, secret);
}

/**
 * Sahiplik ÜRETEN olay türleri.
 *
 * `CANCELLATION` ve `EXPIRATION` bilinçli olarak **listede yoktur**: bu ürün modelinde sahiplik
 * kalıcıdır (ömür boyu paket) ve iptal geçmiş satın almayı geri almaz. İleride gerçek abonelik
 * iptali uygulanacaksa burası tek değişiklik noktasıdır.
 */
const GRANTING = new Set([
  'INITIAL_PURCHASE',
  'NON_RENEWING_PURCHASE',
  'RENEWAL',
  'PRODUCT_CHANGE',
  'UNCANCELLATION',
]);

type RcEvent = {
  type?: string;
  app_user_id?: string;
  product_id?: string;
  transaction_id?: string;
  original_transaction_id?: string;
};

export const POST = guarded(async (req: Request): Promise<Response> => {
  // Gövde HAM olarak okunur: HMAC, ayrıştırılmış nesneden değil, gelen baytlardan hesaplanır.
  const raw = await req.text();

  if (!configured()) {
    return json({ error: 'RevenueCat webhook yapılandırılmadı.' }, { status: 503 });
  }
  if (!authorized(req, raw)) {
    return json({ error: 'Yetkisiz.' }, { status: 401 });
  }

  let body: { event?: RcEvent };
  try {
    body = JSON.parse(raw) as { event?: RcEvent };
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }

  const event = body.event ?? {};
  const type = (event.type ?? '').toUpperCase();
  // Bilinmeyen/ilgisiz olaylar 200 döner: RevenueCat 2xx almazsa saatlerce yeniden dener.
  if (!GRANTING.has(type)) return json({ ok: true, ignored: type || 'unknown' });

  const product = anyProductById(event.product_id ?? '');
  if (!product) return json({ ok: true, ignored: 'unknown_product' });

  // `app_user_id` uygulamanın RevenueCat'e verdiği kimliktir = bizim kullanıcı kimliğimiz.
  const appUserId = (event.app_user_id ?? '').trim();
  if (!appUserId) return json({ ok: true, ignored: 'no_app_user_id' });

  const db = await getDb();
  const found = await db.select({ id: users.id }).from(users).where(eq(users.id, appUserId));
  // Anonim RevenueCat kimliği (`$RCAnonymousID:…`) bizde bir kullanıcıya karşılık gelmez.
  if (found.length === 0) return json({ ok: true, ignored: 'unknown_user' });

  try {
    await db.insert(purchases).values({
      id: newId(),
      userId: appUserId,
      productId: product.id,
      priceTRY: product.priceTRY,
      provider: 'revenuecat',
      externalRef: event.transaction_id ?? event.original_transaction_id ?? 'rc',
    });
  } catch {
    // unique(user, product) → zaten sahip. Tekrar denemeler kopya üretmez.
  }

  return json({ ok: true, granted: product.id });
});
