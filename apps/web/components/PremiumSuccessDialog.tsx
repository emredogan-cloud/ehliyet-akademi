'use client';

/**
 * Premium başarı açılışı (FINAL SPRINT P9 · ref 033). Satın alma BAŞARIYLA tamamlanınca BİR KEZ
 * gösterilir. Açılan GERÇEK özellikler entitlement'tan türetilir (placeholder metin yok).
 */
import { useEffect, useRef } from 'react';
import { unlockedFeatures } from '@/lib/products';
import { Icon, type IconName } from '@/components/ui/icons';

export function PremiumSuccessDialog({ owned, onClose }: { owned: string[]; onClose: () => void }) {
  const closeRef = useRef<HTMLButtonElement>(null);
  const features = unlockedFeatures(owned);

  useEffect(() => {
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);

  return (
    <div
      className="premium-modal"
      role="dialog"
      aria-modal="true"
      aria-labelledby="premium-modal-title"
      data-testid="premium-success"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div className="premium-modal__panel">
        <button
          ref={closeRef}
          className="premium-modal__close"
          onClick={onClose}
          aria-label="Kapat"
          data-testid="premium-close"
        >
          <Icon name="chevron-down" size={18} />
        </button>

        <div className="premium-modal__crown" aria-hidden>
          {/* Üretilmiş taç görseli (ASSET 033/001) */}
          <img src="/assets/art/premium-crown.webp" alt="" />
        </div>

        <h2 id="premium-modal-title" className="premium-modal__title">
          Premium Ailesine Hoş Geldin!
        </h2>
        <div className="premium-modal__rule" aria-hidden>
          <span>✦</span>
        </div>
        <p className="premium-modal__sub">
          Premium Lifetime satın alımın başarıyla tamamlandı. Öğrenme deneyimini zirveye taşıyacak
          yeni özelliklerinin kilidi açıldı:
        </p>

        <ul className="premium-modal__features">
          {features.map((f) => (
            <li key={f.label} className="premium-modal__feature">
              <span className="premium-modal__ficon" aria-hidden>
                <Icon name={f.icon as IconName} size={22} />
              </span>
              <span className="premium-modal__flabel">{f.label}</span>
            </li>
          ))}
        </ul>

        <button
          className="premium-modal__cta"
          onClick={onClose}
          data-testid="premium-explore"
          autoFocus
        >
          Keşfetmeye Başla <Icon name="chevron-right" size={20} />
        </button>
      </div>
    </div>
  );
}
