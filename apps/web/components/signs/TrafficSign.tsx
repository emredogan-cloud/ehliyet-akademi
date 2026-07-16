/**
 * Trafik işareti — ÖZGÜN parametrik SVG (Program 1 · Görsel Dönüşüm Bölüm 1).
 * Mimari: şekil KABUĞU (shell) + SEMBOL (glyph). Standart şekil/renk (serbest) kullanılır;
 * her sembol KENDİ çizgi dilimizle sıfırdan çizilir — telifli çizim KOPYALANMAZ.
 * Renkler sabittir (gerçek levha gibi hem dark hem light modda doğru görünür).
 */
import type { SignShape } from '@/content/signs';

const RED = '#d92d20';
const BLUE = '#1558d6';
const GREEN = '#067647';
const YELLOW = '#f5b301';
const DARK = '#111827';
const WHITE = '#ffffff';

/** Sembol kayıtları — 100×100 grid, `fg` = sembol rengi (zemine göre koyu/beyaz). */
const GLYPHS: Record<string, (fg: string) => React.ReactNode> = {
  exclam: (fg) => (
    <g fill={fg}>
      <rect x="45" y="30" width="10" height="30" rx="3" />
      <circle cx="50" cy="70" r="6" />
    </g>
  ),
  curveLeft: (fg) => (
    <path
      d="M58 72 V52 q0 -14 -14 -14 q-14 0 -14 14"
      fill="none"
      stroke={fg}
      strokeWidth="8"
      strokeLinecap="round"
    />
  ),
  curveRight: (fg) => (
    <path
      d="M42 72 V52 q0 -14 14 -14 q14 0 14 14"
      fill="none"
      stroke={fg}
      strokeWidth="8"
      strokeLinecap="round"
    />
  ),
  sCurve: (fg) => (
    <path
      d="M40 74 q-8 -12 4 -20 q12 -8 4 -20"
      fill="none"
      stroke={fg}
      strokeWidth="8"
      strokeLinecap="round"
    />
  ),
  bump: (fg) => (
    <path d="M28 66 q22 -34 44 0" fill="none" stroke={fg} strokeWidth="8" strokeLinecap="round" />
  ),
  slippery: (fg) => (
    <g fill="none" stroke={fg} strokeWidth="6" strokeLinecap="round">
      <rect x="34" y="34" width="20" height="12" rx="3" />
      <path d="M30 62 q10 8 22 2 M40 70 q10 6 22 0" />
    </g>
  ),
  pedestrian: (fg) => (
    <g fill={fg}>
      <circle cx="50" cy="30" r="7" />
      <path
        d="M50 38 l-8 18 M50 38 l8 18 M50 42 l-10 8 M50 42 l10 8"
        stroke={fg}
        strokeWidth="5"
        strokeLinecap="round"
        fill="none"
      />
    </g>
  ),
  children: (fg) => (
    <g fill="none" stroke={fg} strokeWidth="5" strokeLinecap="round">
      <circle cx="40" cy="34" r="5" fill={fg} />
      <circle cx="60" cy="38" r="5" fill={fg} />
      <path d="M40 40 v14 M35 48 h10 M40 54 l-5 12 M40 54 l5 12" />
      <path d="M60 44 v12 M56 50 h8 M60 56 l-4 10 M60 56 l4 10" />
    </g>
  ),
  animal: (fg) => (
    <path
      d="M30 66 q4 -18 14 -18 q4 -10 10 -6 q2 -8 6 -2 l2 6 q10 2 10 20"
      fill="none"
      stroke={fg}
      strokeWidth="6"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  roundabout: (fg) => (
    <g fill="none" stroke={fg} strokeWidth="7">
      <circle cx="50" cy="52" r="16" strokeDasharray="10 8" />
      <path d="M66 44 l4 -8 -9 -1" fill={fg} stroke="none" />
    </g>
  ),
  narrow: (fg) => (
    <path
      d="M34 30 L44 52 L44 72 M66 30 L56 52 L56 72"
      fill="none"
      stroke={fg}
      strokeWidth="7"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  twoway: (fg) => (
    <g fill={fg} stroke={fg} strokeWidth="6" strokeLinecap="round">
      <path d="M42 30 v40 M58 70 v-40" />
      <path d="M42 30 l-6 8 h12 z M58 70 l-6 -8 h12 z" stroke="none" />
    </g>
  ),
  light: (fg) => (
    <g>
      <rect x="42" y="26" width="16" height="44" rx="6" fill="none" stroke={fg} strokeWidth="4" />
      <circle cx="50" cy="36" r="4" fill={RED} />
      <circle cx="50" cy="48" r="4" fill={YELLOW} />
      <circle cx="50" cy="60" r="4" fill={GREEN} />
    </g>
  ),
  cross: (fg) => (
    <path d="M34 34 L66 66 M66 34 L34 66" stroke={fg} strokeWidth="9" strokeLinecap="round" />
  ),
  car: (fg) => (
    <g fill={fg}>
      <path d="M28 58 l6 -14 h32 l6 14 z" />
      <circle cx="38" cy="60" r="5" />
      <circle cx="62" cy="60" r="5" />
    </g>
  ),
  twoCars: (fg) => (
    <g>
      <g fill={fg}>
        <rect x="30" y="46" width="18" height="9" rx="2" />
      </g>
      <g fill={RED}>
        <rect x="52" y="46" width="18" height="9" rx="2" />
      </g>
      <path d="M50 30 v40" stroke={fg} strokeWidth="4" />
    </g>
  ),
  noStop: (fg) => (
    <g fill="none" stroke={fg} strokeWidth="7">
      <circle cx="50" cy="50" r="4" fill={fg} />
    </g>
  ),
  arrowRight: (fg) => (
    <path
      d="M32 50 h30 M52 38 l14 12 -14 12"
      fill="none"
      stroke={fg}
      strokeWidth="9"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  arrowStraight: (fg) => (
    <path
      d="M50 70 V34 M38 46 l12 -12 12 12"
      fill="none"
      stroke={fg}
      strokeWidth="9"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  arrowLeft: (fg) => (
    <path
      d="M68 50 h-30 M48 38 l-14 12 14 12"
      fill="none"
      stroke={fg}
      strokeWidth="9"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  bike: (fg) => (
    <g fill="none" stroke={fg} strokeWidth="5">
      <circle cx="36" cy="60" r="11" />
      <circle cx="64" cy="60" r="11" />
      <path d="M36 60 l12 -18 h10 M48 42 l16 18 M44 60 h20" />
    </g>
  ),
  hospital: (fg) => (
    <path d="M44 30 h12 v12 h12 v12 h-12 v12 h-12 v-12 h-12 v-12 h12 z" fill={fg} />
  ),
  parkingP: (fg) => (
    <path
      d="M40 30 v40 M40 30 h14 a11 11 0 0 1 0 22 h-14"
      fill="none"
      stroke={fg}
      strokeWidth="9"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  digger: (fg) => (
    <g fill={fg}>
      <rect x="30" y="54" width="24" height="12" rx="2" />
      <path d="M54 58 l16 -16 4 4 -14 16 z" />
    </g>
  ),
  hillDown: (fg) => (
    <g fill={fg} stroke={fg}>
      <path d="M28 40 L72 68 L28 68 Z" opacity="0.85" />
    </g>
  ),
  levelCross: (fg) => (
    <path
      d="M32 34 L68 66 M52 34 h16 v16"
      fill="none"
      stroke={fg}
      strokeWidth="7"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  ),
  // ——— Program 2 · Faz 6 genişletmesi (özgün piktogramlar) ———
  hillUp: (fg) => (
    <g>
      <path d="M22 72 L78 40 L78 72 Z" fill={fg} />
      <text x="30" y="42" fontSize="16" fontWeight="700" fill={fg}>
        %10
      </text>
    </g>
  ),
  narrowRight: (fg) => (
    <g stroke={fg} strokeWidth="7" fill="none" strokeLinecap="round">
      <path d="M34 26 V74" />
      <path d="M66 26 Q60 50 66 74" />
    </g>
  ),
  narrowLeft: (fg) => (
    <g stroke={fg} strokeWidth="7" fill="none" strokeLinecap="round">
      <path d="M66 26 V74" />
      <path d="M34 26 Q40 50 34 74" />
    </g>
  ),
  gravel: (fg) => (
    <g fill={fg}>
      <path d="M22 66 h34 l8 -14 h-18 l-6 8 h-12 z" />
      <circle cx="30" cy="72" r="5" />
      <circle cx="48" cy="72" r="5" />
      <circle cx="66" cy="44" r="3" />
      <circle cx="74" cy="36" r="3" />
      <circle cx="70" cy="54" r="3" />
    </g>
  ),
  wind: (fg) => (
    <g>
      <path d="M36 30 V76" stroke={fg} strokeWidth="6" strokeLinecap="round" />
      <path d="M36 30 L74 36 L36 48 Z" fill={fg} />
    </g>
  ),
  tunnel: (fg) => (
    <path
      d="M26 74 V52 Q26 28 50 28 Q74 28 74 52 V74 H62 V54 Q62 40 50 40 Q38 40 38 54 V74 Z"
      fill={fg}
    />
  ),
  rocks: (fg) => (
    <g fill={fg}>
      <path d="M24 30 L44 34 L38 48 L22 46 Z" />
      <path d="M46 44 L60 48 L54 60 L42 56 Z" />
      <path d="M30 74 h44 l-8 -12 h-30 z" />
    </g>
  ),
  quay: (fg) => (
    <g>
      <path d="M24 56 L52 48" stroke={fg} strokeWidth="6" strokeLinecap="round" />
      <g transform="rotate(20 44 40)">
        <rect x="30" y="34" width="26" height="10" rx="3" fill={fg} />
        <circle cx="36" cy="47" r="4" fill={fg} />
        <circle cx="50" cy="47" r="4" fill={fg} />
      </g>
      <path
        d="M24 70 q6 -6 12 0 q6 6 12 0 q6 -6 12 0 q6 6 12 0"
        fill="none"
        stroke={fg}
        strokeWidth="5"
        strokeLinecap="round"
      />
    </g>
  ),
  airplane: (fg) => (
    <path
      d="M20 62 L80 62 L64 50 L52 50 L40 34 L32 34 L38 50 L26 50 L20 44 L14 44 L18 56 Z"
      fill={fg}
      transform="rotate(-8 50 50)"
    />
  ),
  tram: (fg) => (
    <g fill={fg}>
      <rect x="30" y="30" width="40" height="34" rx="6" />
      <rect x="36" y="36" width="12" height="10" fill="#ffffff" opacity="0.85" />
      <rect x="52" y="36" width="12" height="10" fill="#ffffff" opacity="0.85" />
      <circle cx="38" cy="70" r="5" />
      <circle cx="62" cy="70" r="5" />
      <path d="M44 30 L50 20 L56 30" stroke={fg} strokeWidth="4" fill="none" />
    </g>
  ),
  truck: (fg) => (
    <g fill={fg}>
      <rect x="18" y="38" width="38" height="22" rx="3" />
      <path d="M56 44 h16 l8 10 v6 h-24 z" />
      <circle cx="30" cy="66" r="6" />
      <circle cx="66" cy="66" r="6" />
    </g>
  ),
  motorcycle: (fg) => (
    <g fill={fg}>
      <circle cx="26" cy="64" r="9" fill="none" stroke={fg} strokeWidth="5" />
      <circle cx="74" cy="64" r="9" fill="none" stroke={fg} strokeWidth="5" />
      <path
        d="M26 64 L44 48 H58 L66 40 H74 L66 52 L74 64"
        fill="none"
        stroke={fg}
        strokeWidth="6"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <rect x="40" y="42" width="14" height="7" rx="3" />
    </g>
  ),
  tractor: (fg) => (
    <g fill={fg}>
      <circle cx="32" cy="62" r="12" fill="none" stroke={fg} strokeWidth="6" />
      <circle cx="68" cy="66" r="7" fill="none" stroke={fg} strokeWidth="5" />
      <path
        d="M40 50 h16 v-14 h10 l6 20"
        fill="none"
        stroke={fg}
        strokeWidth="6"
        strokeLinejoin="round"
      />
    </g>
  ),
  handcart: (fg) => (
    <g fill="none" stroke={fg} strokeWidth="6" strokeLinecap="round">
      <path d="M30 34 L58 34 L66 56 L38 56 Z" fill={fg} />
      <path d="M66 42 L80 38" />
      <circle cx="50" cy="66" r="7" />
    </g>
  ),
  horseCart: (fg) => (
    <g fill={fg}>
      <path d="M22 44 q8 -10 16 0 l-2 10 h-12 z" />
      <path d="M24 40 q-2 -8 6 -8" fill="none" stroke={fg} strokeWidth="4" />
      <rect x="46" y="40" width="26" height="12" rx="2" />
      <circle cx="58" cy="62" r="8" fill="none" stroke={fg} strokeWidth="5" />
      <path d="M38 46 h10" stroke={fg} strokeWidth="4" />
    </g>
  ),
  deer: (fg) => (
    <g fill={fg}>
      <path d="M30 70 L36 52 L32 40 L44 48 L60 44 L72 52 L66 60 L68 70 L60 70 L58 60 L44 62 L42 70 Z" />
      <path
        d="M64 44 L60 30 M64 44 L70 28 M60 36 L54 30 M68 34 L74 30"
        stroke={fg}
        strokeWidth="4"
        fill="none"
        strokeLinecap="round"
      />
    </g>
  ),
  chains: (fg) => (
    <g fill="none" stroke={fg} strokeWidth="5">
      <circle cx="50" cy="50" r="24" />
      <circle cx="50" cy="50" r="10" />
      {[0, 60, 120, 180, 240, 300].map((a) => (
        <circle
          key={a}
          cx={50 + 24 * Math.cos((a * Math.PI) / 180)}
          cy={50 + 24 * Math.sin((a * Math.PI) / 180)}
          r="5"
          fill={fg}
          stroke="none"
        />
      ))}
    </g>
  ),
  uTurn: (fg) => (
    <g fill="none" stroke={fg} strokeWidth="8" strokeLinecap="round">
      <path d="M36 72 V44 Q36 28 50 28 Q64 28 64 44 V60" />
      <path d="M54 54 L64 70 L74 54" fill={fg} stroke="none" />
    </g>
  ),
  turnLeft: (fg) => (
    <g fill="none" stroke={fg} strokeWidth="9" strokeLinecap="round">
      <path d="M62 74 V50 Q62 38 50 38 H40" />
      <path d="M44 26 L28 38 L44 50" fill={fg} stroke="none" />
    </g>
  ),
  turnRight: (fg) => (
    <g fill="none" stroke={fg} strokeWidth="9" strokeLinecap="round">
      <path d="M38 74 V50 Q38 38 50 38 H60" />
      <path d="M56 26 L72 38 L56 50" fill={fg} stroke="none" />
    </g>
  ),
  phone: (fg) => (
    <path
      d="M32 26 q18 -8 36 0 l-6 12 q-12 -5 -24 0 Z M30 40 q-8 18 4 34 l10 -8 q-7 -10 -2 -20 Z M70 40 l-12 6 q5 10 -2 20 l10 8 q12 -16 4 -34 Z"
      fill={fg}
    />
  ),
  wrenchTool: (fg) => (
    <g fill={fg}>
      <path d="M30 24 l8 0 0 12 8 0 0 -12 8 0 0 20 -24 0 Z" />
      <rect x="38" y="44" width="8" height="32" rx="3" />
    </g>
  ),
  fuel: (fg) => (
    <g fill={fg}>
      <rect x="30" y="28" width="26" height="46" rx="4" />
      <rect x="35" y="34" width="16" height="12" fill="#ffffff" opacity="0.85" />
      <path
        d="M58 40 h6 l8 10 v18 a5 5 0 0 1 -10 0 v-12 h-4"
        fill="none"
        stroke={fg}
        strokeWidth="5"
      />
    </g>
  ),
  bed: (fg) => (
    <g fill={fg}>
      <path d="M20 64 V40 h6 v14 h48 a8 8 0 0 1 8 8 v10 h-6 v-6 H26 v6 h-6 z" />
      <circle cx="34" cy="46" r="6" />
    </g>
  ),
  cutlery: (fg) => (
    <g fill={fg}>
      <path d="M36 24 v20 a6 6 0 0 1 -12 0 V24 h4 v18 h4 V24 Z" />
      <rect x="28" y="46" width="6" height="30" rx="3" />
      <path d="M62 24 q10 0 10 14 q0 12 -8 14 v24 h-6 V24 Z" />
    </g>
  ),
  fountain: (fg) => (
    <g fill={fg}>
      <rect x="34" y="46" width="22" height="30" rx="3" />
      <path d="M56 50 h10 q4 0 4 5 v6 h-6 v-4 h-8" />
      <path d="M68 64 q-3 8 0 10 q6 -2 0 -10" />
      <rect x="30" y="40" width="30" height="8" rx="2" />
    </g>
  ),
  tent: (fg) => (
    <g fill="none" stroke={fg} strokeWidth="6" strokeLinecap="round">
      <path d="M22 72 L50 30 L78 72 Z" strokeLinejoin="round" />
      <path d="M50 72 L50 48" />
    </g>
  ),
  bus: (fg) => (
    <g fill={fg}>
      <rect x="22" y="32" width="56" height="32" rx="6" />
      <rect x="28" y="38" width="12" height="10" fill="#ffffff" opacity="0.85" />
      <rect x="44" y="38" width="12" height="10" fill="#ffffff" opacity="0.85" />
      <rect x="60" y="38" width="12" height="10" fill="#ffffff" opacity="0.85" />
      <circle cx="34" cy="68" r="6" />
      <circle cx="66" cy="68" r="6" />
    </g>
  ),
  keepRight: (fg) => (
    <g fill="none" stroke={fg} strokeWidth="9" strokeLinecap="round">
      <path d="M42 26 V44 Q42 56 54 60 L62 64" />
      <path d="M62 48 L72 68 L50 66" fill={fg} stroke="none" />
    </g>
  ),
  priorityArrows: (fg) => (
    <g>
      <path
        d="M38 74 V34 M38 34 L30 46 M38 34 L46 46"
        fill="none"
        stroke={fg}
        strokeWidth="8"
        strokeLinecap="round"
      />
      <path
        d="M62 30 V66 M62 66 L56 58 M62 66 L68 58"
        fill="none"
        stroke={RED}
        strokeWidth="6"
        strokeLinecap="round"
      />
    </g>
  ),
  deadEnd: (fg) => (
    <g>
      <path d="M50 76 V40" stroke={fg} strokeWidth="10" />
      <rect x="30" y="26" width="40" height="10" fill={RED} />
    </g>
  ),
  endBar: (fg) => (
    <g stroke={fg} strokeWidth="5" opacity="0.9">
      {[-14, 0, 14].map((o) => (
        <path key={o} d={`M${30 + o} 74 L${58 + o} 26`} />
      ))}
    </g>
  ),
  snow: (fg) => (
    <g stroke={fg} strokeWidth="4" strokeLinecap="round">
      {[0, 60, 120].map((a) => (
        <path key={a} d="M50 26 V74" transform={`rotate(${a} 50 50)`} />
      ))}
      {[0, 60, 120, 180, 240, 300].map((a) => (
        <path key={a} d="M50 30 L44 38 M50 30 L56 38" transform={`rotate(${a} 50 50)`} />
      ))}
    </g>
  ),
};

/** Katalog doğrulaması için piktogram kimlikleri (test kapısı). */
export const GLYPH_IDS = Object.keys(GLYPHS);

function Shell({ shape, children }: { shape: SignShape; children?: React.ReactNode }) {
  switch (shape) {
    case 'triangle':
      return (
        <>
          <path
            d="M50 12 L88 78 H12 Z"
            fill={WHITE}
            stroke={RED}
            strokeWidth="9"
            strokeLinejoin="round"
          />
          <g transform="translate(0 8) scale(0.78) translate(14 6)">{children}</g>
        </>
      );
    case 'inv-triangle':
      return (
        <>
          <path
            d="M12 20 H88 L50 86 Z"
            fill={WHITE}
            stroke={RED}
            strokeWidth="9"
            strokeLinejoin="round"
          />
          {children}
        </>
      );
    case 'ring':
      return (
        <>
          <circle cx="50" cy="50" r="40" fill={WHITE} stroke={RED} strokeWidth="10" />
          {children}
        </>
      );
    case 'disc':
      return (
        <>
          <circle cx="50" cy="50" r="42" fill={BLUE} />
          {children}
        </>
      );
    case 'rect-blue':
      return (
        <>
          <rect x="12" y="16" width="76" height="68" rx="8" fill={BLUE} />
          {children}
        </>
      );
    case 'rect-green':
      return (
        <>
          <rect x="12" y="16" width="76" height="68" rx="8" fill={GREEN} />
          {children}
        </>
      );
    case 'octagon':
      return (
        <path
          d="M32 12 H68 L88 32 V68 L68 88 H32 L12 68 V32 Z"
          fill={RED}
          stroke="#fff"
          strokeWidth="3"
        />
      );
    case 'diamond':
      return (
        <>
          <path d="M50 10 L90 50 L50 90 L10 50 Z" fill={YELLOW} stroke="#fff" strokeWidth="4" />
          {children}
        </>
      );
    default:
      return null;
  }
}

/** Zemin rengine göre sembol ön-plan rengi. */
function fgFor(shape: SignShape): string {
  if (shape === 'disc' || shape === 'rect-blue' || shape === 'rect-green') return WHITE;
  return DARK;
}

export function TrafficSign({
  shape,
  glyph,
  glyphText,
  label,
  size = 84,
}: {
  shape: SignShape;
  glyph?: string;
  glyphText?: string;
  label: string;
  size?: number;
}) {
  const fg = fgFor(shape);
  const g = glyph ? GLYPHS[glyph] : undefined;
  return (
    <svg
      viewBox="0 0 100 100"
      width={size}
      height={size}
      role="img"
      aria-label={label}
      style={{ display: 'block' }}
    >
      <Shell shape={shape}>
        {g && g(fg)}
        {glyphText && (
          <text
            x="50"
            y="50"
            textAnchor="middle"
            dominantBaseline="central"
            style={{
              font: `800 ${glyphText.length > 4 ? 15 : glyphText.length > 2 ? 24 : 34}px system-ui, sans-serif`,
              fill: fg,
            }}
          >
            {glyphText}
          </text>
        )}
      </Shell>
      {shape === 'octagon' && (
        <text
          x="50"
          y="52"
          textAnchor="middle"
          dominantBaseline="central"
          style={{ font: '800 24px system-ui, sans-serif', fill: '#fff' }}
        >
          DUR
        </text>
      )}
      {shape === 'inv-triangle' && (
        <text
          x="50"
          y="42"
          textAnchor="middle"
          dominantBaseline="central"
          style={{ font: '700 13px system-ui, sans-serif', fill: RED }}
        >
          YOL VER
        </text>
      )}
    </svg>
  );
}
