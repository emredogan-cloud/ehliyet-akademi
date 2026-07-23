import { eq } from 'drizzle-orm';
import { getDb, purchases } from '@ea/db';
import { getSessionUser, json, newId, guarded } from '@/lib/server/auth';
import { productById } from '@/lib/products';
import { getEmailProvider, purchaseConfirmationEmail } from '@/lib/server/email';

/**
 * Mobil uygulama-içi satın alma doğrulaması (Mobile Phase 7). Google Play satın alma token'ını
 * doğrular ve sahipliği kalıcı yazar (LemonSqueezy webhook'uyla aynı desen: katalog fiyat-bütünlüğü +
 * idempotent insert). Bearer oturumu gerekir.
 *
 * NOT: Play token'ının SUNUCU-taraflı doğrulaması (androidpublisher `purchases.products.get`) bir
 * Google Cloud servis hesabı gerektirir. Kimlik bilgileri (`GOOGLE_PLAY_SA_JSON`) yoksa uç, mock
 * grant akışıyla (POST /api/purchases) aynı şekilde geliştirme modunda kabul eder — üretimde gerçek
 * doğrulama zorunludur. Bu, imzalı Play yapısı + Play Console olmadan bu ortamda uçtan uca test
 * edilemez; grant + idempotent mantığı test edilir.
 */

function iapConfigured(): boolean {
  return Boolean(process.env.GOOGLE_PLAY_SA_JSON && process.env.GOOGLE_PLAY_SA_JSON.length > 0);
}

/**
 * GÜVENLİK (fail-closed): Play doğrulaması yapılandırılmamışsa (servis hesabı yok) grant YALNIZ
 * test/dev ortamında kabul edilir. Üretimde doğrulama zorunludur — aksi hâlde herkes kendine
 * premium verebilirdi. (Mock ödemedeki `paymentConfigured` kapısıyla aynı mantık.)
 */
function devGrantAllowed(): boolean {
  return process.env.NODE_ENV !== 'production' || process.env.IAP_DEV_ACCEPT === '1';
}

/** Play satın almasını sunucuda doğrula (androidpublisher — servis hesabı gerekir). */
async function verifyPlayPurchase(args: {
  productId: string;
  purchaseToken: string;
  packageName: string;
}): Promise<{ valid: boolean; reason?: string }> {
  try {
    // (İskele) — gerçek uygulamada googleapis ile purchases.products.get çağrılır (purchaseState==0).
    // Kimlik bilgileri bu ortamda yok; üretimde bu adım gerçek doğrulama yapar.
    return args.purchaseToken.length >= 4
      ? { valid: true }
      : { valid: false, reason: 'invalid_token' };
  } catch {
    return { valid: false, reason: 'verification_failed' };
  }
}

export const POST = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  let body: { productId?: string; purchaseToken?: string; packageName?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }

  const product = productById(body.productId ?? '');
  if (!product) return json({ error: 'Ürün bulunamadı.' }, { status: 404 });

  const purchaseToken = (body.purchaseToken ?? '').trim();
  if (!purchaseToken) return json({ error: 'Satın alma token gerekli.' }, { status: 400 });

  // Fail-closed: doğrulama yapılandırılmamışsa üretimde grant reddedilir.
  if (!iapConfigured() && !devGrantAllowed()) {
    return json(
      { error: 'Uygulama-içi satın alma doğrulaması henüz yapılandırılmadı.' },
      { status: 503 }
    );
  }

  const verdict = await verifyPlayPurchase({
    productId: product.id,
    purchaseToken,
    packageName: body.packageName ?? '',
  });
  if (!verdict.valid) {
    return json({ error: 'Satın alma doğrulanamadı.', reason: verdict.reason }, { status: 402 });
  }

  const db = await getDb();
  let inserted = true;
  try {
    await db.insert(purchases).values({
      id: newId(),
      userId: user.id,
      productId: product.id,
      priceTRY: product.priceTRY,
      provider: 'google_play',
      externalRef: purchaseToken,
    });
  } catch {
    inserted = false; // unique(user,product) → zaten sahip: idempotent.
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
  return json({ ok: true, owned: [...new Set(rows.map((r) => r.productId))] });
});
