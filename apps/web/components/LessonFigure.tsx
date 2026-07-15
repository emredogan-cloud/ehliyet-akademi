/**
 * Ders görselleri (ROADMAP Faz 14 · Sprint 3) — tema-uyumlu inline SVG (server component).
 * Telifsiz, keskin, offline. figureId ile eşlenir; her görsel erişilebilir (role=img + aria-label).
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
const svgStyle = {
  width: '100%',
  height: 'auto',
  display: 'block',
  background: 'var(--surface-2)',
} as const;

/* ============ mevcut görseller ============ */

function SignsSvg() {
  return (
    <svg viewBox="0 0 420 180" role="img" aria-label="Trafik işaret grupları" style={svgStyle}>
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
      style={svgStyle}
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
      style={svgStyle}
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

function JunctionSvg() {
  return (
    <svg
      viewBox="0 0 420 200"
      role="img"
      aria-label="Eşit kavşakta sağdan gelen önceliklidir"
      style={svgStyle}
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

/* ============ Sprint 3 — yeni görseller ============ */

/** Takip mesafesi: 2 saniye kuralı. */
function FollowingDistanceSvg() {
  return (
    <svg
      viewBox="0 0 420 150"
      role="img"
      aria-label="İki saniyelik güvenli takip mesafesi"
      style={svgStyle}
    >
      <rect x="0" y="60" width="420" height="46" fill="var(--surface-3)" />
      <line
        x1="0"
        y1="83"
        x2="420"
        y2="83"
        stroke="var(--surface)"
        strokeWidth="2"
        strokeDasharray="22 18"
      />
      <rect x="300" y="66" width="50" height="30" rx="6" fill="var(--green)" />
      <rect x="90" y="66" width="50" height="30" rx="6" fill="var(--primary)" />
      <text x="325" y="55" textAnchor="middle" style={SUB}>
        öndeki
      </text>
      <text x="115" y="55" textAnchor="middle" style={SUB}>
        sen
      </text>
      <path
        d="M150 81 h140"
        stroke="var(--yellow)"
        strokeWidth="2.5"
        markerEnd="url(#fd-ar)"
        markerStart="url(#fd-ar2)"
      />
      <defs>
        <marker id="fd-ar" markerWidth="9" markerHeight="9" refX="7" refY="4" orient="auto">
          <path d="M0 0l7 4-7 4z" fill="var(--yellow)" />
        </marker>
        <marker id="fd-ar2" markerWidth="9" markerHeight="9" refX="2" refY="4" orient="auto">
          <path d="M7 0l-7 4 7 4z" fill="var(--yellow)" />
        </marker>
      </defs>
      <text
        x="220"
        y="120"
        textAnchor="middle"
        style={{ font: '700 14px var(--font)', fill: 'var(--yellow)' }}
      >
        ≈ 2 saniye
      </text>
      <text x="16" y="26" style={LBL}>
        Kuru zeminde en az 2 saniyelik mesafe
      </text>
      <text x="16" y="140" style={SUB}>
        Islak/karlı zeminde mesafeyi artır. Sabit bir noktayı seç, "bin bir–bin iki" say.
      </text>
    </svg>
  );
}

/** Güvenli sollama akışı. */
function OvertakingSvg() {
  return (
    <svg viewBox="0 0 420 160" role="img" aria-label="Soldan güvenli sollama" style={svgStyle}>
      <rect x="0" y="86" width="420" height="40" fill="var(--surface-3)" />
      <line
        x1="0"
        y1="106"
        x2="420"
        y2="106"
        stroke="var(--yellow)"
        strokeWidth="2"
        strokeDasharray="20 16"
      />
      <rect x="250" y="92" width="46" height="26" rx="6" fill="var(--text-3)" />
      <text x="273" y="86" textAnchor="middle" style={SUB}>
        yavaş araç
      </text>
      <path
        d="M120 112 q60 -46 130 -20 q40 14 90 0"
        fill="none"
        stroke="var(--primary)"
        strokeWidth="3"
        strokeDasharray="7 5"
        markerEnd="url(#ov-ar)"
      />
      <rect x="96" y="98" width="46" height="26" rx="6" fill="var(--primary)" />
      <defs>
        <marker id="ov-ar" markerWidth="9" markerHeight="9" refX="7" refY="4" orient="auto">
          <path d="M0 0l7 4-7 4z" fill="var(--primary)" />
        </marker>
      </defs>
      <text x="16" y="26" style={LBL}>
        Sollama soldan; karşı yön boş ve görüş açıkken
      </text>
      <text x="16" y="150" style={SUB}>
        Sinyal ver → aynayı ve kör noktayı kontrol et → soldan geç → güvenli mesafede sağa dön.
      </text>
    </svg>
  );
}

/** Yaya geçidi önceliği. */
function PedestrianSvg() {
  return (
    <svg
      viewBox="0 0 420 160"
      role="img"
      aria-label="Yaya geçidinde yaya önceliklidir"
      style={svgStyle}
    >
      <rect x="0" y="70" width="420" height="60" fill="var(--surface-3)" />
      {[0, 1, 2, 3, 4].map((i) => (
        <rect key={i} x={180 + i * 12} y={72} width="7" height="56" fill="var(--surface)" />
      ))}
      <rect x="70" y="84" width="46" height="28" rx="6" fill="var(--yellow)" />
      <text x="93" y="78" textAnchor="middle" style={SUB}>
        DUR / yol ver
      </text>
      <circle cx="212" cy="96" r="9" fill="var(--green)" />
      <path
        d="M212 105 v16 M212 112 l-8 6 M212 112 l8 6 M212 110 l-9 -3 M212 110 l9 -3"
        stroke="var(--green)"
        strokeWidth="2.5"
        fill="none"
        strokeLinecap="round"
      />
      <text x="16" y="26" style={LBL}>
        Yaya geçidinde geçiş önceliği yayanındır
      </text>
      <text x="16" y="150" style={SUB}>
        Geçide yaklaşırken yavaşla; okul geçidi, çocuk, yaşlı ve engellilere özel dikkat.
      </text>
    </svg>
  );
}

/** Temel yaşam desteği: kalp masajı hız ve derinliği. */
function CprSvg() {
  const metric = (x: number, big: string, small: string) => (
    <g key={big}>
      <rect
        x={x}
        y={46}
        width={150}
        height={62}
        rx={12}
        fill="var(--surface)"
        stroke="var(--red)"
        strokeWidth={2.5}
      />
      <text
        x={x + 75}
        y={78}
        textAnchor="middle"
        style={{ font: '800 22px var(--font)', fill: 'var(--red)' }}
      >
        {big}
      </text>
      <text x={x + 75} y={98} textAnchor="middle" style={SUB}>
        {small}
      </text>
    </g>
  );
  return (
    <svg
      viewBox="0 0 420 150"
      role="img"
      aria-label="Kalp masajı: dakikada 100-120 bası, 5 cm derinlik"
      style={svgStyle}
    >
      <text x="16" y="26" style={LBL}>
        Yetişkinde kalp masajı ölçüleri
      </text>
      {metric(20, '100–120', 'bası / dakika')}
      {metric(190, '≈ 5 cm', 'bası derinliği')}
      <text x="335" y="70" style={{ font: '800 18px var(--font)', fill: 'var(--primary)' }}>
        30:2
      </text>
      <text x="335" y="90" style={SUB}>
        masaj : soluk
      </text>
      <text x="16" y="140" style={SUB}>
        Önce bilinç ve solunumu kontrol et, 112'yi ara; göğüs ortasına kesintisiz bası uygula.
      </text>
    </svg>
  );
}

/** Araca hazırlık: ayna–koltuk–kemer. */
function VehicleSvg() {
  const step = (x: number, n: string, t: string) => (
    <g key={n}>
      <circle cx={x} cy={64} r={22} fill="var(--primary)" />
      <text x={x} y={71} textAnchor="middle" style={{ font: '800 18px var(--font)', fill: '#fff' }}>
        {n}
      </text>
      <text x={x} y={104} textAnchor="middle" style={SUB}>
        {t}
      </text>
    </g>
  );
  return (
    <svg
      viewBox="0 0 420 140"
      role="img"
      aria-label="Sürüşe hazırlık sırası: koltuk, ayna, kemer, kontrol"
      style={svgStyle}
    >
      <text x="16" y="26" style={LBL}>
        Sürüşe başlamadan önce sıra
      </text>
      {step(60, '1', 'Koltuk')}
      {step(160, '2', 'Aynalar')}
      {step(260, '3', 'Kemer')}
      {step(360, '4', 'Vites boşta')}
      <path
        d="M84 64 h52 M184 64 h52 M284 64 h52"
        stroke="var(--text-3)"
        strokeWidth="2.5"
        markerEnd="url(#v-ar)"
      />
      <defs>
        <marker id="v-ar" markerWidth="8" markerHeight="8" refX="6" refY="4" orient="auto">
          <path d="M0 0l6 4-6 4z" fill="var(--text-3)" />
        </marker>
      </defs>
      <text x="16" y="130" style={SUB}>
        Motoru çalıştırmadan önce vites boşta ve debriyaja basılı olmalı.
      </text>
    </svg>
  );
}

/** Rampada kalkış: el freni + debriyaj dengesi. */
function HillStartSvg() {
  return (
    <svg
      viewBox="0 0 420 160"
      role="img"
      aria-label="Rampada geri kaymadan kalkış"
      style={svgStyle}
    >
      <path d="M0 140 L420 40 L420 160 L0 160 Z" fill="var(--surface-3)" />
      <rect
        x="150"
        y="78"
        width="52"
        height="30"
        rx="6"
        fill="var(--primary)"
        transform="rotate(-13 176 93)"
      />
      <path
        d="M176 120 q-20 12 -30 30"
        stroke="var(--red)"
        strokeWidth="3"
        fill="none"
        markerEnd="url(#hs-ar)"
        strokeDasharray="6 5"
      />
      <text x="120" y="150" style={{ fill: 'var(--red)', font: '600 11px var(--font)' }}>
        geri kaymayı önle
      </text>
      <defs>
        <marker id="hs-ar" markerWidth="9" markerHeight="9" refX="7" refY="4" orient="auto">
          <path d="M0 0l7 4-7 4z" fill="var(--red)" />
        </marker>
      </defs>
      <text x="16" y="28" style={LBL}>
        Rampada kalkış: el freni + kavrama noktası
      </text>
      <text x="230" y="60" style={SUB}>
        1) El freni çek
      </text>
      <text x="230" y="80" style={SUB}>
        2) Debriyajı kavrama noktasına getir + hafif gaz
      </text>
      <text x="230" y="100" style={SUB}>
        3) Araç titreyince el frenini bırak
      </text>
    </svg>
  );
}

/** Paralel park adımları. */
function ParkingSvg() {
  return (
    <svg viewBox="0 0 420 160" role="img" aria-label="Paralel park manevrası" style={svgStyle}>
      <rect x="0" y="96" width="420" height="46" fill="var(--surface-3)" />
      <rect x="40" y="102" width="60" height="30" rx="6" fill="var(--text-3)" />
      <rect x="250" y="102" width="60" height="30" rx="6" fill="var(--text-3)" />
      <rect x="130" y="104" width="58" height="28" rx="6" fill="var(--primary)" />
      <path
        d="M300 88 q-70 -6 -120 22 q-30 16 -8 22"
        fill="none"
        stroke="var(--primary)"
        strokeWidth="3"
        strokeDasharray="7 5"
        markerEnd="url(#pk-ar)"
      />
      <defs>
        <marker id="pk-ar" markerWidth="9" markerHeight="9" refX="7" refY="4" orient="auto">
          <path d="M0 0l7 4-7 4z" fill="var(--primary)" />
        </marker>
      </defs>
      <text x="16" y="26" style={LBL}>
        Paralel park: hizala → geri + direksiyon → düzelt
      </text>
      <text x="16" y="152" style={SUB}>
        Öndeki araçla hizala, yavaşça geri gel; aynaları ve kör noktayı sürekli kontrol et.
      </text>
    </svg>
  );
}

/** Dönel kavşak: içerideki önceliklidir. */
function RoundaboutSvg() {
  return (
    <svg
      viewBox="0 0 420 190"
      role="img"
      aria-label="Dönel kavşakta içerideki araç önceliklidir"
      style={svgStyle}
    >
      <circle cx="210" cy="95" r="48" fill="none" stroke="var(--surface-3)" strokeWidth="30" />
      <circle cx="210" cy="95" r="20" fill="var(--surface-3)" />
      <path
        d="M245 60 a48 48 0 0 1 8 60"
        fill="none"
        stroke="var(--green)"
        strokeWidth="3"
        strokeDasharray="7 5"
        markerEnd="url(#rb-ar)"
      />
      <rect x="196" y="150" width="26" height="34" rx="5" fill="var(--primary)" />
      <text
        x="209"
        y="176"
        textAnchor="middle"
        style={{ fill: '#fff', font: '700 10px var(--font)' }}
      >
        SEN
      </text>
      <path d="M209 150 v-18" stroke="var(--primary)" strokeWidth="3" strokeDasharray="6 5" />
      <defs>
        <marker id="rb-ar" markerWidth="9" markerHeight="9" refX="7" refY="4" orient="auto">
          <path d="M0 0l7 4-7 4z" fill="var(--green)" />
        </marker>
      </defs>
      <text x="12" y="26" style={LBL}>
        Dönel kavşak: içeride dönen araç önceliklidir
      </text>
      <text x="12" y="180" style={SUB}>
        Gir­meden yavaşla ve yol ver; çıkışta sinyal ver.
      </text>
    </svg>
  );
}

/* ============ figureId → görsel eşlemesi ============ */

const FIGURE_BY_ID: Record<string, { title: string; render: () => React.ReactNode }> = {
  signs: { title: 'İşaret grupları: şekil ve renk anlam taşır.', render: () => <SignsSvg /> },
  abc: { title: 'ABC değerlendirme sırası.', render: () => <AbcSvg /> },
  dashboard: { title: 'İkaz rengi aciliyeti gösterir.', render: () => <DashSvg /> },
  junction: { title: 'Sağdan gelen kuralı.', render: () => <JunctionSvg /> },
  'following-distance': {
    title: 'İki saniyelik takip mesafesi.',
    render: () => <FollowingDistanceSvg />,
  },
  overtaking: { title: 'Soldan güvenli sollama akışı.', render: () => <OvertakingSvg /> },
  pedestrian: { title: 'Yaya geçidinde öncelik yayanındır.', render: () => <PedestrianSvg /> },
  cpr: { title: 'Kalp masajı: 100–120/dk, ~5 cm, 30:2.', render: () => <CprSvg /> },
  vehicle: { title: 'Sürüşe hazırlık sırası.', render: () => <VehicleSvg /> },
  'hill-start': { title: 'Rampada geri kaymadan kalkış.', render: () => <HillStartSvg /> },
  parking: { title: 'Paralel park manevrası.', render: () => <ParkingSvg /> },
  roundabout: { title: 'Dönel kavşakta içerideki önceliklidir.', render: () => <RoundaboutSvg /> },
};

/** Geriye dönük eşleme: eski ders id'leri → figureId. */
const LEGACY_LESSON_FIGURE: Record<string, string> = {
  'trafik-isaretleri': 'signs',
  'ilk-yardim-temel': 'abc',
  'motor-temel': 'dashboard',
  'kavsak-oncelik': 'junction',
};

export function LessonFigure({ figureId, lessonId }: { figureId?: string; lessonId?: string }) {
  const key = figureId || (lessonId ? LEGACY_LESSON_FIGURE[lessonId] : undefined);
  const fig = key ? FIGURE_BY_ID[key] : undefined;
  if (!fig) return null;
  return <Frame title={fig.title}>{fig.render()}</Frame>;
}
