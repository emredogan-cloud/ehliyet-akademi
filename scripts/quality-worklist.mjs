#!/usr/bin/env node
/**
 * Kalite kapısını geçemeyen soruları, YAZIM TALİMATIYLA birlikte listeler.
 * Ürün Evrimi v1.1 · Faz 1.
 *
 * kullanım: quality-worklist.mjs [--subject motor] [--limit 60] [--offset 0] [--stats]
 *
 * Kapının bağlayıcı ölçütü `longestWinsRate`: doğru şık TEK BAŞINA en uzunsa soru, okunmadan
 * bilinebiliyor demektir. Bu yüzden talimat her zaman "en az bir çeldirici doğru şık kadar
 * uzun olsun" der — gerçek sınavlarda da ayrıntılı ama yanlış bir şık bulunur.
 */
import { execFileSync } from 'node:child_process';
import { writeFileSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const args = process.argv.slice(2);
const opt = (name, def) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : def;
};
const subject = opt('subject', null);
const limit = Number(opt('limit', 60));
const offset = Number(opt('offset', 0));
const stats = args.includes('--stats');

// Vitest kendi kökü dışındaki dosyayı çalıştırmaz; sonda silinen geçici bir dosya paket içine yazılır.
const pkg = join(process.cwd(), 'packages/question-bank');
const dir = mkdtempSync(join(tmpdir(), 'ea-wl-'));
const probe = join(pkg, 'src', '_probe.test.ts');
writeFileSync(
  probe,
  `import { test } from 'vitest';
import { writeFileSync } from 'node:fs';
import { answerLengthRatio, longestOptionWins, measureBank } from '@ea/content-schema';
import { allQuestions } from './index';
test('probe', () => {
  const bank = allQuestions();
  const rows = bank
    .filter((q) => longestOptionWins(q) || answerLengthRatio(q) > 1.5)
    .map((q) => ({ id: q.id, subject: q.subject, topic: q.topic, stem: q.stem,
      options: q.options, answerIndex: q.answerIndex,
      ratio: +answerLengthRatio(q).toFixed(2), longest: longestOptionWins(q) }));
  writeFileSync(${JSON.stringify(join(dir, 'out.json'))},
    JSON.stringify({ report: measureBank(bank), rows }));
});
`
);
try {
  execFileSync('npx', ['vitest', 'run', 'src/_probe.test.ts', '--reporter=dot'], {
    stdio: 'pipe',
    cwd: pkg,
  });
} finally {
  rmSync(probe, { force: true });
}
const { report, rows } = JSON.parse(readFileSync(join(dir, 'out.json'), 'utf8'));

if (stats) {
  const pct = (x) => `%${(x * 100).toFixed(1)}`;
  console.log(
    `soru ${report.total} | "en uzun şıkkı seç" ${report.longestWins} (${pct(report.longestWinsRate)})`
  );
  console.log(
    `paralel ${report.parallel} (${pct(report.parallelRate)}) | oran ${report.lengthRatio.toFixed(2)}×`
  );
  const bySub = {};
  for (const r of rows) bySub[r.subject] = (bySub[r.subject] ?? 0) + 1;
  console.log('kalan:', JSON.stringify(bySub), '=', rows.length);
  process.exit(0);
}

const picked = rows.filter((r) => !subject || r.subject === subject).slice(offset, offset + limit);
for (const r of picked) {
  const a = r.options[r.answerIndex];
  const d = r.options.filter((_, i) => i !== r.answerIndex);
  const need = [];
  if (r.longest) need.push(`≥${a.length} uzunlukta EN AZ BİR çeldirici`);
  if (r.ratio > 1.5) need.push(`en uzun çeldirici ≥${Math.ceil(a.length / 1.5)}`);
  console.log(`${r.id} | ${r.stem}`);
  console.log(`  ✓${a.length}: ${a}`);
  console.log(`  ✗: ${d.map((o) => `(${o.length}) ${o}`).join(' // ')}`);
  console.log(`  → ${need.join(' + ')}`);
}
console.log(`\n# ${picked.length} soru gösterildi (toplam kalan ${rows.length})`);
