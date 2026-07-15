'use client';

/**
 * İstemci ödeme akışı (Sprint 4). /api/checkout → mock ise sunucu-grant (girişliyse) veya
 * yerel demo grant (misafir/DB yok); redirect ise hosted checkout'a yönlendirir.
 * Prod'da DATABASE_URL yokken uç 503 döner → dürüst "demo grant" yoluna düşülür.
 */
import { grantEntitlement, loadEntitlements } from './payments';
import { serverPurchase } from './authClient';
import type { ProductId } from './products';

export interface CheckoutOutcome {
  ok: boolean;
  message: string;
  redirected?: boolean;
}

export async function startCheckout(productId: ProductId): Promise<CheckoutOutcome> {
  try {
    const res = await fetch('/api/checkout', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      credentials: 'same-origin',
      body: JSON.stringify({ productId }),
    });
    const data = (await res.json().catch(() => ({}))) as {
      mode?: string;
      url?: string;
      error?: string;
    };

    if (res.status === 401 || res.status === 503) {
      // Misafir veya hesap sistemi henüz bağlı değil → yerel demo grant (dürüst etiketli).
      grantEntitlement(productId);
      return {
        ok: true,
        message: 'Demo modda paketin bu cihaza tanımlandı. Giriş yaparsan tüm cihazlarına taşınır.',
      };
    }
    if (!res.ok) return { ok: false, message: data.error ?? 'Ödeme başlatılamadı.' };

    if (data.mode === 'redirect' && data.url) {
      window.location.href = data.url;
      return { ok: true, message: 'Ödeme sayfasına yönlendiriliyorsun…', redirected: true };
    }
    // mock → sunucu-taraflı kalıcı sahiplik
    const owned = await serverPurchase(productId);
    if (owned) return { ok: true, message: 'Paketin hesabına tanımlandı (demo ödeme).' };
    return { ok: false, message: 'Satın alma tamamlanamadı, tekrar dene.' };
  } catch {
    grantEntitlement(productId);
    return { ok: true, message: 'Demo modda bu cihaza tanımlandı.' };
  }
}

export { loadEntitlements };
