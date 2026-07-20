'use client';

import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/ui/layout';

interface Collection {
  id: string;
  label: string;
  description: string;
  emoji: string;
  count: number;
  sample: Array<{ id: string; stem: string }>;
}

export default function KoleksiyonlarPage() {
  const [cols, setCols] = useState<Collection[] | null>(null);
  const [date, setDate] = useState('');
  const [open, setOpen] = useState<string | null>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    void fetch('/api/qip/collections')
      .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
      .then((d: { collections: Collection[]; date: string }) => {
        setCols(d.collections);
        setDate(d.date);
      })
      .catch(() => setErr('Koleksiyonlar yüklenemedi.'));
  }, []);

  return (
    <div>
      <PageHeader
        title="Sınav Koleksiyonları"
        emoji="🗂️"
        subtitle="Bankadan otomatik oluşturulan çalışma setleri — Günün Sınavı, Zor Sorular, Yalnız İşaretler ve daha fazlası. Her gün yenilenir."
      />

      {err && (
        <div className="explain" role="alert">
          {err}
        </div>
      )}

      {!cols ? (
        <div className="card" aria-busy="true">
          <div className="skeleton" style={{ height: 40 }} />
        </div>
      ) : (
        <div data-testid="collections">
          {date && (
            <p className="muted" style={{ fontSize: '0.82rem' }}>
              {date} için güncel · {cols.length} koleksiyon
            </p>
          )}
          <div
            style={{
              display: 'grid',
              gap: 12,
              gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))',
            }}
          >
            {cols.map((c) => (
              <div
                key={c.id}
                className="card"
                style={{ margin: 0 }}
                data-testid={`collection-${c.id}`}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <span style={{ fontSize: '1.6rem' }} aria-hidden>
                    {c.emoji}
                  </span>
                  <div style={{ flex: 1 }}>
                    <strong>{c.label}</strong>
                    <div className="muted" style={{ fontSize: '0.78rem' }}>
                      {c.count} soru
                    </div>
                  </div>
                </div>
                <p className="muted" style={{ margin: '8px 0 0', fontSize: '0.85rem' }}>
                  {c.description}
                </p>
                <button
                  className="ui-btn ui-btn--ghost ui-btn--sm"
                  style={{ marginTop: 10 }}
                  onClick={() => setOpen(open === c.id ? null : c.id)}
                  data-testid={`collection-peek-${c.id}`}
                >
                  {open === c.id ? 'Gizle' : 'Örnek soruları gör'}
                </button>
                {open === c.id && (
                  <ul style={{ margin: '8px 0 0 18px', fontSize: '0.83rem' }}>
                    {c.sample.map((s) => (
                      <li key={s.id}>{s.stem}</li>
                    ))}
                  </ul>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
