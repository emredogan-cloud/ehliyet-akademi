/**
 * JSON-LD yapısal veri (ROADMAP Faz 15). Kural: schema yalnız görünen içeriği yansıtır;
 * AggregateRating/Review yalnız gerçek olduğunda (şimdi yok → eklenmedi).
 */
import type { Lesson } from '@ea/content-schema';
import { EXAM_BLUEPRINT } from '@ea/content-schema';

const BASE = process.env.NEXT_PUBLIC_SITE_URL ?? 'https://ehliyet-akademi.example';

function Script({ data }: { data: object }) {
  return (
    <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }} />
  );
}

/** Kök: Organization + WebSite. */
export function SiteJsonLd() {
  return (
    <>
      <Script
        data={{
          '@context': 'https://schema.org',
          '@type': 'Organization',
          name: 'Ehliyet Akademi',
          url: BASE,
          logo: `${BASE}/icon.svg`,
        }}
      />
      <Script
        data={{
          '@context': 'https://schema.org',
          '@type': 'WebSite',
          name: 'Ehliyet Akademi',
          url: BASE,
          inLanguage: 'tr',
        }}
      />
    </>
  );
}

/** Ders sayfası: Course/LearningResource. */
export function LessonJsonLd({ lesson }: { lesson: Lesson }) {
  return (
    <Script
      data={{
        '@context': 'https://schema.org',
        '@type': 'LearningResource',
        name: lesson.title,
        description: lesson.summary,
        inLanguage: 'tr',
        educationalLevel: 'Beginner',
        learningResourceType: 'Lesson',
        timeRequired: `PT${lesson.minutes}M`,
        url: `${BASE}/dersler/${lesson.slug}`,
        teaches: lesson.objectives,
        isPartOf: {
          '@type': 'Course',
          name: 'B Sınıfı Ehliyet Sınavı Hazırlık',
          provider: { '@type': 'Organization', name: 'Ehliyet Akademi' },
        },
      }}
    />
  );
}

/** Deneme sınavı sayfası: Quiz. */
export function ExamJsonLd() {
  return (
    <Script
      data={{
        '@context': 'https://schema.org',
        '@type': 'Quiz',
        name: 'B Sınıfı e-Sınav Deneme Sınavı',
        description: `Gerçek sınav formatında deneme: ${EXAM_BLUEPRINT.totalQuestions} soru, ${EXAM_BLUEPRINT.durationMinutes} dakika.`,
        inLanguage: 'tr',
        educationalAlignment: {
          '@type': 'AlignmentObject',
          alignmentType: 'assesses',
          targetName: 'MEB B sınıfı ehliyet teorik sınavı hazırlığı',
        },
        url: `${BASE}/deneme-sinavi`,
      }}
    />
  );
}
