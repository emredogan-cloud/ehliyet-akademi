import { and, eq } from 'drizzle-orm';
import { getDb, purchases } from '@ea/db';
import { getSessionUser, json, newId, guarded } from '@/lib/server/auth';
import { anyProductById, mobileProductKind, storeProductIdOf } from '@/lib/products';
import { getEmailProvider, purchaseConfirmationEmail } from '@/lib/server/email';
import { isPlayVerificationConfigured, verifyPlayPurchase } from '@/lib/server/play-billing';

/**
 * Mobil uygulama-içi satın alma doğrulaması.
 *
 * ## 10 Ağustos 2026 — İSKELE KALDIRILDI
 *
 * Bu uç, dört karakterden uzun HER jetona `valid: true` diyen bir iskele taşıyordu. Üretim
 * yalnızca `GOOGLE_PLAY_SA_JSON` tanımsız olduğu için (uç 503 dönüyordu) güvendeydi; o değişken
 * ayarlandığı anda kimliği doğrulanmış herhangi bir kullanıcı dört karakterlik bir dizeyle kendine
 * ömür boyu premium verebilirdi. Artık doğrulama gerçektir: `lib/server/play-billing.ts` Google'ın
 * Android Publisher v3 API'sini çağırır.
 *
 * ## Fail-closed sözleşmesi
 *
 * · Doğrulama yapılandırılmamış + üretim → **503**. Grant YOK.
 * · Doğrulama yapılandırılmamış + test/geliştirme → yalnız `IAP_DEV_ACCEPT=1` ile grant.
 * · Doğrulama yapılandırılmış → Google'ın cevabı bağlayıcıdır. Ağ hatası bile `valid:false`'tur;
 *   "doğrulayamadım" ile "geçerli" ASLA karıştırılmaz.
 */

/**
 * Doğrulamasız grant YALNIZ test/geliştirmede kabul edilir.
 *
 * `IAP_DEV_ACCEPT=1` kaçış kapısı, üretimde de açılabilecek bir bayraktır; bu yüzden üretimde
 * ayrıca `GOOGLE_PLAY_SA_JSON` yokluğu şartı korunur (aşağıdaki 503 kapısı).
 */
function devGrantAllowed(): boolean {
  return process.env.NODE_ENV !== 'production' || process.env.IAP_DEV_ACCEPT === '1';
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

  const product = anyProductById(body.productId ?? '');
  if (!product) return json({ error: 'Ürün bulunamadı.' }, { status: 404 });

  const purchaseToken = (body.purchaseToken ?? '').trim();
  if (!purchaseToken) return json({ error: 'Satın alma token gerekli.' }, { status: 400 });

  const configured = isPlayVerificationConfigured();

  // Fail-closed: doğrulama yapılandırılmamışsa üretimde grant reddedilir.
  if (!configured && !devGrantAllowed()) {
    return json(
      { error: 'Uygulama-içi satın alma doğrulaması henüz yapılandırılmadı.' },
      { status: 503 }
    );
  }

  /** Abonelikte bitiş anı; tek seferlik üründe `null` (süresiz). */
  let expiresAt: Date | null = null;

  if (configured) {
    // Ürün türü kataloğun kendisinden gelir; istemcinin söylediğine GÜVENİLMEZ. Aksi hâlde
    // istemci bir aboneliği "tek seferlik" diye göstererek süresiz hak talep edebilirdi.
    const kind = mobileProductKind(product.id) ?? 'product';
    const verdict = await verifyPlayPurchase({
      packageName: body.packageName ?? '',
      storeProductId: storeProductIdOf(product.id),
      purchaseToken,
      kind,
    });

    if (!verdict.valid) {
      return json({ error: 'Satın alma doğrulanamadı.', reason: verdict.reason }, { status: 402 });
    }
    expiresAt = verdict.expiresAtMs != null ? new Date(verdict.expiresAtMs) : null;
  }

  const db = await getDb();

  // Idempotent + yenilenebilir: aynı (kullanıcı, ürün) çifti için tek satır tutulur. Abonelik
  // yenilendiğinde satır SİLİNMEZ, bitiş anı İLERİ ALINIR — aksi hâlde yenileme "zaten sahip"
  // sayılıp yeni dönem hiç yazılmazdı.
  const existing = await db
    .select({ id: purchases.id })
    .from(purchases)
    .where(and(eq(purchases.userId, user.id), eq(purchases.productId, product.id)))
    .limit(1);

  const isNew = existing.length === 0;
  if (isNew) {
    await db.insert(purchases).values({
      id: newId(),
      userId: user.id,
      productId: product.id,
      priceTRY: product.priceTRY,
      provider: 'google_play',
      externalRef: purchaseToken,
      expiresAt,
    });
    await getEmailProvider()
      .send(user.email, purchaseConfirmationEmail(product.title, product.priceTRY))
      .catch(() => {});
  } else {
    await db
      .update(purchases)
      .set({ externalRef: purchaseToken, expiresAt })
      .where(and(eq(purchases.userId, user.id), eq(purchases.productId, product.id)));
  }

  // Sahiplik listesi süresi geçmiş abonelikleri İÇERMEZ.
  const now = new Date();
  const rows = await db
    .select({ productId: purchases.productId, expiresAt: purchases.expiresAt })
    .from(purchases)
    .where(eq(purchases.userId, user.id));
  const owned = [
    ...new Set(rows.filter((r) => !r.expiresAt || r.expiresAt > now).map((r) => r.productId)),
  ];

  return json({ ok: true, owned });
});
