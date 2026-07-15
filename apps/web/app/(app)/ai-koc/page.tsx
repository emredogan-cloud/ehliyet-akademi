import type { Metadata } from 'next';
import { AICoach } from '@/components/AICoach';

export const metadata: Metadata = {
  title: 'AI Koç',
  description:
    'Takıldığın konuyu sor: AI Koç, ders ve soru bankası içeriğinden kaynaklı, güvenilir yanıt verir.',
};

export default function AIKocPage() {
  return (
    <>
      <h1 style={{ margin: '6px 0 4px' }}>AI Koç</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        İçeriğe dayalı (grounded) çalışma arkadaşın.
      </p>
      <AICoach />
    </>
  );
}
