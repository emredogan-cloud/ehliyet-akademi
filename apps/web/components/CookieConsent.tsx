'use client';

/**
 * Çerez rıza bannerı (Sprint 4 / KVKK + ePrivacy). Gizlilik-öncelikli: varsayılan yalnız
 * zorunlu çerezler. Seçim `ea:consent`e yazılır; Ayarlar'dan değiştirilebilir. Analitik
 * yalnız açık rıza ile etkinleşir (şimdilik no-op; sözleşme burada tutulur).
 */
import { useEffect, useState } from 'react';

export const CONSENT_KEY = 'ea:consent';
export type Consent = { essential: true; analytics: boolean; at: number };

export function readConsent(): Consent | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = localStorage.getItem(CONSENT_KEY);
    return raw ? (JSON.parse(raw) as Consent) : null;
  } catch {
    return null;
  }
}

export function CookieConsent() {
  const [show, setShow] = useState(false);

  useEffect(() => {
    setShow(readConsent() === null);
  }, []);

  function save(analytics: boolean) {
    try {
      const c: Consent = { essential: true, analytics, at: Date.now() };
      localStorage.setItem(CONSENT_KEY, JSON.stringify(c));
    } catch {
      /* sessiz */
    }
    setShow(false);
  }

  if (!show) return null;
  return (
    <div
      className="cookie-consent"
      role="dialog"
      aria-label="Çerez tercihleri"
      data-testid="cookie-consent"
    >
      <div className="cookie-consent__body">
        <p style={{ margin: 0 }}>
          Zorunlu çerezleri (oturum, tema) kullanıyoruz. Analitik çerezleri yalnız onayınla
          etkinleşir. <a href="/cerez-politikasi">Çerez Politikası</a>
        </p>
        <div className="cookie-consent__actions">
          <button
            className="btn btn--ghost btn--sm"
            onClick={() => save(false)}
            data-testid="consent-reject"
          >
            Yalnız zorunlu
          </button>
          <button className="btn btn--sm" onClick={() => save(true)} data-testid="consent-accept">
            Tümünü kabul et
          </button>
        </div>
      </div>
    </div>
  );
}
