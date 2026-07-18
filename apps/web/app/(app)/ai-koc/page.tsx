import type { Metadata } from 'next';
import { AICoach } from '@/components/AICoach';
import { PageHeader } from '@/components/ui/layout';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'AI Koç',
  description:
    'Takıldığın konuyu sor: AI Koç, ders ve soru bankası içeriğinden kaynaklı, güvenilir yanıt verir.',
  path: '/ai-koc',
});

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
