import type { Metadata } from 'next';
import { PageHeader } from '@/components/ui/layout';
import { AramaLazy } from '@/components/AramaLazy';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Arama',
  description: 'Ders ve soru bankasında arama yap; istediğin konuyu hızlıca bul.',
  path: '/arama',
  noindex: true,
});

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
