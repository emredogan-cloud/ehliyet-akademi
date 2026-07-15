'use client';

/**
 * Uygulama kabuğu kenar çubuğu (SaaS layout — Notion/Linear ilkeleri):
 * masaüstünde kalıcı tam-boy sol sidebar, mobilde çekmece (drawer).
 */
import { useEffect, useState } from 'react';
import { usePathname } from 'next/navigation';
import { loadStreak } from '@/lib/progress';

const NAV: Array<{ group: string; items: Array<{ href: string; label: string; icon: string }> }> = [
  {
    group: 'Öğren',
    items: [
      { href: '/panel', label: 'Panel', icon: '🏠' },
      { href: '/dersler', label: 'Dersler', icon: '📚' },
      { href: '/e-sinav', label: 'Teorik e-Sınav', icon: '📝' },
    ],
  },
  {
    group: 'Pratik',
    items: [
      { href: '/calis', label: 'Akıllı Çalışma', icon: '🧠' },
      { href: '/deneme-sinavi', label: 'Deneme Sınavı', icon: '⏱️' },
      { href: '/tani', label: 'Tanı Denemesi', icon: '🎯' },
      { href: '/ai-koc', label: 'AI Koç', icon: '🤖' },
    ],
  },
  {
    group: 'İlerleme',
    items: [
      { href: '/hazirlik-skorum', label: 'Hazırlık Skorum', icon: '🚦' },
      { href: '/basarilar', label: 'Başarılar', icon: '🏆' },
      { href: '/arama', label: 'Arama', icon: '🔍' },
    ],
  },
  {
    group: 'Hesap',
    items: [
      { href: '/fiyatlandirma', label: 'Premium', icon: '⭐' },
      { href: '/ayarlar', label: 'Ayarlar', icon: '⚙️' },
    ],
  },
];

export function Sidebar() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const [streak, setStreak] = useState(0);

  useEffect(() => {
    setStreak(loadStreak().current);
  }, [pathname]);

  // Rota değişince mobil çekmeceyi kapat
  useEffect(() => {
    setOpen(false);
  }, [pathname]);

  return (
    <>
      <header className="appbar">
        <button
          className="appbar__menu"
          aria-label="Menüyü aç/kapat"
          aria-expanded={open}
          aria-controls="app-sidebar"
          onClick={() => setOpen((v) => !v)}
          data-testid="drawer-toggle"
        >
          ☰
        </button>
        <a className="brand" href="/panel">
          🚗{' '}
          <span>
            <b>Ehliyet</b> Akademi
          </span>
        </a>
        <span className="appbar__streak" title="Günlük çalışma serin">
          🔥 {streak}
        </span>
      </header>

      {open && <div className="scrim" onClick={() => setOpen(false)} aria-hidden />}

      <aside
        id="app-sidebar"
        className={`sidebar ${open ? 'sidebar--open' : ''}`}
        aria-label="Uygulama menüsü"
      >
        <a className="brand sidebar__brand" href="/panel">
          🚗{' '}
          <span>
            <b>Ehliyet</b> Akademi
          </span>
        </a>
        <nav className="sidebar__nav">
          {NAV.map((g) => (
            <div key={g.group} className="sidebar__group">
              <div className="sidebar__group-title">{g.group}</div>
              {g.items.map((it) => {
                const active = pathname === it.href || pathname.startsWith(it.href + '/');
                return (
                  <a
                    key={it.href}
                    href={it.href}
                    className={`side-link ${active ? 'side-link--active' : ''}`}
                    aria-current={active ? 'page' : undefined}
                  >
                    <span className="side-link__icon" aria-hidden>
                      {it.icon}
                    </span>
                    {it.label}
                  </a>
                );
              })}
            </div>
          ))}
        </nav>
        <div className="sidebar__foot">
          <a href="/" className="muted">
            ← Vitrine dön
          </a>
        </div>
      </aside>
    </>
  );
}
