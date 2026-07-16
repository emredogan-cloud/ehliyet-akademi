'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { PageHeader } from '@/components/ui/layout';

interface Media {
  id: string;
  kind: string;
  filename: string;
  mime: string;
  bytes: number;
  alt: string;
  createdAt: string;
}

export default function AdminMedia() {
  const [items, setItems] = useState<Media[] | null>(null);
  const [msg, setMsg] = useState('');
  const [err, setErr] = useState('');
  const fileRef = useRef<HTMLInputElement>(null);

  const load = useCallback(async () => {
    const r = await fetch('/api/admin/media', { credentials: 'same-origin' });
    if (r.ok) setItems(((await r.json()) as { items: Media[] }).items);
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  async function onFile(e: React.ChangeEvent<HTMLInputElement>) {
    setErr('');
    setMsg('');
    const file = e.target.files?.[0];
    if (!file) return;
    const dataBase64 = await new Promise<string>((res, rej) => {
      const reader = new FileReader();
      reader.onload = () => res(String(reader.result).split(',')[1] ?? '');
      reader.onerror = rej;
      reader.readAsDataURL(file);
    });
    const r = await fetch('/api/admin/media', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      credentials: 'same-origin',
      body: JSON.stringify({ filename: file.name, mime: file.type, dataBase64, alt: file.name }),
    });
    if (r.status === 201) {
      setMsg('Yüklendi.');
      if (fileRef.current) fileRef.current.value = '';
      await load();
    } else {
      const d = (await r.json()) as { errors?: string[]; error?: string };
      setErr((d.errors ?? [d.error ?? 'Yükleme başarısız.']).join(' · '));
    }
  }

  return (
    <div>
      <div className="toolbar">
        <PageHeader title="Medya Kütüphanesi" emoji="🖼️" />
        <input
          ref={fileRef}
          type="file"
          accept="image/svg+xml,image/png,image/jpeg,image/webp,application/json"
          onChange={onFile}
          aria-label="Medya yükle"
          data-testid="media-file"
        />
      </div>
      <p className="muted" style={{ marginTop: 0, fontSize: '0.85rem' }}>
        SVG · PNG · JPEG · WebP · Lottie(JSON) · 2MB'ye kadar. Servis: <code>/api/media/[id]</code>{' '}
        (immutable cache).
      </p>

      {msg && (
        <div className="explain" role="status" data-testid="media-msg">
          {msg}
        </div>
      )}
      {err && (
        <div
          className="explain"
          role="alert"
          style={{ borderColor: 'var(--red)' }}
          data-testid="media-err"
        >
          {err}
        </div>
      )}

      {!items ? (
        <div className="skeleton" style={{ height: 160 }} />
      ) : items.length === 0 ? (
        <div className="card" data-testid="media-empty">
          <p style={{ margin: 0 }}>Henüz medya yok. Yukarıdan bir dosya yükle.</p>
        </div>
      ) : (
        <div className="grid" data-testid="media-grid">
          {items.map((m) => (
            <div className="card" key={m.id}>
              <div
                style={{
                  height: 96,
                  display: 'grid',
                  placeItems: 'center',
                  background: 'var(--surface-2)',
                  borderRadius: 10,
                  overflow: 'hidden',
                }}
              >
                {m.kind === 'image' || m.kind === 'svg' ? (
                  <img
                    src={`/api/media/${m.id}`}
                    alt={m.alt}
                    style={{ maxHeight: 96, maxWidth: '100%' }}
                  />
                ) : (
                  <span className="muted">{m.kind}</span>
                )}
              </div>
              <p style={{ margin: '8px 0 2px', fontWeight: 600, fontSize: '0.9rem' }}>
                {m.filename}
              </p>
              <p className="muted" style={{ margin: 0, fontSize: '0.8rem' }}>
                {m.mime} · {(m.bytes / 1024).toFixed(1)} KB
              </p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
