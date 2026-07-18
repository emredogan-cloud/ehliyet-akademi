/**
 * PROGRAM SEO — sayfa metadata yardımcısı (tek merkez).
 *
 * KRİTİK DÜZELTME: kök layout `alternates.canonical:'/'` tüm sayfalara miras kalıyordu → her sayfa
 * ana sayfaya kanonikleşiyor, Google onları kopya sanıyordu. Artık kök canonical KALDIRILDI ve her
 * sayfa `buildMetadata({ path })` ile KENDİ kanonik URL'ini verir (self-referencing canonical).
 */
import type { Metadata } from 'next';
import { SITE_NAME, SITE_LOCALE, SITE_OG_IMAGE_PATH, SITE_DESCRIPTION, absoluteUrl } from './site';

export interface BuildMetaInput {
  /** Sayfa başlığı (marka soneki template ile eklenir: "%s · Ehliyet Akademi"). */
  title?: string;
  /** Meta açıklama (özgün, sayfaya özel; boşsa site varsayılanı). */
  description?: string;
  /** Kanonik yol — '/' ile başlar, ör. '/isaretler' veya '/isaretler/dur'. ZORUNLU. */
  path: string;
  /** OG/twitter görseli (varsayılan /og.jpg). */
  image?: string;
  imageAlt?: string;
  /** OG türü. */
  type?: 'website' | 'article';
  /** Dizinlemeyi kapat (kişisel/oturum/admin sayfaları). */
  noindex?: boolean;
  keywords?: string[];
  /** Yayın/güncelleme zamanı (article türü için). */
  publishedTime?: string;
  modifiedTime?: string;
}

/**
 * Sayfaya özel Next.js Metadata üretir — self-canonical + OG url + twitter kartı dahil.
 * Kök metadata ile SIĞ birleşir; buradaki `alternates.canonical` kökü EZER (kanonik hatası çözülür).
 */
export function buildMetadata(input: BuildMetaInput): Metadata {
  const url = absoluteUrl(input.path);
  const image = input.image ?? SITE_OG_IMAGE_PATH;
  const description = input.description ?? SITE_DESCRIPTION;
  const alt = input.imageAlt ?? input.title ?? SITE_NAME;
  return {
    title: input.title,
    description,
    keywords: input.keywords,
    alternates: { canonical: input.path },
    openGraph: {
      type: input.type ?? 'website',
      url,
      title: input.title ?? SITE_NAME,
      description,
      siteName: SITE_NAME,
      locale: SITE_LOCALE,
      images: [{ url: image, width: 1200, height: 630, alt }],
      ...(input.publishedTime ? { publishedTime: input.publishedTime } : {}),
      ...(input.modifiedTime ? { modifiedTime: input.modifiedTime } : {}),
    },
    twitter: {
      card: 'summary_large_image',
      title: input.title ?? SITE_NAME,
      description,
      images: [image],
    },
    ...(input.noindex
      ? { robots: { index: false, follow: false, googleBot: { index: false, follow: false } } }
      : {}),
  };
}

/** Kısayol: yalnız dizinleme-dışı (noindex) kabuk sayfaları için (oturum/kişisel/admin). */
export function noindexMetadata(title: string, path: string): Metadata {
  return buildMetadata({ title, path, noindex: true });
}
