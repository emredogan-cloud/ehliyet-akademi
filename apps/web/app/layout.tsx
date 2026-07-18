import type { Metadata, Viewport } from 'next';
import type { ReactNode } from 'react';
import { SiteJsonLd } from '@/components/JsonLd';
import { RegisterSW } from '@/components/RegisterSW';
import { CookieConsent } from '@/components/CookieConsent';
import { AnalyticsLoader } from '@/components/AnalyticsLoader';
import { SITE_URL } from '@/lib/seo/site';
import './globals.css';

const SITE = SITE_URL;

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
  // Uygulama ikonu: new_icon.png'den üretilmiş (FINAL SPRINT P2). Tüm boyutlar PNG.
  icons: {
    icon: [
      { url: '/favicon.ico', sizes: '48x48' },
      { url: '/icon-192.png', type: 'image/png', sizes: '192x192' },
      { url: '/icon-512.png', type: 'image/png', sizes: '512x512' },
    ],
    apple: '/apple-touch-icon.png',
    shortcut: '/favicon.ico',
  },
  // PROGRAM SEO — KÖK canonical KALDIRILDI: '/' tüm alt sayfalara miras kalıp hepsini ana sayfaya
  // kanonikleştiriyordu (Google onları kopya sanıyordu). Her sayfa artık `buildMetadata({path})` ile
  // KENDİ self-canonical'ını verir; ana sayfa canonical'ı (marketing)/page.tsx'te tanımlıdır.
  openGraph: {
    type: 'website',
    locale: 'tr_TR',
    siteName: 'Ehliyet Akademi',
    url: SITE,
    title: 'Ehliyet Akademi — Sınava akıllı hazırlık',
    description: 'Tanı denemesi → hazırlık skoru. Zayıf konularına odaklan, ilk denemede geç.',
    images: [
      {
        url: '/og.jpg',
        width: 1200,
        height: 630,
        alt: 'Ehliyet Akademi — Bugün girsen geçer miydin?',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Ehliyet Akademi — Sınava akıllı hazırlık',
    description: 'Tanı denemesi → hazırlık skoru. Zayıf konularına odaklan, ilk denemede geç.',
    images: ['/og.jpg'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-image-preview': 'large',
      'max-snippet': -1,
      'max-video-preview': -1,
    },
  },
  // Arama motoru doğrulaması — owner env değeri girince meta tag otomatik basılır (owner action).
  verification: {
    ...(process.env.NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION
      ? { google: process.env.NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION }
      : {}),
    ...(process.env.NEXT_PUBLIC_YANDEX_VERIFICATION
      ? { yandex: process.env.NEXT_PUBLIC_YANDEX_VERIFICATION }
      : {}),
    ...(process.env.NEXT_PUBLIC_BING_VERIFICATION
      ? { other: { 'msvalidate.01': process.env.NEXT_PUBLIC_BING_VERIFICATION } }
      : {}),
  },
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
        <AnalyticsLoader />
        {children}
        <CookieConsent />
      </body>
    </html>
  );
}
