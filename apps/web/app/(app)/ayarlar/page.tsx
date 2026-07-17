'use client';

import { useEffect, useState, type ReactNode } from 'react';
import { syncSet, me, restorePurchases, type AuthUser } from '@/lib/authClient';
import { CONSENT_KEY, readConsent, type Consent } from '@/components/CookieConsent';
import { PageHeader, Grid } from '@/components/ui/layout';
import { Card, Button, IconBadge, Chip, type Accent } from '@/components/ui/primitives';
import { QuizLayout, QuizPanel, InfoRow } from '@/components/ui/quiz';
import { Icon, type IconName } from '@/components/ui/icons';

type Theme = 'auto' | 'light' | 'dark';
const THEME_KEY = 'ea:theme';

const THEME_LABEL: Record<Theme, string> = { auto: 'Sistem', light: 'Açık', dark: 'Koyu' };
const THEME_ICON: Record<Theme, IconName> = { auto: 'gear', light: 'sun', dark: 'moon' };

const LEGAL_LINKS = [
  { href: '/gizlilik', label: 'Gizlilik Politikası' },
  { href: '/kullanim-kosullari', label: 'Kullanım Koşulları' },
  { href: '/cerez-politikasi', label: 'Çerez Politikası' },
  { href: '/kvkk', label: 'KVKK Aydınlatma Metni' },
];

function applyTheme(t: Theme) {
  if (t === 'auto') document.documentElement.removeAttribute('data-theme');
  else document.documentElement.setAttribute('data-theme', t);
}

