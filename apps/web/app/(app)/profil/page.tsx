'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { me, logout, restorePurchases, type AuthUser } from '@/lib/authClient';
import { PRODUCTS } from '@/lib/products';

export default function ProfilPage() {
  const router = useRouter();
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loaded, setLoaded] = useState(false);
  const [owned, setOwned] = useState<string[]>([]);
  const [msg, setMsg] = useState('');

  useEffect(() => {
    void me().then((u) => {
      setUser(u);
      setLoaded(true);
    });
  }, []);

  async function doRestore() {
    const list = await restorePurchases();
    setOwned(list);
    setMsg(
      list.length
        ? `${list.length} paket geri yüklendi — bu cihazda aktif.`
        : 'Hesabında satın alma bulunamadı.'
    );
  }

  async function doLogout() {
    await logout();
    router.push('/panel');
  }

  if (!loaded) return <div className="skeleton" style={{ height: 120, maxWidth: 500 }} />;

  // Korumalı sayfa: oturum yoksa giriş CTA'sı (Epic 1 — protected route)
  if (!user) {
    return (
      <div className="card" style={{ maxWidth: 500 }} data-testid="profile-guest">
        <h1 style={{ marginTop: 0 }}>Profil</h1>
        <p>Bu sayfa hesap gerektirir. Giriş yap — ilerlemen tüm cihazlarında seninle gelsin.</p>
        <a className="btn" href="/giris" data-testid="go-login">
          Giriş yap / Kayıt ol
        </a>
      </div>
    );
  }

  return (
    <div style={{ maxWidth: 560 }} data-testid="profile">
      <h1 style={{ margin: '0 0 4px' }}>Profil</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Hesabın ve kalıcı satın almaların.
      </p>

      <div className="card" style={{ marginBottom: 14 }}>
        <p style={{ margin: 0 }}>
          <strong data-testid="profile-name">{user.name || 'İsimsiz aday'}</strong>
        </p>
        <p className="muted" style={{ margin: '4px 0 0' }} data-testid="profile-email">
          {user.email}
        </p>
        <p className="muted" style={{ margin: '4px 0 0', fontSize: '0.85rem' }}>
          İlerleme senkronu: <strong style={{ color: 'var(--green)' }}>aktif</strong> — çalıştığın
          her cihazda aynı hesapla devam edebilirsin.
        </p>
      </div>

      {msg && (
        <div className="explain" role="status" data-testid="restore-msg">
          {msg}
        </div>
      )}

      <div className="card" style={{ marginBottom: 14 }}>
        <h3 style={{ marginTop: 0 }}>Satın almalar (ömür boyu)</h3>
        {owned.length > 0 ? (
          <ul className="prose" style={{ margin: '0 0 10px', paddingLeft: 18 }}>
            {owned.map((id) => (
              <li key={id}>{PRODUCTS.find((p) => p.id === id)?.title ?? id} ✓</li>
            ))}
          </ul>
        ) : (
          <p className="muted">Cihazda görünen paketleri sunucudan doğrulamak için geri yükle.</p>
        )}
        <button className="btn btn--ghost" onClick={doRestore} data-testid="restore">
          ↺ Satın almaları geri yükle
        </button>
      </div>

      <button
        className="btn"
        style={{ background: 'var(--red)' }}
        onClick={doLogout}
        data-testid="logout"
      >
        Çıkış yap
      </button>
    </div>
  );
}
