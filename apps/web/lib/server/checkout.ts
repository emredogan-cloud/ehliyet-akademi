/**
 * Ödeme ağ geçidi (Sprint 4 / ADR-008) — sunucu tarafı. TEK-SEFERLİK satın alma (abonelik YOK).
 * Varsayılan MockGateway (harici servissiz tam akış). ENV geldiğinde LemonSqueezyGateway:
 * hosted checkout + HMAC webhook doğrulaması + makbuz doğrulaması. Uygulama sözleşmesi değişmez.
 */
import { createHmac, timingSafeEqual } from 'node:crypto';
import { productById, type Product } from '../products';
import { SITE_URL } from '../seo/site';

export interface CheckoutSession {
  /** 'mock' → istemci mevcut sunucu-taraflı grant akışını kullanır; 'redirect' → hosted checkout. */
  mode: 'mock' | 'redirect';
  url?: string;
}

export interface WebhookOrder {
  productId: string;
  userId: string;
  orderId: string;
  totalTRY: number;
}

export interface PaymentGateway {
  readonly name: string;
  createCheckout(product: Product, userId: string): Promise<CheckoutSession>;
  /** Webhook ham gövdesi + imza başlığını doğrula (HMAC-SHA256). */
  verifySignature(rawBody: string, signature: string | null): boolean;
  /** Doğrulanmış webhook gövdesinden siparişi çıkar; tanınmayan olay/eksik veri → null. */
  parseOrder(rawBody: string): WebhookOrder | null;
}

/** Mock: gerçek para yok. Webhook gövdesi doğrudan sipariş JSON'u kabul edilir (test/dev). */
export class MockGateway implements PaymentGateway {
  readonly name = 'mock';
  async createCheckout(): Promise<CheckoutSession> {
    return { mode: 'mock' };
  }
  verifySignature(): boolean {
    return true;
  }
  parseOrder(rawBody: string): WebhookOrder | null {
    try {
      const b = JSON.parse(rawBody) as Partial<WebhookOrder>;
      if (!b.productId || !b.userId) return null;
      return {
        productId: b.productId,
        userId: b.userId,
        orderId: b.orderId ?? `mock_${b.productId}_${b.userId}`,
        totalTRY: Number(b.totalTRY ?? 0),
      };
    } catch {
      return null;
    }
  }
}

/** ENV'den ürün → LemonSqueezy variant id eşlemesi (LEMONSQUEEZY_VARIANT_<PRODUCT>). */
export function variantForProduct(productId: string): string | undefined {
  const key = `LEMONSQUEEZY_VARIANT_${productId.toUpperCase().replace(/-/g, '_')}`;
  return process.env[key];
}

export class LemonSqueezyGateway implements PaymentGateway {
  readonly name = 'lemonsqueezy';
  constructor(
    private apiKey: string,
    private storeId: string,
    private webhookSecret: string
  ) {}

  async createCheckout(product: Product, userId: string): Promise<CheckoutSession> {
    const variantId = variantForProduct(product.id);
    if (!variantId) throw new Error(`variant_missing:${product.id}`);
    const res = await fetch('https://api.lemonsqueezy.com/v1/checkouts', {
      method: 'POST',
      headers: {
        authorization: `Bearer ${this.apiKey}`,
        'content-type': 'application/vnd.api+json',
        accept: 'application/vnd.api+json',
      },
      body: JSON.stringify({
        data: {
          type: 'checkouts',
          attributes: {
            // custom → webhook meta.custom_data olarak geri döner (sahiplik ilişkilendirme).
            checkout_data: { custom: { user_id: userId, product_id: product.id } },
            // Ödeme sonrası uygulamaya dönüş: istemci ?checkout=success ile sahipliği uzlaştırıp
            // başarı açılışını gösterir (webhook gecikmesine karşı yeniden dener).
            product_options: { redirect_url: `${SITE_URL}/fiyatlandirma?checkout=success` },
          },
          relationships: {
            store: { data: { type: 'stores', id: this.storeId } },
            variant: { data: { type: 'variants', id: variantId } },
          },
        },
      }),
    });
    if (!res.ok) throw new Error(`lemonsqueezy_checkout_${res.status}`);
    const data = (await res.json()) as { data?: { attributes?: { url?: string } } };
    const url = data.data?.attributes?.url;
    if (!url) throw new Error('lemonsqueezy_no_url');
    return { mode: 'redirect', url };
  }

  verifySignature(rawBody: string, signature: string | null): boolean {
    if (!signature) return false;
    const digest = createHmac('sha256', this.webhookSecret).update(rawBody, 'utf8').digest('hex');
    const a = Buffer.from(digest, 'hex');
    const b = Buffer.from(signature, 'hex');
    return a.length === b.length && timingSafeEqual(a, b);
  }

  parseOrder(rawBody: string): WebhookOrder | null {
    try {
      const evt = JSON.parse(rawBody) as {
        meta?: { event_name?: string; custom_data?: { user_id?: string; product_id?: string } };
        data?: { id?: string; attributes?: { total?: number; currency?: string } };
      };
      if (evt.meta?.event_name !== 'order_created') return null;
      const userId = evt.meta.custom_data?.user_id;
      const productId = evt.meta.custom_data?.product_id;
      if (!userId || !productId) return null;
      return {
        productId,
        userId,
        orderId: evt.data?.id ?? '',
        totalTRY: Math.round((evt.data?.attributes?.total ?? 0) / 100), // kuruş → TRY
      };
    } catch {
      return null;
    }
  }
}

export function paymentConfigured(): boolean {
  return Boolean(
    process.env.LEMONSQUEEZY_API_KEY &&
    process.env.LEMONSQUEEZY_STORE_ID &&
    process.env.LEMONSQUEEZY_WEBHOOK_SECRET
  );
}

export function getPaymentGateway(): PaymentGateway {
  if (paymentConfigured()) {
    return new LemonSqueezyGateway(
      process.env.LEMONSQUEEZY_API_KEY!,
      process.env.LEMONSQUEEZY_STORE_ID!,
      process.env.LEMONSQUEEZY_WEBHOOK_SECRET!
    );
  }
  return new MockGateway();
}

/**
 * Makbuz doğrulaması: sipariş kataloğa göre geçerli mi?
 * `valid` = ürün katalogda VAR (sahiplik verilir). `priceOk` = tutar katalog fiyatıyla birebir.
 *
 * ÖNEMLİ: fiyat uyuşmazlığı artık HARD-REJECT DEĞİL — yalnız uyarı olarak işaretlenir. Gerçek
 * webhook HMAC ile imzalıdır (veri LemonSqueezy'den, güvenilir); vergi/yuvarlama/kupon nedeniyle
 * `total` katalog fiyatından farklı olabilir. Ödeme yapan kullanıcının erişimini kaybetmemesi için
 * bilinen ürün → grant edilir; uyuşmazlık audit için loglanır. (Mock gateway prod'da erişilemez.)
 */
export function validateReceipt(order: WebhookOrder): {
  valid: boolean;
  product?: Product;
  priceOk: boolean;
  reason?: string;
} {
  const product = productById(order.productId);
  if (!product) return { valid: false, priceOk: false, reason: 'unknown_product' };
  const priceOk = order.totalTRY <= 0 || order.totalTRY === product.priceTRY;
  return {
    valid: true,
    product,
    priceOk,
    ...(priceOk ? {} : { reason: `price_mismatch:${order.totalTRY}!=${product.priceTRY}` }),
  };
}
