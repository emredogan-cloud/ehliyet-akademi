/**
 * PROGRAM SEO — Schema.org yapısal veri üreticileri (saf fonksiyonlar → düz JSON-LD nesnesi).
 *
 * İlke: schema YALNIZ görünen, gerçek içeriği yansıtır. AggregateRating/Review ASLA uydurulmaz.
 * Tüm URL'ler `absoluteUrl()` ile mutlak + markalı alan adına (ehliyetegitim.com) sabitlenir.
 * Entity tutarlılığı: her düğüm aynı Organization `@id`'sine bağlanır → knowledge-graph sinyali.
 */
import {
  SITE_URL,
  SITE_NAME,
  SITE_LEGAL_NAME,
  SITE_DESCRIPTION,
  SITE_LANG,
  SITE_SAME_AS,
  SITE_LOGO_PATH,
  absoluteUrl,
} from './site';

/** Sabit @id'ler — düğümler arası referans (entity grafiği). */
export const ORG_ID = `${SITE_URL}/#organization`;
export const WEBSITE_ID = `${SITE_URL}/#website`;

type Json = Record<string, unknown>;

/** Organization — marka/varlık çekirdeği. Logo ImageObject, dil, hizmet alanı (TR). */
export function organizationSchema(): Json {
  return {
    '@type': 'Organization',
    '@id': ORG_ID,
    name: SITE_NAME,
    legalName: SITE_LEGAL_NAME,
    url: SITE_URL,
    description: SITE_DESCRIPTION,
    logo: {
      '@type': 'ImageObject',
      url: absoluteUrl(SITE_LOGO_PATH),
      caption: SITE_NAME,
    },
    image: absoluteUrl('/og.jpg'),
    inLanguage: SITE_LANG,
    knowsLanguage: SITE_LANG,
    areaServed: { '@type': 'Country', name: 'Türkiye' },
    knowsAbout: [
      'B sınıfı ehliyet sınavı',
      'Trafik işaretleri',
      'İlk yardım',
      'Araç tekniği',
      'Trafik adabı',
      'Direksiyon eğitimi',
    ],
    ...(SITE_SAME_AS.length ? { sameAs: SITE_SAME_AS } : {}),
  };
}

/** WebSite — SearchAction ile site-içi arama (Google sitelinks searchbox). */
export function websiteSchema(): Json {
  return {
    '@type': 'WebSite',
    '@id': WEBSITE_ID,
    name: SITE_NAME,
    url: SITE_URL,
    description: SITE_DESCRIPTION,
    inLanguage: SITE_LANG,
    publisher: { '@id': ORG_ID },
    potentialAction: {
      '@type': 'SearchAction',
      target: {
        '@type': 'EntryPoint',
        urlTemplate: `${SITE_URL}/arama?q={search_term_string}`,
      },
      'query-input': 'required name=search_term_string',
    },
  };
}

/** BreadcrumbList — görünen breadcrumb'ın yapısal karşılığı. items: {name, path?}. */
export function breadcrumbSchema(items: Array<{ name: string; path?: string }>): Json {
  return {
    '@type': 'BreadcrumbList',
    itemListElement: items.map((it, i) => ({
      '@type': 'ListItem',
      position: i + 1,
      name: it.name,
      ...(it.path ? { item: absoluteUrl(it.path) } : {}),
    })),
  };
}

/** Trafik işareti → DefinedTerm (bir terim/kavram) + Image-benzeri açıklama. */
export function trafficSignSchema(sign: {
  id: string;
  name: string;
  meaning: string;
  categoryLabel: string;
  keywords?: string[];
}): Json {
  return {
    '@type': 'DefinedTerm',
    '@id': `${absoluteUrl(`/isaretler/${sign.id}`)}#term`,
    name: sign.name,
    description: sign.meaning,
    termCode: sign.id,
    inDefinedTermSet: {
      '@type': 'DefinedTermSet',
      name: 'Türkiye Trafik İşaretleri',
      url: absoluteUrl('/isaretler'),
    },
    url: absoluteUrl(`/isaretler/${sign.id}`),
    inLanguage: SITE_LANG,
    ...(sign.keywords?.length ? { keywords: sign.keywords.join(', ') } : {}),
    isPartOf: { '@id': WEBSITE_ID },
    publisher: { '@id': ORG_ID },
    about: { '@type': 'Thing', name: sign.categoryLabel },
  };
}

/** Araç bileşeni muayene adımları → HowTo (adımlı rehber). */
export function vehicleHowToSchema(part: {
  id: string;
  name: string;
  desc: string;
  steps: string[];
}): Json {
  return {
    '@type': 'HowTo',
    '@id': `${absoluteUrl(`/arac/${part.id}`)}#howto`,
    name: `${part.name} — Kontrol Adımları`,
    description: part.desc,
    url: absoluteUrl(`/arac/${part.id}`),
    inLanguage: SITE_LANG,
    publisher: { '@id': ORG_ID },
    step: part.steps.map((s, i) => ({
      '@type': 'HowToStep',
      position: i + 1,
      name: s.length > 60 ? `${s.slice(0, 57)}…` : s,
      text: s,
    })),
  };
}

