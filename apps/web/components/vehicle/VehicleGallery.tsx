'use client';

/**
 * VehicleGallery — aranabilir bileşen galerisi (Program 2 · Faz 7).
 * Sistem gruplu premium foto kartları + TR-normalize arama + detay bağlantıları.
 */
import { useMemo, useState } from 'react';
import { partsBySystem, SYSTEM_LABEL, VEHICLE_PARTS, type VehicleSystem } from '@/content/vehicle';
import { VehicleFigure, VEHICLE_PART_IDS } from '@/components/vehicle/VehicleFigure';
import { AssetImage } from '@/components/ui/AssetImage';
import { EmptyState } from '@/components/ui/EmptyState';

const ORDER: VehicleSystem[] = ['motor-bolmesi', 'kabin', 'dis', 'muayene'];
const HAS_DIAGRAM = new Set(VEHICLE_PART_IDS);

function norm(s: string): string {
  return s
    .toLocaleLowerCase('tr')
    .replace(/[çğıöşü]/g, (c) => ({ ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u' })[c] ?? c);
}

export function VehicleGallery() {
  const [q, setQ] = useState('');
  const grouped = useMemo(() => {
    const nq = norm(q.trim());
    if (!nq) return partsBySystem();
    const filtered = VEHICLE_PARTS.filter(
      (p) => norm(p.name).includes(nq) || norm(p.desc).includes(nq)
    );
    const out = { 'motor-bolmesi': [], kabin: [], dis: [], muayene: [] } as ReturnType<
      typeof partsBySystem
    >;
    for (const p of filtered) out[p.system].push(p);
    return out;
  }, [q]);

  const total = ORDER.reduce((n, s) => n + grouped[s].length, 0);

  return (
    <>
      <input
        className="chat__input"
        style={{ width: '100%', marginTop: 4 }}
        placeholder="Bileşen ara… (örn. fren, filtre, zincir)"
        value={q}
        onChange={(e) => setQ(e.target.value)}
        aria-label="Araç bileşeni ara"
        data-testid="part-search"
      />

      {total === 0 ? (
        <div style={{ marginTop: 16 }}>
          <EmptyState
            testId="parts-empty"
            icon="🔎"
            title={`"${q}" için bileşen bulunamadı`}
            hint="Farklı bir kelimeyle ara: fren, kayış, filtre, lastik, kemer…"
          />
        </div>
      ) : (
        ORDER.map(
          (sys) =>
            grouped[sys].length > 0 && (
              <section key={sys} style={{ marginTop: 26 }}>
                <h2 className="section-title" style={{ marginTop: 0 }}>
                  {SYSTEM_LABEL[sys]} ({grouped[sys].length})
                </h2>
                <div className="vehicle-grid" data-testid={`vsys-${sys}`}>
                  {grouped[sys].map((p) => (
                    <div
                      className="card"
                      key={p.id}
                      style={{ margin: 0 }}
                      data-testid="vehicle-part"
                    >
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
                      <a
                        style={{
                          fontSize: '0.8rem',
                          display: 'inline-block',
                          marginTop: 8,
                          fontWeight: 700,
                        }}
                        href={`/arac/${p.id}`}
                        data-testid="part-detail-link"
                      >
                        Detay sayfası →
                      </a>
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
            )
        )
      )}
    </>
  );
}
