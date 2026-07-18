import type { Metadata } from 'next';
import { Dashboard } from '@/components/Dashboard';
import { PageHeader } from '@/components/ui/layout';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Panel',
  description: 'Hazırlık skorun, günlük serin, ders bazlı ustalık ve sıradaki en iyi adım.',
  path: '/panel',
  noindex: true, // kişisel panel — indekslenmez
});

export default function PanelPage() {
  return (
    <>
      <PageHeader
        title="Panel"
        emoji="👋"
        subtitle="Hoş geldin! İyi bir güncelle harika bir sürüşle devam et."
      />
      <Dashboard />
    </>
  );
}
