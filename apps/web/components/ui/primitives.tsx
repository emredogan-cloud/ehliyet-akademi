/**
 * Core UI primitifleri (Program 3 · Faz B) — tek doğru bileşen katmanı.
 * Tümü token-tabanlı (magic-number yok); her yerde yeniden kullanılır.
 * Referans: new-image/ (navy + teal design system).
 */
import type { ReactNode, CSSProperties } from 'react';

export type Accent = 'teal' | 'amber' | 'blue' | 'purple' | 'red' | 'green';

/** Aksan hue token eşlemesi. */
export const ACCENT_VAR: Record<Accent, string> = {
  teal: 'var(--accent-teal)',
  amber: 'var(--accent-amber)',
  blue: 'var(--accent-blue)',
  purple: 'var(--accent-purple)',
  red: 'var(--accent-red)',
  green: 'var(--accent-green)',
};

function cx(...parts: Array<string | false | undefined>): string {
  return parts.filter(Boolean).join(' ');
}

/* ─────────────────────────── Card ─────────────────────────── */
export function Card({
  children,
  accent,
  glow = false,
  interactive = false,
  as: Tag = 'div',
  className,
  style,
  ...rest
}: {
  children: ReactNode;
  accent?: Accent;
  glow?: boolean;
  interactive?: boolean;
  as?: 'div' | 'a' | 'button' | 'section' | 'li';
  className?: string;
  style?: CSSProperties;
  href?: string;
  onClick?: () => void;
  'data-testid'?: string;
}) {
  const accentStyle = accent
    ? ({ ['--card-accent' as string]: ACCENT_VAR[accent] } as CSSProperties)
    : undefined;
  return (
    <Tag
      className={cx(
        'ui-card',
        accent && 'ui-card--accent',
        glow && 'ui-card--glow',
        interactive && 'ui-card--interactive',
        className
      )}
      style={{ ...accentStyle, ...style }}
      {...rest}
    >
      {children}
    </Tag>
  );
}

/* ─────────────────────────── Button ─────────────────────────── */
export function Button({
  children,
  variant = 'primary',
  size = 'md',
  accent,
  full = false,
  className,
  ...rest
}: {
  children: ReactNode;
  variant?: 'primary' | 'ghost' | 'accent' | 'soft';
  size?: 'sm' | 'md' | 'lg';
  accent?: Accent;
  full?: boolean;
  className?: string;
  type?: 'button' | 'submit';
  disabled?: boolean;
  href?: string;
  onClick?: () => void;
  'aria-label'?: string;
  'data-testid'?: string;
}) {
  const isLink = 'href' in rest && (rest as { href?: string }).href != null;
  const Tag = (isLink ? 'a' : 'button') as 'a' | 'button';
  const accentStyle =
    accent && (variant === 'accent' || variant === 'soft')
      ? ({ ['--btn-accent' as string]: ACCENT_VAR[accent] } as CSSProperties)
      : undefined;
  return (
    <Tag
      className={cx(
        'ui-btn',
        `ui-btn--${variant}`,
        `ui-btn--${size}`,
        full && 'ui-btn--full',
        className
      )}
      style={accentStyle}
      {...rest}
    >
      {children}
    </Tag>
  );
}

/* ─────────────────────────── IconBadge ─────────────────────────── */
/** Renkli daire zeminli ikon kabı (referansta her yerde: stat/feature/ders ikonları). */
export function IconBadge({
  children,
  accent = 'teal',
  size = 'md',
  className,
}: {
  children: ReactNode;
  accent?: Accent;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}) {
  return (
    <span
      className={cx('ui-iconbadge', `ui-iconbadge--${size}`, className)}
      style={{ ['--ib-accent' as string]: ACCENT_VAR[accent] } as CSSProperties}
      aria-hidden
    >
      {children}
    </span>
  );
}

/* ─────────────────────────── Badge / Chip ─────────────────────────── */
export function Badge({
  children,
  accent = 'teal',
  className,
}: {
  children: ReactNode;
  accent?: Accent;
  className?: string;
}) {
  return (
    <span
      className={cx('ui-badge', className)}
      style={{ ['--badge-accent' as string]: ACCENT_VAR[accent] } as CSSProperties}
    >
      {children}
    </span>
  );
}

export function Chip({
  children,
  active = false,
  onClick,
  count,
  className,
  ...rest
}: {
  children: ReactNode;
  active?: boolean;
  onClick?: () => void;
  count?: number;
  className?: string;
  disabled?: boolean;
  'data-testid'?: string;
}) {
  return (
    <button
      type="button"
      className={cx('ui-chip', active && 'ui-chip--active', className)}
      onClick={onClick}
      aria-pressed={active}
      {...rest}
    >
      {children}
      {count != null && <span className="ui-chip__count">{count}</span>}
    </button>
  );
}

/* ─────────────────────────── StatCard ─────────────────────────── */
export function StatCard({
  icon,
  accent = 'teal',
  value,
  label,
  href,
  'data-testid': testId,
}: {
  icon: ReactNode;
  accent?: Accent;
  value: ReactNode;
  label: string;
  href?: string;
  'data-testid'?: string;
}) {
  const inner = (
    <>
      <IconBadge accent={accent} size="md">
        {icon}
      </IconBadge>
      <div className="ui-stat__body">
        <div className="ui-stat__value">{value}</div>
        <div className="ui-stat__label">{label}</div>
      </div>
      {href && (
        <span className="ui-stat__chev" aria-hidden>
          ›
        </span>
      )}
    </>
  );
  return href ? (
    <a className="ui-card ui-stat ui-card--interactive" href={href} data-testid={testId}>
      {inner}
    </a>
  ) : (
    <div className="ui-card ui-stat" data-testid={testId}>
      {inner}
    </div>
  );
}

/* ─────────────────────────── ProgressBar ─────────────────────────── */
export function ProgressBar({
  value,
  label,
  className,
}: {
  value: number; // 0–100
  label?: string;
  className?: string;
}) {
  const v = Math.max(0, Math.min(100, value));
  return (
    <div
      className={cx('ui-progress', className)}
      role="progressbar"
      aria-valuenow={Math.round(v)}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-label={label}
    >
      <span className="ui-progress__fill" style={{ width: `${v}%` }} />
    </div>
  );
}

/* ─────────────────────────── ProgressRing ─────────────────────────── */
export function ProgressRing({
  value,
  size = 56,
  stroke = 6,
  accent = 'teal',
  children,
}: {
  value: number; // 0–100
  size?: number;
  stroke?: number;
  accent?: Accent;
  children?: ReactNode;
}) {
  const v = Math.max(0, Math.min(100, value));
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  return (
    <span className="ui-ring" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} aria-hidden>
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke="var(--surface-3)"
          strokeWidth={stroke}
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke={ACCENT_VAR[accent]}
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={c}
          strokeDashoffset={c * (1 - v / 100)}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </svg>
      {children != null && <span className="ui-ring__label">{children}</span>}
    </span>
  );
}

/* ─────────────────────────── Field / Input ─────────────────────────── */
export function Field({
  label,
  hint,
  error,
  children,
  htmlFor,
}: {
  label?: string;
  hint?: string;
  error?: string;
  children: ReactNode;
  htmlFor?: string;
}) {
  return (
    <label className="ui-field" htmlFor={htmlFor}>
      {label && <span className="ui-field__label">{label}</span>}
      {children}
      {error ? (
        <span className="ui-field__error">{error}</span>
      ) : (
        hint && <span className="ui-field__hint">{hint}</span>
      )}
    </label>
  );
}
