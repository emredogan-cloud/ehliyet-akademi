import type { Metadata } from 'next';
import { Dashboard } from '@/components/Dashboard';

export const metadata: Metadata = {
  title: 'Panel',
  description: 'Hazırlık skorun, günlük serin, ders bazlı ustalık ve sıradaki en iyi adım.',
  robots: { index: false }, // kişisel panel — indekslenmez
};

export default function PanelPage() {
  return (
    <>
      <h1 style={{ margin: '6px 0 4px' }}>Panel</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Hoş geldin! İşte güncel durumun.
      </p>
      <Dashboard />
    </>
  );
}
