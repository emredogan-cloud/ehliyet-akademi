'use client';

import { useEffect, useState } from 'react';

interface Stats {
  content: number;
  published: number;
  media: number;
  users: number;
}

export default function AdminHome() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    void fetch('/api/admin/stats', { credentials: 'same-origin' })
      .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
      .then((d: { stats: Stats }) => setStats(d.stats))
      .catch(() => setErr('İstatistikler yüklenemedi.'));
  }, []);

  return (
    <div>
      <h1 style={{ margin: '0 0 4px' }}>Yönetim — Genel Bakış</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        İçerik hattı, medya ve kullanıcıların özeti.
      </p>
      {err && (
        <div className="explain" role="alert">
          {err}
        </div>
      )}
      {!stats ? (
        <div className="grid" aria-busy="true">
          {[1, 2, 3, 4].map((k) => (
            <div key={k} className="card">
              <div className="skeleton" style={{ height: 40 }} />
            </div>
          ))}
        </div>
      ) : (
        <div className="grid" data-testid="admin-stats">
          <div className="stat-tile">
            <div className="stat-tile__num">{stats.content}</div>
            <div className="stat-tile__cap">Toplam içerik</div>
          </div>
          <div className="stat-tile">
            <div className="stat-tile__num">{stats.published}</div>
            <div className="stat-tile__cap">Yayında</div>
          </div>
          <div className="stat-tile">
            <div className="stat-tile__num">{stats.media}</div>
            <div className="stat-tile__cap">Medya varlığı</div>
          </div>
          <div className="stat-tile">
            <div className="stat-tile__num">{stats.users}</div>
            <div className="stat-tile__cap">Kullanıcı</div>
          </div>
        </div>
      )}
      <h2 className="section-title">Hızlı işlemler</h2>
      <div className="grid">
        <a className="card card--link" href="/admin/icerik">
          <h3>📝 İçerik yönet</h3>
          <p className="muted">Ders/soru/makale oluştur, incele, yayınla.</p>
        </a>
        <a className="card card--link" href="/admin/medya">
          <h3>🖼️ Medya kütüphanesi</h3>
          <p className="muted">Görsel/SVG yükle ve yönet.</p>
        </a>
        <a className="card card--link" href="/admin/denetim">
          <h3>🧾 Denetim kaydı</h3>
          <p className="muted">Tüm ayrıcalıklı işlemlerin izi.</p>
        </a>
      </div>
    </div>
  );
}
