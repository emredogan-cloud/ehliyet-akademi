#!/usr/bin/env node
/**
 * Şık yamalarını banka kaynağına uygular — Ürün Evrimi v1.1 · Faz 1.
 *
 * Yama biçimi (JSON):  { "<soru-id>": { "answer"?: "...", "distractors": ["...","...","..."] } }
 *
 * `answer` verilirse doğru şık da değişir (açıklama kuyruğu temizlenmiş hâli).
 * `distractors` doğru şık DIŞINDAKİ üç şıkkı, kaynaktaki sırayla değiştirir.
 *
 * Uygulama kaynak metin üzerinde yapılır (AST değil): şık dizeleri kaynakta tek satırlık
 * literaller olarak duruyor, dolayısıyla yorumlar ve biçim korunur.
 */
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const SRC = join(dirname(fileURLToPath(import.meta.url)), '..', 'packages', 'question-bank', 'src');
const patchPath = process.argv[2];
const dryRun = process.argv.includes('--check');
if (!patchPath) {
  console.error('kullanım: apply-option-patches.mjs <yama.json> [--check]');
  process.exit(1);
}
const patches = JSON.parse(readFileSync(patchPath, 'utf8'));

/**
 * Yama hedefe ulaşıyor mu? Kapının bağlayıcı ölçütü, doğru şıkkın TEK BAŞINA en uzun
 * OLMAMASI. Karakter saymayı göze bırakmak yanlış oluyor — makine saysın.
 */
function shortfall(answer, distractors) {
  const a = answer.trim().replace(/\s+/g, ' ').length;
  const ds = distractors.map((d) => d.trim().replace(/\s+/g, ' ').length);
  const maxD = Math.max(...ds);
  const problems = [];
  if (maxD < a)
    problems.push(`en uzun çeldirici ${maxD}, doğru şık ${a} — ${a - maxD} karakter eksik`);
  if (a / maxD > 1.5) problems.push(`oran ${(a / maxD).toFixed(2)}× (sınır 1,5)`);
  return problems;
}

const files = readdirSync(SRC).filter((f) => f.startsWith('questions') && f.endsWith('.ts'));
const text = new Map(files.map((f) => [f, readFileSync(join(SRC, f), 'utf8')]));

const lit = (s) => `'${s.replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;

let applied = 0;
const failed = [];

for (const [id, patch] of Object.entries(patches)) {
  const file = files.find((f) => text.get(f).includes(`id: '${id}'`));
  if (!file) {
    failed.push(`${id}: kaynak bulunamadı`);
    continue;
  }
  let body = text.get(file);

  // Sorunun `options: [ ... ]` bloğunu bul — id çapasından sonraki ilk options.
  const anchor = body.indexOf(`id: '${id}'`);
  const optStart = body.indexOf('options: [', anchor);
  const optEnd = body.indexOf('],', optStart);
  const aiMatch = body.slice(optEnd, optEnd + 200).match(/answerIndex: (\d+)/);
  if (optStart < 0 || optEnd < 0 || !aiMatch) {
    failed.push(`${id}: options/answerIndex ayrıştırılamadı`);
    continue;
  }
  const answerIndex = Number(aiMatch[1]);
  const block = body.slice(optStart, optEnd);
  // Şıklar tek satırda da (`options: ['a', 'b', ...]`) satır satır da yazılmış olabilir; ve
  // içinde kesme işareti geçen şık ÇİFT tırnaklıdır. İkisini de tanı.
  const items = [...block.matchAll(/'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*"/g)]
    .map((m) => m[0])
    .filter((s) => s !== "'options'");
  if (items.length !== 4) {
    failed.push(`${id}: ${items.length} şık bulundu (4 bekleniyordu)`);
    continue;
  }

  // Doğru şık: yama vermişse yeni hâli, vermemişse kaynaktakinin tırnaksız hâli.
  const unlit = (s) => s.slice(1, -1).replace(/\\(['"\\])/g, '$1');
  const answer = patch.answer ?? unlit(items[answerIndex]);
  // Çeldiricilerde `null` = "bu şıkkı olduğu gibi bırak". Çoğu soruda tek bir çeldiriciyi
  // uzatmak yetiyor; üçünü birden yazdırmak gereksiz.
  const existing = items.filter((_, i) => i !== answerIndex).map(unlit);
  const distractors = patch.distractors.map((d, i) => d ?? existing[i]);
  const problems = shortfall(answer, distractors);
  if (problems.length) {
    failed.push(`${id}: ${problems.join(' | ')}`);
    if (dryRun) continue;
  }
  if (dryRun) continue;

  const next = items.slice();
  if (patch.answer) next[answerIndex] = lit(patch.answer);
  let d = 0;
  for (let i = 0; i < 4; i++) if (i !== answerIndex) next[i] = lit(distractors[d++]);

  let newBlock = block;
  for (let i = 0; i < 4; i++) {
    if (next[i] === items[i]) continue;
    // Aynı literal blokta birden fazla geçebilir; sıralı ilerlemek için tek tek değiştir.
    const at = newBlock.indexOf(items[i]);
    if (at < 0) {
      failed.push(`${id}: ${i}. şık literali kayboldu`);
      continue;
    }
    newBlock = newBlock.slice(0, at) + next[i] + newBlock.slice(at + items[i].length);
  }

  text.set(file, body.slice(0, optStart) + newBlock + body.slice(optEnd));
  applied++;
}

if (!dryRun) for (const [f, body] of text) writeFileSync(join(SRC, f), body, 'utf8');

console.log(
  dryRun
    ? `denetlendi: ${Object.keys(patches).length}`
    : `uygulanan: ${applied} / ${Object.keys(patches).length}`
);
if (failed.length) {
  console.log('BAŞARISIZ:');
  failed.forEach((f) => console.log('  ', f));
  process.exit(1);
}
