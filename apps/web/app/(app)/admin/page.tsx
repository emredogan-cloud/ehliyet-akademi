'use client';

import './admin-overview.css';
import { useEffect, useState, type CSSProperties } from 'react';
import { PageHeader } from '@/components/ui/layout';
import { Icon, type IconName } from '@/components/ui/icons';

interface Stats {
  content: number;
  published: number;
  media: number;
  users: number;
}

interface ContentRow {
  id: string;
  type: string;
  slug: string;
  title: string;
  status: string;
  version: number;
  updatedAt: string;
}

interface Health {
  status: string;
  db: string;
  email: string;
  payments: string;
}

/* İçerik türü → Türkçe etiket + donut rengi (gerçek CONTENT_TYPES: @ea/db) */
const TYPE_ORDER = ['lesson', 'question', 'article', 'seo_page', 'kb'] as const;
const TYPE_LABEL: Record<string, string> = {
  lesson: 'Ders',
  question: 'Soru',
  article: 'Makale',
  seo_page: 'SEO Sayfası',
  kb: 'Bilgi Bankası',
};
const TYPE_COLOR: Record<string, string> = {
  lesson: 'var(--primary)',
  question: 'var(--accent-amber)',
  article: 'var(--accent-purple)',
  seo_page: 'var(--accent-blue)',
  kb: 'var(--accent-green)',
};
const STATUS_LABEL: Record<string, string> = {
  draft: 'Taslak',
  in_review: 'İncelemede',
  approved: 'Onaylı',
  published: 'Yayında',
  retired: 'Arşiv',
};

function typeLabel(t: string): string {
  return TYPE_LABEL[t] ?? t;
}
function statusLabel(s: string): string {
  return STATUS_LABEL[s] ?? s;
}
function fmtDate(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '';
  return d.toLocaleDateString('tr-TR', { day: 'numeric', month: 'short', year: 'numeric' });
}

const QUICK_ACTIONS: { href: string; icon: IconName; title: string; desc: string }[] = [
  {
    href: '/admin/icerik',
    icon: 'clipboard',
    title: 'İçerik Yönet',
    desc: 'Ders/soru/makale oluştur, incele, yayınla.',
  },
  {
    href: '/admin/medya',
    icon: 'image',
    title: 'Medya Kütüphanesi',
    desc: 'Görsel/SVG yükle ve yönet.',
  },
  {
    href: '/admin/denetim',
    icon: 'shield',
    title: 'Denetim Kaydı',
    desc: 'Tüm ayrıcalıklı işlemlerin izini görüntüle.',
  },
];

