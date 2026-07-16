import type { Metadata } from 'next';
import { Pricing } from '@/components/Pricing';
import { PageHeader } from '@/components/ui/layout';

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
        emoji="⭐"
        subtitle={
          <>
            <strong>Abonelik yok.</strong> Bir kez öde, paket ömür boyu senin. Ücretsiz kademe: tanı
            denemesi + günde 1 deneme sınavı + SRS pratiği.
          </>
        }
      />
      <Pricing />
    </>
  );
}
