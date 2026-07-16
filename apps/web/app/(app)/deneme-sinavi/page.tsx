import type { Metadata } from 'next';
import { ExamSimulatorLazy } from '@/components/ExamSimulatorLazy';
import { ExamJsonLd } from '@/components/JsonLd';
import { PageHeader } from '@/components/ui/layout';

export const metadata: Metadata = {
  title: 'Deneme Sınavı (e-Sınav Simülatörü)',
  description:
    'Gerçek e-Sınav formatında deneme: 50 soru, 45 dakika, gerçek ders dağılımı (23/12/9/6) ve 35 doğru barajı.',
};

export default function DenemeSinaviPage() {
  return (
    <>
      <PageHeader
        title="Deneme Sınavı"
        emoji="⏱️"
        subtitle={
          <>
            Gerçek sınav formatında simülasyon. Bu bir <em>resmî MEB sınavı değildir</em>.
          </>
        }
      />
      <ExamJsonLd />
      <ExamSimulatorLazy />
    </>
  );
}
