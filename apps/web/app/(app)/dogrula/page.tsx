'use client';

/** E-posta doğrulama iniş sayfası (Sprint 4) — e-postadaki bağlantı buraya gelir. */
import { useEffect, useState } from 'react';

export default function DogrulaPage() {
  const [status, setStatus] = useState<'loading' | 'ok' | 'error'>('loading');

  useEffect(() => {
    const token = new URLSearchParams(window.location.search).get('token');
    if (!token) {
      setStatus('error');
      return;
    }
    fetch('/api/auth/verify', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ token }),
    })
      .then((r) => setStatus(r.ok ? 'ok' : 'error'))
      .catch(() => setStatus('error'));
  }, []);

  return (
    <div style={{ maxWidth: 480, margin: '32px auto' }}>
      <div className="card" data-testid="verify-result">
        {status === 'loading' && <p>E-posta doğrulanıyor…</p>}
        {status === 'ok' && (
          <>
            <div style={{ fontSize: '2rem' }} aria-hidden>
              ✅
            </div>
            <h1 style={{ margin: '8px 0' }}>E-postan doğrulandı</h1>
            <p className="muted">Teşekkürler! Hesabın artık tam etkin.</p>
            <a className="btn" href="/panel">
              Panele git
            </a>
          </>
        )}
        {status === 'error' && (
          <>
            <div style={{ fontSize: '2rem' }} aria-hidden>
              ⚠️
            </div>
            <h1 style={{ margin: '8px 0' }}>Bağlantı geçersiz</h1>
            <p className="muted">
              Doğrulama bağlantısı geçersiz veya süresi dolmuş. Profilinden yeni bir bağlantı
              isteyebilirsin.
            </p>
            <a className="btn btn--ghost" href="/profil">
              Profilim
            </a>
          </>
        )}
      </div>
    </div>
  );
}
