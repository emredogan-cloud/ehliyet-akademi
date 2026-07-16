/**
 * Soru benzerlik taraması (Program 2 · Faz 9). Bank genelinde soru köklerini
 * normalize edip token-küme Jaccard benzerliği > eşik olan çiftleri raporlar.
 * Kullanım: node scripts/content/similarity-check.mjs [--threshold 0.8]
 * Çıkış kodu 1 = şüpheli çift var (CI'da bilgilendirici; kapı testleri ayrı).
 */
import { readFileSync, readdirSync } from 'node:fs';
import { resolve, join } from 'node:path';

const DIR = resolve(import.meta.dirname, '../../packages/question-bank/src');
const args = process.argv.slice(2);
const ti = args.indexOf('--threshold');
const THRESHOLD = ti >= 0 ? Number(args[ti + 1]) : 0.8;

const stems = [];
for (const f of readdirSync(DIR).filter((f) => f.startsWith('questions') && f.endsWith('.ts'))) {
  const src = readFileSync(join(DIR, f), 'utf8');
  const re = /id: '([a-z0-9-]+)',[\s\S]*?stem: ?\n?\s*'((?:[^'\\]|\\.)*)'/g;
  let m;
  while ((m = re.exec(src))) stems.push({ id: m[1], stem: m[2], file: f });
}

function tokens(s) {
  return new Set(
    s
      .toLocaleLowerCase('tr')
      .replace(/[çğıöşü]/g, (c) => ({ ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u' })[c] ?? c)
      .replace(/[^a-z0-9 ]/g, ' ')
      .split(/\s+/)
      .filter((t) => t.length >= 3)
  );
}

const toks = stems.map((s) => tokens(s.stem));
const flagged = [];
for (let i = 0; i < stems.length; i++) {
  for (let j = i + 1; j < stems.length; j++) {
    const a = toks[i];
    const b = toks[j];
    if (a.size === 0 || b.size === 0) continue;
    let inter = 0;
    for (const t of a) if (b.has(t)) inter++;
    const jac = inter / (a.size + b.size - inter);
    if (jac >= THRESHOLD) flagged.push({ a: stems[i], b: stems[j], jac: jac.toFixed(2) });
  }
}

console.log(`tarandı: ${stems.length} soru kökü · eşik ${THRESHOLD}`);
if (flagged.length === 0) {
  console.log('✓ şüpheli benzer çift yok');
  process.exit(0);
}
for (const f of flagged.slice(0, 30)) {
  console.log(`⚠ ${f.jac} ${f.a.id} (${f.a.file}) ~ ${f.b.id} (${f.b.file})`);
  console.log(`   A: ${f.a.stem.slice(0, 90)}`);
  console.log(`   B: ${f.b.stem.slice(0, 90)}`);
}
console.log(`toplam şüpheli çift: ${flagged.length}`);
process.exit(1);
