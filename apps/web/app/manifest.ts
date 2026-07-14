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
    icons: [
      { src: '/icon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'any' },
      { src: '/icon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'maskable' },
    ],
  };
}
