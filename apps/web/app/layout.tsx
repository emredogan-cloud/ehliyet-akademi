import type { Metadata, Viewport } from 'next';
import type { ReactNode } from 'react';
import { SiteJsonLd } from '@/components/JsonLd';
import { RegisterSW } from '@/components/RegisterSW';
import './globals.css';

const SITE = process.env.NEXT_PUBLIC_SITE_URL ?? 'https://ehliyet-akademi-nine.vercel.app';

export const metadata: Metadata = {
  metadataBase: new URL(SITE),
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
  manifest: '/manifest.webmanifest',
  icons: { icon: '/icon.svg', apple: '/icon.svg' },
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
    <html lang="tr" suppressHydrationWarning>
      <head>
        {/* Tema tercihini ilk boyamadan önce uygula (FOUC engelle) — Ayarlar sayfası yönetir. */}
        <script
          dangerouslySetInnerHTML={{
            __html: `try{var t=localStorage.getItem('ea:theme');if(t==='dark'||t==='light'){document.documentElement.setAttribute('data-theme',t);}}catch(e){}`,
          }}
        />
      </head>
      <body>
        <SiteJsonLd />
        <RegisterSW />
        {children}
      </body>
    </html>
  );
}
