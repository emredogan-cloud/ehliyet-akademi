import type { Metadata } from 'next';
import { ExamSimulatorLazy } from '@/components/ExamSimulatorLazy';
import { ExamJsonLd } from '@/components/JsonLd';

export const metadata: Metadata = {
  title: 'Deneme Sınavı (e-Sınav Simülatörü)',
  description:
    'Gerçek e-Sınav formatında deneme: 50 soru, 45 dakika, gerçek ders dağılımı (23/12/9/6) ve 35 doğru barajı.',
};

export default function DenemeSinaviPage() {
  return (
    <>
      <h1 style={{ margin: '24px 0 6px' }}>Deneme Sınavı</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Gerçek sınav formatında simülasyon. Bu bir <em>resmî MEB sınavı değildir</em>.
      </p>
      <ExamJsonLd />
      <ExamSimulatorLazy />
    </>
  );
}
