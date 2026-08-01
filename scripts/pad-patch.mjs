#!/usr/bin/env node
/**
 * Yamadaki KISA KALAN çeldiricileri bulur ve gereken uzunluğu bildirir.
 *
 * NEDEN VAR: `apply-option-patches.mjs --check` "3 karakter eksik" der ama hangi metni ne kadar
 * uzatacağını söylemez; her turda tek tek elle düzeltmek dakikalar yiyor. Bu betik, dökülmüş
 * banka üzerinden HER yama için hedef uzunluğu ve mevcut en uzun çeldiriciyi yazar; yazar
 * metni bir kerede yeterli uzunlukta kurar.
 *
 * kullanım: pad-patch.mjs <bank-dump.json> <yama.json>
 */
import { readFileSync } from 'node:fs';

const [dump, patchPath] = process.argv.slice(2);
if (!dump || !patchPath) {
  console.error('kullanım: pad-patch.mjs <bank-dump.json> <yama.json>');
  process.exit(1);
}
const bank = JSON.parse(readFileSync(dump, 'utf8'));
const patches = JSON.parse(readFileSync(patchPath, 'utf8'));
const byId = new Map(bank.map((q) => [q.id, q]));
const w = (s) => s.trim().replace(/\s+/g, ' ').length;

let short = 0;
for (const [id, patch] of Object.entries(patches)) {
  const q = byId.get(id);
  if (!q) {
    console.log(`${id}: bankada yok`);
    continue;
  }
  const answer = patch.answer ?? q.options[q.answerIndex];
  const existing = q.options.filter((_, i) => i !== q.answerIndex);
  const ds = (patch.distractors ?? [null, null, null]).map((d, i) => d ?? existing[i]);
  const need = w(answer);
  const have = Math.max(...ds.map(w));
  if (have >= need) continue;
  short++;
  const idx = ds.indexOf(ds.reduce((a, b) => (w(a) >= w(b) ? a : b)));
  console.log(
    `${id}: hedef ≥${need}, en uzun ${have} (eksik ${need - have}) → çeldirici[${idx}]: "${ds[idx]}"`
  );
}
console.log(short === 0 ? 'hepsi yeterli uzunlukta' : `${short} yama kısa kaldı`);
