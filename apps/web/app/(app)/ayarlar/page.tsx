'use client';

import { useEffect, useState } from 'react';
import { syncSet, me, restorePurchases, type AuthUser } from '@/lib/authClient';
import { CONSENT_KEY, readConsent, type Consent } from '@/components/CookieConsent';
import { PageHeader } from '@/components/ui/layout';

type Theme = 'auto' | 'light' | 'dark';
const THEME_KEY = 'ea:theme';

function applyTheme(t: Theme) {
  if (t === 'auto') document.documentElement.removeAttribute('data-theme');
  else document.documentElement.setAttribute('data-theme', t);
}

export default function AyarlarPage() {
  const [theme, setTheme] = useState<Theme>('auto');
  const [user, setUser] = useState<AuthUser | null>(null);
  const [consent, setConsent] = useState<Consent | null>(null);
  const [note, setNote] = useState('');

  useEffect(() => {
    try {
      const t = localStorage.getItem(THEME_KEY);
      if (t === 'light' || t === 'dark') setTheme(t);
    } catch {
      /* ilk açılış */
    }
    setConsent(readConsent());
    void me().then(setUser);
  }, []);

  function choose(t: Theme) {
    setTheme(t);
    try {
      if (t === 'auto') localStorage.removeItem(THEME_KEY);
      else syncSet(THEME_KEY, t);
    } catch {
      /* sessiz */
    }
    applyTheme(t);
  }

  function exportData() {
    try {
      const dump: Record<string, unknown> = {};
      for (let i = 0; i < localStorage.length; i++) {
        const k = localStorage.key(i)!;
        if (k.startsWith('ea:')) dump[k] = JSON.parse(localStorage.getItem(k) ?? 'null');
      }
      const blob = new Blob([JSON.stringify(dump, null, 2)], { type: 'application/json' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = 'ehliyet-akademi-verilerim.json';
      a.click();
      URL.revokeObjectURL(a.href);
    } catch {
      /* sessiz */
    }
  }

  function resetData() {
    if (!confirm('Tüm ilerleme, seri, paket ve ayarlar bu cihazdan silinsin mi? Geri alınamaz.'))
      return;
    try {
      const keys: string[] = [];
      for (let i = 0; i < localStorage.length; i++) {
        const k = localStorage.key(i)!;
        if (k.startsWith('ea:')) keys.push(k);
      }
      keys.forEach((k) => localStorage.removeItem(k));
      location.href = '/panel';
    } catch {
      /* sessiz */
    }
  }

  async function doRestore() {
    setNote('');
    const owned = await restorePurchases();
    setNote(
      owned.length
        ? `${owned.length} satın alma geri yüklendi.`
        : 'Geri yüklenecek satın alma bulunamadı.'
    );
  }

  async function resendVerification() {
    setNote('');
    const res = await fetch('/api/auth/verify', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: '{}',
    });
    const data = (await res.json().catch(() => ({}))) as { sent?: boolean; devToken?: string };
    setNote(
      data.sent
        ? 'Doğrulama e-postası gönderildi.'
        : data.devToken
          ? 'E-posta servisi kapalı; geliştirme kodu üretildi (konsolda).'
          : 'Doğrulama isteği gönderildi.'
    );
    if (data.devToken) console.debug('[dev] verify token:', data.devToken);
  }

  async function deleteAccount() {
    if (
      !confirm(
        'Hesabın ve tüm sunucu verilerin (satın almalar, ilerleme senkronu) kalıcı olarak silinsin mi? Bu işlem geri alınamaz.'
      )
    )
      return;
    const res = await fetch('/api/account', { method: 'DELETE', credentials: 'same-origin' });
    if (res.ok) {
      try {
        for (let i = localStorage.length - 1; i >= 0; i--) {
          const k = localStorage.key(i)!;
          if (k.startsWith('ea:')) localStorage.removeItem(k);
        }
      } catch {
        /* sessiz */
      }
      location.href = '/';
    } else {
      setNote('Hesap silinemedi. Lütfen sonra tekrar dene.');
    }
  }

  function setAnalyticsConsent(analytics: boolean) {
    const c: Consent = { essential: true, analytics, at: Date.now() };
    try {
      localStorage.setItem(CONSENT_KEY, JSON.stringify(c));
    } catch {
      /* sessiz */
    }
    setConsent(c);
    setNote(analytics ? 'Analitik çerezleri açıldı.' : 'Analitik çerezleri kapatıldı.');
  }

  const Btn = ({ v, label }: { v: Theme; label: string }) => (
    <button
      className={`btn ${theme === v ? '' : 'btn--ghost'}`}
      onClick={() => choose(v)}
      aria-pressed={theme === v}
      data-testid={`theme-${v}`}
    >
      {label}
    </button>
  );

  return (
    <>
      <PageHeader
        title="Ayarlar"
        emoji="⚙️"
        subtitle="Tema, verilerin, hesabın ve gizlilik tercihlerin."
      />

      {note && (
        <p className="explain" role="status" data-testid="settings-note">
          {note}
        </p>
      )}

      <div className="card" style={{ marginBottom: 16 }}>
        <h3 style={{ marginTop: 0 }}>Tema</h3>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <Btn v="auto" label="🖥️ Sistem" />
          <Btn v="light" label="☀️ Açık" />
          <Btn v="dark" label="🌙 Koyu" />
        </div>
      </div>

      <div className="card" style={{ marginBottom: 16 }}>
        <h3 style={{ marginTop: 0 }}>Verilerim</h3>
        <p className="muted">
          İlerleme, SRS kartları, seri ve paketler tarayıcında saklanır; girişliysen sunucuyla
          senkronlanır.
        </p>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <button className="btn btn--ghost" onClick={exportData} data-testid="export-data">
            ⬇️ Dışa aktar (JSON)
          </button>
          <button
            className="btn"
            style={{ background: 'var(--red)' }}
            onClick={resetData}
            data-testid="reset-data"
          >
            🗑️ Bu cihazı sıfırla
          </button>
        </div>
      </div>

      <div className="card" style={{ marginBottom: 16 }}>
        <h3 style={{ marginTop: 0 }}>Çerez ve gizlilik</h3>
        <p className="muted">
          Zorunlu çerezler her zaman etkindir. Analitik çerezleri:{' '}
          <strong>{consent?.analytics ? 'açık' : 'kapalı'}</strong>.
        </p>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <button
            className="btn btn--ghost"
            onClick={() => setAnalyticsConsent(true)}
            data-testid="consent-on"
          >
            Analitiği aç
          </button>
          <button
            className="btn btn--ghost"
            onClick={() => setAnalyticsConsent(false)}
            data-testid="consent-off"
          >
            Analitiği kapat
          </button>
        </div>
      </div>

      <div className="card" style={{ marginBottom: 16 }}>
        <h3 style={{ marginTop: 0 }}>Hesap</h3>
        {user ? (
          <>
            <p className="muted">{user.email} olarak giriş yaptın.</p>
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
              <button
                className="btn btn--ghost"
                onClick={doRestore}
                data-testid="restore-purchases"
              >
                Satın almaları geri yükle
              </button>
              <button
                className="btn btn--ghost"
                onClick={resendVerification}
                data-testid="resend-verify"
              >
                E-posta doğrulama gönder
              </button>
              <button
                className="btn"
                style={{ background: 'var(--red)' }}
                onClick={deleteAccount}
                data-testid="delete-account"
              >
                Hesabı sil
              </button>
            </div>
          </>
        ) : (
          <p className="muted">
            <a href="/giris">Giriş yap</a> — satın almaların ve ilerlemen tüm cihazlarına
            senkronlansın.
          </p>
        )}
      </div>

      <div className="card">
        <h3 style={{ marginTop: 0 }}>Yasal</h3>
        <ul className="prose" style={{ margin: 0 }}>
          <li>
            <a href="/gizlilik">Gizlilik Politikası</a>
          </li>
          <li>
            <a href="/kullanim-kosullari">Kullanım Koşulları</a>
          </li>
          <li>
            <a href="/cerez-politikasi">Çerez Politikası</a>
          </li>
          <li>
            <a href="/kvkk">KVKK Aydınlatma Metni</a>
          </li>
        </ul>
      </div>
    </>
  );
}
