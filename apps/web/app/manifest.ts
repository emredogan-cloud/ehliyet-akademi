import type { MetadataRoute } from 'next';

/** PWA manifesti (ROADMAP Faz 17/18 temeli) — kurulabilir, çevrimdışı-hazır kabuk. */
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Ehliyet Akademi — Sınav Hazırlık',
    short_name: 'Ehliyet Akademi',
    description:
      'B sınıfı ehliyet teorik e-Sınav + direksiyon hazırlığı: tanı denemesi, hazırlık skoru, dersler.',
    lang: 'tr',
    start_url: '/',
    display: 'standalone',
    background_color: '#0e2320',
    theme_color: '#0f766e',
    categories: ['education'],
    // İkonlar new_icon.png'den üretildi (FINAL SPRINT P2).
    icons: [
      { src: '/icon-192.png', sizes: '192x192', type: 'image/png', purpose: 'any' },
      { src: '/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'any' },
      { src: '/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
    ],
    screenshots: [
      {
        src: '/og.jpg',
        sizes: '1200x630',
        type: 'image/jpeg',
        // form_factor 'wide' → masaüstü kurulum önizlemesi (Chrome PWA install).
        form_factor: 'wide',
        label: 'Ehliyet Akademi — sınava akıllı hazırlık',
      },
    ],
  };
}
