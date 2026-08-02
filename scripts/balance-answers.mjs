#!/usr/bin/env node
/**
 * Cevap konumu dengeleyici — Premium Kalite Programı · Faz 1.
 *
 * NEDEN VAR: denetimde B şıkkı 459 kez doğruydu (beklenen ~391). "Emin değilsen B işaretle"
 * stratejisi %29,4 veriyordu; rastgele %25. Bu, uzunluk tellalığının kardeşi: soru okunmadan
 * kazanılan bir pay.
 *
 * NASIL: fazla temsil edilen konumdaki soruların doğru şıkkı, eksik temsil edilen konuma
 * TAŞINIR (şıklar yer değiştirir, `answerIndex` güncellenir). Metin değişmez, yalnız sıra
 * değişir — anlam ve kalite etkilenmez.
 *
 * BELİRLENİMCİ: hangi sorunun taşınacağı kimliğin karmasından türer; aynı banka → aynı sonuç.
 * Rastgelelik yok, çünkü yeniden çalıştırıldığında farklı sonuç veren bir araç denetlenemez.
 *
 * kullanım: balance-answers.mjs <bank-dump.json> [--apply]
 */
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const SRC = join(dirname(fileURLToPath(import.meta.url)), '..', 'packages', 'question-bank', 'src');
const dump = process.argv[2];
const apply = process.argv.includes('--apply');
if (!dump) {
  console.error('kullanım: balance-answers.mjs <bank-dump.json> [--apply]');
  process.exit(1);
}
const bank = JSON.parse(readFileSync(dump, 'utf8'));

/** Kimlikten türeyen kararlı sayı — sıralamayı belirlenimci kılar. */
function hash(s) {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

const target = bank.length / 4;
const buckets = [[], [], [], []];
for (const q of bank) buckets[q.answerIndex].push(q);
for (const b of buckets) b.sort((a, c) => hash(a.id) - hash(c.id));

console.log('önce :', buckets.map((b) => b.length).join(' / '), `(hedef ~${target.toFixed(0)})`);

// Fazlalıktan al, eksiğe ver. Her taşıma tam bir soruyu bir konumdan diğerine geçirir.
const moves = [];
for (let from = 0; from < 4; from++) {
  while (buckets[from].length > Math.ceil(target)) {
    const to = buckets.reduce((lo, b, i) => (b.length < buckets[lo].length ? i : lo), 0);
    if (buckets[to].length >= Math.floor(target)) break;
    const q = buckets[from].pop();
    moves.push({ id: q.id, from, to });
    buckets[to].push(q);
  }
}
console.log('sonra:', buckets.map((b) => b.length).join(' / '), `· taşınan ${moves.length}`);
if (!apply) {
  console.log('(kuru çalışma — uygulamak için --apply)');
  process.exit(0);
}

// Kaynağa uygula: `options` bloğundaki iki literali takas et, `answerIndex`i güncelle.
const files = readdirSync(SRC).filter((f) => f.startsWith('questions') && f.endsWith('.ts'));
const text = new Map(files.map((f) => [f, readFileSync(join(SRC, f), 'utf8')]));
let done = 0;
const failed = [];

for (const { id, from, to } of moves) {
  const file = files.find((f) => text.get(f).includes(`id: '${id}'`));
  if (!file) {
    failed.push(`${id}: kaynak bulunamadı`);
    continue;
  }
  let body = text.get(file);
  const anchor = body.indexOf(`id: '${id}'`);
  const optStart = body.indexOf('options: [', anchor);
  const optEnd = body.indexOf('],', optStart);
  const aiAt = body.indexOf('answerIndex:', optEnd);
  const aiMatch = body.slice(aiAt, aiAt + 40).match(/answerIndex: (\d+)/);
  if (optStart < 0 || optEnd < 0 || !aiMatch || Number(aiMatch[1]) !== from) {
    failed.push(`${id}: ayrıştırılamadı ya da answerIndex beklenenden farklı`);
    continue;
  }
  const block = body.slice(optStart, optEnd);
  const items = [...block.matchAll(/'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*"/g)].map((m) => m[0]);
  if (items.length !== 4) {
    failed.push(`${id}: ${items.length} şık bulundu`);
    continue;
  }
  const next = items.slice();
  [next[from], next[to]] = [next[to], next[from]];

  let newBlock = block;
  let cursor = 0;
  for (let i = 0; i < 4; i++) {
    const at = newBlock.indexOf(items[i], cursor);
    if (at < 0) {
      failed.push(`${id}: ${i}. şık literali bulunamadı`);
      newBlock = null;
      break;
    }
    newBlock = newBlock.slice(0, at) + next[i] + newBlock.slice(at + items[i].length);
    cursor = at + next[i].length;
  }
  if (newBlock === null) continue;

  body =
    body.slice(0, optStart) +
    newBlock +
    body.slice(optEnd, aiAt) +
    `answerIndex: ${to}` +
    body.slice(aiAt + aiMatch[0].length);
  text.set(file, body);
  done++;
}

for (const [f, body] of text) writeFileSync(join(SRC, f), body, 'utf8');
console.log(`uygulanan: ${done} / ${moves.length}`);
if (failed.length) {
  console.log('BAŞARISIZ:');
  failed.forEach((f) => console.log('  ', f));
  process.exit(1);
}
