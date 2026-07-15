/** Çalışma ısı haritası (Sprint 6) — GitHub tarzı, tema-uyumlu SVG. */
import type { HeatCell } from '@/lib/gamification';

const CELL = 13;
const GAP = 3;
const LEVEL_FILL = [
  'var(--surface-3)',
  'color-mix(in srgb, var(--primary) 30%, var(--surface-3))',
  'color-mix(in srgb, var(--primary) 55%, var(--surface-3))',
  'color-mix(in srgb, var(--primary) 78%, var(--surface-3))',
  'var(--primary)',
] as const;

export function StudyHeatmap({ grid }: { grid: HeatCell[][] }) {
  const weeks = grid.length;
  const width = weeks * (CELL + GAP);
  const height = 7 * (CELL + GAP);
  const total = grid.flat().reduce((s, c) => s + c.count, 0);

  return (
    <div style={{ overflowX: 'auto' }}>
      <svg
        viewBox={`0 0 ${width} ${height}`}
        width={width}
        height={height}
        role="img"
        aria-label={`Çalışma ısı haritası — son ${weeks} hafta, toplam ${total} soru`}
        style={{ maxWidth: '100%', display: 'block' }}
      >
        {grid.map((col, w) =>
          col.map((cell, d) => (
            <rect
              key={`${w}-${d}`}
              x={w * (CELL + GAP)}
              y={d * (CELL + GAP)}
              width={CELL}
              height={CELL}
              rx={3}
              fill={LEVEL_FILL[cell.level]}
              data-testid="heat-cell"
            >
              <title>{`${cell.date}: ${cell.count} soru`}</title>
            </rect>
          ))
        )}
      </svg>
      <div
        style={{
          display: 'flex',
          gap: 6,
          alignItems: 'center',
          marginTop: 8,
          fontSize: '0.78rem',
          color: 'var(--text-3)',
        }}
      >
        <span>Az</span>
        {LEVEL_FILL.map((f, i) => (
          <span
            key={i}
            style={{ width: 13, height: 13, borderRadius: 3, background: f }}
            aria-hidden
          />
        ))}
        <span>Çok</span>
      </div>
    </div>
  );
}
