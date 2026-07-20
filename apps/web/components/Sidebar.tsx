'use client';

/**
 * Uygulama kabuğu kenar çubuğu (Program 3 · Faz D — referans 003-panel).
 * Masaüstünde kalıcı tam-boy sol sidebar, mobilde çekmece (drawer).
 * Marka (kalkan + slogan) · gruplu çizgi-ikon navigasyonu · Premium yükseltme kartı.
 */
import { useEffect, useState } from 'react';
import { usePathname } from 'next/navigation';
import { loadStreak } from '@/lib/progress';
import { me, fullSync, type AuthUser } from '@/lib/authClient';
import { Icon, type IconName } from '@/components/ui/icons';

type NavItem = { href: string; label: string; icon: IconName };

const NAV: Array<{ group: string; items: NavItem[] }> = [
  {
    group: 'Öğren',
    items: [
      { href: '/panel', label: 'Panel', icon: 'home' },
      { href: '/dersler', label: 'Dersler', icon: 'layers' },
      { href: '/isaretler', label: 'Trafik İşaretleri', icon: 'sign' },
      { href: '/arac', label: 'Araç Tanıma', icon: 'car' },
      { href: '/videolar', label: 'Videolar', icon: 'play' },
      { href: '/e-sinav', label: 'Teorik e-Sınav', icon: 'clipboard' },
    ],
  },
  {
    group: 'Pratik',
    items: [
      { href: '/calis', label: 'Akıllı Çalışma', icon: 'brain' },
      { href: '/gorsel-quiz', label: 'Görsel Quiz', icon: 'image' },
      { href: '/senaryolar', label: 'Senaryolar', icon: 'map' },
      { href: '/deneme-sinavi', label: 'Deneme Sınavı', icon: 'timer' },
      { href: '/koleksiyonlar', label: 'Koleksiyonlar', icon: 'clipboard' },
      { href: '/tani', label: 'Tanı Denemesi', icon: 'target' },
      { href: '/ai-koc', label: 'AI Koç', icon: 'bot' },
    ],
  },
  {
    group: 'İlerleme',
    items: [
      { href: '/ilerleme', label: 'İlerleme (XP)', icon: 'trending' },
      { href: '/hazirlik-skorum', label: 'Hazırlık Skorum', icon: 'gauge' },
      { href: '/calisma-plani', label: 'Çalışma Planım', icon: 'calendar' },
      { href: '/basarilar', label: 'Başarılar', icon: 'trophy' },
      { href: '/arama', label: 'Arama', icon: 'search' },
    ],
  },
  {
    group: 'Hesap',
    items: [
      { href: '/fiyatlandirma', label: 'Premium', icon: 'star' },
      { href: '/ayarlar', label: 'Ayarlar', icon: 'gear' },
    ],
  },
];

function Brand({ className }: { className?: string }) {
  return (
    <a className={`sb-brand ${className ?? ''}`} href="/panel" aria-label="Ehliyet Akademi">
      <span className="sb-brand__logo" aria-hidden>
        <Icon name="shield" size={22} strokeWidth={1.8} />
      </span>
      <span className="sb-brand__text">
        <span className="sb-brand__name">
          Ehliyet <b>Akademi</b>
        </span>
        <span className="sb-brand__tag">Güvenli sürüş, aydınlık gelecek.</span>
      </span>
    </a>
  );
}

export function Sidebar() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const [streak, setStreak] = useState(0);
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isPremium, setIsPremium] = useState(false);

  function refreshPremium() {
    try {
      const raw = localStorage.getItem('ea:entitlements:v1');
      const owned = raw ? (JSON.parse(raw) as unknown) : null;
      setIsPremium(Array.isArray(owned) && owned.length > 0);
    } catch {
      setIsPremium(false);
    }
  }

  // Oturum var mı? Varsa cihaz-açılış senkronu (Epic 4) — çerez kalıcı, localStorage boş olabilir.
  useEffect(() => {
    void me().then((u) => {
      setUser(u);
      if (u)
        void fullSync().then(() => {
          setStreak(loadStreak().current);
          refreshPremium();
        });
    });
    refreshPremium();
  }, []);

  useEffect(() => {
    setStreak(loadStreak().current);
    refreshPremium();
  }, [pathname]);

  // Rota değişince mobil çekmeceyi kapat
  useEffect(() => {
    setOpen(false);
  }, [pathname]);

  const isAdmin = user?.role === 'admin' || user?.role === 'editor';

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
        <Brand className="sb-brand--compact" />
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
        <Brand className="sidebar__brand" />

        <nav className="sidebar__nav">
          {NAV.map((g) => {
            const items: NavItem[] =
              g.group === 'Hesap'
                ? [
                    user
                      ? { href: '/profil', label: user.name || 'Profil', icon: 'user' }
                      : { href: '/giris', label: 'Giriş Yap', icon: 'login' },
                    ...(isAdmin
                      ? [{ href: '/admin', label: 'Yönetim', icon: 'tools' as IconName }]
                      : []),
                    ...g.items,
                  ]
                : g.items;
            return (
              <div key={g.group} className="sidebar__group">
                <div className="sidebar__group-title">{g.group}</div>
                {items.map((it) => {
                  const active = pathname === it.href || pathname.startsWith(it.href + '/');
                  return (
                    <a
                      key={it.href}
                      href={it.href}
                      className={`side-link ${active ? 'side-link--active' : ''}`}
                      aria-current={active ? 'page' : undefined}
                    >
                      <span className="side-link__icon">
                        <Icon name={it.icon} size={20} />
                      </span>
                      {it.label}
                    </a>
                  );
                })}
              </div>
            );
          })}
        </nav>

        <div className="sidebar__foot">
          {!isPremium && (
            <a className="sb-premium" href="/fiyatlandirma" data-testid="sidebar-premium">
              <span className="sb-premium__icon" aria-hidden>
                <Icon name="crown" size={22} />
              </span>
              <span className="sb-premium__text">
                <span className="sb-premium__title">Premium&apos;a geç</span>
                <span className="sb-premium__sub">Reklamsız, sınırsız içerik!</span>
              </span>
              <Icon name="chevron-right" size={18} className="sb-premium__chev" />
            </a>
          )}
          <a href="/" className="sidebar__back muted">
            ← Vitrine dön
          </a>
        </div>
      </aside>
    </>
  );
}
