'use client';

/**
 * Satın alma diyaloğu (Sprint 4) — erişilebilir modal. Ürünü gösterir, ödeme akışını başlatır
 * (demo/gerçek), satın almaları geri yüklemeyi sunar. Odak tuzağı + Esc + scrim kapatma.
 */
import { useEffect, useRef, useState } from 'react';
import { productById, type ProductId } from '@/lib/products';
import { startCheckout } from '@/lib/checkoutClient';
import { restorePurchases } from '@/lib/authClient';

export function PurchaseDialog({
  productId,
  onClose,
  onOwned,
}: {
  productId: ProductId;
  onClose: () => void;
  onOwned: (owned: string[]) => void;
}) {
  const product = productById(productId);
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState('');
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [onClose]);

  if (!product) return null;

  async function buy() {
    setBusy(true);
    setMsg('');
    const r = await startCheckout(product!.id);
    setMsg(r.message);
    setBusy(false);
    if (r.ok && !r.redirected) {
      const { loadEntitlements } = await import('@/lib/payments');
      onOwned(loadEntitlements());
    }
  }

  async function restore() {
    setBusy(true);
    const owned = await restorePurchases();
    setBusy(false);
    setMsg(
      owned.length ? 'Satın almaların geri yüklendi.' : 'Geri yüklenecek satın alma bulunamadı.'
    );
    onOwned(owned);
  }

  return (
    <div className="modal-scrim" onClick={onClose} data-testid="purchase-dialog">
      <div
        className="modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="pd-title"
        onClick={(e) => e.stopPropagation()}
      >
        <div
          style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', gap: 12 }}
        >
          <h2 id="pd-title" style={{ margin: 0 }}>
            {product.title}
          </h2>
          <button
            ref={closeRef}
            className="btn btn--ghost btn--sm"
            onClick={onClose}
            aria-label="Kapat"
          >
            ✕
          </button>
        </div>
        <p className="muted" style={{ marginTop: 6 }}>
          {product.blurb}
        </p>
        <div className="price" style={{ fontSize: '1.6rem', fontWeight: 800, margin: '8px 0' }}>
          {product.priceTRY} ₺{' '}
          <span className="muted" style={{ fontSize: '0.9rem', fontWeight: 400 }}>
            · tek seferlik, ömür boyu
          </span>
        </div>
        <ul className="prose" style={{ margin: '4px 0 12px' }}>
          {product.features.map((f, k) => (
            <li key={k}>{f}</li>
          ))}
        </ul>

        {msg && (
          <p
            className="explain"
            role="status"
            data-testid="purchase-msg"
            style={{ margin: '0 0 12px' }}
          >
            {msg}
          </p>
        )}

        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <button className="btn" onClick={buy} disabled={busy} data-testid="purchase-buy">
            {busy ? 'İşleniyor…' : 'Satın al'}
          </button>
          <button
            className="btn btn--ghost"
            onClick={restore}
            disabled={busy}
            data-testid="purchase-restore"
          >
            Satın almaları geri yükle
          </button>
        </div>
        <p className="muted" style={{ fontSize: '0.78rem', marginTop: 12 }}>
          Ödeme sağlayıcısı bağlanana dek satın alma <strong>demo modda</strong> çalışır (gerçek
          tahsilat yapılmaz). Abonelik yoktur; bir kez öde, kalıcı erişim.
        </p>
      </div>
    </div>
  );
}
