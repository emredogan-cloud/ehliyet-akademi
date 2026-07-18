import type { Metadata } from 'next';
import { PageHeader } from '@/components/ui/layout';
import { PRODUCTS } from '@/lib/products';
import { paymentConfigured, variantForProduct } from '@/lib/server/checkout';
import { PricingView } from './PricingView';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Fiyatlandırma — Bir Kez Öde, Ömür Boyu',
  description:
    'Abonelik yok: tek seferlik paketlerle kalıcı erişim. Premium Teori, Direksiyon, Simülatör, Soru Bankası ve Komple B Ehliyet Paketi.',
  path: '/fiyatlandirma',
});

// Ödeme sağlayıcı durumu ENV'den okunur (server) → istemciye dürüst bayraklar geçer.
export const dynamic = 'force-dynamic';

export default function FiyatlandirmaPage() {
  const realPayments = paymentConfigured();
  // Gerçek sağlayıcıda yalnız variant'ı tanımlı paketler satın alınabilir;
  // mock modda (yerel/dev) tümü demo akışıyla alınabilir.
  const purchasable = PRODUCTS.filter((p) => !realPayments || Boolean(variantForProduct(p.id))).map(
    (p) => p.id
  );
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
      <PricingView realPayments={realPayments} purchasable={purchasable} />
    </>
  );
}
