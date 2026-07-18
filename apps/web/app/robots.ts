import type { MetadataRoute } from 'next';
import { SITE_URL } from '@/lib/seo/site';

/**
 * PROGRAM SEO — robots. Halka açık içeriği taramaya açar; API/admin ve kişisel/oturum sayfalarını
 * (indekslenmemeli, thin/duplicate) kapatır. Crawl bütçesi gerçek içeriğe yönlensin.
 * Yapay zekâ tarayıcıları (GPTBot, ClaudeBot, PerplexityBot vb.) BİLİNÇLİ olarak açık bırakılır —
 * içeriğin AI aramalarında (AEO) alıntılanması hedeftir.
 */
export default function robots(): MetadataRoute.Robots {
  const disallow = [
    '/api/',
    '/admin',
    '/panel',
    '/profil',
    '/ayarlar',
    '/ilerleme',
    '/basarilar',
    '/calisma-plani',
    '/giris',
    '/dogrula',
    '/sifirla',
    '/arama', // arama sonuç sayfası — thin/parametrik, indekslenmez
  ];
  return {
    rules: [{ userAgent: '*', allow: '/', disallow }],
    sitemap: `${SITE_URL}/sitemap.xml`,
    host: SITE_URL,
  };
}
