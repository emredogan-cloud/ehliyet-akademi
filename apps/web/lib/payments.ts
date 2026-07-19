/**
 * Ödeme soyutlaması (ROADMAP Faz 16 / ADR mock politikası).
 * Model: TEK-SEFERLİK satın alma (abonelik yok). Sağlayıcı-agnostik arayüz;
 * varsayılan MockPaymentProvider (harici servissiz tam akış). Gerçek sağlayıcı
 * (LemonSqueezy/Stripe one-time) yalnız ENV ile takılır — kod değişmez.
 * Fiyat-bütünlüğü: gösterilen fiyat kataloğun TEK kaynağından gelir (lib/products).
 */
import { productById, type ProductId } from './products';
import { syncSet } from './authClient';

export interface CheckoutResult {
  ok: boolean;
  productId: ProductId;
  message: string;
}

export interface PaymentProvider {
  readonly name: string;
  /** Tek-seferlik satın alma akışını başlat; başarıyla dönerse entitlement verilir. */
  checkout(productId: ProductId): Promise<CheckoutResult>;
}

const ENTITLEMENTS_KEY = 'ea:entitlements:v1';

/* ---- Entitlement deposu (yerel; auth+DB gelince sunucuya taşınır) ---- */
export function loadEntitlements(): string[] {
  if (typeof window === 'undefined') return [];
  try {
    return JSON.parse(window.localStorage.getItem(ENTITLEMENTS_KEY) ?? '[]') as string[];
  } catch {
    return [];
  }
}
export function grantEntitlement(productId: ProductId): string[] {
  const cur = loadEntitlements();
  if (!cur.includes(productId)) cur.push(productId);
  syncSet(ENTITLEMENTS_KEY, cur);
  return cur;
}

/** Mock sağlayıcı: gerçek para YOK; demo/geliştirme için tam akış simülasyonu. */
export class MockPaymentProvider implements PaymentProvider {
  readonly name = 'mock';
  async checkout(productId: ProductId): Promise<CheckoutResult> {
    const p = productById(productId);
    if (!p) return { ok: false, productId, message: 'Ürün bulunamadı.' };
    // Gerçek sağlayıcıda burada hosted-checkout'a yönlendirilir ve webhook doğrulanır.
    grantEntitlement(productId);
    return {
      ok: true,
      productId,
      message: `${p.title} hesabına tanımlandı (demo ödeme — gerçek tahsilat yapılmadı).`,
    };
  }
}

/** Sağlayıcı seçimi (ENV → gerçek; yoksa mock). */
export function getPaymentProvider(): PaymentProvider {
  // İleride: process.env.NEXT_PUBLIC_PAYMENT_PROVIDER === 'lemonsqueezy' → LS adaptörü.
  return new MockPaymentProvider();
}

/* ---- Ücretsiz kademe kotası: günde 1 deneme sınavı ---- */
const QUOTA_KEY = 'ea:examQuota:v1';
export function canStartFreeExam(now = Date.now()): boolean {
  if (typeof window === 'undefined') return true;
  try {
    const raw = window.localStorage.getItem(QUOTA_KEY);
    if (!raw) return true;
    const { day, count } = JSON.parse(raw) as { day: string; count: number };
    const today = new Date(now).toISOString().slice(0, 10);
    return day !== today || count < 1;
  } catch {
    return true;
  }
}
export function consumeFreeExam(now = Date.now()): void {
  if (typeof window === 'undefined') return;
  try {
    const today = new Date(now).toISOString().slice(0, 10);
    const raw = window.localStorage.getItem(QUOTA_KEY);
    const cur = raw ? (JSON.parse(raw) as { day: string; count: number }) : null;
    const next =
      cur && cur.day === today ? { day: today, count: cur.count + 1 } : { day: today, count: 1 };
    syncSet(QUOTA_KEY, next);
  } catch {
    /* sessiz */
  }
}

/* ---- Ücretsiz kademe AI kotası: günde N soru (premium: sınırsız) — PREMIUM STRATEJİSİ (P10) ---- */
const AI_QUOTA_KEY = 'ea:aiQuota:v1';
export const FREE_AI_DAILY = 5;

/** Bugün kaç ücretsiz AI sorusu kaldı (premium değilse). */
export function remainingFreeAI(now = Date.now()): number {
  if (typeof window === 'undefined') return FREE_AI_DAILY;
  try {
    const raw = window.localStorage.getItem(AI_QUOTA_KEY);
    if (!raw) return FREE_AI_DAILY;
    const { day, count } = JSON.parse(raw) as { day: string; count: number };
    const today = new Date(now).toISOString().slice(0, 10);
    if (day !== today) return FREE_AI_DAILY;
    return Math.max(0, FREE_AI_DAILY - count);
  } catch {
    return FREE_AI_DAILY;
  }
}
export function canAskFreeAI(now = Date.now()): boolean {
  return remainingFreeAI(now) > 0;
}
export function consumeFreeAI(now = Date.now()): void {
  if (typeof window === 'undefined') return;
  try {
    const today = new Date(now).toISOString().slice(0, 10);
    const raw = window.localStorage.getItem(AI_QUOTA_KEY);
    const cur = raw ? (JSON.parse(raw) as { day: string; count: number }) : null;
    const next =
      cur && cur.day === today ? { day: today, count: cur.count + 1 } : { day: today, count: 1 };
    syncSet(AI_QUOTA_KEY, next);
  } catch {
    /* sessiz */
  }
}
