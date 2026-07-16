import type { Metadata } from 'next';
import { AICoach } from '@/components/AICoach';
import { PageHeader } from '@/components/ui/layout';

export const metadata: Metadata = {
  title: 'AI Koç',
  description:
    'Takıldığın konuyu sor: AI Koç, ders ve soru bankası içeriğinden kaynaklı, güvenilir yanıt verir.',
};

export default function AIKocPage() {
  return (
    <>
      <PageHeader
        title="AI Koç"
        emoji="🤖"
        subtitle="İçeriğe dayalı (grounded) çalışma arkadaşın."
      />
      <AICoach />
    </>
  );
}
