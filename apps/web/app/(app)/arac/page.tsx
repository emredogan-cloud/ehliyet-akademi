import type { Metadata } from 'next';
import { partsBySystem, SYSTEM_LABEL, VEHICLE_PARTS, type VehicleSystem } from '@/content/vehicle';
import { VehicleFigure } from '@/components/vehicle/VehicleFigure';

export const metadata: Metadata = {
  title: 'Araç Tanıma',
  description:
    'Direksiyon ve araç tekniği için araç bileşenleri: motor bölmesi, kabin kumandaları, lastikler ve muayene noktaları — özgün görsellerle.',
};

const ORDER: VehicleSystem[] = ['motor-bolmesi', 'kabin', 'dis', 'muayene'];

export default function AracPage() {
  const grouped = partsBySystem();
  return (
    <div data-testid="arac">
      <h1 style={{ margin: '24px 0 6px' }}>Araç Tanıma</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        {VEHICLE_PARTS.length} bileşen — direksiyon sınavı ve araç tekniği için görselli rehber. Her
        kart bileşenin görevini ve pratik ipucunu içerir.
      </p>

      {ORDER.map((sys) => (
        <section key={sys} style={{ marginTop: 26 }}>
          <h2 className="section-title" style={{ marginTop: 0 }}>
            {SYSTEM_LABEL[sys]}
          </h2>
          <div className="sign-grid" data-testid={`vsys-${sys}`}>
            {grouped[sys].map((p) => (
              <div className="card" key={p.id} style={{ margin: 0 }} data-testid="vehicle-part">
                <VehicleFigure part={p.id} label={p.name} />
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
              </div>
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
