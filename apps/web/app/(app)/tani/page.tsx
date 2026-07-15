import type { Metadata } from 'next';
import { Diagnostic } from '@/components/Diagnostic';
import { pickDiagnostic } from '@/lib/diagnostic';

export const metadata: Metadata = {
  title: 'Tanı Denemesi',
  description: 'Kısa tanı denemesiyle hazırlık skorunu ve ders bazlı eksiklerini öğren.',
};

export default function TaniPage() {
  const questions = pickDiagnostic(8);
  return (
    <>
      <h1 style={{ margin: '24px 0 6px' }}>Tanı Denemesi</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        {questions.length} soru · dört teorik dersten dengeli. Sonunda hazırlık skorunu göreceksin.
      </p>
      <Diagnostic questions={questions} />
    </>
  );
}
