import { getSessionUser, json, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { getPaymentGateway } from '@/lib/server/checkout';
import { productById } from '@/lib/products';
import { logger } from '@/lib/server/logger';

/**
 * Ödeme oturumu başlat (Sprint 4). Mock: istemci mevcut sunucu-grant akışını kullanır
 * ('mode: mock'). Gerçek (LemonSqueezy): hosted checkout URL döner ('mode: redirect').
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'checkout', limit: 12, windowMs: 60_000 });
  if (limited) return limited;

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

  const gw = getPaymentGateway();
  try {
    const session = await gw.createCheckout(product, user.id);
    return json({ ok: true, provider: gw.name, ...session });
  } catch (e) {
    logger.error('checkout_failed', { productId: product.id, err: String(e) });
    return json(
      { error: 'Ödeme oturumu başlatılamadı. Lütfen sonra tekrar deneyin.' },
      { status: 502 }
    );
  }
});
