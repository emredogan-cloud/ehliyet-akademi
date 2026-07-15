'use client';

import { useEffect, useState } from 'react';
import { syncSet } from '@/lib/authClient';

type Theme = 'auto' | 'light' | 'dark';
const THEME_KEY = 'ea:theme';

function applyTheme(t: Theme) {
  if (t === 'auto') document.documentElement.removeAttribute('data-theme');
  else document.documentElement.setAttribute('data-theme', t);
}

export default function AyarlarPage() {
  const [theme, setTheme] = useState<Theme>('auto');

  useEffect(() => {
    try {
      const t = localStorage.getItem(THEME_KEY);
      if (t === 'light' || t === 'dark') setTheme(t);
    } catch {
      /* ilk açılış */
    }
  }, []);

  function choose(t: Theme) {
    setTheme(t);
    try {
      if (t === 'auto') localStorage.removeItem(THEME_KEY);
      else syncSet(THEME_KEY, t); // ham değer — kök tema scripti okur; girişliyse senkronlanır
    } catch {
      /* sessiz */
    }
    applyTheme(t);
  }

  function exportData() {
    try {
      const dump: Record<string, unknown> = {};
      for (let i = 0; i < localStorage.length; i++) {
        const k = localStorage.key(i)!;
        if (k.startsWith('ea:')) dump[k] = JSON.parse(localStorage.getItem(k) ?? 'null');
      }
      const blob = new Blob([JSON.stringify(dump, null, 2)], { type: 'application/json' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = 'ehliyet-akademi-verilerim.json';
      a.click();
      URL.revokeObjectURL(a.href);
    } catch {
      /* sessiz */
    }
  }

  function resetData() {
    if (!confirm('Tüm ilerleme, seri, paket ve ayarlar bu cihazdan silinsin mi? Geri alınamaz.'))
      return;
    try {
      const keys: string[] = [];
      for (let i = 0; i < localStorage.length; i++) {
        const k = localStorage.key(i)!;
        if (k.startsWith('ea:')) keys.push(k);
      }
      keys.forEach((k) => localStorage.removeItem(k));
      location.href = '/panel';
    } catch {
      /* sessiz */
    }
  }

  const Btn = ({ v, label }: { v: Theme; label: string }) => (
    <button
      className={`btn ${theme === v ? '' : 'btn--ghost'}`}
      onClick={() => choose(v)}
      aria-pressed={theme === v}
      data-testid={`theme-${v}`}
    >
      {label}
    </button>
  );

  return (
    <>
      <h1 style={{ margin: '6px 0 4px' }}>Ayarlar</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Tema ve verilerin — hepsi bu cihazda kalır (KVKK-dostu: sunucuya veri gitmez).
      </p>

      <div className="card" style={{ marginBottom: 16 }}>
        <h3 style={{ marginTop: 0 }}>Tema</h3>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <Btn v="auto" label="🖥️ Sistem" />
          <Btn v="light" label="☀️ Açık" />
          <Btn v="dark" label="🌙 Koyu" />
        </div>
      </div>

      <div className="card">
        <h3 style={{ marginTop: 0 }}>Verilerim</h3>
        <p className="muted">
          İlerleme, SRS kartları, seri ve paketler yalnız tarayıcında (localStorage) saklanır.
        </p>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <button className="btn btn--ghost" onClick={exportData} data-testid="export-data">
            ⬇️ Dışa aktar (JSON)
          </button>
          <button
            className="btn"
            style={{ background: 'var(--red)' }}
            onClick={resetData}
            data-testid="reset-data"
          >
            🗑️ Tümünü sıfırla
          </button>
        </div>
      </div>
    </>
  );
}
