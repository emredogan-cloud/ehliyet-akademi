#!/usr/bin/env node
/**
 * Bankanın TAMAMINI tek JSON dosyasına döker — Ürün Evrimi v1.2 · Faz 1.
 *
 * NEDEN VAR: `quality-worklist.mjs` her çağrıda vitest'i ayağa kaldırıyor (~40 sn). Kalan 907
 * sorunun şıkları elden geçirilirken bu, her turda kaybedilen dakikalar demek. Döküm bir kez
 * alınır, sonrasında ölçüm ve süzme saf JSON üzerinde saniyeler içinde yapılır.
 *
 * kullanım: dump-bank.mjs [çıktı.json]
 */
import { execFileSync } from 'node:child_process';
import { writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';

const out = process.argv[2] ?? join(process.cwd(), 'bank-dump.json');
const pkg = join(process.cwd(), 'packages/question-bank');
const probe = join(pkg, 'src', '_dump.test.ts');

writeFileSync(
  probe,
  `import { test } from 'vitest';
import { writeFileSync } from 'node:fs';
import { allQuestions } from './index';
test('dump', () => {
  writeFileSync(${JSON.stringify(out)}, JSON.stringify(allQuestions()));
});
`
);
try {
  execFileSync('npx', ['vitest', 'run', 'src/_dump.test.ts', '--reporter=dot'], {
    stdio: 'pipe',
    cwd: pkg,
  });
} finally {
  rmSync(probe, { force: true });
}
console.log(`döküldü → ${out}`);
