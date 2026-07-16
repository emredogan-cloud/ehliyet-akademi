/**
 * SceneCanvas — deklaratif kuş-bakışı sahne çizici (Program 2 · Faz 8 · ADR-015).
 * SceneSpec JSON'unu özgün SVG sahneye çevirir; işaret rozetleri Faz 6 parametrik
 * sisteminden overlay olarak gelir. Tamamen telifsiz, dış istek yok.
 */
import { Car } from '@/components/anim/scenes';
import { TrafficSign } from '@/components/signs/TrafficSign';
import { signById } from '@/content/signs';
import type { SceneSpec } from '@/content/scenarios';

const GRASS = '#2c3b33';
const ROAD = '#3a4149';
const LINE = 'rgba(255,255,255,0.75)';
const COLORS: Record<string, string> = {
  ego: '#12b8a6',
  other: '#9aa4ae',
  priority: '#f5b301',
};

export function SceneCanvas({ scene, label }: { scene: SceneSpec; label: string }) {
  const sign = scene.sign ? signById(scene.sign.signId) : undefined;
  return (
    <div className="scene-canvas" style={{ position: 'relative' }}>
      <svg
        viewBox="0 0 420 240"
        role="img"
        aria-label={label}
        style={{ display: 'block', width: '100%', height: 'auto', borderRadius: 12 }}
      >
        <rect width="420" height="240" fill={GRASS} />
        {scene.roads.map((r, i) => (
          <rect key={i} x={r.x} y={r.y} width={r.w} height={r.h} fill={ROAD} />
        ))}
        {scene.dashes?.map((d, i) => (
          <rect key={i} x={d.x} y={d.y} width={d.w} height={d.h} rx="2" fill={LINE} opacity="0.5" />
        ))}
        {scene.stopLine && (
          <rect
            x={scene.stopLine.x}
            y={scene.stopLine.y}
            width={scene.stopLine.w}
            height={scene.stopLine.h}
            fill={LINE}
            opacity="0.85"
          />
        )}
        {scene.crossing && (
          <g>
            {Array.from({ length: Math.floor(scene.crossing.h / 14) }, (_, i) => (
              <rect
                key={i}
                x={scene.crossing!.x}
                y={scene.crossing!.y + i * 14}
                width={scene.crossing!.w}
                height={8}
                fill={LINE}
                opacity="0.8"
              />
            ))}
          </g>
        )}
        {scene.cars.map((c, i) =>
          c.kind === 'ambulance' ? (
            <g key={i} transform={`translate(${c.x} ${c.y}) rotate(${c.rot ?? 0})`}>
              <g transform="rotate(0)">
                <rect x={-13} y={-26} width={26} height={52} rx={6} fill="#f4f6f8" />
                <rect x={-13} y={-6} width={26} height={12} fill="#d92d20" />
                <circle className="anim-beacon" cx="0" cy="-16" r="5" fill="#d92d20" />
              </g>
            </g>
          ) : (
            <g key={i} transform={`translate(${c.x} ${c.y}) rotate(${c.rot ?? 0})`}>
              <Car body={COLORS[c.kind] ?? COLORS.other!} />
            </g>
          )
        )}
        {scene.ped && (
          <g transform={`translate(${scene.ped.x} ${scene.ped.y})`} fill="#f4f6f8">
            <circle cx="0" cy="-8" r="5" />
            <path
              d="M0 -3 l-5 12 M0 -3 l5 12 M0 0 l-6 5 M0 0 l6 5"
              stroke="#f4f6f8"
              strokeWidth="3.5"
              strokeLinecap="round"
              fill="none"
            />
          </g>
        )}
      </svg>
      {sign && scene.sign && (
        <span
          style={{
            position: 'absolute',
            left: `${(scene.sign.x / 420) * 100}%`,
            top: `${(scene.sign.y / 240) * 100}%`,
            transform: 'translate(-50%, -50%)',
            filter: 'drop-shadow(0 3px 8px rgba(0,0,0,0.45))',
          }}
        >
          <TrafficSign
            shape={sign.shape}
            glyph={sign.glyph}
            glyphText={sign.glyphText}
            label={sign.name}
            size={44}
          />
        </span>
      )}
    </div>
  );
}
