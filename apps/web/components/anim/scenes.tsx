/**
 * Özgün eğitsel animasyon sahneleri (Program 2 · Faz 3 · ADR-012).
 * Kuş-bakışı SVG; hareket yalnız transform ile (CSS keyframes globals.css'te).
 * Renk dili: ego araç = yeşil (--anim ego), diğer araçlar = gri, öncelikli/acil = sarı-kırmızı.
 */

/** Kuş-bakışı araç gövdesi (22×44). Merkez (0,0) — transform kolaylığı için. */
function Car({ body, roof = 'rgba(255,255,255,0.35)' }: { body: string; roof?: string }) {
  return (
    <g>
      <rect x={-11} y={-22} width={22} height={44} rx={6} fill={body} />
      <rect x={-8} y={-12} width={16} height={12} rx={3} fill={roof} />
      <rect x={-8} y={4} width={16} height={9} rx={3} fill={roof} opacity={0.7} />
    </g>
  );
}

const ROAD = '#3a4149';
const LINE = 'rgba(255,255,255,0.75)';
const KERB = '#5b6570';
const GRASS = '#2c3b33';
const EGO = '#12b8a6';
const OTHER = '#9aa4ae';

/** Paralel park: sokak, iki park halindeki araç, ego geri geri boşluğa girer. */
export function ParallelParkScene() {
  return (
    <svg
      viewBox="0 0 420 240"
      role="img"
      aria-label="Paralel park animasyonu — araç iki aracın arasına geri geri park eder"
    >
      <rect width="420" height="240" fill={GRASS} />
      <rect y="60" width="420" height="150" fill={ROAD} />
      <rect y="206" width="420" height="10" fill={KERB} />
      <rect y="54" width="420" height="6" fill={KERB} />
      {[0, 60, 120, 180, 240, 300, 360].map((x) => (
        <rect key={x} x={x} y="128" width="30" height="4" rx="2" fill={LINE} opacity="0.5" />
      ))}
      {/* park etmiş araçlar (arkadaki ve öndeki) */}
      <g transform="translate(80 182) rotate(90)">
        <Car body={OTHER} />
      </g>
      <g transform="translate(330 182) rotate(90)">
        <Car body={OTHER} />
      </g>
      {/* boşluk vurgusu */}
      <rect
        x="140"
        y="164"
        width="150"
        height="38"
        rx="8"
        fill="none"
        stroke={LINE}
        strokeDasharray="6 6"
        opacity="0.55"
      />
      {/* ego araç — CSS: anim-parallel */}
      <g className="anim-car anim-parallel">
        <Car body={EGO} />
      </g>
    </svg>
  );
}

/** Dik park: park cepleri, ego 90° dönerek boş cebe girer. */
export function PerpendicularParkScene() {
  return (
    <svg
      viewBox="0 0 420 240"
      role="img"
      aria-label="Dik park animasyonu — araç boş park cebine 90 derece dönerek girer"
    >
      <rect width="420" height="240" fill={ROAD} />
      {/* cep çizgileri (üst sıra) */}
      {[60, 130, 200, 270, 340].map((x) => (
        <line key={x} x1={x} y1="10" x2={x} y2="86" stroke={LINE} strokeWidth="4" />
      ))}
      {/* dolu cepler */}
      <g transform="translate(95 48)">
        <Car body={OTHER} />
      </g>
      <g transform="translate(305 48)">
        <Car body={OTHER} />
      </g>
      {/* boş cep vurgusu (orta) */}
      <rect
        x="206"
        y="12"
        width="58"
        height="74"
        rx="6"
        fill="none"
        stroke={LINE}
        strokeDasharray="6 6"
        opacity="0.6"
      />
      {/* koridor çizgisi */}
      <rect y="150" width="420" height="4" fill={LINE} opacity="0.25" />
      {/* ego araç — CSS: anim-perp */}
      <g className="anim-car anim-perp">
        <Car body={EGO} />
      </g>
    </svg>
  );
}

/** Sağdan gelen: eşit kavşak; ego durur, sağdan gelen geçer, sonra ego geçer. */
export function RightOfWayScene() {
  return (
    <svg
      viewBox="0 0 420 240"
      role="img"
      aria-label="Kavşak animasyonu — sürücü sağdan gelen araca yol verir"
    >
      <rect width="420" height="240" fill={GRASS} />
      {/* yatay + dikey yol */}
      <rect y="85" width="420" height="70" fill={ROAD} />
      <rect x="175" width="70" height="240" fill={ROAD} />
      {/* şerit çizgileri */}
      {[10, 60, 110, 300, 350, 400].map((x) => (
        <rect key={x} x={x} y="118" width="26" height="4" rx="2" fill={LINE} opacity="0.5" />
      ))}
      {[10, 50, 190, 230].map((y) => (
        <rect key={y} x="208" y={y} width="4" height="22" rx="2" fill={LINE} opacity="0.5" />
      ))}
      {/* duraklama çizgisi (ego için) */}
      <rect x="150" y="90" width="5" height="60" fill={LINE} opacity="0.8" />
      {/* sağdan (alttan) gelen öncelikli araç — CSS: anim-row-other */}
      <g className="anim-car anim-row-other">
        <Car body="#f5b301" roof="rgba(0,0,0,0.25)" />
      </g>
      {/* ego araç (soldan) — CSS: anim-row-ego */}
      <g className="anim-car anim-row-ego">
        <Car body={EGO} />
      </g>
    </svg>
  );
}

/** Ambulansa yol açma: ego sağa yanaşır, ambulans soldan geçer. */
export function EmergencyYieldScene() {
  return (
    <svg
      viewBox="0 0 420 240"
      role="img"
      aria-label="Ambulansa yol açma animasyonu — araçlar sağa yanaşır, ambulans soldan geçer"
    >
      <rect width="420" height="240" fill={GRASS} />
      <rect y="70" width="420" height="120" fill={ROAD} />
      <rect y="64" width="420" height="6" fill={KERB} />
      <rect y="190" width="420" height="6" fill={KERB} />
      {[0, 60, 120, 180, 240, 300, 360].map((x) => (
        <rect key={x} x={x} y="128" width="30" height="4" rx="2" fill={LINE} opacity="0.5" />
      ))}
      {/* ego + öndeki araç: sağa yanaşırlar — CSS: anim-ey-ego / anim-ey-front */}
      <g className="anim-car anim-ey-front">
        <Car body={OTHER} />
      </g>
      <g className="anim-car anim-ey-ego">
        <Car body={EGO} />
      </g>
      {/* ambulans — CSS: anim-ey-amb; tepe lambası yanıp söner */}
      <g className="anim-car anim-ey-amb">
        <g transform="rotate(90)">
          <rect x={-13} y={-26} width={26} height={52} rx={6} fill="#f4f6f8" />
          <rect x={-13} y={-6} width={26} height={12} fill="#d92d20" />
          <rect x={-9} y={-16} width={18} height={7} rx={2} fill="rgba(30,60,90,0.5)" />
          <circle className="anim-beacon" cx="0" cy="14" r="5" fill="#d92d20" />
        </g>
      </g>
    </svg>
  );
}

export const SCENE_COMPONENTS: Record<string, () => React.ReactNode> = {
  'parallel-park': ParallelParkScene,
  'perpendicular-park': PerpendicularParkScene,
  'right-of-way': RightOfWayScene,
  'emergency-yield': EmergencyYieldScene,
};
