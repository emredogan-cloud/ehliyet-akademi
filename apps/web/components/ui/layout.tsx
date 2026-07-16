/**
 * Layout sistemi (Program 3 · Faz C) — sayfa iskeleti primitifleri.
 * PageHeader + Section + Grid: her sayfa aynı başlık/bölüm/ızgara dilini kullanır.
 * Tümü token-tabanlı; referans: new-image/003-panel (başlık + bölüm + stat/kart ızgaraları).
 */
import type { ReactNode, CSSProperties } from 'react';

function cx(...parts: Array<string | false | undefined>): string {
  return parts.filter(Boolean).join(' ');
}

/* ─────────────────────────── PageHeader ───────────────────────────
   Referans: “Panel 👋” + alt açıklama + sağda opsiyonel aksiyonlar.
   30+ sayfadaki elle yazılmış <h1>+<p> bloğunu tek yerde toplar. */
export function PageHeader({
  title,
  emoji,
  subtitle,
  actions,
  className,
}: {
  title: ReactNode;
  emoji?: string;
  subtitle?: ReactNode;
  actions?: ReactNode;
  className?: string;
}) {
  return (
    <header className={cx('page-head', className)}>
      <div className="page-head__titles">
        <h1 className="page-head__title">
          {title}
          {emoji && (
            <span className="page-head__emoji" aria-hidden>
              {' '}
              {emoji}
            </span>
          )}
        </h1>
        {subtitle && <p className="page-head__sub">{subtitle}</p>}
      </div>
      {actions && <div className="page-head__actions">{actions}</div>}
    </header>
  );
}

/* ─────────────────────────── Section ───────────────────────────
   Referans: ikonlu başlık (“Ders bazlı ustalık”) + sağda opsiyonel aksiyon. */
export function Section({
  title,
  icon,
  action,
  children,
  className,
  id,
}: {
  title?: ReactNode;
  icon?: ReactNode;
  action?: ReactNode;
  children: ReactNode;
  className?: string;
  id?: string;
}) {
  return (
    <section className={cx('section', className)} id={id}>
      {(title || action) && (
        <div className="section__head">
          {title && (
            <h2 className="section__title">
              {icon && (
                <span className="section__icon" aria-hidden>
                  {icon}
                </span>
              )}
              {title}
            </h2>
          )}
          {action && <div className="section__action">{action}</div>}
        </div>
      )}
      {children}
    </section>
  );
}

/* ─────────────────────────── Grid ───────────────────────────
   Duyarlı ızgara: preset (stats/cards/wide) ya da özel `min` genişliği.
   auto-fill + minmax → kırılganlık yok, her viewport'ta akıcı sarma. */
type GridPreset = 'stats' | 'cards' | 'wide' | 'two';

const PRESET_MIN: Record<GridPreset, string> = {
  stats: '210px',
  cards: '240px',
  wide: '300px',
  two: '380px',
};

export function Grid({
  children,
  preset = 'cards',
  min,
  gap,
  className,
  style,
}: {
  children: ReactNode;
  preset?: GridPreset;
  min?: string;
  gap?: string;
  className?: string;
  style?: CSSProperties;
}) {
  const gridStyle: CSSProperties = {
    ['--grid-min' as string]: min ?? PRESET_MIN[preset],
    ...(gap ? { ['--grid-gap' as string]: gap } : null),
    ...style,
  };
  return (
    <div className={cx('grid-auto', className)} style={gridStyle}>
      {children}
    </div>
  );
}

/* ─────────────────────────── Stack / Row ───────────────────────────
   Token boşluklu dikey/yatay diziliş — magic-number'sız hızlı yerleşim. */
export function Stack({
  children,
  gap = 'var(--sp-4)',
  className,
  style,
}: {
  children: ReactNode;
  gap?: string;
  className?: string;
  style?: CSSProperties;
}) {
  return (
    <div className={cx('stack', className)} style={{ gap, ...style }}>
      {children}
    </div>
  );
}

export function Row({
  children,
  gap = 'var(--sp-3)',
  wrap = true,
  align = 'center',
  justify,
  className,
  style,
}: {
  children: ReactNode;
  gap?: string;
  wrap?: boolean;
  align?: CSSProperties['alignItems'];
  justify?: CSSProperties['justifyContent'];
  className?: string;
  style?: CSSProperties;
}) {
  return (
    <div
      className={cx('row', className)}
      style={{
        gap,
        flexWrap: wrap ? 'wrap' : 'nowrap',
        alignItems: align,
        justifyContent: justify,
        ...style,
      }}
    >
      {children}
    </div>
  );
}
