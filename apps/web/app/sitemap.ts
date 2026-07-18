import type { MetadataRoute } from 'next';
import { LESSONS } from '../content/lessons';
import { SIGNS } from '../content/signs';
import { VEHICLE_PARTS } from '../content/vehicle';
import { SITE_URL } from '@/lib/seo/site';

/**
 * PROGRAM SEO — tam kapsamlı sitemap. Önceki sürüm yalnız 12 URL içeriyordu; 121 işaret + 70 araç
 * bileşeni + 19 ders detay sayfası (hepsi generateStaticParams ile üretiliyor) EKSİKTİ → arama
 * motorlarına görünmezdi. Artık tüm indekslenebilir içerik + liste sayfaları listelenir.
 * Kişisel/oturum/admin sayfaları (panel, profil, ayarlar, admin, giriş) BİLİNÇLİ olarak dışarıda.
 */
export default function sitemap(): MetadataRoute.Sitemap {
  const now = new Date();
  const url = (p: string) => `${SITE_URL}${p === '/' ? '' : p}`;

  // Halka açık, indekslenebilir statik içerik/giriş sayfaları.
  const staticDefs: Array<{
    path: string;
    priority: number;
    changeFrequency: MetadataRoute.Sitemap[number]['changeFrequency'];
  }> = [
    { path: '/', priority: 1.0, changeFrequency: 'weekly' },
    { path: '/dersler', priority: 0.9, changeFrequency: 'weekly' },
    { path: '/isaretler', priority: 0.9, changeFrequency: 'weekly' },
    { path: '/arac', priority: 0.9, changeFrequency: 'weekly' },
    { path: '/e-sinav', priority: 0.8, changeFrequency: 'weekly' },
    { path: '/deneme-sinavi', priority: 0.8, changeFrequency: 'weekly' },
    { path: '/gorsel-quiz', priority: 0.7, changeFrequency: 'weekly' },
    { path: '/senaryolar', priority: 0.7, changeFrequency: 'monthly' },
    { path: '/videolar', priority: 0.7, changeFrequency: 'monthly' },
    { path: '/tani', priority: 0.8, changeFrequency: 'monthly' },
    { path: '/calis', priority: 0.6, changeFrequency: 'monthly' },
    { path: '/hazirlik-skorum', priority: 0.6, changeFrequency: 'monthly' },
    { path: '/ai-koc', priority: 0.7, changeFrequency: 'monthly' },
    { path: '/fiyatlandirma', priority: 0.7, changeFrequency: 'monthly' },
    { path: '/gizlilik', priority: 0.3, changeFrequency: 'yearly' },
    { path: '/kvkk', priority: 0.3, changeFrequency: 'yearly' },
    { path: '/cerez-politikasi', priority: 0.3, changeFrequency: 'yearly' },
    { path: '/kullanim-kosullari', priority: 0.3, changeFrequency: 'yearly' },
  ];
  const staticEntries: MetadataRoute.Sitemap = staticDefs.map((e) => ({
    url: url(e.path),
    lastModified: now,
    changeFrequency: e.changeFrequency,
    priority: e.priority,
  }));

  // 19 ders detay sayfası.
  const lessonEntries: MetadataRoute.Sitemap = LESSONS.map((l) => ({
    url: url(`/dersler/${l.slug}`),
    lastModified: now,
    changeFrequency: 'monthly',
    priority: 0.7,
  }));

  // 121 trafik işareti detay sayfası.
  const signEntries: MetadataRoute.Sitemap = SIGNS.map((s) => ({
    url: url(`/isaretler/${s.id}`),
    lastModified: now,
    changeFrequency: 'monthly',
    priority: 0.6,
  }));

  // 70 araç bileşeni detay sayfası.
  const vehicleEntries: MetadataRoute.Sitemap = VEHICLE_PARTS.map((p) => ({
    url: url(`/arac/${p.id}`),
    lastModified: now,
    changeFrequency: 'monthly',
    priority: 0.6,
  }));

  return [...staticEntries, ...lessonEntries, ...signEntries, ...vehicleEntries];
}
