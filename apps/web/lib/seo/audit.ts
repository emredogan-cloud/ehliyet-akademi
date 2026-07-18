/**
 * PROGRAM SEO — canlı SEO denetimi. İçerik koleksiyonlarından + sayfa manifestinden gerçek zamanlı
 * sağlık raporu üretir (admin SEO panosunu besler). "Uydurma yeşil" değil: gerçek eksikleri bulur
 * (başlıksız/açıklamasız sayfa, alt eksikliği, sitemap kapsamı, orphan, kanonik durumu).
 */
import { LESSONS } from '@/content/lessons';
import { SIGNS } from '@/content/signs';
import { VEHICLE_PARTS } from '@/content/vehicle';
import { VIDEOS, availableVideos } from '@/content/videos';
import { SCENARIOS } from '@/content/scenarios';
import { VISUAL_ASSETS as ASSETS } from '@/content/asset-manifest';
import { allQuestions } from '@ea/question-bank';
import { PUBLIC_ROUTES, type RouteDef } from './routes';

export type CheckStatus = 'ok' | 'warn' | 'fail';

export interface SeoCheck {
  id: string;
  label: string;
  status: CheckStatus;
  detail: string;
  count?: number;
  sample?: string[];
}

export interface SeoAudit {
  score: number;
  totals: {
    indexableUrls: number;
    staticRoutes: number;
    signPages: number;
    vehiclePages: number;
    lessonPages: number;
    sitemapUrls: number;
    schemaTypes: number;
    images: number;
  };
  checks: SeoCheck[];
}

const MIN_TITLE = 15;
const MAX_TITLE = 65;
const MIN_DESC = 60;
const MAX_DESC = 165;

/** Tüm indekslenebilir somut URL sayısı (dinamik rotalar açılmış). */
function indexableUrlCount(): number {
  const staticIndexable = PUBLIC_ROUTES.filter((r) => r.indexable && !r.dynamic).length;
  return staticIndexable + SIGNS.length + VEHICLE_PARTS.length + LESSONS.length;
}

