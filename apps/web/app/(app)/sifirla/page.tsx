'use client';

/** Parola sıfırlama iniş sayfası (Sprint 4) — e-postadaki bağlantı buraya gelir. */
import { useEffect, useState } from 'react';
import { resetPassword } from '@/lib/authClient';

export default function SifirlaPage() {
  const [token, setToken] = useState('');
  const [pw, setPw] = useState('');
  const [msg, setMsg] = useState('');
  const [done, setDone] = useState(false);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    setToken(new URLSearchParams(window.location.search).get('token') ?? '');
  }, []);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setMsg('');
    const r = await resetPassword(token, pw);
    setBusy(false);
    if (r.ok) setDone(true);
    else setMsg(r.error ?? 'Sıfırlama başarısız.');
  }

  return (
    <div style={{ maxWidth: 420, margin: '32px auto' }}>
      <div className="card" data-testid="reset-page">
        <h1 style={{ marginTop: 0 }}>Parolanı sıfırla</h1>
        {done ? (
          <>
            <p className="muted">Parolan güncellendi. Yeni parolanla giriş yapabilirsin.</p>
            <a className="btn" href="/giris">
              Giriş yap
            </a>
          </>
        ) : (
          <form onSubmit={submit}>
            {!token && (
              <p className="explain" role="note">
                Bağlantıda doğrulama kodu yok. Lütfen e-postandaki bağlantıyı kullan.
              </p>
            )}
            <label style={{ display: 'block', marginBottom: 8 }}>
              Yeni parola (en az 8 karakter)
              <input
                className="chat__input"
                type="password"
                value={pw}
                onChange={(e) => setPw(e.target.value)}
                minLength={8}
                required
                data-testid="reset-password"
                style={{ width: '100%', marginTop: 6 }}
              />
            </label>
            {msg && (
              <p className="explain" role="alert" style={{ color: 'var(--red)' }}>
                {msg}
              </p>
            )}
            <button
              className="btn"
              disabled={busy || !token || pw.length < 8}
              data-testid="reset-submit"
            >
              {busy ? 'Kaydediliyor…' : 'Parolayı güncelle'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
