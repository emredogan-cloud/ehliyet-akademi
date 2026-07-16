/**
 * Paylaşılan desenler (Program 3 · Faz E) — primitifler üzerine kurulu bileşik bloklar.
 * Referans: new-image/003-panel, 004-dersler, 008-detay-şablonu.
 * Bir kez yazılır, tüm sayfalarda kullanılır (Faz F). Tümü token-tabanlı.
 */
import type { ReactNode, CSSProperties } from 'react';
import { Card, Button, IconBadge, Badge, type Accent } from './primitives';
import { Icon, type IconName } from './icons';

function cx(...parts: Array<string | false | undefined>): string {
  return parts.filter(Boolean).join(' ');
}

/* ─────────────────────── Breadcrumb ─────────────────────── */
export function Breadcrumb({ items }: { items: Array<{ label: string; href?: string }> }) {
  return (
    <nav className="crumbs" aria-label="Konum">
      {items.map((it, i) => (
        <span key={i} className="crumbs__item">
          {it.href && i < items.length - 1 ? (
            <a href={it.href}>{it.label}</a>
          ) : (
            <span aria-current={i === items.length - 1 ? 'page' : undefined}>{it.label}</span>
          )}
          {i < items.length - 1 && (
            <span className="crumbs__sep" aria-hidden>
              ›
            </span>
          )}
        </span>
      ))}
    </nav>
  );
}

/* ─────────────────────── Tag ─────────────────────── */
export function Tag({ children, accent }: { children: ReactNode; accent?: Accent }) {
  return (
    <span
      className={cx('ui-tag', accent && 'ui-tag--accent')}
      style={
        accent
          ? ({ ['--tag-accent' as string]: `var(--accent-${accent})` } as CSSProperties)
          : undefined
      }
    >
      {children}
    </span>
  );
}

/* ─────────────────────── Callout ─────────────────────── */
const CALLOUT_ICON: Record<'info' | 'warn' | 'success', IconName> = {
  info: 'target',
  warn: 'sign',
  success: 'shield',
};
export function Callout({
  tone = 'info',
  title,
  children,
}: {
  tone?: 'info' | 'warn' | 'success';
  title?: string;
  children: ReactNode;
}) {
  return (
    <div className={`callout callout--${tone}`} role="note">
      <span className="callout__icon" aria-hidden>
        <Icon name={CALLOUT_ICON[tone]} size={20} />
      </span>
      <div className="callout__body">
        {title && <strong className="callout__title">{title}</strong>}
        <div className="callout__text">{children}</div>
      </div>
    </div>
  );
}

/* ─────────────────────── FactTile ─────────────────────── */
export function FactTile({
  icon,
  label,
  value,
  accent = 'teal',
}: {
  icon: IconName;
  label: string;
  value: ReactNode;
  accent?: Accent;
}) {
  return (
    <div className="fact-tile">
      <span
        className="fact-tile__icon"
        style={{ ['--fact-accent' as string]: `var(--accent-${accent})` } as CSSProperties}
        aria-hidden
      >
        <Icon name={icon} size={18} />
      </span>
      <div className="fact-tile__body">
        <div className="fact-tile__label">{label}</div>
        <div className="fact-tile__value">{value}</div>
      </div>
    </div>
  );
}

/* ─────────────────────── HeroBanner ───────────────────────
   Referans: panel “Bugün 10 soruyla başla” bandı. İkon + metin + CTA + opsiyonel görsel. */
export function HeroBanner({
  icon,
  accent = 'teal',
  title,
  text,
  action,
  art,
  'data-testid': testId,
}: {
  icon?: IconName;
  accent?: Accent;
  title: ReactNode;
  text?: ReactNode;
  action?: ReactNode;
  art?: ReactNode;
  'data-testid'?: string;
}) {
  return (
    <Card accent={accent} className="hero-banner" data-testid={testId}>
      {icon && (
        <IconBadge accent={accent} size="lg">
          <Icon name={icon} size={26} />
        </IconBadge>
      )}
      <div className="hero-banner__body">
        <div className="hero-banner__title">{title}</div>
        {text && <div className="hero-banner__text">{text}</div>}
      </div>
      {art && (
        <div className="hero-banner__art" aria-hidden>
          {art}
        </div>
      )}
      {action && <div className="hero-banner__action">{action}</div>}
    </Card>
  );
}

