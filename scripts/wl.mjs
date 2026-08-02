#!/usr/bin/env node
/**
 * Dökülmüş banka üzerinde hızlı kalite süzgeci — `dump-bank.mjs` çıktısını okur.
 *
 * kullanım: wl.mjs <dump.json> [--subject X] [--limit N] [--offset N] [--stats] [--ids]
 */
import { readFileSync } from 'node:fs';

const args = process.argv.slice(2);
const file = args[0];
const opt = (n, d) => {
  const i = args.indexOf(`--${n}`);
  return i >= 0 ? args[i + 1] : d;
};
const weigh = (s) => s.trim().replace(/\s+/g, ' ').length;
const longestWins = (q) => {
  const l = q.options.map(weigh);
  const m = Math.max(...l);
  return l[q.answerIndex] === m && l.filter((x) => x === m).length === 1;
};
const ratio = (q) => {
  const l = q.options.map(weigh);
  const o = l.filter((_, i) => i !== q.answerIndex);
  return l[q.answerIndex] / Math.max(...o);
};

const bank = JSON.parse(readFileSync(file, 'utf8'));
const bad = bank.filter((q) => longestWins(q) || ratio(q) > 1.5);

if (args.includes('--stats')) {
  const n = bank.length;
  const lw = bank.filter(longestWins).length;
  const par = bank.filter((q) => ratio(q) <= 1.5).length;
  let ac = 0,
    dc = 0,
    dn = 0;
  const pos = [0, 0, 0, 0];
  for (const q of bank) {
    pos[q.answerIndex]++;
    q.options.forEach((o, i) =>
      i === q.answerIndex ? (ac += weigh(o)) : ((dc += weigh(o)), dn++)
    );
  }
  const bySub = {};
  for (const r of bad) bySub[r.subject] = (bySub[r.subject] ?? 0) + 1;
  console.log(`soru ${n} | "en uzun şıkkı seç" ${lw} (%${((lw / n) * 100).toFixed(1)})`);
  console.log(
    `paralel ${par} (%${((par / n) * 100).toFixed(1)}) | oran ${(ac / n / (dc / dn)).toFixed(2)}×`
  );
  console.log(`cevap konumu ${pos.join('/')} | kalan ${JSON.stringify(bySub)} = ${bad.length}`);
  process.exit(0);
}

const subject = opt('subject', null);
const picked = bad
  .filter((r) => !subject || r.subject === subject)
  .slice(Number(opt('offset', 0)), Number(opt('offset', 0)) + Number(opt('limit', 40)));

if (args.includes('--ids')) {
  console.log(picked.map((r) => r.id).join('\n'));
  process.exit(0);
}

for (const r of picked) {
  const a = r.options[r.answerIndex];
  const d = r.options.filter((_, i) => i !== r.answerIndex);
  console.log(`${r.id} [${r.topic}] ${r.stem}`);
  console.log(`  ✓(${weigh(a)}) ${a}`);
  d.forEach((o) => console.log(`  ✗(${weigh(o)}) ${o}`));
  console.log(`  → en az bir çeldirici ≥${weigh(a)} olmalı`);
}
console.log(`\n# ${picked.length} gösterildi / toplam kalan ${bad.length}`);
