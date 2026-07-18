/**
 * PROGRAM SEO — tek doğruluk kaynağı (single source of truth) site kimliği.
 *
 * Üretim markalı alan adı: https://ehliyetegitim.com
 * Önizleme (Vercel) dağıtımları kendi *.vercel.app adreslerini kullanabilir; `NEXT_PUBLIC_SITE_URL`
 * ayarlıysa o KAZANIR (Vercel Production'da bu markalı alan adına ayarlanmalı — owner action).
 *
 * Daha önce canonical/OG/sitemap/robots/JSON-LD dört ayrı dosyada FARKLI varsayılanlara sahipti
 * (biri sahte `ehliyet-akademi.example`). Hepsi artık buradan okur → tutarlı entity sinyali.
 */

/** Markalı üretim alan adı (şema kaymaz sonu). */
export const PRODUCTION_ORIGIN = 'https://ehliyetegitim.com';

/** Kanonik origin — env override edilebilir; sondaki `/` temizlenir. */
export const SITE_URL = (process.env.NEXT_PUBLIC_SITE_URL ?? PRODUCTION_ORIGIN).replace(/\/+$/, '');

/** Marka/entity sabitleri — tüm metadata + JSON-LD aynı entity'yi işaret eder. */
export const SITE_NAME = 'Ehliyet Akademi';
export const SITE_LEGAL_NAME = 'Ehliyet Akademi';
export const SITE_LOCALE = 'tr_TR';
export const SITE_LANG = 'tr';

export const SITE_TAGLINE = 'Türkiye’nin En Gelişmiş Ehliyet Eğitim Platformu';
export const SITE_DESCRIPTION =
  'Türkiye B sınıfı ehliyet sınavına hazırlık: özgün soru bankası, AI Koç, ders anlatımları, ' +
  'trafik işaretleri ve deneme sınavları. Tanı denemesiyle hazırlık skorunu öğren, ilk denemede geç.';

/** Sosyal/knowledge-graph bağlantıları — YALNIZ gerçek profiller eklenir (owner doldurur). */
export const SITE_SAME_AS: string[] = [];

/** Marka logosu (SVG — ölçeklenebilir). */
export const SITE_LOGO_PATH = '/icon.svg';
/** 1200×630 sosyal önizleme kartı. */
export const SITE_OG_IMAGE_PATH = '/og.jpg';

/** Göreli yolu kanonik mutlak URL'e çevirir. `path` '/' ile başlamalı (yoksa eklenir). */
export function absoluteUrl(path = '/'): string {
  if (/^https?:\/\//.test(path)) return path;
  const p = path.startsWith('/') ? path : `/${path}`;
  return `${SITE_URL}${p === '/' ? '' : p}`;
}
