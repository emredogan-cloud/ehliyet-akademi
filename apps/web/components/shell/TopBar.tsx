'use client';

/**
 * Uygulama üst çubuğu (Program 3 · Faz D) — referans 003-panel sağ-üst kümesi.
 * Bildirim zili (boş-durum açılırı) + kullanıcı avatarı menüsü (Profil/Ayarlar/Tema/Çıkış).
 * İçerik sütununun sağ-üstünde konumlanır; sayfa başlığı (PageHeader) sol-üstte kalır.
 */
import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { usePathname } from 'next/navigation';
import { me, logout, type AuthUser } from '@/lib/authClient';
import { loadStreak } from '@/lib/progress';
import { Icon } from '@/components/ui/icons';

type Theme = 'auto' | 'light' | 'dark';

function currentTheme(): Theme {
  if (typeof document === 'undefined') return 'auto';
  const t = document.documentElement.getAttribute('data-theme');
  return t === 'light' || t === 'dark' ? t : 'auto';
}

function initials(user: AuthUser | null): string {
  if (!user?.name) return 'EA';
  const parts = user.name.trim().split(/\s+/).slice(0, 2);
  return parts.map((p) => p[0]?.toLocaleUpperCase('tr-TR') ?? '').join('') || 'EA';
}

export function TopBar() {
  const router = useRouter();
  const pathname = usePathname();
  const [user, setUser] = useState<AuthUser | null>(null);
  const [openMenu, setOpenMenu] = useState<'none' | 'bell' | 'avatar'>('none');
  const [theme, setTheme] = useState<Theme>('auto');
  const [streak, setStreak] = useState(0);
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    void me().then(setUser);
    setTheme(currentTheme());
  }, []);

  // Seri çipi (ref kabuk dili) — rota değişince tazele; gerçek veriden.
  useEffect(() => {
    setStreak(loadStreak().current);
  }, [pathname]);

  // Dışarı tıklayınca / ESC ile menüyü kapat
  useEffect(() => {
    if (openMenu === 'none') return;
    function onDown(e: MouseEvent) {
      if (rootRef.current && !rootRef.current.contains(e.target as Node)) setOpenMenu('none');
    }
    function onKey(e: KeyboardEvent) {
      if (e.key === 'Escape') setOpenMenu('none');
    }
    document.addEventListener('mousedown', onDown);
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('mousedown', onDown);
      document.removeEventListener('keydown', onKey);
    };
  }, [openMenu]);

  function applyTheme(t: Theme) {
    setTheme(t);
    try {
      if (t === 'auto') localStorage.removeItem('ea:theme');
      else localStorage.setItem('ea:theme', t);
    } catch {
      /* storage engellenmiş olabilir */
    }
    if (t === 'auto') document.documentElement.removeAttribute('data-theme');
    else document.documentElement.setAttribute('data-theme', t);
  }

  function cycleTheme() {
    applyTheme(theme === 'dark' ? 'light' : 'dark');
  }

  async function onLogout() {
    setOpenMenu('none');
    await logout();
    setUser(null);
    router.push('/giris');
    router.refresh();
  }

  return (
    <div className="topbar-float" ref={rootRef}>
      {/* Günlük seri çipi (gerçek veri) */}
      {streak > 0 && (
        <a className="topbar-streak" href="/ilerleme" title="Günlük çalışma serin">
          <span aria-hidden>🔥</span> {streak} gün
        </a>
      )}
      {/* Tema anahtarı */}
      <button
        type="button"
        className="topbar-btn"
        onClick={cycleTheme}
        aria-label={theme === 'dark' ? 'Açık temaya geç' : 'Koyu temaya geç'}
        title="Tema"
        data-testid="theme-toggle"
      >
        <Icon name={theme === 'dark' ? 'sun' : 'moon'} size={20} />
      </button>

      {/* Bildirimler */}
      <div className="topbar-item">
        <button
          type="button"
          className="topbar-btn"
          aria-label="Bildirimler"
          aria-haspopup="menu"
          aria-expanded={openMenu === 'bell'}
          onClick={() => setOpenMenu((m) => (m === 'bell' ? 'none' : 'bell'))}
          data-testid="topbar-bell"
        >
          <Icon name="bell" size={20} />
        </button>
        {openMenu === 'bell' && (
          <div className="topbar-pop" role="menu" aria-label="Bildirimler">
            <div className="topbar-pop__head">Bildirimler</div>
            <div className="topbar-pop__empty">
              <Icon name="bell" size={26} />
              <p>Şimdilik yeni bildirim yok.</p>
            </div>
          </div>
        )}
      </div>

      {/* Avatar menüsü */}
      <div className="topbar-item">
        <button
          type="button"
          className="topbar-avatar"
          aria-haspopup="menu"
          aria-expanded={openMenu === 'avatar'}
          onClick={() => setOpenMenu((m) => (m === 'avatar' ? 'none' : 'avatar'))}
          data-testid="topbar-avatar"
        >
          <span className="topbar-avatar__badge" aria-hidden>
            {initials(user)}
          </span>
          <Icon name="chevron-down" size={16} className="topbar-avatar__chev" />
        </button>
        {openMenu === 'avatar' && (
          <div className="topbar-pop topbar-pop--menu" role="menu" aria-label="Hesap menüsü">
            <div className="topbar-pop__user">
              <span className="topbar-avatar__badge topbar-avatar__badge--lg" aria-hidden>
                {initials(user)}
              </span>
              <div>
                <div className="topbar-pop__name">{user?.name || 'Misafir'}</div>
                <div className="topbar-pop__sub">{user?.email || 'Giriş yapılmadı'}</div>
              </div>
            </div>
            <div className="topbar-pop__sep" />
            {user ? (
              <>
                <a className="topbar-pop__row" href="/profil" role="menuitem">
                  <Icon name="user" size={18} /> Profil
                </a>
                <a className="topbar-pop__row" href="/ayarlar" role="menuitem">
                  <Icon name="gear" size={18} /> Ayarlar
                </a>
                <button
                  className="topbar-pop__row"
                  role="menuitem"
                  onClick={onLogout}
                  data-testid="topbar-logout"
                >
                  <Icon name="login" size={18} /> Çıkış yap
                </button>
              </>
            ) : (
              <>
                <a className="topbar-pop__row" href="/giris" role="menuitem">
                  <Icon name="login" size={18} /> Giriş yap
                </a>
                <a className="topbar-pop__row" href="/ayarlar" role="menuitem">
                  <Icon name="gear" size={18} /> Ayarlar
                </a>
              </>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
