import type { Metadata } from 'next';
import { PageHeader } from '@/components/ui/layout';
import { PricingView } from './PricingView';

export const metadata: Metadata = {
  title: 'Fiyatlandırma — Bir Kez Öde, Ömür Boyu',
  description:
    'Abonelik yok: tek seferlik paketlerle kalıcı erişim. Premium Teori, Direksiyon, Simülatör, Soru Bankası ve Komple B Ehliyet Paketi.',
};

export default function FiyatlandirmaPage() {
  return (
    <>
      <PageHeader
        title="Fiyatlandırma"
        subtitle={
          <>
            <strong>Abonelik yok.</strong> Tek ödeme, ömür boyu erişim. Ücretsiz kademe: tanı
            denemesi + günde 1 deneme sınavı + SRS pratiği.
          </>
        }
      />
      <PricingView />
    </>
  );
}
