/**
 * Çizgi ikon seti (Program 3 · Faz D) — elde çizilmiş SVG, API değil.
 * Referans: new-image/003-panel kenar çubuğu + top bar line-icon dili.
 * Tümü currentColor ile boyanır → muted/teal-aktif durumu otomatik miras alır.
 * Emoji placeholder'ların yerini alır (ASSET_GENERATION_PLAN A5).
 */
import type { ReactElement, SVGProps } from 'react';

export type IconName =
  | 'home'
  | 'layers'
  | 'sign'
  | 'car'
  | 'play'
  | 'clipboard'
  | 'brain'
  | 'image'
  | 'map'
  | 'timer'
  | 'target'
  | 'bot'
  | 'trending'
  | 'gauge'
  | 'calendar'
  | 'trophy'
  | 'search'
  | 'login'
  | 'user'
  | 'star'
  | 'gear'
  | 'shield'
  | 'bell'
  | 'crown'
  | 'chevron-right'
  | 'chevron-down'
  | 'tools'
  | 'sun'
  | 'moon'
  | 'trafficlight'
  | 'firstaid'
  | 'road'
  | 'flame';

/* Her ikon: 24×24 viewBox, stroke tabanlı, currentColor. */
const PATHS: Record<IconName, ReactElement> = {
  home: (
    <>
      <path d="M4 11 12 4l8 7" />
      <path d="M6 10v9a1 1 0 0 0 1 1h10a1 1 0 0 0 1-1v-9" />
      <path d="M10 20v-5h4v5" />
    </>
  ),
  layers: (
    <>
      <path d="M12 3 3 8l9 5 9-5-9-5Z" />
      <path d="m3 13 9 5 9-5" />
      <path d="m3 18 9 5 9-5" opacity="0.5" />
    </>
  ),
  sign: (
    <>
      <path d="M12 3 2.5 20h19L12 3Z" />
      <path d="M12 10v4" />
      <circle cx="12" cy="17" r="0.6" fill="currentColor" stroke="none" />
    </>
  ),
  car: (
    <>
      <path d="M4 13l1.6-4.2A2 2 0 0 1 7.5 7.5h9a2 2 0 0 1 1.9 1.3L20 13" />
      <path d="M3 13h18v4a1 1 0 0 1-1 1h-1a1 1 0 0 1-1-1v-1H6v1a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-4Z" />
      <circle cx="7" cy="15.5" r="0.7" fill="currentColor" stroke="none" />
      <circle cx="17" cy="15.5" r="0.7" fill="currentColor" stroke="none" />
    </>
  ),
  play: (
    <>
      <rect x="3" y="5" width="18" height="14" rx="2.5" />
      <path d="M10 9.5v5l4-2.5-4-2.5Z" fill="currentColor" stroke="none" />
    </>
  ),
  clipboard: (
    <>
      <rect x="5" y="4" width="14" height="17" rx="2" />
      <path d="M9 4a3 3 0 0 1 6 0" />
      <path d="m8.5 13 2.2 2.2L15 11" />
    </>
  ),
  brain: (
    <>
      <path d="M9 4a2.5 2.5 0 0 0-2.5 2.5A2.5 2.5 0 0 0 5 11a2.5 2.5 0 0 0 1.5 4A2.5 2.5 0 0 0 9 18a2 2 0 0 0 3-1.7V6a2 2 0 0 0-3-2Z" />
      <path d="M15 4a2.5 2.5 0 0 1 2.5 2.5A2.5 2.5 0 0 1 19 11a2.5 2.5 0 0 1-1.5 4A2.5 2.5 0 0 1 15 18a2 2 0 0 1-3-1.7" />
    </>
  ),
  image: (
    <>
      <rect x="3" y="4" width="18" height="16" rx="2.5" />
      <circle cx="8.5" cy="9.5" r="1.5" />
      <path d="m4 17 5-4.5 4 3.5 3-2.5 4 3.5" />
    </>
  ),
  map: (
    <>
      <path d="m9 4-6 2.5v13L9 17l6 3 6-2.5v-13L15 7 9 4Z" />
      <path d="M9 4v13" />
      <path d="M15 7v13" />
    </>
  ),
  timer: (
    <>
      <circle cx="12" cy="14" r="7" />
      <path d="M12 14V9.5" />
      <path d="M9.5 2.5h5" />
      <path d="m18.5 8 1.3-1.3" />
    </>
  ),
  target: (
    <>
      <circle cx="12" cy="12" r="8" />
      <circle cx="12" cy="12" r="4.5" />
      <circle cx="12" cy="12" r="1" fill="currentColor" stroke="none" />
    </>
  ),
  bot: (
    <>
      <rect x="4.5" y="8" width="15" height="11" rx="3" />
      <path d="M12 8V4.5" />
      <circle cx="12" cy="3.5" r="1.2" />
      <circle cx="9.5" cy="13" r="0.9" fill="currentColor" stroke="none" />
      <circle cx="14.5" cy="13" r="0.9" fill="currentColor" stroke="none" />
      <path d="M2.5 12v3M21.5 12v3" />
    </>
  ),
  trending: (
    <>
      <path d="m3 16 5-5 4 4 8.5-8.5" />
      <path d="M16 6h4.5v4.5" />
    </>
  ),
  gauge: (
    <>
      <path d="M4 18a8 8 0 1 1 16 0" />
      <path d="m12 14 4-4" />
      <circle cx="12" cy="14" r="1.2" fill="currentColor" stroke="none" />
    </>
  ),
  calendar: (
    <>
      <rect x="4" y="5" width="16" height="16" rx="2.5" />
      <path d="M4 9.5h16M8.5 3v4M15.5 3v4" />
      <circle cx="9" cy="14" r="0.8" fill="currentColor" stroke="none" />
      <circle cx="13" cy="14" r="0.8" fill="currentColor" stroke="none" />
    </>
  ),
  trophy: (
    <>
      <path d="M7 4h10v4a5 5 0 0 1-10 0V4Z" />
      <path d="M17 5h3v2a3 3 0 0 1-3 3M7 5H4v2a3 3 0 0 0 3 3" />
      <path d="M12 13v4M9 20h6M10 20v-1.5a2 2 0 0 1 4 0V20" />
    </>
  ),
  search: (
    <>
      <circle cx="11" cy="11" r="6.5" />
      <path d="m16 16 4.5 4.5" />
    </>
  ),
  login: (
    <>
      <path d="M14 4h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-4" />
      <path d="M3 12h11" />
      <path d="m10 8 4 4-4 4" />
    </>
  ),
  user: (
    <>
      <circle cx="12" cy="8.5" r="3.8" />
      <path d="M5 20a7 7 0 0 1 14 0" />
    </>
  ),
  star: (
    <path d="m12 3.5 2.6 5.3 5.8.8-4.2 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8L3.6 9.6l5.8-.8L12 3.5Z" />
  ),
  gear: (
    <>
      <circle cx="12" cy="12" r="3" />
      <path d="M12 2.5v3M12 18.5v3M21.5 12h-3M5.5 12h-3M18.7 5.3l-2.1 2.1M7.4 16.6l-2.1 2.1M18.7 18.7l-2.1-2.1M7.4 7.4 5.3 5.3" />
    </>
  ),
  shield: (
    <>
      <path d="M12 3 5 6v5c0 4.5 3 7.6 7 9 4-1.4 7-4.5 7-9V6l-7-3Z" />
      <path d="m9 12 2 2 4-4" />
    </>
  ),
  bell: (
    <>
      <path d="M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6Z" />
      <path d="M10 19a2 2 0 0 0 4 0" />
    </>
  ),
  crown: (
    <>
      <path d="M3 8l3.5 3L12 5l5.5 6L21 8l-1.5 10h-15L3 8Z" />
      <path d="M4.5 18h15" />
    </>
  ),
  'chevron-right': <path d="m9 6 6 6-6 6" />,
  'chevron-down': <path d="m6 9 6 6 6-6" />,
  tools: (
    <>
      <path d="M14.5 5.5a3.5 3.5 0 0 0-4.7 4.3L4 15.6 8.4 20l5.8-5.8a3.5 3.5 0 0 0 4.3-4.7l-2.3 2.3-2-2 2.3-2.3Z" />
    </>
  ),
  sun: (
    <>
      <circle cx="12" cy="12" r="4" />
      <path d="M12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M5.1 5.1l1.8 1.8M17.1 17.1l1.8 1.8M18.9 5.1l-1.8 1.8M6.9 17.1l-1.8 1.8" />
    </>
  ),
  moon: <path d="M20 13.5A8 8 0 1 1 10.5 4a6.5 6.5 0 0 0 9.5 9.5Z" />,
  trafficlight: (
    <>
      <rect x="8" y="2.5" width="8" height="19" rx="4" />
      <circle cx="12" cy="7" r="1.4" fill="currentColor" stroke="none" />
      <circle cx="12" cy="12" r="1.4" fill="currentColor" stroke="none" />
      <circle cx="12" cy="17" r="1.4" fill="currentColor" stroke="none" />
    </>
  ),
  firstaid: (
    <>
      <rect x="3.5" y="5.5" width="17" height="13" rx="3" />
      <path d="M12 9v6M9 12h6" />
    </>
  ),
  road: (
    <>
      <path d="M7 3 3 21M17 3l4 18" />
      <path d="M12 4v2M12 10v3M12 17v3" />
    </>
  ),
  flame: (
    <path d="M12 3s5 4 5 8.5A5 5 0 0 1 7 12c0-1.5.6-2.8 1.4-3.7C8.9 9.5 10 10 10 11c1-.5 1.5-2 1-3.5-.4-1.4.3-3.2 1-4.5Z" />
  ),
};

export function Icon({
  name,
  size = 22,
  strokeWidth = 1.7,
  ...rest
}: { name: IconName; size?: number; strokeWidth?: number } & Omit<
  SVGProps<SVGSVGElement>,
  'name' | 'width' | 'height'
>) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
      {...rest}
    >
      {PATHS[name]}
    </svg>
  );
}
