'use client';

import { useCallback, useEffect, useState } from 'react';
import { useParams } from 'next/navigation';

interface Version {
  version: number;
  status: string;
  changedBy: string;
  createdAt: string;
}
interface Item {
  id: string;
  type: string;
  slug: string;
  title: string;
  status: string;
  version: number;
  payload: Record<string, unknown>;
  versions: Version[];
}

const NEXT: Record<string, Array<{ to: string; label: string }>> = {
  draft: [{ to: 'in_review', label: 'İncelemeye gönder' }],
  in_review: [
    { to: 'approved', label: 'Onayla' },
    { to: 'draft', label: 'Taslağa geri al' },
  ],
  approved: [
    { to: 'published', label: 'Yayınla' },
    { to: 'draft', label: 'Taslağa geri al' },
  ],
  published: [{ to: 'retired', label: 'Emekliye ayır' }],
  retired: [{ to: 'draft', label: 'Yeniden çalış' }],
};

export default function AdminContentEdit() {
  const params = useParams<{ id: string }>();
  const id = params.id;
  const [item, setItem] = useState<Item | null>(null);
  const [payloadText, setPayloadText] = useState('');
  const [title, setTitle] = useState('');
  const [msg, setMsg] = useState('');
  const [err, setErr] = useState('');

  const load = useCallback(async () => {
    const r = await fetch(`/api/admin/content/${id}`, { credentials: 'same-origin' });
    if (r.ok) {
      const { item } = (await r.json()) as { item: Item };
      setItem(item);
      setTitle(item.title);
      setPayloadText(JSON.stringify(item.payload, null, 2));
    }
  }, [id]);

  useEffect(() => {
    void load();
  }, [load]);

  async function save() {
    setErr('');
    setMsg('');
    let payload: unknown;
    try {
      payload = JSON.parse(payloadText);
    } catch {
      return setErr('Payload geçerli JSON değil.');
    }
    const r = await fetch(`/api/admin/content/${id}`, {
      method: 'PUT',
      headers: { 'content-type': 'application/json' },
      credentials: 'same-origin',
      body: JSON.stringify({ title, payload }),
    });
    if (r.ok) {
      setMsg('Kaydedildi (yeni sürüm).');
      await load();
    } else {
      const d = (await r.json()) as { errors?: string[] };
      setErr('Doğrulama hatası: ' + (d.errors ?? []).join(' · '));
    }
  }

  async function transition(to: string) {
    setErr('');
    setMsg('');
    const r = await fetch(`/api/admin/content/${id}`, {
      method: 'PATCH',
      headers: { 'content-type': 'application/json' },
      credentials: 'same-origin',
      body: JSON.stringify({ to }),
    });
    if (r.ok) {
      setMsg(`Durum: ${to}`);
      await load();
    } else {
      const d = (await r.json()) as { errors?: string[] };
      setErr((d.errors ?? ['Geçiş reddedildi.']).join(' · '));
    }
  }

  if (!item) return <div className="skeleton" style={{ height: 260 }} />;

  return (
    <div>
      <div className="toolbar">
        <a href="/admin/icerik" className="btn btn--ghost">
          ← İçerik listesi
        </a>
        <span className={`pill pill--${item.status}`} data-testid="edit-status">
          {item.status}
        </span>
        <span className="muted">
          {item.type} · v{item.version}
        </span>
      </div>

      {msg && (
        <div className="explain" role="status" data-testid="edit-msg">
          {msg}
        </div>
      )}
      {err && (
        <div
          className="explain"
          role="alert"
          style={{ borderColor: 'var(--red)' }}
          data-testid="edit-err"
        >
          {err}
        </div>
      )}

      <div className="card" style={{ display: 'grid', gap: 12 }}>
        <label>
          Başlık
          <input
            className="chat__input"
            style={{ width: '100%', marginTop: 4 }}
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            data-testid="edit-title"
          />
        </label>
        <label>
          Payload (JSON — Zod ile doğrulanır)
          <textarea
            className="chat__input"
            style={{
              width: '100%',
              marginTop: 4,
              minHeight: 220,
              fontFamily: 'var(--mono, monospace)',
            }}
            value={payloadText}
            onChange={(e) => setPayloadText(e.target.value)}
            data-testid="edit-payload"
          />
        </label>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <button className="btn" onClick={save} data-testid="edit-save">
            Kaydet
          </button>
          {(NEXT[item.status] ?? []).map((n) => (
            <button
              key={n.to}
              className="btn btn--ghost"
              onClick={() => transition(n.to)}
              data-testid={`transition-${n.to}`}
            >
              {n.label}
            </button>
          ))}
        </div>
      </div>

      <h2 className="section-title">Sürüm geçmişi</h2>
      <div className="table-wrap">
        <table className="tbl">
          <thead>
            <tr>
              <th>Sürüm</th>
              <th>Durum</th>
              <th>Tarih</th>
            </tr>
          </thead>
          <tbody>
            {item.versions.map((v, k) => (
              <tr key={k}>
                <td>v{v.version}</td>
                <td>
                  <span className={`pill pill--${v.status}`}>{v.status}</span>
                </td>
                <td className="muted">{new Date(v.createdAt).toLocaleString('tr-TR')}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
