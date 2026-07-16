import type { Metadata } from 'next';
import { Dashboard } from '@/components/Dashboard';
import { PageHeader } from '@/components/ui/layout';

export const metadata: Metadata = {
  title: 'Panel',
  description: 'Hazırlık skorun, günlük serin, ders bazlı ustalık ve sıradaki en iyi adım.',
  robots: { index: false }, // kişisel panel — indekslenmez
};

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
