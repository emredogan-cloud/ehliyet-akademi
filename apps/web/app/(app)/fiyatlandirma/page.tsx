import type { Metadata } from 'next';
import { PageHeader } from '@/components/ui/layout';
import { paymentConfigured } from '@/lib/server/checkout';
import { PricingView } from './PricingView';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Fiyatlandırma — Bir Kez Öde, Ömür Boyu',
  description:
    'Abonelik yok: tek seferlik ödemeyle Komple B Ehliyet Paketi — tüm premium dersler, sınırsız deneme, tam soru bankası ve AI Koç ömür boyu erişim.',
  path: '/fiyatlandirma',
});

// Ödeme sağlayıcı durumu ENV'den okunur (server) → istemciye dürüst bayraklar geçer.
export const dynamic = 'force-dynamic';

export default function FiyatlandirmaPage() {
  const realPayments = paymentConfigured();
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
      <PricingView realPayments={realPayments} />
    </>
  );
}
