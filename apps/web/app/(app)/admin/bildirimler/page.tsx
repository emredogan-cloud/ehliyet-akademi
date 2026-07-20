'use client';

import { useCallback, useEffect, useState } from 'react';
import { PageHeader } from '@/components/ui/layout';

interface Report {
  id: string;
  questionId: string;
  kind: string;
  message: string;
  status: string;
  createdAt: string;
}

const KIND_LABEL: Record<string, string> = {
  'wrong-answer': 'Yanlış cevap',
  unclear: 'Belirsiz ifade',
  typo: 'Yazım hatası',
  suggestion: 'Öneri',
  other: 'Diğer',
};

export default function AdminReportsPage() {
  const [reports, setReports] = useState<Report[] | null>(null);
  const [filter, setFilter] = useState('open');
  const [err, setErr] = useState('');

  const load = useCallback(() => {
    const qs = filter === 'all' ? '' : `?status=${filter}`;
    void fetch(`/api/admin/reports${qs}`, { credentials: 'same-origin' })
      .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
      .then((d: { reports: Report[] }) => setReports(d.reports))
      .catch(() => setErr('Bildirimler yüklenemedi (admin/editör gerekli).'));
  }, [filter]);

  useEffect(() => load(), [load]);

  async function setStatus(id: string, status: string) {
    await fetch('/api/admin/reports', {
      method: 'PATCH',
      credentials: 'same-origin',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ id, status }),
    });
    load();
  }

  return (
    <div>
      <PageHeader
        title="Soru Bildirimleri"
        emoji="🚩"
        subtitle="Kullanıcıların bildirdiği hata, belirsizlik ve önerileri incele; çöz veya reddet."
      />

      <div className="toolbar" role="tablist" style={{ marginBottom: 12 }}>
        {['open', 'resolved', 'dismissed', 'all'].map((f) => (
          <button
            key={f}
            className={`btn ${filter === f ? '' : 'btn--ghost'}`}
            onClick={() => setFilter(f)}
            data-testid={`reports-filter-${f}`}
          >
            {f === 'open'
              ? 'Açık'
              : f === 'resolved'
                ? 'Çözüldü'
                : f === 'dismissed'
                  ? 'Reddedildi'
                  : 'Tümü'}
          </button>
        ))}
      </div>

      {err && (
        <div className="explain" role="alert">
          {err}
        </div>
      )}

      {!reports ? (
        <div className="card" aria-busy="true">
          <div className="skeleton" style={{ height: 40 }} />
        </div>
      ) : reports.length === 0 ? (
        <div className="card" data-testid="reports-empty">
          Bu filtrede bildirim yok.
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 10 }} data-testid="reports-list">
          {reports.map((r) => (
            <div key={r.id} className="card" style={{ margin: 0 }} data-testid="report-item">
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <span className="badge">{KIND_LABEL[r.kind] ?? r.kind}</span>
                <code style={{ fontSize: '0.82rem' }}>{r.questionId}</code>
                <span className="muted" style={{ marginLeft: 'auto', fontSize: '0.78rem' }}>
                  {r.status}
                </span>
              </div>
              {r.message && <p style={{ margin: '6px 0 0', fontSize: '0.88rem' }}>{r.message}</p>}
              {r.status === 'open' && (
                <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
                  <button
                    className="ui-btn ui-btn--primary ui-btn--sm"
                    onClick={() => setStatus(r.id, 'resolved')}
                    data-testid="report-resolve"
                  >
                    Çöz
                  </button>
                  <button
                    className="ui-btn ui-btn--ghost ui-btn--sm"
                    onClick={() => setStatus(r.id, 'dismissed')}
                    data-testid="report-dismiss"
                  >
                    Reddet
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
