/**
 * JSON-LD yapısal veri (ROADMAP Faz 15 · PROGRAM SEO genişletmesi).
 * Kural: schema yalnız görünen, gerçek içeriği yansıtır; AggregateRating/Review ASLA uydurulmaz.
 * Üreticiler `lib/seo/schema.ts` içinde (saf fonksiyonlar); burası yalnız React sarmalayıcı katmanı.
 */
import type { Lesson } from '@ea/content-schema';
import { EXAM_BLUEPRINT } from '@ea/content-schema';
import { SITE_LANG, absoluteUrl } from '@/lib/seo/site';
import {
  graph,
  organizationSchema,
  websiteSchema,
  breadcrumbSchema,
  trafficSignSchema,
  vehicleHowToSchema,
  vehiclePartSchema,
  videoSchema,
  faqSchema,
  courseSchema,
  collectionPageSchema,
  lessonSchema,
  WEBSITE_ID,
  ORG_ID,
} from '@/lib/seo/schema';

/**
 * Genel JSON-LD script yazıcı. GÜVENLİK (M6): `<` kaçırılır → içerikte `</script>` geçse bile
 * script bloğundan çıkış yapılamaz (gelecekte CMS/kullanıcı içeriği schema'ya akarsa XSS önlenir).
 */
export function JsonLd({ data }: { data: object }) {
  const html = JSON.stringify(data).replace(/</g, '\\u003c');
  return <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: html }} />;
}

/** Kök: Organization + WebSite(+SearchAction) tek @graph içinde (paylaşılan @id). */
export function SiteJsonLd() {
  return <JsonLd data={graph(organizationSchema(), websiteSchema())} />;
}

/** Kırıntı (breadcrumb) yapısal verisi — görünen breadcrumb ile birebir. */
export function BreadcrumbJsonLd({ items }: { items: Array<{ name: string; path?: string }> }) {
  return <JsonLd data={{ '@context': 'https://schema.org', ...breadcrumbSchema(items) }} />;
}

/** Ders sayfası: LearningResource + (opsiyonel) breadcrumb. */
export function LessonJsonLd({
  lesson,
  breadcrumb,
}: {
  lesson: Lesson;
  breadcrumb?: Array<{ name: string; path?: string }>;
}) {
  const nodes = [
    lessonSchema({
      slug: lesson.slug,
      title: lesson.title,
      summary: lesson.summary,
      minutes: lesson.minutes,
      objectives: lesson.objectives,
    }),
  ];
  if (breadcrumb?.length) nodes.push(breadcrumbSchema(breadcrumb));
  return <JsonLd data={graph(...nodes)} />;
}

/** Trafik işareti detay: DefinedTerm + breadcrumb. */
export function SignJsonLd({
  sign,
  breadcrumb,
}: {
  sign: { id: string; name: string; meaning: string; categoryLabel: string; keywords?: string[] };
  breadcrumb?: Array<{ name: string; path?: string }>;
}) {
  const nodes = [trafficSignSchema(sign)];
  if (breadcrumb?.length) nodes.push(breadcrumbSchema(breadcrumb));
  return <JsonLd data={graph(...nodes)} />;
}

/** Araç bileşeni detay: HowTo (muayene adımı varsa) veya Article + breadcrumb. */
export function VehicleJsonLd({
  part,
  breadcrumb,
}: {
  part: { id: string; name: string; desc: string; steps?: string[] };
  breadcrumb?: Array<{ name: string; path?: string }>;
}) {
  const primary =
    part.steps && part.steps.length > 0
      ? vehicleHowToSchema({ id: part.id, name: part.name, desc: part.desc, steps: part.steps })
      : vehiclePartSchema({ id: part.id, name: part.name, desc: part.desc });
  const nodes = [primary];
  if (breadcrumb?.length) nodes.push(breadcrumbSchema(breadcrumb));
  return <JsonLd data={graph(...nodes)} />;
}

/** Video listesi: available videolar için VideoObject dizisi. */
export function VideoListJsonLd({
  videos,
}: {
  videos: Array<{
    id: string;
    title: string;
    description: string;
    poster?: string;
    src?: string;
    duration?: number;
    transcript?: Array<{ t: number; text: string }>;
  }>;
}) {
  if (!videos.length) return null;
  return <JsonLd data={graph(...videos.map((v) => videoSchema(v)))} />;
}

/** SSS yapısal verisi (AEO/AI Overviews). */
export function FaqJsonLd({ items }: { items: Array<{ question: string; answer: string }> }) {
  if (!items.length) return null;
  return <JsonLd data={{ '@context': 'https://schema.org', ...faqSchema(items) }} />;
}

/** Koleksiyon/galeri sayfası: CollectionPage (+ opsiyonel breadcrumb). */
export function CollectionJsonLd({
  name,
  description,
  path,
  itemCount,
  breadcrumb,
}: {
  name: string;
  description: string;
  path: string;
  itemCount: number;
  breadcrumb?: Array<{ name: string; path?: string }>;
}) {
  const nodes = [collectionPageSchema({ name, description, path, itemCount })];
  if (breadcrumb?.length) nodes.push(breadcrumbSchema(breadcrumb));
  return <JsonLd data={graph(...nodes)} />;
}

/** Dersler hub: Course düğümü. */
export function CourseJsonLd({
  lessonCount,
  questionCount,
}: {
  lessonCount: number;
  questionCount: number;
}) {
  return <JsonLd data={graph(courseSchema({ lessonCount, questionCount }))} />;
}

/** Deneme sınavı sayfası: Quiz (gerçek sınav formatı). */
export function ExamJsonLd() {
  return (
    <JsonLd
      data={{
        '@context': 'https://schema.org',
        '@type': 'Quiz',
        name: 'B Sınıfı e-Sınav Deneme Sınavı',
        description: `Gerçek sınav formatında deneme: ${EXAM_BLUEPRINT.totalQuestions} soru, ${EXAM_BLUEPRINT.durationMinutes} dakika, ${EXAM_BLUEPRINT.passCorrect} doğru barajı.`,
        inLanguage: SITE_LANG,
        educationalAlignment: {
          '@type': 'AlignmentObject',
          alignmentType: 'assesses',
          targetName: 'MEB B sınıfı ehliyet teorik sınavı hazırlığı',
        },
        about: { '@id': WEBSITE_ID },
        provider: { '@id': ORG_ID },
        url: absoluteUrl('/deneme-sinavi'),
      }}
    />
  );
}
