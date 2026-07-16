/**
 * Animasyon sahnesi → MP4 video üretim hattı (Program 2 · Faz 4 · ADR-013).
 * ADR-012 sahnelerinin bire bir kopyası standalone HTML'e gömülür; Web Animations API ile
 * kare kare dondurulup (currentTime) Playwright ile ekran görüntüsü alınır; ffmpeg birleştirir.
 *
 * Kullanım: node apps/web/scripts/render-video.mjs [--only parallel-park] [--fps 12]
 * Çıktı:   apps/web/public/videos/<id>.mp4 + <id>-poster.jpg
 * Not: Sahne markup'ı components/anim/scenes.tsx + globals.css keyframe'lerinin kopyasıdır;
 *      sahneler değişirse burası da güncellenmelidir (test: videolar diskte + boyut makul).
 */
import { mkdirSync, rmSync, existsSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { resolve, join } from 'node:path';
import { chromium } from '@playwright/test';

const ROOT = resolve(import.meta.dirname, '..');
const OUT = join(ROOT, 'public', 'videos');
const args = process.argv.slice(2);
const opt = (n, d) => {
  const i = args.indexOf(`--${n}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : d;
};
const ONLY = opt('only', '');
const FPS = Number(opt('fps', '12'));

const CAR = (body, roof = 'rgba(255,255,255,0.35)') => `
  <g><rect x="-11" y="-22" width="22" height="44" rx="6" fill="${body}"/>
  <rect x="-8" y="-12" width="16" height="12" rx="3" fill="${roof}"/>
  <rect x="-8" y="4" width="16" height="9" rx="3" fill="${roof}" opacity="0.7"/></g>`;

const SCENES = {
  'parallel-park': {
    duration: 9,
    svg: `<svg viewBox="0 0 420 240" width="840" height="480" xmlns="http://www.w3.org/2000/svg">
      <rect width="420" height="240" fill="#2c3b33"/>
      <rect y="60" width="420" height="150" fill="#3a4149"/>
      <rect y="206" width="420" height="10" fill="#5b6570"/>
      <rect y="54" width="420" height="6" fill="#5b6570"/>
      ${[0, 60, 120, 180, 240, 300, 360].map((x) => `<rect x="${x}" y="128" width="30" height="4" rx="2" fill="rgba(255,255,255,0.75)" opacity="0.5"/>`).join('')}
      <g transform="translate(80 182) rotate(90)">${CAR('#9aa4ae')}</g>
      <g transform="translate(330 182) rotate(90)">${CAR('#9aa4ae')}</g>
      <rect x="140" y="164" width="150" height="38" rx="8" fill="none" stroke="rgba(255,255,255,0.75)" stroke-dasharray="6 6" opacity="0.55"/>
      <g class="anim-car anim-parallel">${CAR('#12b8a6')}</g>
    </svg>`,
    css: `@keyframes kf-parallel {
      0% { transform: translate(-30px, 96px) rotate(90deg); }
      30% { transform: translate(300px, 96px) rotate(90deg); }
      38% { transform: translate(300px, 96px) rotate(90deg); }
      60% { transform: translate(250px, 148px) rotate(66deg); }
      82% { transform: translate(216px, 178px) rotate(86deg); }
      92%, 100% { transform: translate(213px, 182px) rotate(90deg); }
    }
    .anim-parallel { animation: kf-parallel 9s ease-in-out infinite; }`,
  },
  'right-of-way': {
    duration: 8,
    svg: `<svg viewBox="0 0 420 240" width="840" height="480" xmlns="http://www.w3.org/2000/svg">
      <rect width="420" height="240" fill="#2c3b33"/>
      <rect y="85" width="420" height="70" fill="#3a4149"/>
      <rect x="175" width="70" height="240" fill="#3a4149"/>
      ${[10, 60, 110, 300, 350, 400].map((x) => `<rect x="${x}" y="118" width="26" height="4" rx="2" fill="rgba(255,255,255,0.75)" opacity="0.5"/>`).join('')}
      ${[10, 50, 190, 230].map((y) => `<rect x="208" y="${y}" width="4" height="22" rx="2" fill="rgba(255,255,255,0.75)" opacity="0.5"/>`).join('')}
      <rect x="150" y="90" width="5" height="60" fill="rgba(255,255,255,0.75)" opacity="0.8"/>
      <g class="anim-car anim-row-other">${CAR('#f5b301', 'rgba(0,0,0,0.25)')}</g>
      <g class="anim-car anim-row-ego">${CAR('#12b8a6')}</g>
    </svg>`,
    css: `@keyframes kf-row-ego {
      0% { transform: translate(-30px, 137px) rotate(90deg); }
      28% { transform: translate(128px, 137px) rotate(90deg); }
      62% { transform: translate(128px, 137px) rotate(90deg); }
      100% { transform: translate(460px, 137px) rotate(90deg); }
    }
    @keyframes kf-row-other {
      0% { transform: translate(228px, 280px) rotate(0deg); }
      15% { transform: translate(228px, 245px) rotate(0deg); }
      60% { transform: translate(228px, -60px) rotate(0deg); }
      100% { transform: translate(228px, -60px) rotate(0deg); }
    }
    .anim-row-ego { animation: kf-row-ego 8s ease-in-out infinite; }
    .anim-row-other { animation: kf-row-other 8s ease-in-out infinite; }`,
  },
};

mkdirSync(OUT, { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 840, height: 480 }, deviceScaleFactor: 1 });

for (const [id, scene] of Object.entries(SCENES)) {
  if (ONLY && ONLY !== id) continue;
  const frames = Math.round(scene.duration * FPS);
  const tmp = join(OUT, `.frames-${id}`);
  rmSync(tmp, { recursive: true, force: true });
  mkdirSync(tmp, { recursive: true });

  const html = `<!doctype html><meta charset="utf-8"><style>
    html,body{margin:0;background:#0b1214}${scene.css}
  </style>${scene.svg}`;
  await page.setContent(html);

  for (let f = 0; f < frames; f++) {
    const tMs = (f / FPS) * 1000;
    await page.evaluate((t) => {
      for (const a of document.getAnimations()) {
        a.pause();
        a.currentTime = t;
      }
    }, tMs);
    await page.screenshot({ path: join(tmp, `${String(f).padStart(3, '0')}.png`) });
  }
  execSync(
    `ffmpeg -y -framerate ${FPS} -i "${tmp}/%03d.png" -c:v libx264 -pix_fmt yuv420p -crf 27 -movflags +faststart "${join(OUT, `${id}.mp4`)}"`,
    { stdio: 'pipe' }
  );
  // WebM (VP9): açık kodek — Playwright Chromium'da da oynar (H.264 lisanslı kodek içermez)
  execSync(
    `ffmpeg -y -framerate ${FPS} -i "${tmp}/%03d.png" -c:v libvpx-vp9 -b:v 0 -crf 40 "${join(OUT, `${id}.webm`)}"`,
    { stdio: 'pipe' }
  );
  // Poster: manevranın bilgilendirici ânı (~%60)
  execSync(
    `ffmpeg -y -i "${join(OUT, `${id}.mp4`)}" -ss ${(scene.duration * 0.6).toFixed(1)} -frames:v 1 -q:v 4 "${join(OUT, `${id}-poster.jpg`)}"`,
    { stdio: 'pipe' }
  );
  rmSync(tmp, { recursive: true, force: true });
  console.log(`✓ ${id}.mp4 (${frames} kare @ ${FPS}fps) + poster`);
}

await browser.close();
console.log(existsSync(join(OUT, 'parallel-park.mp4')) ? 'bitti' : 'çıktı eksik!');
