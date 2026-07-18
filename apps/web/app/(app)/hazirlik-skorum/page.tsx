import type { Metadata } from 'next';
import { HazirlikSkorumContent } from '@/components/HazirlikSkorumContent';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Hazırlık Skorum',
  description:
    'Tanı denemesi ve çözdüğün sorulardan hesaplanan kişisel hazırlık skorun: konu bazlı ustalık, zayıf alanlar ve sınava ne kadar hazır olduğunu gösteren analiz.',
  path: '/hazirlik-skorum',
  keywords: ['ehliyet hazırlık', 'hazırlık skoru', 'sınav hazırlık analizi'],
});

export default function HazirlikSkorumPage() {
  return <HazirlikSkorumContent />;
}
