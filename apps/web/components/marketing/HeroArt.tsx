/**
 * Vitrin kahraman görseli (Program 1 · Görsel Dönüşüm Bölüm 3) — ÖZGÜN SVG sahne.
 * Perspektifli yol + şerit çizgileri + stilize araç + işaret direkleri (kendi işaret sistemimiz).
 * Tema-uyumlu, hafif, telifsiz.
 */
import { TrafficSign } from '@/components/signs/TrafficSign';

export function HeroArt() {
  return (
    <div className="hero-art" aria-hidden>
      <svg
        viewBox="0 0 420 300"
        role="img"
        aria-label="Yol ve trafik işaretleri illüstrasyonu"
        style={{ width: '100%', height: 'auto', display: 'block' }}
      >
        <defs>
          <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="rgba(255,255,255,0.10)" />
            <stop offset="1" stopColor="rgba(255,255,255,0)" />
          </linearGradient>
          <linearGradient id="road" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="rgba(0,0,0,0.28)" />
            <stop offset="1" stopColor="rgba(0,0,0,0.14)" />
          </linearGradient>
        </defs>
        {/* gökyüzü parıltısı */}
        <rect x="0" y="0" width="420" height="180" fill="url(#sky)" />
        <circle cx="330" cy="70" r="46" fill="rgba(255,255,255,0.12)" />
        {/* perspektif yol */}
        <path d="M170 300 L200 130 L220 130 L250 300 Z" fill="url(#road)" />
        {/* kesikli orta şerit */}
        {[300, 250, 210, 182, 162].map((y, i) => (
          <rect
            key={i}
            x={208 - (i === 0 ? 4 : i)}
            y={y}
            width={8 - i * 1.2}
            height={14 - i * 2}
            rx="2"
            fill="rgba(255,255,255,0.7)"
          />
        ))}
        {/* stilize araç */}
        <g transform="translate(184 246)">
          <rect x="0" y="10" width="52" height="20" rx="6" fill="#fff" opacity="0.92" />
          <path d="M8 10 q8 -12 18 -12 h10 q10 0 16 12 z" fill="#fff" opacity="0.92" />
          <circle cx="12" cy="32" r="6" fill="#1f2937" />
          <circle cx="40" cy="32" r="6" fill="#1f2937" />
          <rect x="2" y="16" width="8" height="6" rx="2" fill="#f5b301" />
        </g>
        {/* işaret direkleri */}
        <rect x="96" y="150" width="5" height="66" rx="2" fill="rgba(255,255,255,0.35)" />
        <rect x="330" y="150" width="5" height="66" rx="2" fill="rgba(255,255,255,0.35)" />
      </svg>
      {/* İşaretler foreignObject yerine üstte overlay (SVG içi bileşen sınırı için) */}
      <div className="hero-art__signs">
        <span className="hero-sign hero-sign--a">
          <TrafficSign shape="octagon" label="DUR" size={62} />
        </span>
        <span className="hero-sign hero-sign--b">
          <TrafficSign shape="ring" glyphText="50" label="Azami hız 50" size={54} />
        </span>
        <span className="hero-sign hero-sign--c">
          <TrafficSign shape="triangle" glyph="pedestrian" label="Yaya geçidi" size={56} />
        </span>
      </div>
    </div>
  );
}
