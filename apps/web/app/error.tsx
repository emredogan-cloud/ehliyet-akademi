'use client';

/** Uygulama hata sınırı (Sprint 4) — beklenmeyen hatada dostane kurtarma ekranı. */
import { useEffect } from 'react';

export default function AppError({ error, reset }: { error: Error; reset: () => void }) {
  useEffect(() => {
    // İstemci hatası — üretimde gözlemlenebilirlik sağlayıcısına (Sentry) bağlanır.
    console.error('[app-error]', error?.message);
  }, [error]);

  return (
    <div className="container" style={{ padding: '48px 16px', maxWidth: 560 }}>
      <div className="card" data-testid="app-error">
        <div style={{ fontSize: '2rem' }} aria-hidden>
          ⚠️
        </div>
        <h1 style={{ margin: '8px 0' }}>Bir şeyler ters gitti</h1>
        <p className="muted">
          Beklenmeyen bir hata oluştu. Verilerin güvende — tekrar deneyebilir ya da panele
          dönebilirsin.
        </p>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', marginTop: 8 }}>
          <button className="btn" onClick={() => reset()}>
            Tekrar dene
          </button>
          <a className="btn btn--ghost" href="/panel">
            Panele dön
          </a>
        </div>
      </div>
    </div>
  );
}
