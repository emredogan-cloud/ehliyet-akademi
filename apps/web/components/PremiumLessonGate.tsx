'use client';

/**
 * Premium ders kapısı (Sprint 4) — istemci erişim kontrolü. Sahiplik varsa içerik gösterilir;
 * yoksa kilit + satın alma diyaloğu. Güvenlik/ilk-yardım dersleri premium işaretlenmez.
 */
import { useEffect, useState } from 'react';
import { canAccessLesson, productForLesson } from '@/lib/entitlements';
import { loadEntitlements } from '@/lib/payments';
import { productById, type ProductId } from '@/lib/products';
import { PurchaseDialog } from './PurchaseDialog';

export function PremiumLessonGate({ slug, children }: { slug: string; children: React.ReactNode }) {
  const [owned, setOwned] = useState<string[] | null>(null);
  const [dialog, setDialog] = useState(false);

  useEffect(() => setOwned(loadEntitlements()), []);

  if (owned === null)
    return <div className="skeleton" style={{ height: 140, marginTop: 18 }} aria-busy="true" />;

  if (canAccessLesson({ slug, premium: true }, owned)) return <>{children}</>;

  const pid: ProductId = productForLesson(slug);
  const product = productById(pid);

  return (
    <div className="paywall card" data-testid="premium-locked">
      <div style={{ fontSize: '2rem', lineHeight: 1 }} aria-hidden>
        🔒
      </div>
      <h2 style={{ margin: '8px 0 6px' }}>Bu ileri ders premium</h2>
      <p className="muted" style={{ marginTop: 0 }}>
        Dersin tamamı <strong>{product?.title}</strong> ile açılır — tek seferlik ödeme, ömür boyu
        erişim. (Temel dersler ve tüm ilk yardım içeriği herkese açıktır.)
      </p>
      <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
        <button className="btn" onClick={() => setDialog(true)} data-testid="premium-unlock">
          Kilidi aç · {product?.priceTRY}₺
        </button>
        <a className="btn btn--ghost" href="/fiyatlandirma">
          Tüm paketler
        </a>
      </div>
      {dialog && (
        <PurchaseDialog
          productId={pid}
          onClose={() => setDialog(false)}
          onOwned={(o) => {
            setOwned(o);
            setDialog(false);
          }}
        />
      )}
    </div>
  );
}
