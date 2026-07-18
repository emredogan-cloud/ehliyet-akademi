'use client';

/**
 * Profil — zengin hesap panosu (referans: new-image/032-profil-page.png).
 * Görsel dil: koyu, kartlı, teal aksanlı (globals.css jetonları). Sayfaya özel
 * düzen profil.css içinde (`pf-` ön eki). TÜM veriler GERÇEK kaynaklardan türetilir;
 * uydurma yok — modelde olmayan alanlar (telefon, doğum tarihi) dürüstçe "Eklenmemiş".
 */
import './profil.css';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { me, logout, restorePurchases, type AuthUser } from '@/lib/authClient';
import { productById } from '@/lib/products';
import { loadAnswers, loadStreak, loadCounters, loadViewedLessons } from '@/lib/progress';
import { loadEntitlements } from '@/lib/payments';
import { totalXp, levelForXp, type LevelInfo } from '@/lib/gamification';
import { computeAchievements, earnedCount, type Achievement } from '@/lib/achievements';
import { PageHeader } from '@/components/ui/layout';
import { Icon, type IconName } from '@/components/ui/icons';

const ROLE_LABEL: Record<AuthUser['role'], string> = {
  user: 'Üye',
  editor: 'Editör',
  admin: 'Yönetici',
};

const nf = (n: number): string => n.toLocaleString('tr-TR');

function initials(name: string, email: string): string {
  const src = (name || '').trim() || email.split('@')[0] || '?';
  const parts = src.split(/\s+/).filter(Boolean);
  const letters =
    parts.length >= 2 ? `${parts[0]![0]}${parts[parts.length - 1]![0]}` : src.slice(0, 2);
  return letters.toUpperCase();
}

function formatMinutes(min: number): string {
  if (min <= 0) return '0 dk';
  const h = Math.floor(min / 60);
  const m = min % 60;
  if (h && m) return `${nf(h)} sa ${m} dk`;
  if (h) return `${nf(h)} sa`;
  return `${m} dk`;
}

/** Gerçek cevap zaman damgalarından çalışma süresi türet (oturum içi < 5 dk boşluklar sayılır). */
function estimateStudyMinutes(times: number[]): number {
  const ts = times.filter(Boolean).sort((a, b) => a - b);
  if (!ts.length) return 0;
  const GAP = 5 * 60 * 1000;
  const SOLO = 30 * 1000;
  let ms = SOLO;
  for (let i = 1; i < ts.length; i++) {
    const d = ts[i]! - ts[i - 1]!;
    ms += d > 0 && d <= GAP ? d : SOLO;
  }
  return Math.round(ms / 60000);
}

/** Yalnız MEVCUT cihazı navigator.userAgent'tan türet (uydurma cihaz listesi yok). */
function currentDevice(): string {
  if (typeof navigator === 'undefined') return 'Bu tarayıcı';
  const ua = navigator.userAgent;
  const browser = /Firefox/.test(ua)
    ? 'Firefox'
    : /Edg/.test(ua)
      ? 'Edge'
      : /Chrome/.test(ua)
        ? 'Chrome'
        : /Safari/.test(ua)
          ? 'Safari'
          : 'Tarayıcı';
  const os = /Windows/.test(ua)
    ? 'Windows'
    : /Android/.test(ua)
      ? 'Android'
      : /iPhone|iPad|iPod/.test(ua)
        ? 'iOS'
        : /Mac OS X|Macintosh/.test(ua)
          ? 'macOS'
          : /Linux/.test(ua)
            ? 'Linux'
            : 'Bilinmeyen';
  return `${browser} · ${os}`;
}

interface Stats {
  studyMin: number;
  answered: number;
  accuracy: number | null;
  streakCurrent: number;
  streakBest: number;
  level: LevelInfo;
  xpRemaining: number;
  achievements: Achievement[];
  earnedN: number;
  device: string;
}

