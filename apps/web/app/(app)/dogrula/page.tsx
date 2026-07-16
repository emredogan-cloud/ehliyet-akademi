'use client';

/** E-posta doğrulama iniş sayfası (Sprint 4) — e-postadaki bağlantı buraya gelir. */
import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/ui/layout';

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
            <PageHeader
              title="E-postan doğrulandı"
              emoji="✉️"
              subtitle="Teşekkürler! Hesabın artık tam etkin."
            />
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
            <PageHeader
              title="Bağlantı geçersiz"
              emoji="✉️"
              subtitle="Doğrulama bağlantısı geçersiz veya süresi dolmuş. Profilinden yeni bir bağlantı isteyebilirsin."
            />
            <a className="btn btn--ghost" href="/profil">
              Profilim
            </a>
          </>
        )}
      </div>
    </div>
  );
}
