// Workspace bütünlük doğrulaması — CI'ın ilk kapısı.
// Amaç: yapısal sözleşmeleri (workspace, engine, yasak içerik) her push'ta doğrulamak.
import { readFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const fail = (msg) => {
  console.error('✗ ' + msg);
  process.exitCode = 1;
};
const ok = (msg) => console.error('✓ ' + msg);

// 1) Zorunlu kök dosyalar
for (const f of [
  'pnpm-workspace.yaml',
  'turbo.json',
  'tsconfig.base.json',
  'LICENSE',
  'SECURITY.md',
  'CONTRIBUTING.md',
  'CHANGELOG.md',
  '.github/CODEOWNERS',
  '.github/workflows/ci.yml',
]) {
  if (existsSync(join(root, f))) ok(f);
  else fail(`Eksik zorunlu dosya: ${f}`);
}

// 2) package.json sözleşmeleri
const pkg = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8'));
if (!pkg.private) fail('Kök package.json private olmalı');
if (!/^pnpm@/.test(pkg.packageManager ?? '')) fail('packageManager pnpm olmalı');
const nodeMajor = Number(process.versions.node.split('.')[0]);
if (nodeMajor < 20) fail(`Node >=20 gerekli (mevcut: ${process.versions.node})`);
ok(`Node ${process.versions.node}, pnpm sözleşmesi tamam`);

// 3) Yasak içerik taraması (kaynak dosyalarda placeholder ve sır kalıntısı)
// TODO taraması yalnız gerçek iş-kalıntılarını hedefler: yorum-stili (`// TODO`, `# TODO`,
// `<!-- TODO`) ve `TODO:` önekleri. Kural metinlerindeki "TODO" kelimesi serbesttir.
const FORBIDDEN = [
  /lorem ipsum/i,
  /(\/\/|<!--|#)\s*TODO\b/,
  /\bTODO:/,
  /sk-proj-[A-Za-z0-9_-]{20,}/,
  /PLACEHOLDER/,
];
const SCAN_EXT = new Set(['.ts', '.tsx', '.js', '.mjs', '.md', '.json', '.css', '.yml', '.yaml']);
const SKIP_DIRS = new Set([
  'node_modules',
  '.git',
  '.next',
  'dist',
  '.turbo',
  'coverage',
  'playwright-report',
  'test-results',
  'sınav-soruları-pdf', // telif korumalı MEB sınav-arşivi (referans-only) + venv — taranmaz
]);
let scanned = 0;
function walk(dir) {
  for (const name of readdirSync(dir)) {
    if (SKIP_DIRS.has(name)) continue;
    const p = join(dir, name);
    const st = statSync(p);
    if (st.isDirectory()) walk(p);
    else if (SCAN_EXT.has(name.slice(name.lastIndexOf('.')))) {
      // Bu betiğin kendisi desenleri tanımlar — kendini tarama dışı bırak.
      if (p.endsWith(join('scripts', 'verify-workspace.mjs'))) continue;
      scanned++;
      const body = readFileSync(p, 'utf8');
      for (const re of FORBIDDEN) {
        if (re.test(body)) fail(`Yasak içerik (${re}) → ${p.replace(root + '/', '')}`);
      }
    }
  }
}
walk(root);
if (!process.exitCode) ok(`${scanned} dosya tarandı — placeholder/sır kalıntısı yok`);

if (process.exitCode) {
  console.error('\nWorkspace doğrulaması BAŞARISIZ');
  process.exit(1);
}
console.error('\nWorkspace doğrulaması TAMAM');
