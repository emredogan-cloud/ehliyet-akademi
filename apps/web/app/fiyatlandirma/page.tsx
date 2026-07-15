import type { Metadata } from 'next';
import { Pricing } from '../../components/Pricing';

export const metadata: Metadata = {
  title: 'Fiyatlandırma — Bir Kez Öde, Ömür Boyu',
  description:
    'Abonelik yok: tek seferlik paketlerle kalıcı erişim. Premium Teori, Direksiyon, Simülatör, Soru Bankası ve Komple B Ehliyet Paketi.',
};

export default function FiyatlandirmaPage() {
  return (
    <>
      <h1 style={{ margin: '24px 0 6px' }}>Fiyatlandırma</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        <strong>Abonelik yok.</strong> Bir kez öde, paket ömür boyu senin. Ücretsiz kademe: tanı
        denemesi + günde 1 deneme sınavı + SRS pratiği.
      </p>
      <Pricing />
    </>
  );
}