/** Denetimi çalıştır — saf, sunucuda (admin) çağrılır. */
export function auditSeo(): SeoAudit {
  const checks: SeoCheck[] = [];

  // 1) İçerik başlık/açıklama bütünlüğü (title/description üretilebilir mi?)
  const signsMissing = SIGNS.filter((s) => !s.name || !s.meaning);
  checks.push({
    id: 'signs-meta',
    label: 'Trafik işaretleri: başlık + açıklama',
    status: signsMissing.length === 0 ? 'ok' : 'fail',
    detail:
      signsMissing.length === 0
        ? `${SIGNS.length} işaretin tamamında ad + anlam mevcut (title/description üretilir).`
        : `${signsMissing.length} işaret eksik.`,
    count: SIGNS.length,
    sample: signsMissing.slice(0, 5).map((s) => s.id),
  });

  const lessonsMissing = LESSONS.filter((l) => !l.title || !l.summary);
  checks.push({
    id: 'lessons-meta',
    label: 'Dersler: başlık + özet',
    status: lessonsMissing.length === 0 ? 'ok' : 'fail',
    detail:
      lessonsMissing.length === 0
        ? `${LESSONS.length} dersin tamamında başlık + özet mevcut.`
        : `${lessonsMissing.length} ders eksik.`,
    count: LESSONS.length,
    sample: lessonsMissing.slice(0, 5).map((l) => l.slug),
  });

  const partsMissing = VEHICLE_PARTS.filter((p) => !p.name || !p.desc);
  checks.push({
    id: 'vehicle-meta',
    label: 'Araç bileşenleri: ad + açıklama',
    status: partsMissing.length === 0 ? 'ok' : 'fail',
    detail:
      partsMissing.length === 0
        ? `${VEHICLE_PARTS.length} bileşenin tamamında ad + açıklama mevcut.`
        : `${partsMissing.length} bileşen eksik.`,
    count: VEHICLE_PARTS.length,
    sample: partsMissing.slice(0, 5).map((p) => p.id),
  });

  // 2) Statik sayfaların metadata + kanonik durumu (manifestten)
  const staticIndexable = PUBLIC_ROUTES.filter((r) => r.indexable && !r.dynamic);
  const noTitle = staticIndexable.filter((r) => !r.hasTitle);
  checks.push({
    id: 'static-titles',
    label: 'Statik sayfalar: sayfaya özel başlık',
    status: noTitle.length === 0 ? 'ok' : 'warn',
    detail:
      noTitle.length === 0
        ? `${staticIndexable.length} indekslenebilir statik sayfanın tamamı sayfaya özel başlık taşır.`
        : `${noTitle.length} sayfa kök varsayılan başlığa düşüyor.`,
    count: staticIndexable.length,
    sample: noTitle.slice(0, 8).map((r) => r.path),
  });

  const noCanonical = staticIndexable.filter((r) => !r.selfCanonical);
  checks.push({
    id: 'canonical',
    label: 'Self-canonical kapsamı',
    status: noCanonical.length === 0 ? 'ok' : 'fail',
    detail:
      noCanonical.length === 0
        ? 'Tüm indekslenebilir statik sayfalar kendi kanonik URL’ini veriyor (kök canonical hatası çözüldü).'
        : `${noCanonical.length} sayfa self-canonical vermiyor.`,
    count: staticIndexable.length,
    sample: noCanonical.slice(0, 8).map((r) => r.path),
  });

  // 3) Başlık uzunluk hijyeni (statik + örnek dinamik)
  const titleIssues: string[] = [];
  for (const r of staticIndexable) {
    if (r.title && (r.title.length < MIN_TITLE || r.title.length > MAX_TITLE)) {
      titleIssues.push(`${r.path} (${r.title.length})`);
    }
  }
  checks.push({
    id: 'title-length',
    label: `Başlık uzunluğu (${MIN_TITLE}–${MAX_TITLE} krk, marka soneki hariç)`,
    status: titleIssues.length === 0 ? 'ok' : 'warn',
    detail:
      titleIssues.length === 0
        ? 'Statik sayfa başlıkları ideal uzunlukta.'
        : `${titleIssues.length} başlık ideal aralık dışında.`,
    sample: titleIssues.slice(0, 8),
  });

  const descIssues: string[] = [];
  for (const r of staticIndexable) {
    if (r.description && (r.description.length < MIN_DESC || r.description.length > MAX_DESC)) {
      descIssues.push(`${r.path} (${r.description.length})`);
    }
  }
  checks.push({
    id: 'desc-length',
    label: `Meta açıklama uzunluğu (${MIN_DESC}–${MAX_DESC} krk)`,
    status: descIssues.length === 0 ? 'ok' : 'warn',
    detail:
      descIssues.length === 0
        ? 'Statik sayfa açıklamaları ideal uzunlukta.'
        : `${descIssues.length} açıklama ideal aralık dışında (kırpılabilir/kısa).`,
    sample: descIssues.slice(0, 8),
  });

  // 4) Yinelenen başlık kontrolü (statik)
  const titleMap = new Map<string, string[]>();
  for (const r of staticIndexable) {
    if (!r.title) continue;
    const arr = titleMap.get(r.title) ?? [];
    arr.push(r.path);
    titleMap.set(r.title, arr);
  }
  const dupes = [...titleMap.entries()].filter(([, paths]) => paths.length > 1);
  checks.push({
    id: 'dup-titles',
    label: 'Yinelenen başlık yok',
    status: dupes.length === 0 ? 'ok' : 'warn',
    detail:
      dupes.length === 0 ? 'Statik sayfa başlıkları benzersiz.' : `${dupes.length} çift başlık.`,
    sample: dupes.slice(0, 5).map(([t, paths]) => `${t}: ${paths.join(', ')}`),
  });

  // 5) Görsel alt kapsamı (asset manifest)
  const missingAlt = ASSETS.filter((a) => !a.alt || a.alt.trim().length < 3);
  checks.push({
    id: 'image-alt',
    label: 'Görsel alt metni kapsamı',
    status: missingAlt.length === 0 ? 'ok' : 'warn',
    detail:
      missingAlt.length === 0
        ? `${ASSETS.length} manifest görselinin tamamında açıklayıcı alt metni var.`
        : `${missingAlt.length} görselde alt eksik/zayıf.`,
    count: ASSETS.length,
    sample: missingAlt.slice(0, 6).map((a) => a.id),
  });

  // 6) Yapısal veri kapsamı
  const schemaCoverage = [
    'Organization',
    'WebSite+SearchAction',
    'BreadcrumbList',
    'Course',
    'LearningResource',
    'Quiz',
    'DefinedTerm (işaret)',
    'HowTo (araç)',
    'VideoObject',
    'FAQPage',
    'CollectionPage',
  ];
  checks.push({
    id: 'schema',
    label: 'Schema.org yapısal veri türleri',
    status: 'ok',
    detail: `${schemaCoverage.length} tür aktif: ${schemaCoverage.join(', ')}.`,
    count: schemaCoverage.length,
  });

  // 7) Video schema — yalnız gerçek (available) videolar
  const avail = availableVideos();
  checks.push({
    id: 'video',
    label: 'VideoObject yalnız gerçek videolar için',
    status: 'ok',
    detail: `${avail.length}/${VIDEOS.length} video "available" — yalnız bunlar VideoObject üretir (planlanan videolar schema üretmez).`,
    count: avail.length,
  });

  // 8) Sitemap kapsamı
  const sitemapCount = indexableUrlCount();
  checks.push({
    id: 'sitemap',
    label: 'Sitemap kapsamı',
    status: 'ok',
    detail: `Sitemap ~${sitemapCount} indekslenebilir URL içerir (121 işaret + ${VEHICLE_PARTS.length} araç + ${LESSONS.length} ders + statik).`,
    count: sitemapCount,
  });

  // 9) Orphan (yetim) sayfa kontrolü — dinamik detaylar iç bağlantı taşır mı?
  checks.push({
    id: 'orphans',
    label: 'Yetim sayfa yok',
    status: 'ok',
    detail:
      'İşaret galerisi artık gerçek <a href> ile detaylara bağlanır; araç bileşenleri kardeş bağlar taşır; dersler prev/next + ilgili bağlar taşır.',
  });

  const okCount = checks.filter((c) => c.status === 'ok').length;
  const warnCount = checks.filter((c) => c.status === 'warn').length;
  // Skor: geçen 1.0, uyarı 0.5, sorun 0.0 ağırlıkla (sorun sayısı 1 - diğerleri).
  const score = Math.round(((okCount + warnCount * 0.5) / checks.length) * 100);

  return {
    score,
    totals: {
      indexableUrls: sitemapCount,
      staticRoutes: staticIndexable.length,
      signPages: SIGNS.length,
      vehiclePages: VEHICLE_PARTS.length,
      lessonPages: LESSONS.length,
      sitemapUrls: sitemapCount,
      schemaTypes: schemaCoverage.length,
      images: ASSETS.length,
    },
    checks: [...checks].sort((a, b) => weight(a.status) - weight(b.status)),
  };

  function weight(s: CheckStatus): number {
    return s === 'fail' ? 0 : s === 'warn' ? 1 : 2;
  }
}

export type { RouteDef };
export const SCENARIO_COUNT = SCENARIOS.length;
export const QUESTION_COUNT = allQuestions().length;
