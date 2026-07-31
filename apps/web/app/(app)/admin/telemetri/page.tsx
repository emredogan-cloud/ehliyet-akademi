'use client';

import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/ui/layout';

/**
 * Beta Faz 8 — telemetri panosu.
 *
 * Faz 3 ve 4 veri topluyordu ama okuyacak hiçbir yüzey yoktu. Yazılıp okunmayan telemetri en kötü
 * durumdur: maliyeti (istemci karmaşıklığı, ağ, depolama, KVKK yükümlülüğü) ödenir, faydası
 * alınmaz — üstelik bozulduğunda kimse fark etmez.
 */

interface EventCount {
  name: string;
  total: number;
  uniqueActors: number;
}
interface FunnelStep {
  label: string;
  value: number;
  conversion: number | null;
}
interface ErrorGroup {
  fingerprint: string;
  kind: string;
  message: string;
  route: string;
  count: number;
  affectedActors: number;
  lastSeen: string;
  appVersions: string[];
}
interface Payload {
  windowDays: number;
  events: EventCount[];
  funnel: FunnelStep[];
  referral: FunnelStep[];
  errors: ErrorGroup[];
  daily: Array<{ day: string; actors: number }>;
}

const pct = (v: number | null) => (v === null ? '—' : `%${Math.round(v * 100)}`);

function Funnel({ steps, testId }: { steps: FunnelStep[]; testId: string }) {
  const top = steps[0]?.value ?? 0;
  return (
    <div className="tlm-funnel" data-testid={testId}>
      {steps.map((s) => (
        <div className="tlm-step" key={s.label}>
          <div className="tlm-step__head">
            <span>{s.label}</span>
            <strong>{s.value}</strong>
          </div>
          <div className="tlm-bar">
            <div
              className="tlm-bar__fill"
              style={{ width: top > 0 ? `${Math.max(2, (s.value / top) * 100)}%` : '2%' }}
            />
          </div>
          {/* Bir önceki basamağa göre dönüşüm — düşüşün NEREDE olduğunu bu söyler. */}
          <span className="tlm-step__conv muted">{pct(s.conversion)}</span>
        </div>
      ))}
    </div>
  );
}

export default function AdminTelemetry() {
  const [data, setData] = useState<Payload | null>(null);
  const [days, setDays] = useState(30);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    setData(null);
    setFailed(false);
    void fetch(`/api/admin/telemetry?days=${days}`, { credentials: 'same-origin' })
      .then((r) => (r.ok ? r.json() : Promise.reject(new Error(String(r.status)))))
      .then((d: Payload) => setData(d))
      .catch(() => setFailed(true));
  }, [days]);

  return (
    <div>
      <PageHeader
        title="Telemetri"
        emoji="📈"
        subtitle="Ürün hunisi, olay sayıları, davet hunisi ve gruplanmış hata raporları."
      />

      <div className="tlm-range">
        {[7, 30, 90].map((d) => (
          <button
            key={d}
            type="button"
            className={`ui-btn ui-btn--sm ${d === days ? 'ui-btn--primary' : 'ui-btn--ghost'}`}
            onClick={() => setDays(d)}
          >
            Son {d} gün
          </button>
        ))}
      </div>

      {failed ? (
        <div className="card">
          <p style={{ margin: 0 }}>
            Telemetri okunamadı. Veritabanı bağlantısını ve yönetici yetkini kontrol et.
          </p>
        </div>
      ) : !data ? (
        <div className="skeleton" style={{ height: 260 }} />
      ) : (
        <>
          <h2 className="tlm-h2">Ürün hunisi</h2>
          <div className="card">
            <Funnel steps={data.funnel} testId="product-funnel" />
          </div>

          <h2 className="tlm-h2">Davet hunisi</h2>
          <div className="card">
            <Funnel steps={data.referral} testId="referral-funnel" />
          </div>

          <h2 className="tlm-h2">Hatalar</h2>
          {data.errors.length === 0 ? (
            <div className="card">
              <p style={{ margin: 0 }}>Bu dönemde hata raporu yok.</p>
            </div>
          ) : (
            <div className="table-wrap">
              <table className="tbl" data-testid="error-table">
                <thead>
                  <tr>
                    <th>Hata</th>
                    <th>Tür</th>
                    <th>Ekran</th>
                    <th>Kişi</th>
                    <th>Adet</th>
                    <th>Sürüm</th>
                  </tr>
                </thead>
                <tbody>
                  {data.errors.map((e) => (
                    <tr key={e.fingerprint}>
                      <td>{e.message}</td>
                      <td>{e.kind}</td>
                      <td>{e.route || '—'}</td>
                      {/* ETKİLENEN KİŞİ önce: tek bir cihazın döngüye girip bin rapor üretmesi
                          o hatayı en önemli hata yapmaz. */}
                      <td>
                        <strong>{e.affectedActors}</strong>
                      </td>
                      <td className="muted">{e.count}</td>
                      <td className="muted">{e.appVersions.join(', ') || '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          <h2 className="tlm-h2">Olaylar</h2>
          <div className="table-wrap">
            <table className="tbl" data-testid="event-table">
              <thead>
                <tr>
                  <th>Olay</th>
                  <th>Kişi</th>
                  <th>Toplam</th>
                </tr>
              </thead>
              <tbody>
                {data.events.map((e) => (
                  // Sıfır olan olaylar da LİSTELENİR: "listede yok" ile "sıfır" farklı şeylerdir.
                  // Birincisi ölçümün koptuğunu, ikincisi kimsenin yapmadığını gösterir.
                  <tr key={e.name} className={e.total === 0 ? 'tlm-zero' : undefined}>
                    <td>{e.name}</td>
                    <td>{e.uniqueActors}</td>
                    <td className="muted">{e.total}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}
    </div>
  );
}
