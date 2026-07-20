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
  graph: {
    nodeCount: number;
    edgeCount: number;
    byNodeType: Record<string, number>;
    byEdgeType: Record<string, number>;
    orphanQuestions: number;
    avgQuestionDegree: number;
  };
  families: {
    totalFamilies: number;
    multiVariant: number;
    singletons: number;
    largestSize: number;
    avgSize: number;
    questionsInMultiVariant: number;
  };
  validation: {
    score: number;
    passed: boolean;
    checks: Array<{ id: string; label: string; status: 'ok' | 'warn' | 'fail'; detail: string }>;
  };
}

const VStatus: Record<string, { icon: string; color: string }> = {
  ok: { icon: '✓', color: 'var(--accent-green)' },
  warn: { icon: '!', color: 'var(--accent-amber)' },
  fail: { icon: '✕', color: 'var(--accent-red)' },
};

const NODE_LABEL: Record<string, string> = {
  question: 'Soru',
  lesson: 'Ders',
  sign: 'İşaret',
  part: 'Araç Parçası',
  topic: 'Konu',
  theme: 'Tema',
  subject: 'Ders (alan)',
  scenario: 'Senaryo',
};
const EDGE_LABEL: Record<string, string> = {
  'belongs-to': 'ait',
  'about-topic': 'konu',
  'classified-as': 'tema',
  'related-lesson': 'ilgili ders',
  'depicts-sign': 'işaret',
  'depicts-part': 'parça',
};

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

          {/* Nihai Doğrulama */}
          <h2 className="section-title" style={{ marginTop: 22 }}>
            Nihai Doğrulama
          </h2>
          <div className="card" data-testid="qip-validation">
            <div style={{ display: 'flex', alignItems: 'center', gap: 16, flexWrap: 'wrap' }}>
              <div
                style={{
                  fontSize: '2rem',
                  fontWeight: 800,
                  color: data.validation.passed ? 'var(--accent-green)' : 'var(--accent-red)',
                }}
              >
                {data.validation.score}
              </div>
              <div>
                <strong>{data.validation.passed ? 'GEÇTİ' : 'SORUN VAR'}</strong>
                <div className="muted" style={{ fontSize: '0.78rem' }}>
                  bütünlük · yineleme · kalite · denge · görsel · referans · grafik
                </div>
              </div>
            </div>
            <div style={{ display: 'grid', gap: 6, marginTop: 12 }}>
              {data.validation.checks.map((c) => {
                const m = VStatus[c.status]!;
                return (
                  <div
                    key={c.id}
                    style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '0.85rem' }}
                    data-testid={`qip-check-${c.id}`}
                  >
                    <span style={{ color: m.color, fontWeight: 800, minWidth: 14 }}>{m.icon}</span>
                    <strong style={{ minWidth: 190 }}>{c.label}</strong>
                    <span className="muted">{c.detail}</span>
                  </div>
                );
              })}
            </div>
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

          {/* Bilgi grafiği */}
          <h2 className="section-title" style={{ marginTop: 22 }}>
            Bilgi Grafiği
          </h2>
          <div className="card" data-testid="qip-graph">
            <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap' }}>
              <Stat label="Düğüm" value={data.graph.nodeCount} />
              <Stat label="Kenar" value={data.graph.edgeCount} />
              <Stat label="Ort. soru derecesi" value={data.graph.avgQuestionDegree} />
              <Stat label="Zengin bağı olmayan soru" value={data.graph.orphanQuestions} />
            </div>
            <div style={{ display: 'flex', gap: 18, flexWrap: 'wrap', marginTop: 14 }}>
              {Object.entries(data.graph.byNodeType).map(([k, v]) => (
                <div key={k}>
                  <div style={{ fontSize: '1.05rem', fontWeight: 700 }}>{v}</div>
                  <div className="muted" style={{ fontSize: '0.72rem' }}>
                    {NODE_LABEL[k] ?? k}
                  </div>
                </div>
              ))}
            </div>
            <div className="muted" style={{ fontSize: '0.78rem', marginTop: 12 }}>
              Kenarlar:{' '}
              {Object.entries(data.graph.byEdgeType)
                .map(([k, v]) => `${EDGE_LABEL[k] ?? k} ${v}`)
                .join(' · ')}
            </div>
          </div>

          {/* Soru aileleri */}
          <h2 className="section-title" style={{ marginTop: 22 }}>
            Soru Aileleri (bir kavram → çok varyant)
          </h2>
          <div className="card" data-testid="qip-families">
            <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap' }}>
              <Stat label="Aile" value={data.families.totalFamilies} />
              <Stat label="Çok varyantlı" value={data.families.multiVariant} />
              <Stat label="Tekil" value={data.families.singletons} />
              <Stat label="En büyük aile" value={data.families.largestSize} />
              <Stat label="Ort. boyut" value={data.families.avgSize} />
              <Stat label="Adaptif kapsam (soru)" value={data.families.questionsInMultiVariant} />
            </div>
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