/** Ref 029 bölüm kartı: renkli ikon rozeti + başlık + açıklama + içerik. */
function SectionCard({
  icon,
  accent,
  title,
  sub,
  children,
}: {
  icon: IconName;
  accent: Accent;
  title: string;
  sub?: string;
  children: ReactNode;
}) {
  return (
    <Card accent={accent} style={{ display: 'flex', flexDirection: 'column', gap: 'var(--sp-3)' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--sp-3)' }}>
        <IconBadge accent={accent} size="md">
          <Icon name={icon} size={20} />
        </IconBadge>
        <div>
          <h3 style={{ margin: 0, fontSize: 'var(--fs-md)' }}>{title}</h3>
          {sub && (
            <p style={{ margin: 0, color: 'var(--text-3)', fontSize: 'var(--fs-xs)' }}>{sub}</p>
          )}
        </div>
      </div>
      {children}
    </Card>
  );
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

  const themeChoices: Theme[] = ['auto', 'light', 'dark'];

  return (
    <>
      <PageHeader
        title="Ayarlar"
        emoji="⚙️"
        subtitle="Hesabını, öğrenme deneyimini ve uygulama tercihlerini yönet."
      />

      {note && (
        <p className="explain" role="status" data-testid="settings-note">
          {note}
        </p>
      )}

      <QuizLayout
        main={
          <Grid min="260px">
            <SectionCard icon="sun" accent="amber" title="Görünüm" sub="Uygulamanın temasını seç.">
              <div style={{ display: 'flex', gap: 'var(--sp-2)', flexWrap: 'wrap' }}>
                {themeChoices.map((t) => (
                  <Chip
                    key={t}
                    active={theme === t}
                    onClick={() => choose(t)}
                    data-testid={`theme-${t}`}
                  >
                    <Icon name={THEME_ICON[t]} size={15} /> {THEME_LABEL[t]}
                  </Chip>
                ))}
              </div>
            </SectionCard>

            <SectionCard
              icon="book"
              accent="blue"
              title="Öğrenme Verileri"
              sub="Verilerini yönet ve yedekle."
            >
              <p style={{ margin: 0, color: 'var(--text-2)', fontSize: 'var(--fs-sm)' }}>
                İlerleme, SRS kartları, seri ve paketler tarayıcında saklanır; girişliysen sunucuyla
                senkronlanır.
              </p>
              <div style={{ display: 'flex', gap: 'var(--sp-2)', flexWrap: 'wrap' }}>
                <Button variant="ghost" size="sm" onClick={exportData} data-testid="export-data">
                  ⬇️ Dışa aktar (JSON)
                </Button>
                <Button
                  variant="accent"
                  accent="red"
                  size="sm"
                  onClick={resetData}
                  data-testid="reset-data"
                >
                  🗑️ Bu cihazı sıfırla
                </Button>
              </div>
            </SectionCard>

            <SectionCard
              icon="lock"
              accent="purple"
              title="Çerez ve gizlilik"
              sub="Gizlilik tercihlerini yönet."
            >
              <p style={{ margin: 0, color: 'var(--text-2)', fontSize: 'var(--fs-sm)' }}>
                Zorunlu çerezler her zaman etkindir. Analitik çerezleri:{' '}
                <strong>{consent?.analytics ? 'açık' : 'kapalı'}</strong>.
              </p>
              <div style={{ display: 'flex', gap: 'var(--sp-2)', flexWrap: 'wrap' }}>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setAnalyticsConsent(true)}
                  data-testid="consent-on"
                >
                  Analitiği aç
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setAnalyticsConsent(false)}
                  data-testid="consent-off"
                >
                  Analitiği kapat
                </Button>
              </div>
            </SectionCard>

            <SectionCard
              icon="user"
              accent="teal"
              title="Hesap"
              sub="Oturum ve satın almalarını yönet."
            >
              {user ? (
                <>
                  <p style={{ margin: 0, color: 'var(--text-2)', fontSize: 'var(--fs-sm)' }}>
                    {user.email} olarak giriş yaptın.
                  </p>
                  <div style={{ display: 'flex', gap: 'var(--sp-2)', flexWrap: 'wrap' }}>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={doRestore}
                      data-testid="restore-purchases"
                    >
                      Satın almaları geri yükle
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={resendVerification}
                      data-testid="resend-verify"
                    >
                      E-posta doğrulama gönder
                    </Button>
                    <Button
                      variant="accent"
                      accent="red"
                      size="sm"
                      onClick={deleteAccount}
                      data-testid="delete-account"
                    >
                      Hesabı sil
                    </Button>
                  </div>
                </>
              ) : (
                <p style={{ margin: 0, color: 'var(--text-2)', fontSize: 'var(--fs-sm)' }}>
                  <a href="/giris">Giriş yap</a> — satın almaların ve ilerlemen tüm cihazlarına
                  senkronlansın.
                </p>
              )}
            </SectionCard>

            <SectionCard
              icon="shield"
              accent="green"
              title="Yasal"
              sub="Yasal metinler ve politikalar."
            >
              <ul
                style={{
                  listStyle: 'none',
                  margin: 0,
                  padding: 0,
                  display: 'grid',
                  gap: 'var(--sp-2)',
                }}
              >
                {LEGAL_LINKS.map((l) => (
                  <li key={l.href}>
                    <a
                      href={l.href}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        gap: 'var(--sp-2)',
                        fontSize: 'var(--fs-sm)',
                      }}
                    >
                      {l.label}
                      <Icon name="chevron-right" size={15} />
                    </a>
                  </li>
                ))}
              </ul>
            </SectionCard>
          </Grid>
        }
        aside={
          <>
            <QuizPanel title="Günün ipucu" icon="sun">
              <p style={{ margin: 0, color: 'var(--text-2)', fontSize: 'var(--fs-sm)' }}>
                Araç kullanırken dikkatin yolda olsun. Güvenli sürüş, hayatı korur.
              </p>
            </QuizPanel>
            <QuizPanel title="Hesap durumu" icon="user">
              <InfoRow icon={THEME_ICON[theme]} label="Tema" value={THEME_LABEL[theme]} />
              <InfoRow icon="login" label="Oturum" value={user ? user.email : 'Misafir'} />
              <InfoRow
                icon="shield"
                label="Analitik"
                value={consent?.analytics ? 'Açık' : 'Kapalı'}
              />
            </QuizPanel>
          </>
        }
      />
    </>
  );
}
