import type { Metadata, Viewport } from 'next';
import type { ReactNode } from 'react';
import './globals.css';

export const metadata: Metadata = {
  metadataBase: new URL('https://ehliyet-akademi.example'),
  title: {
    default: 'Ehliyet Akademi — B Sınıfı Teorik + Direksiyon Sınavı Hazırlık',
    template: '%s · Ehliyet Akademi',
  },
  description:
    'Türkiye B sınıfı ehliyet sınavına hazırlık: teorik e-Sınav (trafik, ilk yardım, motor, trafik adabı) ve direksiyon pratiği. Tanı denemesiyle hazırlık skorunu öğren.',
  keywords: [
    'ehliyet sınavı',
    'e-sınav',
    'trafik işaretleri',
    'ilk yardım',
    'direksiyon sınavı',
    'deneme sınavı',
  ],
  applicationName: 'Ehliyet Akademi',
  openGraph: {
    type: 'website',
    locale: 'tr_TR',
    siteName: 'Ehliyet Akademi',
    title: 'Ehliyet Akademi — Sınava akıllı hazırlık',
    description: 'Tanı denemesi → hazırlık skoru. Zayıf konularına odaklan, ilk denemede geç.',
  },
  robots: { index: true, follow: true },
};

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#0f766e' },
    { media: '(prefers-color-scheme: dark)', color: '#042f2e' },
  ],
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="tr">
      <body>
        <a className="skip-link" href="#main">
          İçeriğe atla
        </a>
        <header className="topbar">
          <div className="container topbar__inner">
            <a className="brand" href="/" aria-label="Ehliyet Akademi ana sayfa">
              🚗{' '}
              <span>
                <b>Ehliyet</b> Akademi
              </span>
            </a>
            <nav className="nav" aria-label="Ana menü">
              <a href="/dersler">Dersler</a>
              <a href="/e-sinav">e-Sınav</a>
              <a href="/tani">Tanı Denemesi</a>
              <a href="/hazirlik-skorum">Hazırlık Skorum</a>
            </nav>
          </div>
        </header>
        <main id="main" className="container" tabIndex={-1}>
          {children}
        </main>
        <footer className="site">
          <div className="container">
            <p>
              Ehliyet Akademi · Eğitim amaçlı hazırlık platformu. Resmî sınav ve güncel kural için
              MEB/MTSK ve sürücü kursunuz esastır. Bu bir <em>resmî MEB sınavı değildir</em>; gerçek
              sınav formatında denemedir.
            </p>
          </div>
        </footer>
      </body>
    </html>
  );
}
