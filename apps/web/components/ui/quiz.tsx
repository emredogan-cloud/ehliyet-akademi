/**
 * Quiz kabuğu parçaları (Program 3.1 — ref 009/011/012/016 ortak dili):
 * iki sütunlu yerleşim + sağ ray kartları (bilgi satırları, ilerleme donutu,
 * soru navigasyonu, ipucu). Salt sunum — sınav/pratik mantığına dokunmaz.
 */
import type { ReactNode } from 'react';
import { Icon, type IconName } from './icons';

/* ── Yerleşim ── */
export function QuizLayout({ main, aside }: { main: ReactNode; aside: ReactNode }) {
  return (
    <div className="quiz-grid">
      <div className="quiz-grid__main">{main}</div>
      <aside className="quiz-grid__aside">{aside}</aside>
    </div>
  );
}

/* ── Ray kartı ── */
export function QuizPanel({
  title,
  icon,
  action,
  children,
}: {
  title?: string;
  icon?: IconName;
  action?: ReactNode;
  children: ReactNode;
}) {
  return (
    <div className="ui-card quiz-panel">
      {(title || action) && (
        <div className="quiz-panel__head">
          {title && (
            <h3 className="quiz-panel__title">
              {icon && (
                <span className="quiz-panel__ic" aria-hidden>
                  <Icon name={icon} size={17} />
                </span>
              )}
              {title}
            </h3>
          )}
          {action}
        </div>
      )}
      {children}
    </div>
  );
}

/* ── Bilgi satırı ── */
export function InfoRow({
  icon,
  label,
  value,
}: {
  icon?: IconName;
  label: string;
  value: ReactNode;
}) {
  return (
    <div className="info-row">
      {icon && (
        <span className="info-row__ic" aria-hidden>
          <Icon name={icon} size={16} />
        </span>
      )}
      <span className="info-row__label">{label}</span>
      <span className="info-row__value">{value}</span>
    </div>
  );
}

/* ── Donut + lejant ── */
export function DonutStat({
  pct,
  center,
  sub,
  rows,
  size = 116,
}: {
  pct: number; // 0-100 (teal yay)
  center: string;
  sub?: string;
  rows?: Array<{ color: string; label: string; value: ReactNode }>;
  size?: number;
}) {
  const stroke = 10;
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const v = Math.max(0, Math.min(100, pct));
  return (
    <div className="donut">
      <span className="donut__ring" style={{ width: size, height: size }}>
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
            stroke="var(--primary)"
            strokeWidth={stroke}
            strokeLinecap="round"
            strokeDasharray={c}
            strokeDashoffset={c * (1 - v / 100)}
            transform={`rotate(-90 ${size / 2} ${size / 2})`}
          />
        </svg>
        <span className="donut__center">
          <strong>{center}</strong>
          {sub && <small>{sub}</small>}
        </span>
      </span>
      {rows && rows.length > 0 && (
        <div className="donut__rows">
          {rows.map((row) => (
            <div className="donut__row" key={row.label}>
              <span className="donut__dot" style={{ background: row.color }} aria-hidden />
              <span className="donut__label">{row.label}</span>
              <span className="donut__value">{row.value}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

/* ── Soru navigasyonu ── */
export type QuizNavState = 'correct' | 'wrong' | 'current' | 'todo';

const NAV_LEGEND: Array<{ state: QuizNavState; label: string }> = [
  { state: 'correct', label: 'Doğru' },
  { state: 'wrong', label: 'Yanlış' },
  { state: 'current', label: 'Mevcut' },
  { state: 'todo', label: 'Yanıtlanmadı' },
];

export function QuizNav({ states, legend = true }: { states: QuizNavState[]; legend?: boolean }) {
  return (
    <div className="qnav">
      <div className="qnav__grid" role="list" aria-label="Soru durumları">
        {states.map((s, i) => (
          <span key={i} role="listitem" className={`qnav__dot qnav__dot--${s}`}>
            {i + 1}
          </span>
        ))}
      </div>
      {legend && (
        <div className="qnav__legend" aria-hidden>
          {NAV_LEGEND.map((l) => (
            <span key={l.state} className="qnav__leg">
              <span className={`qnav__mini qnav__dot--${l.state}`} /> {l.label}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}

/* ── İpucu ── */
export function HintCard({ children }: { children: ReactNode }) {
  return (
    <div className="ui-card quiz-panel quiz-hint">
      <h3 className="quiz-panel__title">
        <span className="quiz-hint__bulb" aria-hidden>
          💡
        </span>
        İpucu
      </h3>
      <p className="quiz-hint__text">{children}</p>
    </div>
  );
}
