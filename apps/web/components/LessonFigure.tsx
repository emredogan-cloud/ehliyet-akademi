/**
 * Ders görselleri (ROADMAP Faz 14) — tema-uyumlu inline SVG (server component).
 * v1'in SVG-öncelikli görsel stratejisi: telifsiz, keskin, offline.
 */

function Frame({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <figure
      style={{
        margin: '18px 0',
        border: '1px solid var(--border)',
        borderRadius: 'var(--radius)',
        overflow: 'hidden',
        background: 'var(--surface)',
      }}
    >
      {children}
      <figcaption
        style={{
          padding: '10px 14px',
          fontSize: '0.85rem',
          color: 'var(--text-3)',
          borderTop: '1px solid var(--border)',
        }}
      >
        {title}
      </figcaption>
    </figure>
  );
}

const LBL = { font: '600 13px var(--font)', fill: 'var(--text)' } as const;
const SUB = { font: '500 11px var(--font)', fill: 'var(--text-3)' } as const;

/** Trafik işaret grupları: üçgen (tehlike) · kırmızı daire (yasak) · mavi daire (mecburiyet). */
function SignsSvg() {
  return (
    <svg
      viewBox="0 0 420 180"
      role="img"
      aria-label="Trafik işaret grupları"
      style={{ width: '100%', height: 'auto', display: 'block', background: 'var(--surface-2)' }}
    >
      <path
        d="M70 30 l45 78 h-90 z"
        fill="var(--surface)"
        stroke="var(--red)"
        strokeWidth="7"
        strokeLinejoin="round"
      />
      <text
        x="70"
        y="98"
        textAnchor="middle"
        style={{ font: '800 30px var(--font)', fill: 'var(--red)' }}
      >
        !
      </text>
      <text x="70" y="140" textAnchor="middle" style={LBL}>
        Tehlike uyarı
      </text>
      <text x="70" y="158" textAnchor="middle" style={SUB}>
        üçgen · kırmızı kenar
      </text>

      <circle cx="210" cy="70" r="42" fill="var(--surface)" stroke="var(--red)" strokeWidth="8" />
      <text
        x="210"
        y="82"
        textAnchor="middle"
        style={{ font: '800 28px var(--font)', fill: 'var(--text)' }}
      >
        50
      </text>
      <text x="210" y="140" textAnchor="middle" style={LBL}>
        Yasak / tanzim
      </text>
      <text x="210" y="158" textAnchor="middle" style={SUB}>
        kırmızı daire
      </text>

      <circle cx="350" cy="70" r="42" fill="var(--blue)" />
      <path
        d="M350 46 v34 M350 80 l-14 -14 M350 80 l14 -14"
        stroke="#fff"
        strokeWidth="7"
        strokeLinecap="round"
        fill="none"
        transform="rotate(180 350 63)"
      />
      <text x="350" y="140" textAnchor="middle" style={LBL}>
        Mecburiyet / bilgi
      </text>
      <text x="350" y="158" textAnchor="middle" style={SUB}>
        mavi daire
      </text>
    </svg>
  );
}

/** İlk yardım ABC akışı. */
function AbcSvg() {
  const box = (x: number, c: string, t1: string, t2: string) => (
    <g key={t1}>
      <rect
        x={x}
        y={40}
        width={110}
        height={64}
        rx={12}
        fill="var(--surface)"
        stroke={c}
        strokeWidth={2.5}
      />
      <text x={x + 55} y={68} textAnchor="middle" style={{ font: '800 20px var(--font)', fill: c }}>
        {t1}
      </text>
      <text x={x + 55} y={90} textAnchor="middle" style={SUB}>
        {t2}
      </text>
    </g>
  );
  return (
    <svg
      viewBox="0 0 420 150"
      role="img"
      aria-label="İlk yardım ABC değerlendirmesi"
      style={{ width: '100%', height: 'auto', display: 'block', background: 'var(--surface-2)' }}
    >
      <text x="16" y="26" style={LBL}>
        Önce güvenlik → sonra ABC
      </text>
      {box(16, 'var(--red)', 'A', 'Hava yolu')}
      {box(155, 'var(--yellow)', 'B', 'Solunum')}
      {box(294, 'var(--green)', 'C', 'Dolaşım')}
      <path
        d="M128 72 h24 M267 72 h24"
        stroke="var(--text-3)"
        strokeWidth="2.5"
        markerEnd="url(#abc-ar)"
      />
      <defs>
        <marker id="abc-ar" markerWidth="8" markerHeight="8" refX="6" refY="4" orient="auto">
          <path d="M0 0l6 4-6 4z" fill="var(--text-3)" />
        </marker>
      </defs>
      <text x="16" y="136" style={SUB}>
        Sıra bozulmaz: hava yolu açık değilse solunum/dolaşım değerlendirilemez.
      </text>
    </svg>
  );
}

