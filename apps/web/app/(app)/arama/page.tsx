'use client';

/** Arama (Faz 28): SearchProvider soyutlaması üzerinden — Meili/Typesense/Algolia takılabilir. */
import { useEffect, useMemo, useState } from 'react';
import { getSearchProvider, type SearchHit } from '@/lib/search';
import { PageHeader } from '@/components/ui/layout';

export default function AramaPage() {
  const [q, setQ] = useState('');
  const [hits, setHits] = useState<SearchHit[]>([]);
  const provider = useMemo(() => getSearchProvider(), []);

  useEffect(() => {
    let alive = true;
    if (q.trim().length < 2) {
      setHits([]);
      return;
    }
    void provider.search(q).then((h) => {
      if (alive) setHits(h);
    });
    return () => {
      alive = false;
    };
  }, [q, provider]);

  const empty = q.trim().length >= 2 && hits.length === 0;

  return (
    <>
      <PageHeader
        title="Arama"
        emoji="🔍"
        subtitle={<>Ders ve soru bankasında anında ara. (Sağlayıcı: {provider.name})</>}
      />
      <input
        className="chat__input"
        style={{ width: '100%', maxWidth: 560 }}
        value={q}
        onChange={(e) => setQ(e.target.value)}
        placeholder="örn. hız sınırı, kalp masajı, DUR levhası…"
        aria-label="Arama"
        data-testid="search-input"
        autoFocus
      />

      {empty && (
        <div className="card" style={{ marginTop: 16 }} data-testid="search-empty">
          <p style={{ margin: 0 }}>&quot;{q}&quot; için sonuç yok. Farklı bir kelime dene.</p>
        </div>
      )}

      {hits.length > 0 && (
        <div style={{ display: 'grid', gap: 10, marginTop: 16 }} data-testid="search-results">
          {hits.map((h) => (
            <a key={h.type + h.id} className="card card--link" href={h.href}>
              <span className="badge">{h.type}</span>
              <p style={{ margin: '8px 0 4px', fontWeight: 600 }}>{h.title}</p>
              <p className="muted" style={{ margin: 0, fontSize: '0.9rem' }}>
                {h.snippet}
              </p>
            </a>
          ))}
        </div>
      )}
    </>
  );
}