export default function ProfilPage() {
  const router = useRouter();
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loaded, setLoaded] = useState(false);
  const [owned, setOwned] = useState<string[]>([]);
  const [stats, setStats] = useState<Stats | null>(null);
  const [msg, setMsg] = useState('');

  useEffect(() => {
    void me().then((u) => {
      setUser(u);
      setLoaded(true);
    });
  }, []);

  // Oturum doğrulandıktan sonra GERÇEK ilerleme verisini yükle.
  useEffect(() => {
    if (!user) return;
    const answers = loadAnswers();
    const streak = loadStreak();
    const counters = loadCounters();
    const viewed = loadViewedLessons();
    const ents = loadEntitlements();
    setOwned(ents);

    const correct = answers.filter((a) => a.correct).length;
    const xp = totalXp({
      answers,
      streak,
      examsFinished: counters.examsFinished,
      lessonsViewed: viewed.length,
    });
    const level = levelForXp(xp);
    const achievements = computeAchievements({
      streakCurrent: streak.current,
      streakBest: streak.best,
      totalAnswers: answers.length,
      correctAnswers: correct,
      examsFinished: counters.examsFinished,
      packsOwned: ents.length,
    });
    setStats({
      studyMin: estimateStudyMinutes(answers.map((a) => a.at)),
      answered: answers.length,
      accuracy: answers.length ? Math.round((correct / answers.length) * 100) : null,
      streakCurrent: streak.current,
      streakBest: streak.best,
      level,
      xpRemaining: Math.max(0, level.xpForNext - level.xpIntoLevel),
      achievements,
      earnedN: earnedCount(achievements),
      device: currentDevice(),
    });
  }, [user]);

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

  // Korumalı sayfa: oturum yoksa giriş CTA'sı (Epic 1 — protected route).
  if (!user) {
    return (
      <div className="card" style={{ maxWidth: 500 }} data-testid="profile-guest">
        <PageHeader title="Profil" emoji="👤" />
        <p>Bu sayfa hesap gerektirir. Giriş yap — ilerlemen tüm cihazlarında seninle gelsin.</p>
        <a className="btn" href="/giris" data-testid="go-login">
          Giriş yap / Kayıt ol
        </a>
      </div>
    );
  }

  const name = user.name || 'İsimsiz aday';
  const isPremium = owned.length > 0;
  const hasKomple = owned.includes('komple-b');
  const planLabel = hasKomple ? 'Komple B · Ömür boyu' : isPremium ? 'Premium' : 'Ücretsiz plan';

  const infoRows: Array<{ icon: IconName; label: string; value: string; missing?: boolean }> = [
    { icon: 'user', label: 'Ad Soyad', value: name },
    { icon: 'login', label: 'E-posta adresi', value: user.email },
    { icon: 'shield', label: 'Hesap türü', value: ROLE_LABEL[user.role] },
    { icon: 'phone', label: 'Telefon', value: 'Eklenmemiş', missing: true },
    { icon: 'calendar', label: 'Doğum tarihi', value: 'Eklenmemiş', missing: true },
  ];

  const statTiles: Array<{
    icon: IconName;
    accent: string;
    label: string;
    value: React.ReactNode;
  }> = [
    {
      icon: 'book',
      accent: 'var(--primary)',
      label: 'Çalışma süresi',
      value: formatMinutes(stats?.studyMin ?? 0),
    },
    {
      icon: 'clipboard',
      accent: 'var(--accent-green)',
      label: 'Çözülen soru',
      value: nf(stats?.answered ?? 0),
    },
    {
      icon: 'target',
      accent: 'var(--accent-blue)',
      label: 'Doğruluk oranı',
      value: stats?.accuracy != null ? `%${stats.accuracy}` : '—',
    },
    {
      icon: 'flame',
      accent: 'var(--accent-amber)',
      label: 'Seri gün',
      value: (
        <>
          {stats?.streakCurrent ?? 0}
          <small>gün</small>
        </>
      ),
    },
  ];

  const quickActions: Array<{
    icon: IconName;
    accent: string;
    title: string;
    desc: string;
    href: string;
  }> = [
    {
      icon: 'lock',
      accent: 'var(--primary)',
      title: 'Şifre değiştir',
      desc: 'Hesap şifreni güncelle',
      href: '/sifirla',
    },
    {
      icon: 'shield',
      accent: 'var(--accent-green)',
      title: 'İki adımlı doğrulama',
      desc: 'Güvenlik ayarlarına git',
      href: '/ayarlar',
    },
    {
      icon: 'login',
      accent: 'var(--accent-blue)',
      title: 'E-posta değiştir',
      desc: 'Kayıtlı e-postanı güncelle',
      href: '/ayarlar',
    },
    {
      icon: 'ban',
      accent: 'var(--accent-red)',
      title: 'Hesabı sil',
      desc: 'Hesabını kalıcı olarak sil',
      href: '/ayarlar',
    },
  ];

  const earned = stats?.achievements.filter((a) => a.earned) ?? [];

  return (
    <div className="pf" data-testid="profile">
      <PageHeader title="Profil" emoji="👤" subtitle="Hesabını ve kalıcı satın almalarını yönet." />

      {/* ─── Hero ─── */}
      <section className="pf-hero">
        <div className="pf-id">
          <div className="pf-avatar" aria-hidden>
            {initials(name, user.email)}
          </div>
          <div className="pf-id__body">
            <h2 className="pf-id__name" data-testid="profile-name">
              {name}
            </h2>
            <div className="pf-id__mailrow">
              <span className="pf-id__mail" data-testid="profile-email">
                {user.email}
              </span>
              <span
                className="pf-badge"
                style={{
                  ['--pf-badge' as string]: isPremium ? 'var(--accent-amber)' : 'var(--text-3)',
                }}
              >
                {isPremium && <Icon name="crown" size={13} />}
                {planLabel}
              </span>
            </div>
            <p className="pf-id__sync">
              <Icon name="check-circle" size={14} />
              İlerleme senkronu: <strong>aktif</strong> — çalıştığın her cihazda devam et.
            </p>
            <div className="pf-id__actions">
              <a className="pf-btn pf-btn--primary" href="/ayarlar">
                <Icon name="gear" size={16} />
                Profili düzenle
              </a>
              <button
                type="button"
                className="pf-btn pf-btn--danger"
                onClick={doLogout}
                data-testid="logout"
              >
                <Icon name="login" size={16} />
                Çıkış yap
              </button>
            </div>
          </div>
        </div>

        <div className="pf-hcell" style={{ ['--pf-accent' as string]: 'var(--accent-green)' }}>
          <span className="pf-hcell__head">
            <Icon name="check-circle" size={16} />
            Senkronizasyon
          </span>
          <span className="pf-hcell__status">Aktif</span>
          <p className="pf-hcell__note">Satın almaların ve ilerlemen sunucuyla eşitlenir.</p>
          <button
            type="button"
            className="pf-btn pf-btn--full pf-hcell__btn"
            onClick={doRestore}
            data-testid="restore"
          >
            <Icon name="trending" size={16} />
            Şimdi senkronize et
          </button>
        </div>

        <div className="pf-hcell" style={{ ['--pf-accent' as string]: 'var(--accent-blue)' }}>
          <span className="pf-hcell__head">
            <Icon name="shield" size={16} />
            Hesap güvenliği
          </span>
          <span className="pf-hcell__status">Oturum açık</span>
          <p className="pf-hcell__note">Şifreni ve oturum güvenliğini ayarlardan yönet.</p>
          <a className="pf-btn pf-btn--full pf-hcell__btn" href="/ayarlar">
            <Icon name="lock" size={16} />
            Güvenlik ayarları
          </a>
        </div>

        <div className="pf-hcell" style={{ ['--pf-accent' as string]: 'var(--accent-amber)' }}>
          <span className="pf-hcell__head">
            <Icon name="crown" size={16} />
            Üyelik durumu
          </span>
          <span className="pf-hcell__status">{planLabel}</span>
          <p className="pf-hcell__note">
            {isPremium ? 'Premium özelliklere erişimin var.' : 'Premium paketlerle kilidini aç.'}
          </p>
          <a className="pf-btn pf-btn--full pf-hcell__btn" href="/fiyatlandirma">
            <Icon name="crown" size={16} />
            {isPremium ? 'Üyeliği yönet' : 'Planları gör'}
          </a>
        </div>
      </section>

      {msg && (
        <div className="pf-status" role="status" data-testid="restore-msg">
          {msg}
        </div>
      )}

      {/* ─── 3 sütunlu ızgara ─── */}
      <div className="pf-grid">
        {/* SOL: Hesap bilgileri + Cihazlarım */}
        <div className="pf-col">
          <section className="pf-card">
            <div className="pf-card__head">
              <h3 className="pf-card__title">
                <Icon name="user" size={20} />
                Hesap bilgileri
              </h3>
            </div>
            <div className="pf-rows">
              {infoRows.map((r) => (
                <a key={r.label} className="pf-row" href="/ayarlar">
                  <span className="pf-row__ic">
                    <Icon name={r.icon} size={18} />
                  </span>
                  <span className="pf-row__body">
                    <span className="pf-row__label">{r.label}</span>
                    <span className={`pf-row__value${r.missing ? ' pf-muted' : ''}`}>
                      {r.value}
                    </span>
                  </span>
                  <span className="pf-row__end">
                    <Icon name="chevron-right" size={18} />
                  </span>
                </a>
              ))}
            </div>
          </section>

          <section className="pf-card">
            <div className="pf-card__head">
              <div className="pf-card__titlewrap">
                <h3 className="pf-card__title">
                  <Icon name="image" size={20} />
                  Cihazlarım
                </h3>
                <p className="pf-card__sub">Bu oturumda kullandığın cihaz</p>
              </div>
            </div>
            <div className="pf-row">
              <span className="pf-row__ic">
                <Icon name="image" size={18} />
              </span>
              <span className="pf-row__body">
                <span className="pf-row__label">Bu cihaz · şu an aktif</span>
                <span className="pf-row__value">{stats?.device ?? 'Bu tarayıcı'}</span>
              </span>
              <span className="pf-row__end">
                <span className="pf-badge" style={{ ['--pf-badge' as string]: 'var(--primary)' }}>
                  Bu cihaz
                </span>
              </span>
            </div>
            <a className="pf-btn pf-btn--full" href="/ayarlar" style={{ marginTop: 'var(--sp-3)' }}>
              <Icon name="gear" size={16} />
              Cihaz ve oturumları yönet
            </a>
          </section>
        </div>

        {/* ORTA: İlerleme özeti + Faturalarım */}
        <div className="pf-col">
          <section className="pf-card">
            <div className="pf-card__head">
              <h3 className="pf-card__title">
                <Icon name="trending" size={20} />
                İlerleme özeti
              </h3>
              <a className="pf-card__link" href="/ilerleme">
                Tüm istatistikleri gör
                <Icon name="chevron-right" size={14} />
              </a>
            </div>
            <div className="pf-stats">
              {statTiles.map((t) => (
                <div
                  key={t.label}
                  className="pf-stat"
                  style={{ ['--pf-accent' as string]: t.accent }}
                >
                  <span className="pf-stat__ic">
                    <Icon name={t.icon} size={20} />
                  </span>
                  <span className="pf-stat__value">{t.value}</span>
                  <span className="pf-stat__label">{t.label}</span>
                </div>
              ))}
            </div>
            {stats && (
              <div className="pf-xp">
                <div className="pf-xp__top">
                  <span className="pf-xp__level">
                    Seviye {stats.level.level} · {stats.level.title}
                  </span>
                  <span className="pf-xp__val">
                    {nf(stats.level.xpIntoLevel)} / {nf(stats.level.xpForNext)} XP
                  </span>
                </div>
                <div className="pf-bar">
                  <div
                    className="pf-bar__fill"
                    style={{ width: `${Math.round(stats.level.progress * 100)}%` }}
                  />
                </div>
                <p className="pf-xp__next">Bir sonraki seviyeye: {nf(stats.xpRemaining)} XP</p>
              </div>
            )}
          </section>

          <section className="pf-card">
            <div className="pf-card__head">
              <div className="pf-card__titlewrap">
                <h3 className="pf-card__title">
                  <Icon name="clipboard" size={20} />
                  Satın almalarım
                </h3>
                <p className="pf-card__sub">Ömür boyu erişim — kalıcı paketler</p>
              </div>
            </div>
            {owned.length > 0 ? (
              owned.map((id) => {
                const p = productById(id);
                return (
                  <div key={id} className="pf-inv">
                    <div>
                      <div className="pf-inv__title">{p?.title ?? id}</div>
                      <div className="pf-inv__meta">Ömür boyu erişim</div>
                    </div>
                    {p && <div className="pf-inv__price">{nf(p.priceTRY)} ₺</div>}
                  </div>
                );
              })
            ) : (
              <p className="pf-empty">
                Cihazda görünen paketleri sunucudan doğrulamak için “Şimdi senkronize et”i kullan.
              </p>
            )}
            <a
              className="pf-btn pf-btn--full"
              href="/fiyatlandirma"
              style={{ marginTop: 'var(--sp-2)' }}
            >
              <Icon name="crown" size={16} />
              Paketleri görüntüle
            </a>
          </section>
        </div>

        {/* SAĞ: Başarılarım + Destek */}
        <div className="pf-col">
          <section className="pf-card">
            <div className="pf-card__head">
              <h3 className="pf-card__title">
                <Icon name="trophy" size={20} />
                Başarılarım
              </h3>
              <a className="pf-card__link" href="/basarilar">
                Tümünü gör
                <Icon name="chevron-right" size={14} />
              </a>
            </div>
            <div className="pf-ach__hero">
              <span className="pf-ach__ring">
                <Icon name="trophy" size={28} />
              </span>
              <div>
                <div className="pf-ach__count">
                  {stats?.earnedN ?? 0}
                  <small> / {stats?.achievements.length ?? 8}</small>
                </div>
                <div className="pf-ach__label">Kazanılan başarı rozeti</div>
              </div>
            </div>
            {earned.length > 0 ? (
              <div className="pf-ach__list">
                {earned.slice(0, 4).map((a) => (
                  <div key={a.id} className="pf-ach__item">
                    <span className="pf-ach__emoji" aria-hidden>
                      {a.icon}
                    </span>
                    <div className="pf-ach__meta">
                      <div className="pf-ach__t">{a.title}</div>
                      <div className="pf-ach__d">{a.desc}</div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="pf-empty">Henüz rozet kazanmadın — soru çözerek ilkini aç.</p>
            )}
            <a className="pf-btn pf-btn--full pf-ach__foot" href="/basarilar">
              <Icon name="trophy" size={16} />
              Başarılar sayfasına git
            </a>
          </section>

          <section className="pf-card pf-support">
            <h3 className="pf-support__title">Yardıma mı ihtiyacın var?</h3>
            <p className="pf-support__text">
              Takıldığın yerde AI Koç anında yol gösterir; hesap ve içerik sorularında yanındayız.
            </p>
            <a className="pf-btn pf-btn--full" href="/ai-koc">
              <Icon name="bot" size={16} />
              AI Koç'a sor
            </a>
          </section>
        </div>
      </div>

      {/* ─── Hızlı işlemler ─── */}
      <section className="pf-card">
        <div className="pf-card__head">
          <h3 className="pf-card__title">
            <Icon name="tools" size={20} />
            Hızlı işlemler
          </h3>
        </div>
        <div className="pf-quick">
          {quickActions.map((a) => (
            <a
              key={a.title}
              className="pf-action"
              href={a.href}
              style={{ ['--pf-accent' as string]: a.accent }}
            >
              <span className="pf-action__ic">
                <Icon name={a.icon} size={20} />
              </span>
              <span className="pf-action__body">
                <span className="pf-action__t">{a.title}</span>
                <span className="pf-action__d">{a.desc}</span>
              </span>
              <span className="pf-action__chev">
                <Icon name="chevron-right" size={18} />
              </span>
            </a>
          ))}
        </div>
      </section>
    </div>
  );
}
