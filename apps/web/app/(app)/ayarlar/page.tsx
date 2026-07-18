'use client';

import './ayarlar.css';
import { useEffect, useState, type CSSProperties, type ReactNode } from 'react';
import {
  syncSet,
  me,
  restorePurchases,
  logout,
  fullSync,
  isAuthed,
  type AuthUser,
} from '@/lib/authClient';
import { CONSENT_KEY, readConsent, type Consent } from '@/components/CookieConsent';
import { PageHeader } from '@/components/ui/layout';
import { Icon, type IconName } from '@/components/ui/icons';
import {
  loadAnswers,
  loadCards,
  loadCounters,
  loadStreak,
  loadViewedLessons,
} from '@/lib/progress';
import { totalXp, levelForXp, type LevelInfo } from '@/lib/gamification';
import { productById } from '@/lib/products';
import { isDue } from '@ea/srs-engine';

type Theme = 'auto' | 'light' | 'dark';
const THEME_KEY = 'ea:theme';
const BACKUP_KEY = 'ea:lastBackup';
const PREFS_KEY = 'ea:prefs:v1';

type Accent = 'teal' | 'amber' | 'blue' | 'purple' | 'red' | 'green';
const ACCENT: Record<Accent, string> = {
  teal: 'var(--accent-teal)',
  amber: 'var(--accent-amber)',
  blue: 'var(--accent-blue)',
  purple: 'var(--accent-purple)',
  red: 'var(--accent-red)',
  green: 'var(--accent-green)',
};

const THEMES: { id: Theme; label: string; desc: string }[] = [
  { id: 'auto', label: 'Sistem', desc: 'Cihaz temasını kullanır.' },
  { id: 'dark', label: 'Koyu', desc: 'Gece sürüş modu.' },
  { id: 'light', label: 'Açık', desc: 'Gündüz modu.' },
];

/** Sadece bu sayfada saklanan görsel tercihler (localStorage'a GERÇEKTEN yazılır). */
interface Prefs {
  notifyDaily: boolean;
  notifyExam: boolean;
  notifyNewLesson: boolean;
  notifyWeekly: boolean;
  privCrash: boolean;
  privPersonalize: boolean;
  a11yHighContrast: boolean;
  a11yReduceMotion: boolean;
  fontSize: 'sm' | 'md' | 'lg';
  timezone: string;
}
const DEFAULT_PREFS: Prefs = {
  notifyDaily: true,
  notifyExam: true,
  notifyNewLesson: true,
  notifyWeekly: false,
  privCrash: true,
  privPersonalize: true,
  a11yHighContrast: false,
  a11yReduceMotion: false,
  fontSize: 'md',
  timezone: 'Europe/Istanbul',
};

const LEGAL_LINKS: { href: string; label: string }[] = [
  { href: '/kvkk', label: 'KVKK Aydınlatma Metni' },
  { href: '/gizlilik', label: 'Gizlilik Politikası' },
  { href: '/kullanim-kosullari', label: 'Kullanım Koşulları' },
  { href: '/cerez-politikasi', label: 'Çerez Politikası' },
];

function applyTheme(t: Theme) {
  if (t === 'auto') document.documentElement.removeAttribute('data-theme');
  else document.documentElement.setAttribute('data-theme', t);
}

