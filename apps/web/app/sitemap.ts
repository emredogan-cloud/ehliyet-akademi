import type { MetadataRoute } from 'next';
import { LESSONS } from '../content/lessons';

const BASE = process.env.NEXT_PUBLIC_SITE_URL ?? 'https://ehliyet-akademi.example';

export default function sitemap(): MetadataRoute.Sitemap {
  const staticRoutes = [
    '',
    '/dersler',
    '/e-sinav',
    '/tani',
    '/calis',
    '/deneme-sinavi',
    '/hazirlik-skorum',
  ].map((p) => ({
    url: `${BASE}${p}`,
    changeFrequency: 'weekly' as const,
    priority: p === '' ? 1 : 0.7,
  }));
  const lessonRoutes = LESSONS.map((l) => ({
    url: `${BASE}/dersler/${l.slug}`,
    changeFrequency: 'monthly' as const,
    priority: 0.6,
  }));
  return [...staticRoutes, ...lessonRoutes];
}
