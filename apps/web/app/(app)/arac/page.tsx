import type { Metadata } from 'next';
import { partsBySystem, SYSTEM_LABEL, VEHICLE_PARTS, type VehicleSystem } from '@/content/vehicle';
import { VehicleFigure, VEHICLE_PART_IDS } from '@/components/vehicle/VehicleFigure';
import { AssetImage } from '@/components/ui/AssetImage';
import { Hotspots } from '@/components/media/Hotspots';
import { ZoomImage } from '@/components/media/ZoomImage';

export const metadata: Metadata = {
  title: 'Araç Tanıma',
  description:
    'Direksiyon ve araç tekniği için araç bileşenleri: motor bölmesi, kabin kumandaları, lastikler ve muayene noktaları — premium fotoğraflar ve özgün şemalarla.',
};

const ORDER: VehicleSystem[] = ['motor-bolmesi', 'kabin', 'dis', 'muayene'];
const HAS_DIAGRAM = new Set(VEHICLE_PART_IDS);

export default function AracPage() {
  const grouped = partsBySystem();
  return (
    <div data-testid="arac">
      <h1 style={{ margin: '24px 0 6px' }}>Araç Tanıma</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        {VEHICLE_PARTS.length} bileşen — direksiyon sınavı ve araç tekniği için premium fotoğraflı
        rehber. Her kart bileşenin görevini ve pratik ipucunu içerir.
      </p>

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

      {ORDER.map((sys) => (
        <section key={sys} style={{ marginTop: 26 }}>
          <h2 className="section-title" style={{ marginTop: 0 }}>
            {SYSTEM_LABEL[sys]}
          </h2>
          <div className="vehicle-grid" data-testid={`vsys-${sys}`}>
            {grouped[sys].map((p) => (
              <div className="card" key={p.id} style={{ margin: 0 }} data-testid="vehicle-part">
                {p.photo ? (
                  <AssetImage assetId={p.photo} caption={false} />
                ) : (
                  <VehicleFigure part={p.id} label={p.name} />
                )}
                <h3 style={{ margin: '10px 0 4px', fontSize: '1rem' }}>{p.name}</h3>
                <p className="muted" style={{ margin: '0 0 6px', fontSize: '0.85rem' }}>
                  {p.desc}
                </p>
                <p style={{ margin: 0, fontSize: '0.82rem', color: 'var(--primary)' }}>
                  💡 {p.tip}
                </p>
                {p.relatedLessonSlug && (
                  <a
                    className="muted"
                    style={{ fontSize: '0.78rem', display: 'inline-block', marginTop: 6 }}
                    href={`/dersler/${p.relatedLessonSlug}`}
                  >
                    İlgili ders →
                  </a>
                )}
                {p.photo && HAS_DIAGRAM.has(p.id) && (
                  <details style={{ marginTop: 8 }}>
                    <summary
                      className="muted"
                      style={{ fontSize: '0.78rem', cursor: 'pointer' }}
                      data-testid="diagram-toggle"
                    >
                      Çizim şeması
                    </summary>
                    <VehicleFigure part={p.id} label={p.name} />
                  </details>
                )}
              </div>
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
