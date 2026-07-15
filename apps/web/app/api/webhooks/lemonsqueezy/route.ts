import { eq } from 'drizzle-orm';
import { getDb, purchases, users } from '@ea/db';
import { json, newId } from '@/lib/server/auth';
import { getPaymentGateway, validateReceipt } from '@/lib/server/checkout';
import { getEmailProvider, purchaseConfirmationEmail } from '@/lib/server/email';
import { logger } from '@/lib/server/logger';

/**
 * Ödeme webhook'u (Sprint 4). HAM gövde imza doğrulaması (HMAC) → makbuz doğrulaması →
 * idempotent sahiplik yazımı (external_ref) → onay e-postası. Tanınmayan olay 200 (yok say).
 * guarded() KULLANMAZ: ham gövde ve DB hatasını burada ele alır.
 */
export async function POST(req: Request): Promise<Response> {
  const raw = await req.text();
  const sig = req.headers.get('x-signature');
  const gw = getPaymentGateway();

  if (!gw.verifySignature(raw, sig)) {
    logger.warn('webhook_bad_signature', { provider: gw.name });
    return json({ error: 'invalid signature' }, { status: 401 });
  }

  const order = gw.parseOrder(raw);
  if (!order) return json({ ok: true, ignored: true }); // ilgisiz/tanınmayan olay

  const check = validateReceipt(order);
  if (!check.valid || !check.product) {
    logger.warn('webhook_invalid_receipt', { reason: check.reason, order: order.orderId });
    return json({ error: 'invalid receipt' }, { status: 400 });
  }

  try {
    const db = await getDb();
    // İdempotent: aynı sipariş daha önce işlendiyse yeniden yazma.
    if (order.orderId) {
      const seen = await db
        .select({ id: purchases.id })
        .from(purchases)
        .where(eq(purchases.externalRef, order.orderId));
      if (seen.length > 0) return json({ ok: true, duplicate: true });
    }

    let inserted = true;
    try {
      await db.insert(purchases).values({
        id: newId(),
        userId: order.userId,
        productId: check.product.id,
        priceTRY: check.product.priceTRY,
        provider: gw.name,
        externalRef: order.orderId || null,
      });
    } catch {
      inserted = false; // unique(user,product) — zaten sahip
    }

    if (inserted) {
      const rows = await db
        .select({ email: users.email })
        .from(users)
        .where(eq(users.id, order.userId));
      const email = rows[0]?.email;
      if (email) {
        await getEmailProvider()
          .send(email, purchaseConfirmationEmail(check.product.title, check.product.priceTRY))
          .catch((e) => logger.warn('purchase_email_failed', { err: String(e) }));
      }
      logger.info('purchase_granted', { productId: check.product.id, order: order.orderId });
    }
    return json({ ok: true });
  } catch (e) {
    if (e instanceof Error && e.message === 'DB_NOT_CONFIGURED')
      return json({ error: 'db not configured' }, { status: 503 });
    logger.error('webhook_error', { err: String(e) });
    return json({ error: 'server error' }, { status: 500 });
  }
}