/** Araç bileşeni (muayene adımı yoksa) → TechArticle-benzeri hafif Thing. */
export function vehiclePartSchema(part: { id: string; name: string; desc: string }): Json {
  return {
    '@type': 'Article',
    '@id': `${absoluteUrl(`/arac/${part.id}`)}#article`,
    headline: `${part.name} — Araç Tanıma`,
    description: part.desc,
    url: absoluteUrl(`/arac/${part.id}`),
    inLanguage: SITE_LANG,
    isPartOf: { '@id': WEBSITE_ID },
    publisher: { '@id': ORG_ID },
    author: { '@id': ORG_ID },
  };
}

/** Video → VideoObject (yalnız gerçek/available videolar için). */
export function videoSchema(video: {
  id: string;
  title: string;
  description: string;
  poster?: string;
  src?: string;
  duration?: number;
  transcript?: Array<{ t: number; text: string }>;
}): Json {
  return {
    '@type': 'VideoObject',
    '@id': `${absoluteUrl('/videolar')}#${video.id}`,
    name: video.title,
    description: video.description,
    inLanguage: SITE_LANG,
    ...(video.poster ? { thumbnailUrl: absoluteUrl(video.poster) } : {}),
    ...(video.src ? { contentUrl: absoluteUrl(video.src) } : {}),
    ...(typeof video.duration === 'number' ? { duration: `PT${video.duration}S` } : {}),
    ...(video.transcript?.length
      ? { transcript: video.transcript.map((c) => c.text).join(' ') }
      : {}),
    publisher: { '@id': ORG_ID },
    isPartOf: { '@id': WEBSITE_ID },
  };
}

/** FAQPage — soru/cevap dizisinden. AEO/AI Overviews için birincil format. */
export function faqSchema(items: Array<{ question: string; answer: string }>): Json {
  return {
    '@type': 'FAQPage',
    mainEntity: items.map((it) => ({
      '@type': 'Question',
      name: it.question,
      acceptedAnswer: { '@type': 'Answer', text: it.answer },
    })),
    inLanguage: SITE_LANG,
  };
}

/** Course — B sınıfı hazırlık programı (dersler koleksiyonu). */
export function courseSchema(input: { lessonCount: number; questionCount: number }): Json {
  return {
    '@type': 'Course',
    '@id': `${SITE_URL}/#course`,
    name: 'B Sınıfı Ehliyet Sınavı Hazırlık',
    description: `${input.lessonCount} ders, ${input.questionCount} özgün soru ve deneme sınavlarıyla MEB B sınıfı teorik e-Sınav ve direksiyon hazırlığı.`,
    url: absoluteUrl('/dersler'),
    inLanguage: SITE_LANG,
    provider: { '@id': ORG_ID },
    educationalLevel: 'Beginner',
    teaches: [
      'Trafik kuralları',
      'Trafik işaretleri',
      'İlk yardım',
      'Araç tekniği',
      'Trafik adabı',
    ],
    isAccessibleForFree: true,
    hasCourseInstance: {
      '@type': 'CourseInstance',
      courseMode: 'online',
      inLanguage: SITE_LANG,
    },
  };
}

/** CollectionPage — liste/galeri sayfaları (işaretler, araç, dersler) için. */
export function collectionPageSchema(input: {
  name: string;
  description: string;
  path: string;
  itemCount: number;
}): Json {
  return {
    '@type': 'CollectionPage',
    name: input.name,
    description: input.description,
    url: absoluteUrl(input.path),
    inLanguage: SITE_LANG,
    isPartOf: { '@id': WEBSITE_ID },
    publisher: { '@id': ORG_ID },
    mainEntity: {
      '@type': 'ItemList',
      numberOfItems: input.itemCount,
    },
  };
}

/** ItemList — bir koleksiyonun elemanlarını sıralı listeler (crawl keşfi + AEO). */
export function itemListSchema(items: Array<{ name: string; path: string }>): Json {
  return {
    '@type': 'ItemList',
    numberOfItems: items.length,
    itemListElement: items.map((it, i) => ({
      '@type': 'ListItem',
      position: i + 1,
      name: it.name,
      url: absoluteUrl(it.path),
    })),
  };
}

/** LearningResource — ders (mevcut LessonJsonLd ile aynı; merkezi sürüm). */
export function lessonSchema(lesson: {
  slug: string;
  title: string;
  summary: string;
  minutes: number;
  objectives: string[];
}): Json {
  return {
    '@type': 'LearningResource',
    '@id': `${absoluteUrl(`/dersler/${lesson.slug}`)}#lesson`,
    name: lesson.title,
    description: lesson.summary,
    inLanguage: SITE_LANG,
    educationalLevel: 'Beginner',
    learningResourceType: 'Lesson',
    timeRequired: `PT${lesson.minutes}M`,
    url: absoluteUrl(`/dersler/${lesson.slug}`),
    teaches: lesson.objectives,
    isPartOf: { '@id': `${SITE_URL}/#course` },
    publisher: { '@id': ORG_ID },
  };
}

/**
 * Birden çok düğümü tek bir @graph olarak sarar — sayfa başına TEK script,
 * paylaşılan @id referanslarıyla (Organization/WebSite bir kez tanımlanır).
 */
export function graph(...nodes: Json[]): Json {
  return { '@context': 'https://schema.org', '@graph': nodes };
}
