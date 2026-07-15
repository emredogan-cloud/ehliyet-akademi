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
};

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
              font: `800 ${glyphText.length > 2 ? 26 : 34}px system-ui, sans-serif`,
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
