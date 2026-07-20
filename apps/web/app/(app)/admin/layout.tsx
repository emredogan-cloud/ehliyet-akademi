'use client';

import { useEffect, useState } from 'react';
import { usePathname } from 'next/navigation';
import { me, type AuthUser } from '@/lib/authClient';

const TABS = [
  { href: '/admin', label: 'Genel Bakış' },
  { href: '/admin/icerik', label: 'İçerik' },
  { href: '/admin/medya', label: 'Medya' },
  { href: '/admin/kullanicilar', label: 'Kullanıcılar' },
  { href: '/admin/denetim', label: 'Denetim' },
  { href: '/admin/seo', label: 'SEO' },
  { href: '/admin/soru-zekasi', label: 'Soru Zekâsı' },
  { href: '/admin/soru-uretimi', label: 'Soru Üretimi' },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [user, setUser] = useState<AuthUser | null | undefined>(undefined);

  useEffect(() => {
    void me().then((u) => setUser(u));
  }, []);

  if (user === undefined)
    return <div className="skeleton" style={{ height: 200, maxWidth: 600 }} />;

  // Korumalı alan (Epic 3): yalnız admin/editor.
  if (!user || (user.role !== 'admin' && user.role !== 'editor')) {
    return (
      <div className="card" style={{ maxWidth: 520 }} data-testid="admin-denied">
        <h1 style={{ marginTop: 0 }}>Yönetim Paneli</h1>
        <p>Bu alan yönetici/editör yetkisi gerektirir.</p>
        <a className="btn" href="/giris">
          Giriş yap
        </a>
      </div>
    );
  }

  return (
    <div data-testid="admin-shell">
      <div className="toolbar" role="tablist" aria-label="Yönetim sekmeleri">
        {TABS.map((t) => {
          const active =
            pathname === t.href || (t.href !== '/admin' && pathname.startsWith(t.href));
          return (
            <a
              key={t.href}
              href={t.href}
              className={`btn ${active ? '' : 'btn--ghost'}`}
              aria-current={active ? 'page' : undefined}
            >
              {t.label}
            </a>
          );
        })}
        <span className="muted" style={{ marginLeft: 'auto', fontSize: '0.85rem' }}>
          {user.name || user.email} · {user.role}
        </span>
      </div>
      {children}
    </div>
  );
}