export default function AdminHome() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [items, setItems] = useState<ContentRow[] | null>(null);
  const [health, setHealth] = useState<Health | null>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    void fetch('/api/admin/stats', { credentials: 'same-origin' })
      .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
      .then((d: { stats: Stats }) => setStats(d.stats))
      .catch(() => setErr('İstatistikler yüklenemedi.'));

    void fetch('/api/admin/content?limit=200', { credentials: 'same-origin' })
      .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
      .then((d: { items: ContentRow[] }) => setItems(d.items ?? []))
      .catch(() => setItems([]));

    void fetch('/api/health', { credentials: 'same-origin' })
      .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
      .then((d: Health) => setHealth(d))
      .catch(() => setHealth(null));
  }, []);

  /* Donut segmentleri — GERÇEK içerik türü dağılımı (fetch'lenen kalemlerden sayılır) */
  const dist = TYPE_ORDER.map((t) => ({
    type: t,
    n: (items ?? []).filter((i) => i.type === t).length,
  })).filter((d) => d.n > 0);
  const distTotal = dist.reduce((s, d) => s + d.n, 0);
  let acc = 0;
  const stops = dist.map((d) => {
    const start = (acc / distTotal) * 100;
    acc += d.n;
    const end = (acc / distTotal) * 100;
    return `${TYPE_COLOR[d.type]} ${start}% ${end}%`;
  });
  const ringStyle = {
    '--ao-ring': `conic-gradient(${stops.join(', ')})`,
  } as CSSProperties;

  const recent = (items ?? []).slice(0, 5);

  const statCards: { icon: IconName; num: number; cap: string }[] = stats
    ? [
        { icon: 'layers', num: stats.content, cap: 'Toplam İçerik' },
        { icon: 'book', num: stats.published, cap: 'Yayında' },
        { icon: 'image', num: stats.media, cap: 'Medya Varlığı' },
        { icon: 'user', num: stats.users, cap: 'Kullanıcı' },
      ]
    : [];

  /* Sistem Durumu — GERÇEK /api/health çıktısından türetilir (uydurma yok) */
  const sysRows = health
    ? [
        {
          icon: 'gauge' as IconName,
          name: 'Sunucu',
          ...(health.status === 'ok'
            ? { level: 'ok' as const, text: 'Çevrimiçi' }
            : { level: 'down' as const, text: 'Sorunlu' }),
        },
        {
          icon: 'layers' as IconName,
          name: 'Veritabanı',
          ...(health.db === 'unconfigured'
            ? { level: 'warn' as const, text: 'Yapılandırılmadı' }
            : {
                level: 'ok' as const,
                text: health.db === 'pglite' ? 'Bağlı (PGlite)' : 'Bağlı',
              }),
        },
        {
          icon: 'bell' as IconName,
          name: 'E-posta',
          ...(health.email === 'resend'
            ? { level: 'ok' as const, text: 'Resend' }
            : { level: 'warn' as const, text: 'Konsol' }),
        },
        {
          icon: 'shield' as IconName,
          name: 'Ödemeler',
          ...(health.payments === 'lemonsqueezy'
            ? { level: 'ok' as const, text: 'LemonSqueezy' }
            : { level: 'warn' as const, text: 'Mock' }),
        },
      ]
    : [];

  return (
    <div className="ao-root">
      <PageHeader
        title="Yönetim — Genel Bakış"
        emoji="🛠️"
        subtitle="İçerik hattı, medya ve kullanıcıların özeti."
        actions={
          <nav className="ao-crumb" aria-label="Konum">
            <a href="/panel">Ana Sayfa</a>
            <span className="ao-crumb__sep" aria-hidden>
              •
            </span>
            <span className="ao-crumb__here">Genel Bakış</span>
          </nav>
        }
      />

      {err && (
        <div className="ao-alert" role="alert">
          {err}
        </div>
      )}

      {/* ── Stat kartları (GERÇEK: /api/admin/stats) ── */}
      {!stats ? (
        <div className="ao-stats" aria-busy="true">
          {[1, 2, 3, 4].map((k) => (
            <div key={k} className="ao-skel">
              <div className="skeleton" style={{ height: 44 }} />
            </div>
          ))}
        </div>
      ) : (
        <div className="ao-stats" data-testid="admin-stats">
          {statCards.map((c) => (
            <div key={c.cap} className="ao-stat">
              <span className="ao-stat__ico" aria-hidden>
                <Icon name={c.icon} size={26} />
              </span>
              <div className="ao-stat__body">
                <div className="ao-stat__num">{c.num}</div>
                <div className="ao-stat__cap">{c.cap}</div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ── Satır 1: Hızlı İşlemler + İçerik Dağılımı ── */}
      <div className="ao-cols">
        <section className="ao-panel" aria-labelledby="ao-quick-h">
          <header className="ao-panel__head">
            <span className="ao-hicon" aria-hidden>
              <Icon name="flame" size={20} />
            </span>
            <h2 className="ao-panel__title" id="ao-quick-h">
              Hızlı İşlemler
            </h2>
          </header>
          <div className="ao-panel__body">
            <div className="ao-actions">
              {QUICK_ACTIONS.map((a) => (
                <a key={a.href} className="ao-action" href={a.href}>
                  <span className="ao-action__ico" aria-hidden>
                    <Icon name={a.icon} size={22} />
                  </span>
                  <span className="ao-action__txt">
                    <span className="ao-action__title">{a.title}</span>
                    <span className="ao-action__desc">{a.desc}</span>
                  </span>
                  <span className="ao-action__arrow" aria-hidden>
                    <Icon name="chevron-right" size={20} />
                  </span>
                </a>
              ))}
            </div>
          </div>
          <footer className="ao-panel__foot">
            <a className="ao-morelink" href="/admin/icerik">
              Tüm Hızlı İşlemleri Görüntüle
              <Icon name="chevron-right" size={16} aria-hidden />
            </a>
          </footer>
        </section>

        <section className="ao-panel" aria-labelledby="ao-dist-h">
          <header className="ao-panel__head">
            <span className="ao-hicon" aria-hidden>
              <Icon name="target" size={20} />
            </span>
            <h2 className="ao-panel__title" id="ao-dist-h">
              İçerik Dağılımı
            </h2>
          </header>
          <div className="ao-panel__body">
            {items === null ? (
              <div className="skeleton" style={{ height: 180 }} />
            ) : distTotal === 0 ? (
              <div className="ao-empty">Henüz sınıflandırılacak içerik yok.</div>
            ) : (
              <div className="ao-dist">
                <div
                  className="ao-donut"
                  style={ringStyle}
                  role="img"
                  aria-label="İçerik türü dağılımı"
                >
                  <div className="ao-donut__center">
                    <div className="ao-donut__num">{distTotal}</div>
                    <div className="ao-donut__lbl">Toplam</div>
                  </div>
                </div>
                <div className="ao-legend">
                  {dist.map((d) => (
                    <div key={d.type} className="ao-legend__row">
                      <span
                        className="ao-legend__dot"
                        style={{ '--ao-c': TYPE_COLOR[d.type] } as CSSProperties}
                        aria-hidden
                      />
                      <span className="ao-legend__name">{typeLabel(d.type)}</span>
                      <span className="ao-legend__n">{d.n}</span>
                      <span className="ao-legend__pct">
                        %{((d.n / distTotal) * 100).toFixed(1)}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
          <footer className="ao-panel__foot">
            <a className="ao-morelink" href="/admin/icerik">
              Tüm İçerikleri Görüntüle
              <Icon name="chevron-right" size={16} aria-hidden />
            </a>
          </footer>
        </section>
      </div>

      {/* ── Satır 2: Son Güncellenen İçerikler + Sistem Durumu ── */}
      <div className="ao-cols">
        <section className="ao-panel" aria-labelledby="ao-recent-h">
          <header className="ao-panel__head">
            <span className="ao-hicon" aria-hidden>
              <Icon name="book" size={20} />
            </span>
            <h2 className="ao-panel__title" id="ao-recent-h">
              Son Güncellenen İçerikler
            </h2>
          </header>
          <div className="ao-panel__body">
            {items === null ? (
              <div className="skeleton" style={{ height: 120 }} />
            ) : recent.length === 0 ? (
              <div className="ao-empty">Henüz içerik eklenmedi.</div>
            ) : (
              <div className="ao-recent">
                {recent.map((r) => (
                  <a key={r.id} className="ao-recent__row" href={`/admin/icerik/${r.id}`}>
                    <span className="ao-recent__ico" aria-hidden>
                      <Icon name="clipboard" size={20} />
                    </span>
                    <span className="ao-recent__txt">
                      <span className="ao-recent__title">{r.title}</span>
                      <span className="ao-recent__meta">
                        <span className="ao-badge">{typeLabel(r.type)}</span>
                        {fmtDate(r.updatedAt) && <span>{fmtDate(r.updatedAt)}</span>}
                      </span>
                    </span>
                    <span
                      className={`ao-status-pill${r.status === 'published' ? ' ao-status-pill--published' : ''}`}
                    >
                      {statusLabel(r.status)}
                    </span>
                  </a>
                ))}
              </div>
            )}
          </div>
          <footer className="ao-panel__foot">
            <a className="ao-morelink" href="/admin/icerik">
              Tüm İçerikleri Görüntüle
              <Icon name="chevron-right" size={16} aria-hidden />
            </a>
          </footer>
        </section>

        <section className="ao-panel" aria-labelledby="ao-sys-h">
          <header className="ao-panel__head">
            <span className="ao-hicon" aria-hidden>
              <Icon name="shield" size={20} />
            </span>
            <h2 className="ao-panel__title" id="ao-sys-h">
              Sistem Durumu
            </h2>
          </header>
          <div className="ao-panel__body">
            {health === null ? (
              <div className="ao-empty">Sistem durumu okunamadı.</div>
            ) : (
              <div className="ao-sys">
                {sysRows.map((s) => (
                  <div key={s.name} className="ao-sys__row">
                    <span className="ao-sys__ico" aria-hidden>
                      <Icon name={s.icon} size={18} />
                    </span>
                    <span className="ao-sys__name">{s.name}</span>
                    <span className={`ao-sys__state ao-sys__state--${s.level}`}>
                      {s.text}
                      <span className="ao-sys__dot" aria-hidden />
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
          <footer className="ao-panel__foot">
            <a className="ao-morelink" href="/api/health">
              Tüm Durumları Görüntüle
              <Icon name="chevron-right" size={16} aria-hidden />
            </a>
          </footer>
        </section>
      </div>
    </div>
  );
}