/* ─────────────────────── ActionCard ───────────────────────
   Referans: panel “Bugün ne yapalım?” kartları. İkon + başlık + açıklama + renkli CTA. */
export function ActionCard({
  icon,
  accent = 'teal',
  title,
  desc,
  cta,
  glow = false,
}: {
  icon: IconName;
  accent?: Accent;
  title: string;
  desc: string;
  cta: { label: string; href: string };
  glow?: boolean;
}) {
  return (
    <Card accent={accent} glow={glow} className="action-card">
      <div className="action-card__head">
        <IconBadge accent={accent} size="md">
          <Icon name={icon} size={20} />
        </IconBadge>
        <h3 className="action-card__title">{title}</h3>
      </div>
      <p className="action-card__desc">{desc}</p>
      <Button variant="accent" accent={accent} size="md" full href={cta.href}>
        {cta.label}
        <Icon name="chevron-right" size={16} />
      </Button>
    </Card>
  );
}

/* ─────────────────────── LessonCard ───────────────────────
   Referans: dersler ızgara kartı. İkon rozeti + (premium) + başlık + açıklama + meta + yer imi. */
export function LessonCard({
  icon,
  accent = 'teal',
  title,
  desc,
  meta,
  href,
  premium = false,
  'data-testid': testId,
}: {
  icon: IconName;
  accent?: Accent;
  title: string;
  desc?: string;
  meta?: string;
  href: string;
  premium?: boolean;
  'data-testid'?: string;
}) {
  return (
    <Card
      as="a"
      href={href}
      accent={accent}
      interactive
      className="lesson-card"
      data-testid={testId}
    >
      <div className="lesson-card__top">
        <IconBadge accent={accent} size="lg">
          <Icon name={icon} size={26} />
        </IconBadge>
        {premium && <Badge accent="amber">Premium</Badge>}
      </div>
      <h3 className="lesson-card__title">{title}</h3>
      {desc && <p className="lesson-card__desc">{desc}</p>}
      {meta && (
        <div className="lesson-card__foot">
          <span className="lesson-card__meta">{meta}</span>
        </div>
      )}
    </Card>
  );
}

/* ─────────────────────── DetailLayout + PrevNext ───────────────────────
   Referans: detay şablonu iki sütun (ana içerik + özet aside) + önceki/sonraki. */
export function DetailLayout({ main, aside }: { main: ReactNode; aside: ReactNode }) {
  return (
    <div className="detail-grid">
      <div className="detail-grid__main">{main}</div>
      <aside className="detail-grid__aside">{aside}</aside>
    </div>
  );
}

type NavLink = { label: string; sub?: string; href: string };
export function PrevNext({
  prev,
  next,
  indexHref,
}: {
  prev?: NavLink;
  next?: NavLink;
  indexHref?: string;
}) {
  return (
    <div className="prevnext">
      {prev ? (
        <a className="prevnext__link prevnext__link--prev" href={prev.href}>
          <span className="prevnext__dir" aria-hidden>
            ←
          </span>
          <span className="prevnext__text">
            {prev.sub && <span className="prevnext__sub">{prev.sub}</span>}
            <span className="prevnext__label">{prev.label}</span>
          </span>
        </a>
      ) : (
        <span />
      )}
      {indexHref && (
        <a className="prevnext__index" href={indexHref} aria-label="Tüm liste">
          <Icon name="layers" size={20} />
        </a>
      )}
      {next ? (
        <a className="prevnext__link prevnext__link--next" href={next.href}>
          <span className="prevnext__text">
            {next.sub && <span className="prevnext__sub">{next.sub}</span>}
            <span className="prevnext__label">{next.label}</span>
          </span>
          <span className="prevnext__dir" aria-hidden>
            →
          </span>
        </a>
      ) : (
        <span />
      )}
    </div>
  );
}
