import type { Metadata } from 'next';
import { SIGNS } from '@/content/signs';
import { IsaretlerContent } from '@/components/IsaretlerContent';
import { CollectionJsonLd } from '@/components/JsonLd';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Trafik İşaretleri — Anlamları ve Açıklamaları',
  description: `${SIGNS.length} Türkiye trafik işareti: tehlike uyarı, yasaklayıcı, mecburiyet, bilgi ve öncelik levhaları — anlamları, hafıza teknikleri ve sınav soruları ile. Ehliyet Akademi.`,
  path: '/isaretler',
  keywords: [
    'trafik işaretleri',
    'trafik levhaları',
    'trafik işaretleri anlamları',
    'trafik levhası anlamları',
    'ehliyet trafik işaretleri',
  ],
});

export default function IsaretlerPage() {
  return (
    <>
      <CollectionJsonLd
        name="Türkiye Trafik İşaretleri"
        description={`${SIGNS.length} trafik işareti: anlamları, kategorileri ve sınav önemi.`}
        path="/isaretler"
        itemCount={SIGNS.length}
        breadcrumb={[
          { name: 'Ana Sayfa', path: '/' },
          { name: 'Trafik İşaretleri', path: '/isaretler' },
        ]}
      />
      <IsaretlerContent />
    </>
  );
}
