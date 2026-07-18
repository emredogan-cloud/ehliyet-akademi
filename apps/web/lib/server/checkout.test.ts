import { describe, it, expect } from 'vitest';
import { createHmac } from 'node:crypto';
import {
  MockGateway,
  LemonSqueezyGateway,
  validateReceipt,
  getPaymentGateway,
  paymentConfigured,
} from './checkout';

describe('MockGateway', () => {
  const gw = new MockGateway();
  it('checkout mock modu döner', async () => {
    expect((await gw.createCheckout()).mode).toBe('mock');
  });
  it('imza her zaman geçerli (mock)', () => {
    expect(gw.verifySignature()).toBe(true);
  });
  it('sipariş JSON gövdesini ayrıştırır; eksik alanlar → null', () => {
    const order = gw.parseOrder(
      JSON.stringify({ productId: 'komple-b', userId: 'u1', totalTRY: 449 })
    );
    expect(order?.productId).toBe('komple-b');
    expect(gw.parseOrder(JSON.stringify({ userId: 'u1' }))).toBeNull();
    expect(gw.parseOrder('bozuk')).toBeNull();
  });
});

describe('LemonSqueezyGateway imza + ayrıştırma', () => {
  const secret = 'whsec_test';
  const gw = new LemonSqueezyGateway('key', 'store1', secret);

  it('HMAC-SHA256 imza doğrulaması (geçerli/geçersiz)', () => {
    const body = JSON.stringify({ hello: 'world' });
    const sig = createHmac('sha256', secret).update(body, 'utf8').digest('hex');
    expect(gw.verifySignature(body, sig)).toBe(true);
    expect(gw.verifySignature(body, sig.replace(/.$/, '0'))).toBe(false);
    expect(gw.verifySignature(body, null)).toBe(false);
  });

  it('order_created olayından sipariş çıkarır; başka olay → null', () => {
    const evt = JSON.stringify({
      meta: {
        event_name: 'order_created',
        custom_data: { user_id: 'u9', product_id: 'premium-teori' },
      },
      data: { id: 'ord_123', attributes: { total: 24900, currency: 'TRY' } },
    });
    const order = gw.parseOrder(evt);
    expect(order).toEqual({
      productId: 'premium-teori',
      userId: 'u9',
      orderId: 'ord_123',
      totalTRY: 249,
    });
    expect(
      gw.parseOrder(JSON.stringify({ meta: { event_name: 'subscription_created' } }))
    ).toBeNull();
  });
});

describe('validateReceipt (makbuz doğrulaması)', () => {
  it('bilinmeyen ürün geçersiz', () => {
    const r = validateReceipt({ productId: 'yok', userId: 'u', orderId: 'o', totalTRY: 100 });
    expect(r.valid).toBe(false);
    expect(r.reason).toBe('unknown_product');
  });
  it('fiyat uyuşmazlığı: valid ama priceOk=false (imzalı webhook güvenilir → grant + uyarı)', () => {
    const r = validateReceipt({
      productId: 'premium-teori',
      userId: 'u',
      orderId: 'o',
      totalTRY: 1,
    });
    expect(r.valid).toBe(true);
    expect(r.priceOk).toBe(false);
    expect(r.reason).toMatch(/price_mismatch/);
  });
  it('doğru fiyat geçerli + priceOk; total=0 (mock) da geçerli + priceOk', () => {
    const exact = validateReceipt({
      productId: 'premium-teori',
      userId: 'u',
      orderId: 'o',
      totalTRY: 249,
    });
    expect(exact.valid).toBe(true);
    expect(exact.priceOk).toBe(true);
    const zero = validateReceipt({
      productId: 'premium-teori',
      userId: 'u',
      orderId: 'o',
      totalTRY: 0,
    });
    expect(zero.valid).toBe(true);
    expect(zero.priceOk).toBe(true);
  });
});

describe('sağlayıcı seçimi', () => {
  it('ENV yokken mock', () => {
    expect(paymentConfigured()).toBe(false);
    expect(getPaymentGateway().name).toBe('mock');
  });
});