function fmtWhen(ts: number | null): string {
  if (!ts) return '—';
  const d = new Date(ts);
  const hhmm = `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  if (d.toDateString() === new Date().toDateString()) return `Bugün ${hhmm}`;
  return d.toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' });
}

/* ------------------------------- Alt bileşenler ------------------------------- */

function Card({
  icon,
  accent,
  title,
  sub,
  className,
  children,
}: {
  icon: IconName;
  accent: Accent;
  title: string;
  sub?: string;
  className?: string;
  children: ReactNode;
}) {
  return (
    <section
      className={`st-card${className ? ` ${className}` : ''}`}
      style={{ ['--st-ac' as string]: ACCENT[accent] } as CSSProperties}
    >
      <header className="st-card__head">
        <span className="st-badge">
          <Icon name={icon} size={20} />
        </span>
        <div>
          <h3 className="st-card__title">{title}</h3>
          {sub && <p className="st-card__sub">{sub}</p>}
        </div>
      </header>
      {children}
    </section>
  );
}

function Row({
  icon,
  label,
  value,
  tone,
}: {
  icon?: IconName;
  label: string;
  value: ReactNode;
  tone?: 'good' | 'warn' | 'muted';
}) {
  return (
    <div className="st-row">
      <span className="st-row__label">
        {icon && <Icon name={icon} size={16} />}
        {label}
      </span>
      <span className={`st-row__val${tone ? ` is-${tone}` : ''}`}>{value}</span>
    </div>
  );
}

function Switch({
  checked,
  onChange,
  testid,
  labelId,
}: {
  checked: boolean;
  onChange: (v: boolean) => void;
  testid?: string;
  labelId?: string;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-labelledby={labelId}
      data-testid={testid}
      className={`st-switch${checked ? ' is-on' : ''}`}
      onClick={() => onChange(!checked)}
    >
      <span className="st-switch__knob" />
    </button>
  );
}

function Toggle({
  icon,
  label,
  checked,
  onChange,
}: {
  icon: IconName;
  label: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <div className="st-toggle">
      <span className="st-toggle__label">
        <Icon name={icon} size={16} />
        {label}
      </span>
      <Switch checked={checked} onChange={onChange} />
    </div>
  );
}

/* ------------------------------- Sayfa ------------------------------- */

export default function AyarlarPage() {
  const [theme, setTheme] = useState<Theme>('auto');
  const [user, setUser] = useState<AuthUser | null>(null);
  const [consent, setConsent] = useState<Consent | null>(null);
  const [owned, setOwned] = useState<string[]>([]);
  const [prefs, setPrefs] = useState<Prefs>(DEFAULT_PREFS);
  const [lastBackup, setLastBackup] = useState<number | null>(null);
  const [note, setNote] = useState('');

  // Gerçek ilerleme metrikleri (yalnız istemcide hesaplanır)
  const [stats, setStats] = useState({
    total: 0,
    correct: 0,
    wrongPool: 0,
    srs: 0,
    due: 0,
    streak: 0,
    lastActivity: null as number | null,
    level: levelForXp(0) as LevelInfo,
  });

  useEffect(() => {
    try {
      const t = localStorage.getItem(THEME_KEY);
      if (t === 'light' || t === 'dark') setTheme(t);
    } catch {
      /* ilk açılış */
    }
    setConsent(readConsent());
    void me().then(setUser);

    // Sahiplik (yetki listesi) — yereldeki gerçek satın almalar
    try {
      const raw = localStorage.getItem('ea:entitlements:v1');
      if (raw) setOwned(JSON.parse(raw) as string[]);
    } catch {
      /* yok */
    }

    // Tercihler
    try {
      const raw = localStorage.getItem(PREFS_KEY);
      const parsed = raw ? (JSON.parse(raw) as Partial<Prefs>) : {};
      const detectedTz = Intl.DateTimeFormat().resolvedOptions().timeZone || DEFAULT_PREFS.timezone;
      setPrefs({ ...DEFAULT_PREFS, timezone: detectedTz, ...parsed });
    } catch {
      /* yok */
    }

    try {
      const b = localStorage.getItem(BACKUP_KEY);
      if (b) setLastBackup(Number(b));
    } catch {
      /* yok */
    }

    // Gerçek istatistikler
    try {
      const answers = loadAnswers();
      const cards = loadCards();
      const now = Date.now();
      const correct = answers.filter((a) => a.correct).length;
      const lastByQ = new Map<string, boolean>();
      let lastActivity = 0;
      for (const a of answers) {
        lastByQ.set(a.questionId, a.correct);
        if (a.at > lastActivity) lastActivity = a.at;
      }
      let wrongPool = 0;
      lastByQ.forEach((ok) => {
        if (!ok) wrongPool += 1;
      });
      let due = 0;
      cards.forEach((c) => {
        if (isDue(c, now)) due += 1;
      });
      const streak = loadStreak();
      const xp = totalXp({
        answers,
        streak,
        examsFinished: loadCounters().examsFinished,
        lessonsViewed: loadViewedLessons().length,
      });
      setStats({
        total: answers.length,
        correct,
        wrongPool,
        srs: cards.size,
        due,
        streak: streak.current,
        lastActivity: lastActivity || null,
        level: levelForXp(xp),
      });
    } catch {
      /* boş veri */
    }
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

  function savePrefs(next: Prefs) {
    setPrefs(next);
    try {
      localStorage.setItem(PREFS_KEY, JSON.stringify(next));
    } catch {
      /* kota */
    }
  }
  function setPref<K extends keyof Prefs>(key: K, value: Prefs[K]) {
    savePrefs({ ...prefs, [key]: value });
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
      const now = Date.now();
      localStorage.setItem(BACKUP_KEY, String(now));
      setLastBackup(now);
      setNote('Verilerin JSON olarak indirildi.');
    } catch {
      setNote('Dışa aktarma başarısız oldu.');
    }
  }

  async function cloudBackup() {
    if (!user && !isAuthed()) {
      setNote('Bulut yedek için önce giriş yapmalısın.');
      return;
    }
    setNote('Buluta yedekleniyor…');
    try {
      await fullSync();
      const now = Date.now();
      localStorage.setItem(BACKUP_KEY, String(now));
      setLastBackup(now);
      setNote('Verilerin bulutla senkronlandı.');
    } catch {
      setNote('Bulut yedeği başarısız oldu.');
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
    const list = await restorePurchases();
    setOwned(list);
    setNote(
      list.length
        ? `${list.length} satın alma geri yüklendi.`
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

  async function logoutAll() {
    await logout();
    location.href = '/';
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

  /* ---- Türetilmiş görünüm değerleri (uydurma yok) ---- */
  const displayName = user?.name || 'Misafir';
  const initials =
    displayName
      .trim()
      .split(/\s+/)
      .map((w) => w[0])
      .slice(0, 2)
      .join('')
      .toUpperCase() || 'EA';

  const lifetime = owned.includes('komple-b');
  const premiumActive = owned.length > 0;
  const packageLabel = lifetime
    ? 'Komple B · Lifetime'
    : premiumActive
      ? owned
          .map((id) => productById(id)?.title)
          .filter(Boolean)
          .join(' + ') || 'Premium'
      : 'Ücretsiz';
  const membershipTitle = lifetime ? 'Premium Lifetime' : premiumActive ? 'Premium' : 'Ücretsiz';
  const analyticsOn = consent?.analytics ?? false;
  const accuracy = stats.total ? Math.round((stats.correct / stats.total) * 100) : 0;
  const synced = !!user;
  const tzLabel = (tz: string) => (tz === 'Europe/Istanbul' ? '(GMT+03:00) İstanbul' : tz);
  const tzOptions = Array.from(new Set([prefs.timezone, 'Europe/Istanbul', 'UTC']));

  return (
    <>
      <PageHeader
        title="Ayarlar"
        emoji="⚙️"
        subtitle="Hesabını, öğrenme deneyimini ve uygulama tercihlerini yönet."
      />

      {note && (
        <p className="st-note" role="status" data-testid="settings-note">
          {note}
        </p>
      )}

      <div className="st-shell">
        <div className="st-main">
          {/* ---- Kahraman ---- */}
          <section className="st-hero">
            <div className="st-hero__id">
              <span className="st-avatar" aria-hidden>
                {initials}
              </span>
              <div>
                <h2 className="st-hero__name">{displayName}</h2>
                <div className="st-hero__meta">
                  <span>{stats.level.title}</span>
                  {premiumActive && (
                    <span className="st-pill">
                      <Icon name="crown" size={13} /> {membershipTitle}
                    </span>
                  )}
                </div>
                <a className="st-btn" href="/profil">
                  <Icon name="user" size={15} /> Hesabı yönet
                </a>
              </div>
            </div>

            <div className="st-hero__block">
              <span className="st-hero__block-head">
                <Icon name="check-circle" size={15} /> Senkronizasyon
              </span>
              <span
                className="st-hero__block-val"
                style={{ color: synced ? 'var(--green)' : 'var(--text-2)' }}
              >
                {synced ? 'Senkronize edildi' : 'Yalnızca bu cihaz'}
              </span>
              <span className="st-hero__block-sub">Son çalışma {fmtWhen(stats.lastActivity)}</span>
            </div>

            <div className="st-hero__block">
              <span className="st-hero__block-head">
                <Icon name="crown" size={15} /> Üyelik durumu
              </span>
              <span className="st-hero__block-val">{membershipTitle}</span>
              <span className="st-hero__block-sub">
                {premiumActive ? 'Premium içeriklere erişim açık' : 'Ücretsiz sürüm'}
              </span>
            </div>
          </section>

          {/* ---- Kart ızgarası ---- */}
          <div className="st-grid">
            {/* Görünüm */}
            <Card icon="sun" accent="amber" title="Görünüm" sub="Uygulamanın temasını seç.">
              <div className="st-theme">
                <div className="st-theme__list" role="radiogroup" aria-label="Tema">
                  {THEMES.map((t) => (
                    <button
                      key={t.id}
                      type="button"
                      role="radio"
                      aria-checked={theme === t.id}
                      data-testid={`theme-${t.id}`}
                      className={`st-radio${theme === t.id ? ' is-on' : ''}`}
                      onClick={() => choose(t.id)}
                    >
                      <span className="st-radio__dot" />
                      <span className="st-radio__text">
                        <strong>{t.label}</strong>
                        <em>{t.desc}</em>
                      </span>
                    </button>
                  ))}
                </div>
                <div className="st-preview" aria-hidden>
                  <div className="st-preview__pane st-preview__pane--dark">
                    <span className="st-preview__dot" />
                    <span className="st-preview__bar accent" />
                    <span className="st-preview__bar" />
                    <span className="st-preview__bar" />
                  </div>
                  <div className="st-preview__pane st-preview__pane--light">
                    <span className="st-preview__dot" />
                    <span className="st-preview__bar accent" />
                    <span className="st-preview__bar" />
                    <span className="st-preview__bar" />
                  </div>
                </div>
              </div>
            </Card>

            {/* Öğrenme Verileri */}
            <Card
              icon="layers"
              accent="blue"
              title="Öğrenme Verileri"
              sub="Verilerini yönet ve yedekle."
            >
              <div className="st-rows">
                <Row icon="clipboard" label="Toplam soru" value={stats.total} />
                <Row icon="ban" label="Yanlış havuzu" value={stats.wrongPool} />
                <Row icon="brain" label="SRS kartları" value={stats.srs} />
                <Row icon="timer" label="Son yedek" value={fmtWhen(lastBackup)} tone="muted" />
              </div>
              <div className="st-btns">
                <button
                  type="button"
                  className="st-btn"
                  onClick={exportData}
                  data-testid="export-data"
                >
                  <Icon name="tools" size={15} /> Dışa aktar
                </button>
                <button type="button" className="st-btn" onClick={cloudBackup}>
                  <Icon name="check-circle" size={15} /> Bulut yedekle
                </button>
                <button
                  type="button"
                  className="st-btn st-btn--danger"
                  onClick={resetData}
                  data-testid="reset-data"
                >
                  <Icon name="ban" size={15} /> Sıfırla
                </button>
              </div>
            </Card>

            {/* Premium */}
            <Card icon="crown" accent="amber" title="Premium" sub="Üyelik ve fatura bilgilerin.">
              <div className="st-rows">
                <Row label="Paket" value={packageLabel} />
                <Row
                  label="Durum"
                  value={
                    premiumActive ? (
                      <>
                        <Icon name="check-circle" size={14} /> Aktif
                      </>
                    ) : (
                      'Pasif'
                    )
                  }
                  tone={premiumActive ? 'good' : 'muted'}
                />
                <Row label="Satın alma tarihi" value="—" tone="muted" />
                <Row
                  label="Güncelleme"
                  value={lifetime ? 'Sonsuz' : '—'}
                  tone={lifetime ? undefined : 'muted'}
                />
                <Row
                  label="Otomatik yenileme"
                  value={lifetime ? 'Yok (Lifetime)' : '—'}
                  tone="muted"
                />
              </div>
              <div className="st-btns">
                <button
                  type="button"
                  className="st-btn"
                  onClick={doRestore}
                  data-testid="restore-purchases"
                >
                  <Icon name="crown" size={15} /> Satın almaları geri yükle
                </button>
                <a className="st-btn" href="/profil">
                  <Icon name="clipboard" size={15} /> Geçmiş
                </a>
                <a className="st-btn" href="/fiyatlandirma">
                  <Icon name="star" size={15} /> Paketler
                </a>
              </div>
            </Card>

            {/* Bildirimler */}
            <Card icon="bell" accent="amber" title="Bildirimler" sub="Bildirim tercihlerini yönet.">
              <div>
                <Toggle
                  icon="calendar"
                  label="Günlük çalışma hatırlatmaları"
                  checked={prefs.notifyDaily}
                  onChange={(v) => setPref('notifyDaily', v)}
                />
                <Toggle
                  icon="timer"
                  label="Sınav zamanı yaklaşınca uyar"
                  checked={prefs.notifyExam}
                  onChange={(v) => setPref('notifyExam', v)}
                />
                <Toggle
                  icon="book"
                  label="Yeni ders eklendiğinde bildir"
                  checked={prefs.notifyNewLesson}
                  onChange={(v) => setPref('notifyNewLesson', v)}
                />
                <Toggle
                  icon="trending"
                  label="Haftalık rapor gönder"
                  checked={prefs.notifyWeekly}
                  onChange={(v) => setPref('notifyWeekly', v)}
                />
              </div>
            </Card>

            {/* Gizlilik */}
            <Card icon="lock" accent="purple" title="Gizlilik" sub="Gizlilik tercihlerini yönet.">
              <div className="st-toggle">
                <span className="st-toggle__label">
                  <Icon name="trending" size={16} /> Analitik verileri paylaş
                </span>
                <div className="st-seg" role="group" aria-label="Analitik çerezleri">
                  <button
                    type="button"
                    className={`st-seg__btn${!analyticsOn ? ' is-on' : ''}`}
                    aria-pressed={!analyticsOn}
                    data-testid="consent-off"
                    onClick={() => setAnalyticsConsent(false)}
                  >
                    Kapalı
                  </button>
                  <button
                    type="button"
                    className={`st-seg__btn${analyticsOn ? ' is-on' : ''}`}
                    aria-pressed={analyticsOn}
                    data-testid="consent-on"
                    onClick={() => setAnalyticsConsent(true)}
                  >
                    Açık
                  </button>
                </div>
              </div>
              <Toggle
                icon="shield"
                label="Çökme raporlarını gönder"
                checked={prefs.privCrash}
                onChange={(v) => setPref('privCrash', v)}
              />
              <Toggle
                icon="target"
                label="Kişiselleştirme önerileri"
                checked={prefs.privPersonalize}
                onChange={(v) => setPref('privPersonalize', v)}
              />
              <div className="st-toggle">
                <span className="st-toggle__label">
                  <Icon name="lock" size={16} /> Çerez tercihleri
                </span>
                <a className="st-btn" href="/cerez-politikasi">
                  Yönet
                </a>
              </div>
            </Card>

            {/* Dil ve Bölge */}
            <Card icon="map" accent="blue" title="Dil ve Bölge" sub="Uygulama dilini seç.">
              <div className="st-field">
                <label className="st-field__label" htmlFor="st-lang">
                  Uygulama dili
                </label>
                <select id="st-lang" className="st-select" value="tr" disabled>
                  <option value="tr">🇹🇷 Türkçe</option>
                </select>
              </div>
              <div className="st-field">
                <label className="st-field__label" htmlFor="st-tz">
                  Saat dilimi
                </label>
                <select
                  id="st-tz"
                  className="st-select"
                  value={prefs.timezone}
                  onChange={(e) => setPref('timezone', e.target.value)}
                >
                  {tzOptions.map((tz) => (
                    <option key={tz} value={tz}>
                      {tzLabel(tz)}
                    </option>
                  ))}
                </select>
              </div>
            </Card>

            {/* Erişilebilirlik */}
            <Card
              icon="tools"
              accent="teal"
              title="Erişilebilirlik"
              sub="Erişilebilirlik seçeneklerini özelleştir."
            >
              <div className="st-field">
                <span className="st-field__label">Yazı boyutu</span>
                <div className="st-seg st-seg--full" role="group" aria-label="Yazı boyutu">
                  {(['sm', 'md', 'lg'] as const).map((s) => (
                    <button
                      key={s}
                      type="button"
                      className={`st-seg__btn${prefs.fontSize === s ? ' is-on' : ''}`}
                      aria-pressed={prefs.fontSize === s}
                      onClick={() => setPref('fontSize', s)}
                    >
                      {s === 'sm' ? 'Küçük' : s === 'md' ? 'Normal' : 'Büyük'}
                    </button>
                  ))}
                </div>
              </div>
              <Toggle
                icon="sun"
                label="Yüksek kontrast modu"
                checked={prefs.a11yHighContrast}
                onChange={(v) => setPref('a11yHighContrast', v)}
              />
              <Toggle
                icon="ban"
                label="Hareketleri azalt"
                checked={prefs.a11yReduceMotion}
                onChange={(v) => setPref('a11yReduceMotion', v)}
              />
            </Card>

            {/* Güvenlik */}
            <Card icon="shield" accent="green" title="Güvenlik" sub="Hesabını güvende tut.">
              <div className="st-links">
                <a className="st-link" href="/giris">
                  <span className="st-link__l">
                    <Icon name="lock" size={16} /> Şifre değiştir
                  </span>
                  <Icon name="chevron-right" size={16} />
                </a>
                {user ? (
                  <>
                    <button
                      type="button"
                      className="st-link"
                      onClick={resendVerification}
                      data-testid="resend-verify"
                    >
                      <span className="st-link__l">
                        <Icon name="check-circle" size={16} /> E-posta doğrulama gönder
                      </span>
                      <Icon name="chevron-right" size={16} />
                    </button>
                    <button type="button" className="st-link st-link--danger" onClick={logoutAll}>
                      <span className="st-link__l">
                        <Icon name="login" size={16} /> Tüm cihazlardan çıkış yap
                      </span>
                      <Icon name="chevron-right" size={16} />
                    </button>
                    <button
                      type="button"
                      className="st-link st-link--danger"
                      onClick={deleteAccount}
                      data-testid="delete-account"
                    >
                      <span className="st-link__l">
                        <Icon name="ban" size={16} /> Hesabı sil
                      </span>
                      <Icon name="chevron-right" size={16} />
                    </button>
                  </>
                ) : (
                  <a className="st-link" href="/giris">
                    <span className="st-link__l">
                      <Icon name="login" size={16} /> Giriş yap — senkron ve satın almalar
                    </span>
                    <Icon name="chevron-right" size={16} />
                  </a>
                )}
              </div>
            </Card>

            {/* Destek */}
            <Card icon="bot" accent="teal" title="Destek" sub="Yardım ve destek seçenekleri.">
              <p className="st-tip">Takıldığın yerde yapay zeka koçuna anında sorabilirsin.</p>
              <div className="st-links">
                <a className="st-link" href="/ai-koc">
                  <span className="st-link__l">
                    <Icon name="bot" size={16} /> AI Koç&apos;a sor
                  </span>
                  <Icon name="chevron-right" size={16} />
                </a>
                <a className="st-link" href="/kvkk">
                  <span className="st-link__l">
                    <Icon name="shield" size={16} /> Verilerim &amp; haklarım
                  </span>
                  <Icon name="chevron-right" size={16} />
                </a>
              </div>
            </Card>

            {/* Yasal */}
            <Card icon="book" accent="green" title="Yasal" sub="Yasal metinler ve politikalar.">
              <div className="st-links">
                {LEGAL_LINKS.map((l) => (
                  <a key={l.href} className="st-link" href={l.href}>
                    <span className="st-link__l">{l.label}</span>
                    <Icon name="chevron-right" size={16} />
                  </a>
                ))}
              </div>
            </Card>
          </div>
        </div>

        {/* ---- Sağ ray ---- */}
        <aside className="st-rail">
          <Card icon="sun" accent="amber" title="Günün ipucu">
            <p className="st-tip">
              Araç kullanırken dikkatin yolda olsun. Güvenli sürüş, hem seni hem çevreni korur.
            </p>
            {/* Üretilmiş gece-yol görseli — ipucu kartına doğal doku (FINAL SPRINT P7 asset reuse). */}
            <div className="st-tip-art">
              <img src="/assets/art/night-road-city.webp" alt="" loading="lazy" />
            </div>
          </Card>

          <Card icon="user" accent="teal" title="Hesap durumu">
            <div className="st-rows">
              <Row
                icon="crown"
                label="Premium"
                value={premiumActive ? 'Aktif' : 'Pasif'}
                tone={premiumActive ? 'good' : 'muted'}
              />
              <Row
                icon="check-circle"
                label="Senkronizasyon"
                value={synced ? 'Başarılı' : 'Yerel'}
                tone={synced ? 'good' : 'muted'}
              />
              <Row
                icon="timer"
                label="Bulut yedek"
                value={synced ? 'Güncel' : '—'}
                tone={synced ? 'good' : 'muted'}
              />
            </div>
          </Card>

          <Card icon="gauge" accent="blue" title="Öğrenme özeti">
            <div className="st-rows">
              <Row icon="clipboard" label="Çözülen soru" value={stats.total} />
              <Row icon="target" label="Doğruluk oranı" value={`%${accuracy}`} />
              <Row icon="flame" label="Güncel seri" value={`${stats.streak} gün`} />
              <Row icon="star" label="Toplam XP" value={`${stats.level.xp} XP`} />
            </div>
            <div>
              <div className="st-summary__bar">
                <div
                  className="st-summary__fill"
                  style={{ width: `${Math.round(stats.level.progress * 100)}%` }}
                />
              </div>
              <div className="st-summary__level">
                <span>
                  {stats.level.level}. Seviye · {stats.level.title}
                </span>
                <span>
                  {stats.level.xpIntoLevel} / {stats.level.xpForNext} XP
                </span>
              </div>
            </div>
          </Card>

          <Card icon="bot" accent="teal" title="Bir şeye mi ihtiyacın var?" className="st-coach">
            <p className="st-tip">AI Koç sana yol boyunca yardımcı olabilir.</p>
            <a className="st-coach__cta" href="/ai-koc">
              <Icon name="bot" size={16} /> AI Koç&apos;a Sor
            </a>
          </Card>
        </aside>
      </div>
    </>
  );
}
