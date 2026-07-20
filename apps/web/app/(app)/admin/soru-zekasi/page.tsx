'use client';

import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/ui/layout';

interface Intelligence {
  coverage: {
    total: number;
    byCategory: Record<string, number>;
    byDifficulty: Record<string, number>;
    withRelatedLesson: number;
    withRelatedSigns: number;
    withRelatedVehicleParts: number;
    uniqueFingerprints: number;
    estimatedTotalMinutes: number;
  };
  categoryDistribution: Record<string, number>;
  themeDistribution: Array<{ id: string; label: string; count: number }>;
  classifiedByTheme: number;
  quality: {
    count: number;
    avg: number;
    min: number;
    max: number;
    below70: number;
    below50: number;
    flagged: number;
    flagHistogram: Record<string, number>;
  };
  dedup: {
    total: number;
    exactDuplicateRecords: number;
    nearDuplicatePairs: number;
    nearDuplicateClusters: number;
    duplicateRatePct: number;
    topPairs: Array<{ a: string; b: string; similarity: number }>;
  };
}

function Bar({ value, max, color }: { value: number; max: number; color: string }) {
  const pct = max > 0 ? Math.round((value / max) * 100) : 0;
  return (
    <div style={{ background: 'var(--surface-2, #eee)', borderRadius: 6, height: 8, flex: 1 }}>
      <div style={{ width: `${pct}%`, background: color, height: 8, borderRadius: 6 }} />
    </div>
  );
}

export default function AdminQipPage() {
  const [data, setData] = useState<Intelligence | null>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    void fetch('/api/admin/qip', { credentials: 'same-origin' })
      .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
      .then((d: { intelligence: Intelligence }) => setData(d.intelligence))
      .catch(() => setErr('Soru zekâsı özeti yüklenemedi (admin/editör gerekli).'));
  }, []);

  const pctClassified = data
    ? Math.round((data.classifiedByTheme / data.coverage.total) * 1000) / 10
    : 0;
  const maxTheme = data ? Math.max(...data.themeDistribution.map((t) => t.count), 1) : 1;
  const topFlags = data
    ? Object.entries(data.quality.flagHistogram).sort((a, b) => b[1] - a[1])
    : [];

  return (
    <div>
      <PageHeader
        title="Soru Zekâsı"
        emoji="🧠"
        subtitle="Akıllı sınıflandırma, kalite analizi ve yineleme tespiti — bankadan gerçek zamanlı hesaplanır."
      />

      {err && (
        <div className="explain" role="alert">
          {err}
        </div>
      )}

      {!data ? (
        <div className="card" aria-busy="true">
          <div className="skeleton" style={{ height: 40 }} />
        </div>
      ) : (
        <div data-testid="qip-panel">
          {/* Genel istatistik */}
          <div
            className="card"
            style={{ display: 'flex', gap: 24, flexWrap: 'wrap', alignItems: 'center' }}
          >
            <Stat label="Soru" value={data.coverage.total} testid="qip-stat-total" />
            <Stat label="Kategori" value={Object.keys(data.categoryDistribution).length} />
            <Stat label="Tema" value={data.themeDistribution.length} />
            <Stat label="Temaya atanan" value={`%${pctClassified}`} />
            <Stat label="Benzersiz parmak izi" value={data.coverage.uniqueFingerprints} />
            <Stat label="Tahmini süre (dk)" value={data.coverage.estimatedTotalMinutes} />
          </div>

          {/* Kalite */}
          <h2 className="section-title" style={{ marginTop: 22 }}>
            Kalite Analizi
          </h2>
          <div className="card" data-testid="qip-quality">
            <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap' }}>
              <Stat label="Ortalama skor" value={data.quality.avg} />
              <Stat label="En düşük" value={data.quality.min} />
              <Stat label="En yüksek" value={data.quality.max} />
              <Stat label="70 altı" value={data.quality.below70} />
              <Stat label="Bayraklı" value={data.quality.flagged} />
            </div>
            {topFlags.length > 0 && (
              <div style={{ marginTop: 14 }}>
                <div className="muted" style={{ fontSize: '0.82rem', marginBottom: 6 }}>
                  En sık kalite bayrakları
                </div>
                <div style={{ display: 'grid', gap: 6 }}>
                  {topFlags.map(([flag, count]) => (
                    <div key={flag} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <span style={{ minWidth: 220, fontSize: '0.85rem' }}>{flag}</span>
                      <Bar value={count} max={topFlags[0]![1]} color="var(--accent-amber)" />
                      <strong style={{ minWidth: 40, textAlign: 'right' }}>{count}</strong>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Yineleme */}
          <h2 className="section-title" style={{ marginTop: 22 }}>
            Yineleme Tespiti
          </h2>
          <div className="card" data-testid="qip-dedup">
            <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap' }}>
              <Stat label="Tam yineleme" value={data.dedup.exactDuplicateRecords} />
              <Stat label="Yakın-yineleme çifti" value={data.dedup.nearDuplicatePairs} />
              <Stat label="Yakın küme" value={data.dedup.nearDuplicateClusters} />
              <Stat label="Yineleme oranı" value={`%${data.dedup.duplicateRatePct}`} />
            </div>
            {data.dedup.topPairs.length > 0 && (
              <div style={{ marginTop: 14 }}>
                <div className="muted" style={{ fontSize: '0.82rem', marginBottom: 6 }}>
                  En yüksek benzerlikli çiftler (birleştirme adayı)
                </div>
                <ul style={{ margin: 0, paddingLeft: 18, fontSize: '0.85rem' }}>
                  {data.dedup.topPairs.slice(0, 8).map((p) => (
                    <li key={`${p.a}-${p.b}`}>
                      <code>{p.a}</code> ≈ <code>{p.b}</code> — %{Math.round(p.similarity * 100)}{' '}
                      benzerlik
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </div>

          {/* Tema dağılımı */}
          <h2 className="section-title" style={{ marginTop: 22 }}>
            Tema Dağılımı ({pctClassified}% özel temaya atanmış)
          </h2>
          <div className="card" style={{ display: 'grid', gap: 6 }}>
            {data.themeDistribution.slice(0, 20).map((t) => (
              <div
                key={t.id}
                style={{ display: 'flex', alignItems: 'center', gap: 10 }}
                data-testid={`qip-theme-${t.id}`}
              >
                <span style={{ minWidth: 210, fontSize: '0.85rem' }}>{t.label}</span>
                <Bar value={t.count} max={maxTheme} color="var(--accent-green)" />
                <strong style={{ minWidth: 40, textAlign: 'right' }}>{t.count}</strong>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function Stat({
  label,
  value,
  testid,
}: {
  label: string;
  value: number | string;
  testid?: string;
}) {
  return (
    <div data-testid={testid}>
      <div style={{ fontSize: '1.5rem', fontWeight: 800 }}>{value}</div>
      <div className="muted" style={{ fontSize: '0.78rem' }}>
        {label}
      </div>
    </div>
  );
}
