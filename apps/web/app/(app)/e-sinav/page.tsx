import type { Metadata } from 'next';
import { EXAM_BLUEPRINT } from '@ea/content-schema';
import { subjectCounts } from '@ea/question-bank';
import { PageHeader } from '@/components/ui/layout';
import { ESinavContent } from '@/components/ESinavContent';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'e-Sınav Hazırlık',
  description:
    'Teorik e-Sınav dersleri ve deneme: trafik ve çevre, ilk yardım, araç tekniği, trafik adabı.',
  path: '/e-sinav',
});

export default function ESinavPage() {
  const counts = subjectCounts();
  return (
    <>
      <PageHeader
        title="Teorik e-Sınav"
        emoji="📝"
        subtitle={
          <>
            Gerçek sınav: {EXAM_BLUEPRINT.totalQuestions} soru · {EXAM_BLUEPRINT.durationMinutes} dk
            · geçmek için {EXAM_BLUEPRINT.passCorrect} doğru. Bu bir{' '}
            <em>resmî MEB sınavı değildir</em>; gerçek sınav formatında denemedir.
          </>
        }
      />
      <ESinavContent counts={counts} />
    </>
  );
}