/** Gösterge ikazları: kırmızı=dur, sarı=dikkat, yeşil/mavi=bilgi. */
function DashSvg() {
  const lamp = (x: number, c: string, sym: string, t: string) => (
    <g key={t}>
      <circle cx={x} cy={62} r={26} fill="var(--surface)" stroke={c} strokeWidth={3} />
      <text x={x} y={70} textAnchor="middle" style={{ font: '700 18px var(--font)', fill: c }}>
        {sym}
      </text>
      <text x={x} y={112} textAnchor="middle" style={SUB}>
        {t}
      </text>
    </g>
  );
  return (
    <svg
      viewBox="0 0 420 150"
      role="img"
      aria-label="Gösterge paneli ikaz renkleri"
      style={{ width: '100%', height: 'auto', display: 'block', background: 'var(--surface-2)' }}
    >
      <text x="16" y="26" style={LBL}>
        İkaz rengi = aciliyet
      </text>
      {lamp(70, 'var(--red)', '🌡', 'Hararet — DUR')}
      {lamp(180, 'var(--red)', '🛢', 'Yağ basıncı — DUR')}
      {lamp(290, 'var(--yellow)', '⚙', 'Motor — kontrol')}
      {lamp(385, 'var(--blue)', '≡', 'Uzun far')}
      <text x="16" y="140" style={SUB}>
        Kırmızı ikaz: güvenli yerde dur. Sarı: en kısa sürede kontrol ettir.
      </text>
    </svg>
  );
}

/** Kavşak: sağdan gelen önceliği. */
function JunctionSvg() {
  return (
    <svg
      viewBox="0 0 420 200"
      role="img"
      aria-label="Eşit kavşakta sağdan gelen önceliklidir"
      style={{ width: '100%', height: 'auto', display: 'block', background: 'var(--surface-2)' }}
    >
      <rect x="180" y="0" width="60" height="200" fill="var(--surface-3)" />
      <rect x="0" y="70" width="420" height="60" fill="var(--surface-3)" />
      <rect x="196" y="150" width="28" height="40" rx="5" fill="var(--primary)" />
      <text x="240" y="185" style={SUB}>
        SEN
      </text>
      <rect x="300" y="86" width="44" height="28" rx="5" fill="var(--red)" />
      <text x="300" y="70" style={SUB}>
        sağdan gelen → ÖNCELİKLİ
      </text>
      <path d="M210 148 v-30" stroke="var(--primary)" strokeWidth="3" strokeDasharray="6 5" />
      <path d="M296 100 h-60" stroke="var(--red)" strokeWidth="3" strokeDasharray="6 5" />
      <text x="12" y="26" style={LBL}>
        Işıksız eşit kavşak: sağdaki önce geçer
      </text>
    </svg>
  );
}

const FIGURES: Record<string, () => React.ReactNode> = {
  'trafik-isaretleri': () => (
    <Frame title="İşaret grupları: şekil ve renk anlamı taşır.">
      <SignsSvg />
    </Frame>
  ),
  'ilk-yardim-temel': () => (
    <Frame title="ABC değerlendirme sırası.">
      <AbcSvg />
    </Frame>
  ),
  'motor-temel': () => (
    <Frame title="İkaz rengi aciliyeti gösterir.">
      <DashSvg />
    </Frame>
  ),
  'kavsak-oncelik': () => (
    <Frame title="Sağdan gelen kuralı.">
      <JunctionSvg />
    </Frame>
  ),
};

export function LessonFigure({ lessonId }: { lessonId: string }) {
  const F = FIGURES[lessonId];
  return F ? <>{F()}</> : null;
}
