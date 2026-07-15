'use client';

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

interface Row {
  id: string;
  type: string;
  slug: string;
  title: string;
  status: string;
  version: number;
  updatedAt: string;
}

const TYPES = ['', 'article', 'seo_page', 'kb', 'lesson', 'question'];
const STATUSES = ['', 'draft', 'in_review', 'approved', 'published', 'retired'];

export default function AdminContent() {
  const router = useRouter();
  const [rows, setRows] = useState<Row[] | null>(null);
  const [type, setType] = useState('');
  const [status, setStatus] = useState('');
  const [q, setQ] = useState('');
  const [creating, setCreating] = useState(false);
  const [msg, setMsg] = useState('');

  const load = useCallback(async () => {
    const p = new URLSearchParams();
    if (type) p.set('type', type);
    if (status) p.set('status', status);
    if (q) p.set('q', q);
    const r = await fetch(`/api/admin/content?${p}`, { credentials: 'same-origin' });
    if (r.ok) setRows(((await r.json()) as { items: Row[] }).items);
  }, [type, status, q]);

  useEffect(() => {
    void load();
  }, [load]);

  async function quickCreateArticle() {
    setCreating(true);
    setMsg('');
    const stamp = Date.now();
    const body = {
      type: 'article',
      slug: `yeni-makale-${stamp}`,
      title: 'Yeni Makale (taslak)',
      payload: {
        title: 'Yeni Makale (taslak)',
        summary: 'Bu makalenin özetini düzenleyin.',
        body: 'Makale gövdesini buraya yazın. En az yirmi karakter olmalıdır ve düzenlenebilir.',
      },
    };
    const r = await fetch('/api/admin/content', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      credentials: 'same-origin',
      body: JSON.stringify(body),
    });
    setCreating(false);
    if (r.status === 201) {
      const { id } = (await r.json()) as { id: string };
      router.push(`/admin/icerik/${id}`);
    } else {
      setMsg('Oluşturulamadı.');
    }
  }

  return (
    <div>
      <div className="toolbar">
        <h1 style={{ margin: 0, marginRight: 'auto' }}>İçerik</h1>
        <button
          className="btn"
          onClick={quickCreateArticle}
          disabled={creating}
          data-testid="new-article"
        >
          {creating ? 'Oluşturuluyor…' : '+ Makale taslağı'}
        </button>
      </div>

      <div className="toolbar">
        <select
          value={type}
          onChange={(e) => setType(e.target.value)}
          aria-label="Tür"
          data-testid="filter-type"
        >
          {TYPES.map((t) => (
            <option key={t} value={t}>
              {t || 'Tüm türler'}
            </option>
          ))}
        </select>
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          aria-label="Durum"
          data-testid="filter-status"
        >
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {s || 'Tüm durumlar'}
            </option>
          ))}
        </select>
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Başlık/slug ara…"
          aria-label="Ara"
          data-testid="filter-q"
        />
      </div>

      {msg && (
        <div className="explain" role="alert">
          {msg}
        </div>
      )}

      {!rows ? (
        <div className="skeleton" style={{ height: 200 }} />
      ) : rows.length === 0 ? (
        <div className="card" data-testid="content-empty">
          <p style={{ margin: 0 }}>Eşleşen içerik yok. Yeni bir taslak oluşturabilirsin.</p>
        </div>
      ) : (
        <div className="table-wrap">
          <table className="tbl" data-testid="content-table">
            <thead>
              <tr>
                <th>Başlık</th>
                <th>Tür</th>
                <th>Durum</th>
                <th>Sürüm</th>
                <th>Güncellendi</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr
                  key={r.id}
                  onClick={() => router.push(`/admin/icerik/${r.id}`)}
                  style={{ cursor: 'pointer' }}
                  data-testid="content-row"
                >
                  <td>
                    <strong>{r.title}</strong>
                    <div className="muted" style={{ fontSize: '0.8rem' }}>
                      {r.slug}
                    </div>
                  </td>
                  <td>{r.type}</td>
                  <td>
                    <span className={`pill pill--${r.status}`}>{r.status}</span>
                  </td>
                  <td>v{r.version}</td>
                  <td className="muted">{new Date(r.updatedAt).toLocaleDateString('tr-TR')}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
