'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { login, register, forgotPassword, resetPassword } from '@/lib/authClient';
import { Icon, type IconName } from '@/components/ui/icons';

type Mode = 'login' | 'register' | 'forgot' | 'reset';

const PROMO: Array<{ icon: IconName; accent: string; title: string; desc: string }> = [
  {
    icon: 'shield',
    accent: 'teal',
    title: 'Güvenilir İçerik',
    desc: 'MEB/MTSK müfredatına uygun, güncel ve güvenilir eğitim içerikleri.',
  },
  {
    icon: 'gauge',
    accent: 'blue',
    title: 'Pratik Odaklı',
    desc: 'Gerçek sürüş senaryoları, araç bilgisi ve pratik ipuçları.',
  },
  {
    icon: 'trophy',
    accent: 'amber',
    title: 'Sınavda Başarı',
    desc: 'Akıllı çalışma, deneme sınavları ve performans takibi ile başarıya ulaş.',
  },
];

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
  const [showPw, setShowPw] = useState(false); // salt görünüm — parola göster/gizle

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

  const Tab = ({ m, label, icon }: { m: Mode; label: string; icon: IconName }) => (
    <button
      type="button"
      className={`auth-tab${mode === m ? ' auth-tab--on' : ''}`}
      onClick={() => {
        setMode(m);
        setErr('');
        setMsg('');
      }}
      aria-pressed={mode === m}
      data-testid={`tab-${m}`}
    >
      <Icon name={icon} size={16} /> {label}
    </button>
  );

  const SUB: Record<Mode, string> = {
    login: 'Hesabına giriş yaparak eğitimine kaldığın yerden devam et.',
    register: 'Hesap; ilerlemeni, seri ve paketlerini tüm cihazlarında senkronlar.',
    forgot: 'E-postanı gir — sıfırlama bağlantısı gönderelim.',
    reset: 'Tokenı ve yeni parolanı gir.',
  };

  return (
    <div className="auth-grid">
      {/* Sol tanıtım paneli (ref 027) */}
      <div className="auth-promo">
        <span className="ui-tag ui-tag--accent auth-promo__badge">
          <Icon name="shield" size={14} /> Ehliyet yolculuğuna hoş geldin!
        </span>
        <h1 className="auth-promo__title">
          Ehliyet, Sürüş ve Eğitimde <span className="mk-hero__grad">doğru yerdesin.</span>
        </h1>
        <p className="auth-promo__lead muted">
          Teoriden pratiğe, sınavdan gerçek trafiğe kadar yanında olan{' '}
          <strong style={{ color: 'var(--text)' }}>akıllı</strong> eğitim platformun.
        </p>
        <div className="auth-promo__feats">
          {PROMO.map((f) => (
            <div className="auth-promo__feat" key={f.title}>
              <span
                className="mastery-row__icon"
                style={{ ['--m-accent' as string]: `var(--accent-${f.accent})` }}
                aria-hidden
              >
                <Icon name={f.icon} size={20} />
              </span>
              <span>
                <strong>{f.title}</strong>
                <span className="muted auth-promo__desc">{f.desc}</span>
              </span>
            </div>
          ))}
        </div>
        <div className="auth-promo__scene" aria-hidden>
          {/* Gece yol sahnesi (ref 027-E) */}
          <img src="/assets/art/sedan-side.webp" alt="" />
        </div>
        <div className="ui-card auth-promo__note">
          <span className="mastery-row__icon" aria-hidden>
            <Icon name="clipboard" size={20} />
          </span>
          <p className="muted">
            Ehliyet hedefin ne olursa olsun, sana en uygun öğrenme yolunu birlikte çizelim.{' '}
            <strong style={{ color: 'var(--text)' }}>Başarıya giden yolculuk burada başlar!</strong>
          </p>
        </div>
      </div>

      {/* Sağ: kimlik kartı */}
      <div>
        <div className="ui-card auth-card">
          <div className="auth-tabs" role="tablist" aria-label="Hesap işlemleri">
            <Tab m="login" label="Giriş" icon="user" />
            <Tab m="register" label="Kayıt ol" icon="login" />
            <Tab m="forgot" label="Parolamı unuttum" icon="lock" />
          </div>
          <p className="muted auth-card__sub">{SUB[mode]}</p>

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

          <form onSubmit={submit} style={{ display: 'grid', gap: 14 }}>
            {mode === 'register' && (
              <label className="auth-field">
                İsim
                <span className="auth-field__wrap">
                  <span className="auth-field__ic" aria-hidden>
                    <Icon name="user" size={17} />
                  </span>
                  <input
                    className="ui-input auth-field__input"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    autoComplete="name"
                    data-testid="name"
                  />
                </span>
              </label>
            )}
            {mode !== 'reset' && (
              <label className="auth-field">
                E-posta
                <span className="auth-field__wrap">
                  <span className="auth-field__ic" aria-hidden>
                    <Icon name="book" size={17} />
                  </span>
                  <input
                    className="ui-input auth-field__input"
                    type="email"
                    required
                    placeholder="ornek@email.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    autoComplete="email"
                    data-testid="email"
                  />
                </span>
              </label>
            )}
            {mode === 'reset' && (
              <label className="auth-field">
                Sıfırlama tokenı
                <span className="auth-field__wrap">
                  <span className="auth-field__ic" aria-hidden>
                    <Icon name="lock" size={17} />
                  </span>
                  <input
                    className="ui-input auth-field__input"
                    required
                    value={token}
                    onChange={(e) => setToken(e.target.value)}
                    data-testid="reset-token"
                  />
                </span>
              </label>
            )}
            {mode !== 'forgot' && (
              <label className="auth-field">
                <span className="auth-field__row">
                  <span>
                    Parola {mode !== 'login' && <span className="muted">(en az 8 karakter)</span>}
                  </span>
                  {mode === 'login' && (
                    <button
                      type="button"
                      className="auth-forgot"
                      onClick={() => {
                        setMode('forgot');
                        setErr('');
                        setMsg('');
                      }}
                    >
                      Parolamı unuttum?
                    </button>
                  )}
                </span>
                <span className="auth-field__wrap">
                  <span className="auth-field__ic" aria-hidden>
                    <Icon name="lock" size={17} />
                  </span>
                  <input
                    className="ui-input auth-field__input"
                    type={showPw ? 'text' : 'password'}
                    required
                    placeholder="Parolanı gir"
                    minLength={mode === 'login' ? 1 : 8}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
                    data-testid="password"
                  />
                  <button
                    type="button"
                    className="auth-eye"
                    onClick={() => setShowPw((v) => !v)}
                    aria-label={showPw ? 'Parolayı gizle' : 'Parolayı göster'}
                  >
                    <Icon name={showPw ? 'ban' : 'search'} size={16} />
                  </button>
                </span>
              </label>
            )}
            <button
              className="ui-btn ui-btn--primary ui-btn--md ui-btn--full"
              disabled={busy}
              data-testid="auth-submit"
            >
              <Icon name="login" size={17} />{' '}
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
        </div>
        <p className="muted auth-kvkk">
          <Icon name="shield" size={14} /> Verilerin KVKK kapsamında korunur; yalnız hesabına bağlı
          ilerleme senkronu için kullanılır.
        </p>
      </div>
    </div>
  );
}
