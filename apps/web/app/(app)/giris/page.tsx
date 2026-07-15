'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { login, register, forgotPassword, resetPassword } from '@/lib/authClient';

type Mode = 'login' | 'register' | 'forgot' | 'reset';

export default function GirisPage() {
  const router = useRouter();
  const [mode, setMode] = useState<Mode>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [token, setToken] = useState('');
  const [msg, setMsg] = useState('');
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setErr('');
    setMsg('');
    setBusy(true);
    try {
      if (mode === 'login') {
        const r = await login(email, password);
        if (!r.ok) return setErr(r.error ?? 'Giriş başarısız.');
        router.push('/panel');
      } else if (mode === 'register') {
        const r = await register(email, password, name);
        if (!r.ok) return setErr(r.error ?? 'Kayıt başarısız.');
        router.push('/panel');
      } else if (mode === 'forgot') {
        const r = await forgotPassword(email);
        if (r.devToken) {
          setToken(r.devToken);
          setMsg(
            'E-posta servisi henüz bağlı değil — geliştirme tokenı aşağıya kondu; yeni parolanı belirle.'
          );
          setMode('reset');
        } else {
          setMsg('Eğer hesap varsa sıfırlama bağlantısı gönderildi.');
        }
      } else {
        const r = await resetPassword(token, password);
        if (!r.ok) return setErr(r.error ?? 'Sıfırlama başarısız.');
        setMsg('Parolan güncellendi — şimdi giriş yap.');
        setMode('login');
        setPassword('');
      }
    } finally {
      setBusy(false);
    }
  }

  const Tab = ({ m, label }: { m: Mode; label: string }) => (
    <button
      type="button"
      className={`btn ${mode === m ? '' : 'btn--ghost'}`}
      onClick={() => {
        setMode(m);
        setErr('');
        setMsg('');
      }}
      aria-pressed={mode === m}
      data-testid={`tab-${m}`}
    >
      {label}
    </button>
  );

  return (
    <div style={{ maxWidth: 440, margin: '24px auto' }}>
      <h1 style={{ margin: '0 0 4px' }}>Hesap</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Hesap; ilerlemeni, seri ve paketlerini <strong>tüm cihazlarında</strong> senkronlar.
      </p>

      <div style={{ display: 'flex', gap: 8, marginBottom: 16, flexWrap: 'wrap' }}>
        <Tab m="login" label="Giriş" />
        <Tab m="register" label="Kayıt ol" />
        <Tab m="forgot" label="Parolamı unuttum" />
      </div>

      {err && (
        <div
          className="explain"
          role="alert"
          style={{ borderColor: 'var(--red)' }}
          data-testid="auth-error"
        >
          {err}
        </div>
      )}
      {msg && (
        <div className="explain" role="status" data-testid="auth-msg">
          {msg}
        </div>
      )}

      <form onSubmit={submit} className="card" style={{ display: 'grid', gap: 12 }}>
        {mode === 'register' && (
          <label>
            İsim
            <input
              className="chat__input"
              style={{ width: '100%', marginTop: 4 }}
              value={name}
              onChange={(e) => setName(e.target.value)}
              autoComplete="name"
              data-testid="name"
            />
          </label>
        )}
        {mode !== 'reset' && (
          <label>
            E-posta
            <input
              className="chat__input"
              style={{ width: '100%', marginTop: 4 }}
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="email"
              data-testid="email"
            />
          </label>
        )}
        {mode === 'reset' && (
          <label>
            Sıfırlama tokenı
            <input
              className="chat__input"
              style={{ width: '100%', marginTop: 4 }}
              required
              value={token}
              onChange={(e) => setToken(e.target.value)}
              data-testid="reset-token"
            />
          </label>
        )}
        {mode !== 'forgot' && (
          <label>
            Parola {mode !== 'login' && <span className="muted">(en az 8 karakter)</span>}
            <input
              className="chat__input"
              style={{ width: '100%', marginTop: 4 }}
              type="password"
              required
              minLength={mode === 'login' ? 1 : 8}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
              data-testid="password"
            />
          </label>
        )}
        <button className="btn" disabled={busy} data-testid="auth-submit">
          {busy
            ? 'İşleniyor…'
            : mode === 'login'
              ? 'Giriş yap'
              : mode === 'register'
                ? 'Hesap oluştur'
                : mode === 'forgot'
                  ? 'Sıfırlama isteği gönder'
                  : 'Parolayı güncelle'}
        </button>
      </form>
      <p className="muted" style={{ fontSize: '0.85rem', marginTop: 12 }}>
        Verilerin KVKK kapsamında yalnız hesabına bağlı ilerleme senkronu için kullanılır.
      </p>
    </div>
  );
}
