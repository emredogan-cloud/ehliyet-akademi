/**
 * Animasyon sahnesi → premium video üretim hattı (Evolution Faz E12; ADR-013'ün devamı).
 *
 * E12 YÜKSELTMELERİ:
 *  - Çözünürlük 840×480 → **1120×640**, kare hızı 12 → **30 fps** (akıcı hareket).
 *  - Sahneler tasarım token'larının renkleriyle çizilir; araçlarda tekerlek/cam/far ayrıntısı var.
 *  - **Adım etiketleri** videonun içine gömülür ve bölümlerle aynı anda değişir.
 *  - Bölüm ve altyazı verisi sahneyle AYNI kaynaktan gelir (`video-scenes.mjs`) → hat ile içerik
 *    arasında sapma YAPISAL OLARAK imkânsız (roadmap'in E12 için işaretlediği risk buydu).
 *  - Çıktılar: `<id>.mp4`, `<id>.webm`, `<id>-poster.jpg`, `<id>.tr.vtt` ve
 *    `content/videos.generated.ts` (süre + bölüm + transkript).
 *
 * Kullanım: node apps/web/scripts/render-video.mjs [--only l-park] [--fps 30]
 */
/* global document */
import { mkdirSync, rmSync, existsSync, writeFileSync, statSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { resolve, join } from 'node:path';
import { chromium } from '@playwright/test';
import { SCENES } from './video-scenes.mjs';

const ROOT = resolve(import.meta.dirname, '..');
const OUT = join(ROOT, 'public', 'videos');
const args = process.argv.slice(2);
const opt = (n, d) => {
  const i = args.indexOf(`--${n}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : d;
};
const ONLY = opt('only', '');
const FPS = Number(opt('fps', '30'));
const W = 1120;
const H = 640;

/** Saniyeyi WebVTT damgasına çevirir (`mm:ss.mmm`). */
function vttStamp(seconds) {
  const ms = Math.round(seconds * 1000);
  const m = Math.floor(ms / 60000);
  const s = Math.floor((ms % 60000) / 1000);
  const rest = ms % 1000;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}.${String(rest).padStart(3, '0')}`;
}

/** Altyazı ipuçlarını WebVTT'ye çevirir; her ipucu bir sonrakine kadar sürer. */
function toVtt(captions, duration) {
  const lines = ['WEBVTT', ''];
  captions.forEach((c, i) => {
    const end = i + 1 < captions.length ? captions[i + 1].t : duration;
    lines.push(`${vttStamp(c.t)} --> ${vttStamp(end)}`, c.text, '');
  });
  return lines.join('\n');
}

mkdirSync(OUT, { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });

const produced = [];

for (const [id, scene] of Object.entries(SCENES)) {
  if (ONLY && ONLY !== id) continue;
  const frames = Math.round(scene.duration * FPS);
  const tmp = join(OUT, `.frames-${id}`);
  rmSync(tmp, { recursive: true, force: true });
  mkdirSync(tmp, { recursive: true });

  const svg = `<svg viewBox="0 0 560 320" width="${W}" height="${H}" xmlns="http://www.w3.org/2000/svg">
    ${scene.svg}
    ${scene.svgExtra}
  </svg>`;
  const html = `<!doctype html><meta charset="utf-8"><style>
    html,body{margin:0;background:#050b16}
    ${scene.css}
    ${scene.cssExtra}
  </style>${svg}`;
  await page.setContent(html);

  for (let f = 0; f < frames; f++) {
    const tMs = (f / FPS) * 1000;
    await page.evaluate((t) => {
      for (const a of document.getAnimations()) {
        a.pause();
        a.currentTime = t;
      }
    }, tMs);
    await page.screenshot({ path: join(tmp, `${String(f).padStart(4, '0')}.png`) });
  }

  // H.264: cihazlarda donanım hızlandırmalı. `-preset slow` + crf 26 → küçük dosya, temiz kenar.
  execSync(
    `ffmpeg -y -framerate ${FPS} -i "${tmp}/%04d.png" -c:v libx264 -preset slow -crf 26 ` +
      `-pix_fmt yuv420p -movflags +faststart "${join(OUT, `${id}.mp4`)}"`,
    { stdio: 'pipe' }
  );
  // WebM (VP9): açık kodek — Chromium H.264 lisanslı kodek içermeyebilir.
  execSync(
    `ffmpeg -y -framerate ${FPS} -i "${tmp}/%04d.png" -c:v libvpx-vp9 -b:v 0 -crf 38 -row-mt 1 ` +
      `"${join(OUT, `${id}.webm`)}"`,
    { stdio: 'pipe' }
  );
  // Poster: ikinci bölümün ortası — manevranın anlatan ânı (ilk kare çoğu sahnede boş yol).
  // Poster ânı: ikinci bölümün ortası. (`a + b ?? c` önceliği (a+b) ?? c olduğu için burada
  // açıkça yazılıyor — kısa yazım NaN üretiyordu.)
  const secondStart = scene.chapters[1]?.t;
  const thirdStart = scene.chapters[2]?.t ?? scene.duration;
  const posterAt =
    secondStart === undefined ? scene.duration * 0.5 : (secondStart + thirdStart) / 2;
  execSync(
    `ffmpeg -y -i "${join(OUT, `${id}.mp4`)}" -ss ${Number(posterAt).toFixed(2)} -frames:v 1 -q:v 3 ` +
      `"${join(OUT, `${id}-poster.jpg`)}"`,
    { stdio: 'pipe' }
  );

  writeFileSync(join(OUT, `${id}.tr.vtt`), toVtt(scene.captions, scene.duration), 'utf8');
  rmSync(tmp, { recursive: true, force: true });

  const mb = (p) => (statSync(join(OUT, p)).size / 1024).toFixed(0);
  produced.push({ id, scene });
  console.log(
    `✓ ${id}  ${frames} kare @ ${FPS}fps  ·  mp4 ${mb(`${id}.mp4`)} KB  ·  webm ${mb(`${id}.webm`)} KB  ·  poster ${mb(`${id}-poster.jpg`)} KB`
  );
}

await browser.close();

// ── İçerik verisi: bölüm + transkript tek kaynaktan üretilir ────────────────
if (!ONLY) {
  const entries = Object.entries(SCENES)
    .map(([id, s]) => {
      const chapters = s.chapters
        .map((c) => `      { t: ${c.t}, title: ${JSON.stringify(c.title)} },`)
        .join('\n');
      const transcript = s.captions
        .map((c) => `      { t: ${c.t}, text: ${JSON.stringify(c.text)} },`)
        .join('\n');
      return `  '${id}': {
    duration: ${s.duration},
    chapters: [
${chapters}
    ],
    transcript: [
${transcript}
    ],
  },`;
    })
    .join('\n');

  const file = `/**
 * ÜRETİLMİŞ DOSYA — elle düzenlemeyin.
 * Kaynak: \`scripts/video-scenes.mjs\` · Üretici: \`node scripts/render-video.mjs\`
 *
 * Bölüm ve transkript verisi videoyu çizen sahneyle AYNI nesneden türetilir; böylece video ile
 * katalog arasında sapma olamaz (Evolution Faz E12).
 */
import type { VideoChapter, TranscriptCue } from './videos';

export type GeneratedVideoData = {
  duration: number;
  chapters: VideoChapter[];
  transcript: TranscriptCue[];
};

export const GENERATED_VIDEOS: Record<string, GeneratedVideoData> = {
${entries}
};
`;
  writeFileSync(join(ROOT, 'content', 'videos.generated.ts'), file, 'utf8');
  console.log('✓ content/videos.generated.ts yazıldı');
}

console.log(existsSync(join(OUT, 'parallel-park.mp4')) ? 'bitti' : 'çıktı eksik!');
