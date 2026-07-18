import type { Metadata } from 'next';
import { Diagnostic } from '@/components/Diagnostic';
import { pickDiagnostic } from '@/lib/diagnostic';
import { PageHeader } from '@/components/ui/layout';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Tanı Denemesi',
  description: 'Kısa tanı denemesiyle hazırlık skorunu ve ders bazlı eksiklerini öğren.',
  path: '/tani',
});

export default function TaniPage() {
  const questions = pickDiagnostic(8);
  return (
    <>
      <PageHeader
        title="Tanı Denemesi"
        emoji="🎯"
        subtitle={
          <>
            {questions.length} soru · dört teorik dersten dengeli. Sonunda hazırlık skorunu
            göreceksin.
          </>
        }
      />
      <Diagnostic questions={questions} />
    </>
  );
}
