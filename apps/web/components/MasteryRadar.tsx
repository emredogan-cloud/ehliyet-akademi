/**
 * Ders ustalığı radar grafiği (Sprint 3 — ilerleme görselleştirme).
 * Saf, tema-uyumlu SVG. 4 teorik ders ekseninde 0..1 ustalık.
 */
import { SUBJECT_LABEL, type TheorySubject } from '@ea/content-schema';

export interface RadarDatum {
  subject: TheorySubject;
  mastery: number; // 0..1
}

const ORDER: TheorySubject[] = ['trafik', 'ilkyardim', 'motor', 'adab'];
const SHORT: Record<TheorySubject, string> = {
  trafik: 'Trafik',
  ilkyardim: 'İlk Yardım',
  motor: 'Araç Tekniği',
  adab: 'Adab',
};

export function MasteryRadar({ data }: { data: RadarDatum[] }) {
  const cx = 130;
  const cy = 120;
  const R = 84;
  const byS = new Map(data.map((d) => [d.subject, d.mastery]));
  // Eksen açıları: üst, sağ, alt, sol.
  const angle = (i: number) => -Math.PI / 2 + (i * Math.PI) / 2;
  const point = (i: number, r: number) => ({
    x: cx + Math.cos(angle(i)) * R * r,
    y: cy + Math.sin(angle(i)) * R * r,
  });
  const rings = [0.25, 0.5, 0.75, 1];
  const poly = ORDER.map((s, i) => {
    const p = point(i, Math.max(0.04, byS.get(s) ?? 0));
    return `${p.x.toFixed(1)},${p.y.toFixed(1)}`;
  }).join(' ');

  return (
    <svg
      viewBox="0 0 260 250"
      role="img"
      aria-label="Ders bazlı ustalık radar grafiği"
      style={{ width: '100%', maxWidth: 320, height: 'auto', display: 'block', margin: '0 auto' }}
    >
      {/* ızgara halkaları */}
      {rings.map((r, k) => (
        <polygon
          key={k}
          points={ORDER.map((_, i) => {
            const p = point(i, r);
            return `${p.x.toFixed(1)},${p.y.toFixed(1)}`;
          }).join(' ')}
          fill="none"
          stroke="var(--border)"
          strokeWidth={1}
        />
      ))}
      {/* eksenler */}
      {ORDER.map((_, i) => {
        const p = point(i, 1);
        return (
          <line key={i} x1={cx} y1={cy} x2={p.x} y2={p.y} stroke="var(--border)" strokeWidth={1} />
        );
      })}
      {/* veri poligonu */}
      <polygon
        points={poly}
        fill="color-mix(in srgb, var(--primary) 22%, transparent)"
        stroke="var(--primary)"
        strokeWidth={2}
      />
      {ORDER.map((s, i) => {
        const p = point(i, Math.max(0.04, byS.get(s) ?? 0));
        return <circle key={s} cx={p.x} cy={p.y} r={3.5} fill="var(--primary)" />;
      })}
      {/* etiketler */}
      {ORDER.map((s, i) => {
        const p = point(i, 1.16);
        return (
          <text
            key={s}
            x={p.x}
            y={p.y}
            textAnchor="middle"
            dominantBaseline="middle"
            style={{ font: '600 11px var(--font)', fill: 'var(--text-2)' }}
          >
            {SHORT[s]} %{Math.round((byS.get(s) ?? 0) * 100)}
          </text>
        );
      })}
      <title>
        Ders bazlı ustalık:{' '}
        {ORDER.map((s) => `${SUBJECT_LABEL[s]} %${Math.round((byS.get(s) ?? 0) * 100)}`).join(', ')}
      </title>
    </svg>
  );
}
