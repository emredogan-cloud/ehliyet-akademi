'use client';

/**
 * Kök hata sınırı (LCP P4) — kök layout'un KENDİSİ hata verirse devreye girer;
 * app/error.tsx bunu yakalayamaz (o, layout'un İÇİNDE render olur). Kendi <html>/<body>'sini
 * getirir ve globals.css yüklenmemiş olabileceğinden yalnız satır-içi stil kullanır.
 */
import { useEffect } from 'react';

export default function GlobalError({ error, reset }: { error: Error; reset: () => void }) {
  useEffect(() => {
    // Üretimde gözlemlenebilirlik sağlayıcısına (Sentry) bağlanır.
    console.error('[global-error]', error?.message);
  }, [error]);

  return (
    <html lang="tr">
      <body
        style={{
          margin: 0,
          minHeight: '100vh',
          display: 'grid',
          placeItems: 'center',
          background: '#0e2320',
          color: '#e6f4f1',
          fontFamily: 'system-ui, -apple-system, Segoe UI, Roboto, sans-serif',
          padding: '24px',
        }}
      >
        <div
          data-testid="global-error"
          style={{
            maxWidth: 480,
            width: '100%',
            background: '#123a35',
            border: '1px solid #1f5049',
            borderRadius: 16,
            padding: '32px 24px',
            textAlign: 'center',
          }}
        >
          <div style={{ fontSize: '2.5rem' }} aria-hidden>
            ⚠️
          </div>
          <h1 style={{ margin: '12px 0 8px', fontSize: '1.35rem' }}>Bir şeyler ters gitti</h1>
          <p style={{ margin: '0 0 20px', color: '#9fc6bf', lineHeight: 1.5 }}>
            Beklenmeyen bir hata oluştu. Verilerin güvende — sayfayı yenilemeyi deneyebilirsin.
          </p>
          <button
            onClick={() => reset()}
            style={{
              background: '#14b8a6',
              color: '#04211d',
              border: 'none',
              borderRadius: 10,
              padding: '12px 22px',
              fontWeight: 700,
              fontSize: '1rem',
              cursor: 'pointer',
            }}
          >
            Tekrar dene
          </button>
        </div>
      </body>
    </html>
  );
}
