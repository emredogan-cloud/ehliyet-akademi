/**
 * Program 2 · Faz 1 — Premium görsel üretim hattı.
 * Katalogdaki her varlık için OpenAI Images API (gpt-image-1) ile fotogerçekçi
 * eğitim görseli üretir; WebP olarak apps/web/public/assets/vehicle/ altına yazar.
 *
 * Kullanım:
 *   node scripts/assets/generate.mjs [--only id1,id2] [--force] [--quality high|medium|low] [--dry]
 *
 * Sır güvenliği: OPENAI_API_KEY .env / .env.local / ortamdan okunur; asla loglanmaz.
 */
import { readFileSync, writeFileSync, mkdirSync, existsSync, statSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { ASSETS, OUT_DIR, SIZE } from './catalog.mjs';

const ROOT = resolve(import.meta.dirname, '../..');

function loadKey() {
  if (process.env.OPENAI_API_KEY) return process.env.OPENAI_API_KEY;
  for (const f of ['.env', '.env.local']) {
    const p = join(ROOT, f);
    if (!existsSync(p)) continue;
    const m = readFileSync(p, 'utf8').match(/^OPENAI_API_KEY=(.+)$/m);
    if (m) return m[1].trim().replace(/^["']|["']$/g, '');
  }
  throw new Error('OPENAI_API_KEY bulunamadı (.env / .env.local / ortam)');
}

const args = process.argv.slice(2);
const flag = (n) => args.includes(`--${n}`);
const opt = (n, d) => {
  const i = args.indexOf(`--${n}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : d;
};

const ONLY = opt('only', '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);
const QUALITY = opt('quality', 'high');
const FORCE = flag('force');
const DRY = flag('dry');
const CONCURRENCY = Number(opt('concurrency', '3'));

const KEY = DRY ? '' : loadKey();
const outDir = join(ROOT, OUT_DIR);
mkdirSync(outDir, { recursive: true });

const queue = ASSETS.filter((a) => (ONLY.length ? ONLY.includes(a.id) : true)).filter((a) => {
  const f = join(outDir, `${a.id}.webp`);
  if (!FORCE && existsSync(f) && statSync(f).size > 10_000) {
    console.log(`atla (mevcut): ${a.id}`);
    return false;
  }
  return true;
});

console.log(
  `üretilecek: ${queue.length} varlık · kalite=${QUALITY} · boyut=${SIZE}${DRY ? ' · DRY RUN' : ''}`
);
if (DRY) {
  for (const a of queue) console.log(`- ${a.id}: ${a.prompt.slice(0, 90)}…`);
  process.exit(0);
}

async function generateOne(asset, attempt = 1) {
  const res = await fetch('https://api.openai.com/v1/images/generations', {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${KEY}` },
    body: JSON.stringify({
      model: 'gpt-image-1',
      prompt: asset.prompt,
      size: SIZE,
      quality: QUALITY,
      output_format: 'webp',
      output_compression: 85,
      n: 1,
    }),
  });
  if (!res.ok) {
    const body = await res.text();
    const retryable = res.status === 429 || res.status >= 500;
    if (retryable && attempt <= 4) {
      const wait = attempt * 15_000;
      console.warn(
        `  ${asset.id}: HTTP ${res.status}, ${wait / 1000}s sonra tekrar (deneme ${attempt})`
      );
      await new Promise((r) => setTimeout(r, wait));
      return generateOne(asset, attempt + 1);
    }
    throw new Error(`${asset.id}: HTTP ${res.status} — ${body.slice(0, 300)}`);
  }
  const json = await res.json();
  const b64 = json.data?.[0]?.b64_json;
  if (!b64) throw new Error(`${asset.id}: yanıt b64_json içermiyor`);
  const buf = Buffer.from(b64, 'base64');
  const file = join(outDir, `${asset.id}.webp`);
  writeFileSync(file, buf);
  console.log(`✓ ${asset.id}.webp (${Math.round(buf.length / 1024)} KB)`);
}

let failed = 0;
const pending = [...queue];
async function worker(n) {
  while (pending.length) {
    const asset = pending.shift();
    if (!asset) break;
    try {
      await generateOne(asset);
    } catch (e) {
      failed++;
      console.error(`✗ ${e.message}`);
    }
  }
}
await Promise.all(Array.from({ length: Math.min(CONCURRENCY, queue.length) }, (_, i) => worker(i)));
console.log(`bitti: ${queue.length - failed} başarılı, ${failed} hatalı`);
process.exit(failed ? 1 : 0);
