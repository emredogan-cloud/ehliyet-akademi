/**
 * Araç görsel kütüphanesi (Program 1 · Görsel Dönüşüm Bölüm 2) — ÖZGÜN çizgi-resim SVG'ler.
 * Direksiyon sınavı + araç tekniği için bileşen görselleri; tema-uyumlu, offline, erişilebilir.
 * Her görsel KENDİ çizgi dilimizle sıfırdan; telifli görsel kopyalanmadı.
 */

const S = {
  stroke: 'var(--text-2)',
  fill: 'none',
  strokeWidth: 3,
  strokeLinecap: 'round',
  strokeLinejoin: 'round',
} as const;
const ACC = 'var(--primary)';
const RED = 'var(--red)';
const YEL = 'var(--yellow)';

function Frame({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <svg
      viewBox="0 0 160 120"
      role="img"
      aria-label={label}
      style={{
        width: '100%',
        height: 'auto',
        display: 'block',
        background: 'var(--surface-2)',
        borderRadius: 12,
      }}
    >
      {children}
    </svg>
  );
}

const PARTS: Record<string, () => React.ReactNode> = {
  'engine-bay': () => (
    <g {...S}>
      <rect x="18" y="30" width="124" height="64" rx="6" />
      <rect x="30" y="42" width="40" height="30" rx="4" fill={ACC} opacity="0.25" />
      <rect x="80" y="44" width="26" height="18" rx="3" />
      <circle cx="122" cy="54" r="9" />
      <path d="M30 84 h100" />
      <text
        x="80"
        y="108"
        textAnchor="middle"
        style={{ font: '600 11px var(--font)', fill: 'var(--text-3)' }}
      >
        Motor bölmesi
      </text>
    </g>
  ),
  battery: () => (
    <g {...S}>
      <rect x="40" y="40" width="80" height="46" rx="4" fill={ACC} opacity="0.18" />
      <rect x="52" y="32" width="12" height="10" rx="2" />
      <rect x="96" y="32" width="12" height="10" rx="2" />
      <text x="58" y="70" style={{ font: '800 16px var(--font)', fill: RED, stroke: 'none' }}>
        +
      </text>
      <text
        x="98"
        y="70"
        style={{ font: '800 18px var(--font)', fill: 'var(--text)', stroke: 'none' }}
      >
        −
      </text>
    </g>
  ),
  dipstick: () => (
    <g {...S}>
      <path d="M60 26 q8 -8 14 0 l-2 60 q-5 6 -10 0 z" fill={YEL} opacity="0.25" />
      <circle cx="67" cy="24" r="9" fill={YEL} opacity="0.4" />
      <path d="M63 74 h8 M63 80 h8" stroke={ACC} />
      <text
        x="96"
        y="72"
        style={{ font: '600 10px var(--font)', fill: 'var(--text-3)', stroke: 'none' }}
      >
        MIN–MAX
      </text>
    </g>
  ),
  coolant: () => (
    <g {...S}>
      <rect x="46" y="34" width="68" height="56" rx="8" fill={ACC} opacity="0.14" />
      <ellipse cx="80" cy="34" rx="14" ry="6" />
      <path d="M52 66 q28 8 56 0" stroke={ACC} />
      <text
        x="80"
        y="106"
        textAnchor="middle"
        style={{ font: '600 10px var(--font)', fill: 'var(--text-3)', stroke: 'none' }}
      >
        Soğutma suyu
      </text>
    </g>
  ),
  'brake-fluid': () => (
    <g {...S}>
      <rect x="52" y="36" width="56" height="50" rx="6" fill={RED} opacity="0.12" />
      <ellipse cx="80" cy="36" rx="12" ry="5" />
      <path d="M70 30 a10 10 0 0 1 20 0" />
      <circle cx="80" cy="60" r="8" stroke={RED} />
      <path d="M74 60 h12 M80 54 v12" stroke={RED} />
    </g>
  ),
  washer: () => (
    <g {...S}>
      <rect x="50" y="36" width="60" height="52" rx="7" fill={ACC} opacity="0.14" />
      <path d="M62 30 q18 -8 36 0" />
      <path d="M70 52 q6 6 0 12 M80 50 q6 6 0 12 M90 52 q6 6 0 12" stroke={ACC} />
    </g>
  ),
  'fuse-box': () => (
    <g {...S}>
      <rect x="34" y="32" width="92" height="56" rx="5" />
      {[0, 1, 2, 3, 4].map((i) => (
        <rect
          key={i}
          x={44 + i * 16}
          y={44}
          width="8"
          height="16"
          rx="2"
          fill={ACC}
          opacity="0.3"
        />
      ))}
      {[0, 1, 2, 3, 4].map((i) => (
        <rect key={'b' + i} x={44 + i * 16} y={66} width="8" height="12" rx="2" />
      ))}
    </g>
  ),
  tyre: () => (
    <g {...S}>
      <circle cx="80" cy="60" r="34" strokeWidth="8" />
      <circle cx="80" cy="60" r="14" fill={ACC} opacity="0.25" />
      {Array.from({ length: 8 }).map((_, i) => {
        const a = (i * Math.PI) / 4;
        return (
          <line
            key={i}
            x1={80 + Math.cos(a) * 20}
            y1={60 + Math.sin(a) * 20}
            x2={80 + Math.cos(a) * 30}
            y2={60 + Math.sin(a) * 30}
          />
        );
      })}
    </g>
  ),
  'spare-wheel': () => (
    <g {...S}>
      <circle cx="80" cy="60" r="30" strokeWidth="7" strokeDasharray="6 5" />
      <circle cx="80" cy="60" r="12" />
      <text
        x="80"
        y="102"
        textAnchor="middle"
        style={{ font: '600 10px var(--font)', fill: 'var(--text-3)', stroke: 'none' }}
      >
        Stepne
      </text>
    </g>
  ),
  jack: () => (
    <g {...S}>
      <path d="M40 88 L80 44 L120 88" />
      <path d="M56 66 L104 66" />
      <path d="M80 44 v-14" />
      <circle cx="80" cy="28" r="4" fill={ACC} />
    </g>
  ),
  wrench: () => (
    <g {...S}>
      <path d="M40 60 h50" strokeWidth="8" />
      <path d="M90 60 m0 -12 a12 12 0 1 0 0 24 a12 12 0 1 0 0 -24" fill={ACC} opacity="0.2" />
      <path d="M40 52 v16 M110 52 v16" />
    </g>
  ),
  dashboard: () => (
    <g {...S}>
      <rect x="24" y="34" width="112" height="52" rx="10" />
      <circle cx="56" cy="60" r="16" />
      <circle cx="104" cy="60" r="16" />
      <circle cx="56" cy="60" r="2" fill={ACC} />
      <path d="M56 60 l8 -8" stroke={ACC} />
      <circle cx="80" cy="46" r="3" fill={RED} />
      <circle cx="80" cy="56" r="3" fill={YEL} />
      <circle cx="80" cy="66" r="3" fill={ACC} />
    </g>
  ),
  steering: () => (
    <g {...S}>
      <circle cx="80" cy="60" r="30" strokeWidth="6" />
      <circle cx="80" cy="60" r="8" fill={ACC} opacity="0.3" />
      <path d="M80 68 v22 M74 60 h-22 M86 60 h22" strokeWidth="6" />
    </g>
  ),
  mirrors: () => (
    <g {...S}>
      <rect x="30" y="46" width="26" height="18" rx="4" fill={ACC} opacity="0.2" />
      <rect x="104" y="46" width="26" height="18" rx="4" fill={ACC} opacity="0.2" />
      <rect x="66" y="30" width="28" height="12" rx="4" fill={ACC} opacity="0.2" />
      <path d="M56 55 h48" strokeDasharray="4 4" />
      <text
        x="80"
        y="86"
        textAnchor="middle"
        style={{ font: '600 10px var(--font)', fill: 'var(--text-3)', stroke: 'none' }}
      >
        Ayna üçlüsü
      </text>
    </g>
  ),
  seat: () => (
    <g {...S}>
      <path d="M56 88 V54 q0 -8 8 -8 h20 q8 0 8 8 V70 h10" />
      <path d="M56 88 h44" />
      <path d="M100 88 l16 6" stroke={ACC} strokeDasharray="4 4" />
    </g>
  ),
  pedals: () => (
    <g {...S}>
      <rect x="40" y="40" width="16" height="40" rx="4" />
      <rect x="72" y="40" width="16" height="40" rx="4" fill={ACC} opacity="0.25" />
      <rect x="104" y="40" width="16" height="40" rx="4" />
      <text
        x="48"
        y="96"
        textAnchor="middle"
        style={{ font: '600 9px var(--font)', fill: 'var(--text-3)', stroke: 'none' }}
      >
        D
      </text>
      <text
        x="80"
        y="96"
        textAnchor="middle"
        style={{ font: '600 9px var(--font)', fill: 'var(--text-3)', stroke: 'none' }}
      >
        F
      </text>
      <text
        x="112"
        y="96"
        textAnchor="middle"
        style={{ font: '600 9px var(--font)', fill: 'var(--text-3)', stroke: 'none' }}
      >
        G
      </text>
    </g>
  ),
  gearbox: () => (
    <g {...S}>
      <path d="M60 84 V44" strokeWidth="5" />
      <circle cx="60" cy="40" r="8" fill={ACC} opacity="0.3" />
      <path d="M44 60 h48 M44 76 h48" strokeWidth="2" opacity="0.6" />
      {['1', '3', '5', '2', '4', 'R'].map((g, i) => (
        <text
          key={g}
          x={48 + (i % 3) * 24}
          y={i < 3 ? 58 : 74}
          style={{ font: '700 11px var(--font)', fill: 'var(--text-2)', stroke: 'none' }}
        >
          {g}
        </text>
      ))}
    </g>
  ),
  handbrake: () => (
    <g {...S}>
      <path d="M40 84 L96 52" strokeWidth="6" />
      <circle cx="98" cy="50" r="6" fill={ACC} />
      <path d="M52 78 l6 -3 m6 -3 l6 -3 m6 -3 l6 -3" stroke={ACC} strokeWidth="2" />
      <text
        x="80"
        y="100"
        textAnchor="middle"
        style={{ font: '600 10px var(--font)', fill: 'var(--text-3)', stroke: 'none' }}
      >
        El freni
      </text>
    </g>
  ),
  lights: () => (
    <g {...S}>
      <circle cx="60" cy="60" r="18" />
      <path d="M78 50 l14 -4 M78 58 l16 0 M78 66 l14 4" stroke={YEL} />
      <path d="M52 60 q8 -10 16 0 q-8 10 -16 0" fill={YEL} opacity="0.3" />
    </g>
  ),
  'inspection-points': () => (
    <g {...S}>
      <path d="M20 74 h120 M40 74 v-20 h80 v20" />
      <circle cx="46" cy="80" r="8" />
      <circle cx="114" cy="80" r="8" />
      {[
        [30, 46],
        [80, 40],
        [130, 46],
        [46, 80],
        [114, 80],
      ].map(([x, y], i) => (
        <circle key={i} cx={x} cy={y} r="4" fill={RED} stroke="none" />
      ))}
      <text
        x="80"
        y="106"
        textAnchor="middle"
        style={{ font: '600 10px var(--font)', fill: 'var(--text-3)', stroke: 'none' }}
      >
        Muayene noktaları
      </text>
    </g>
  ),
  'parking-reference': () => (
    <g {...S}>
      <rect x="24" y="70" width="112" height="20" fill="var(--surface-3)" stroke="none" />
      <rect x="40" y="74" width="28" height="12" rx="2" fill="var(--text-3)" stroke="none" />
      <rect x="100" y="74" width="28" height="12" rx="2" fill="var(--text-3)" stroke="none" />
      <rect x="74" y="74" width="24" height="12" rx="2" fill={ACC} stroke="none" />
      <path d="M110 62 q-24 -6 -40 10" stroke={ACC} strokeDasharray="5 4" />
      <text
        x="80"
        y="104"
        textAnchor="middle"
        style={{ font: '600 10px var(--font)', fill: 'var(--text-3)', stroke: 'none' }}
      >
        Park referans noktaları
      </text>
    </g>
  ),
};

export const VEHICLE_PART_IDS = Object.keys(PARTS);

export function VehicleFigure({ part, label }: { part: string; label: string }) {
  const P = PARTS[part];
  if (!P) return null;
  return <Frame label={label}>{P()}</Frame>;
}
