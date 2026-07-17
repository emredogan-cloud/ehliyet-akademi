import type { Metadata } from 'next';
import { VEHICLE_PARTS } from '@/content/vehicle';
import { VehicleGallery } from '@/components/vehicle/VehicleGallery';
import { Hotspots } from '@/components/media/Hotspots';
import { ZoomImage } from '@/components/media/ZoomImage';
import { PageHeader } from '@/components/ui/layout';

export const metadata: Metadata = {
  title: 'Araç Tanıma',
  description:
    'Direksiyon ve araç tekniği için araç bileşenleri: motor bölmesi, kabin kumandaları, lastikler ve muayene noktaları — premium fotoğraflar, kontrol adımları ve detay sayfalarıyla.',
};

export default function AracPage() {
  return (
    <div data-testid="arac">
      <PageHeader
        title="Araç Tanıma"
        emoji="🚗"
        subtitle={
          <>
            {VEHICLE_PARTS.length} bileşen — direksiyon sınavı ve araç tekniği için premium
            fotoğraflı rehber. Her kartın detay sayfasında kontrol adımları ve sık hatalar var.
          </>
        }
        actions={
          // Üretilmiş başlık dekoru (ASSET A9)
          <img src="/assets/ui/vehicle-hero.webp" alt="" className="page-decor" aria-hidden />
        }
      />

      <section style={{ margin: '22px 0' }}>
        <h2 className="section-title" style={{ marginTop: 0 }}>
          İnteraktif keşif
        </h2>
        <div className="lesson-interactive" style={{ margin: 0 }}>
          <Hotspots sceneId="engine-bay-tour" />
          <ZoomImage
            assetId="fuse-box"
            caption="Sigorta kutusunu yakınlaştırarak incele — renkler amper değerini gösterir."
          />
        </div>
      </section>

      <VehicleGallery />
    </div>
  );
}
