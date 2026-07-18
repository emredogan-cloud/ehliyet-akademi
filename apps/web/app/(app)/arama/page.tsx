import type { Metadata } from 'next';
import { PageHeader } from '@/components/ui/layout';
import { AramaLazy } from '@/components/AramaLazy';

export const metadata: Metadata = {
  title: 'Arama',
  description: 'Ders ve soru bankasında arama yap; istediğin konuyu hızlıca bul.',
};

export default function AramaPage() {
  return (
    <>
      <PageHeader
        title="Arama"
        emoji="🔍"
        subtitle="Ders ve soru bankasında arama yap, istediğin konuyu hızlıca bul."
      />
      <AramaLazy />
    </>
  );
}
