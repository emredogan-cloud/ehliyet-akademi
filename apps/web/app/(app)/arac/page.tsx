import type { Metadata } from 'next';
import { VEHICLE_PARTS } from '@/content/vehicle';
import { VehicleGallery } from '@/components/vehicle/VehicleGallery';
import { Hotspots } from '@/components/media/Hotspots';
import { ZoomImage } from '@/components/media/ZoomImage';
import { PageHeader } from '@/components/ui/layout';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Araç Tanıma',
  description:
    'Direksiyon ve araç tekniği için araç bileşenleri: motor bölmesi, kabin kumandaları, lastikler ve muayene noktaları — premium fotoğraflar, kontrol adımları ve detay sayfalarıyla.',
  path: '/arac',
});

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

      <section style={{ margin: '26px 0' }}>
        <h2 className="section-title" style={{ marginTop: 0 }}>
          Araç Rehber Posterleri
        </h2>
        <p className="muted" style={{ marginTop: 0, fontSize: 'var(--fs-sm)' }}>
          Ehliyet kursu aracının bölge bölge rehberi — postere tıkla, tam boyutunda incele.
        </p>
        <div className="grid-auto" style={{ ['--grid-min' as string]: '260px' }}>
          {[
            {
              src: '/assets/vehicle-posters/gosterge-paneli.webp',
              t: 'Gösterge Paneli İşaretleri',
            },
            { src: '/assets/vehicle-posters/arac-ici-kontroller.webp', t: 'Araç İçi Kontroller' },
            { src: '/assets/vehicle-posters/kaput-alti.webp', t: 'Kaput Altı Rehberi' },
            { src: '/assets/vehicle-posters/bagaj-ici.webp', t: 'Bagaj Malzemeleri' },
            { src: '/assets/vehicle-posters/materyaller-genel.webp', t: 'Genel Materyal Haritası' },
            { src: '/assets/vehicle-posters/ikaz-isiklari.webp', t: 'İkaz Işıkları Seti' },
          ].map((pst) => (
            <a
              key={pst.src}
              className="ui-card ui-card--interactive poster-card"
              href={pst.src}
              target="_blank"
              rel="noopener"
              aria-label={`${pst.t} — tam boyut aç`}
            >
              <img src={pst.src} alt={pst.t} loading="lazy" />
              <strong>{pst.t}</strong>
            </a>
          ))}
        </div>
      </section>

      <VehicleGallery />
    </div>
  );
}
