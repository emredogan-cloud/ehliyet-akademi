/**
 * Dağıtım teşhis aracı — `OPERATIONS_MANUAL.md` §19.10'un çalıştırılabilir hâli.
 *
 * Hiçbir şeyi DEĞİŞTİRMEZ; yalnız ölçer ve her bulguyu el kitabının ilgili bölümüne yönlendirir.
 *
 * Kullanım:
 *   node scripts/doctor.mjs
 *   node scripts/doctor.mjs --base http://localhost:3000
 *
 * Çıkış kodu: 0 = yayın engelleyici sorun yok · 1 = en az bir 🔴 bulgu var.
 */
import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

const args = process.argv.slice(2);
const opt = (n, d) => {
  const i = args.indexOf(`--${n}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : d;
};
const BASE = opt('base', 'https://www.ehliyetegitim.com').replace(/\/$/, '');

const C = {
  ok: '[32m',
  warn: '[33m',
  err: '[31m',
  dim: '[2m',
  off: '[0m',
};

let blockers = 0;
const line = (icon, color, label, detail, ref) => {
  const r = ref ? `${C.dim} → el kitabı ${ref}${C.off}` : '';
  console.log(`${color}${icon}${C.off} ${label.padEnd(34)} ${detail}${r}`);
};
const ok = (l, d, r) => line('✅', C.ok, l, d, r);
const warn = (l, d, r) => line('⚠️ ', C.warn, l, d, r);
const bad = (l, d, r) => {
  blockers += 1;
  line('❌', C.err, l, d, r);
};

async function status(path, init) {
  try {
    const res = await fetch(BASE + path, init);
    return { code: res.status, res };
  } catch (e) {
    return { code: 0, error: String(e) };
  }
}

const jsonPost = (body) => ({
  method: 'POST',
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify(body),
});

console.log(`\n${C.dim}Hedef: ${BASE}${C.off}\n`);

// ── 1) Sağlık ────────────────────────────────────────────────────────────────
{
  const { code, res, error } = await status('/api/health');
  if (code !== 200) {
    bad('Backend sağlık', error ?? `HTTP ${code}`, '§19.1');
  } else {
    const h = await res.json();
    if (h.db === 'configured') ok('Veritabanı', 'configured', '§19.2');
    else bad('Veritabanı', `db="${h.db}" — DATABASE_URL eksik`, '§16.2');

    if (h.email === 'resend') ok('E-posta', 'resend', '§19.7');
    else warn('E-posta', `email="${h.email}" — doğrulama e-postası gitmez`, '§16.4');

    if (h.payments) ok('Web ödemesi', String(h.payments), '§16.10');
    else warn('Web ödemesi', 'yapılandırılmamış', '§16.10');
  }
}

// ── 2) Google giriş sunucu tarafı ────────────────────────────────────────────
{
  const { code } = await status('/api/auth/google', jsonPost({ idToken: 'a.b.c' }));
  if (code === 401) {
    ok('Google (sunucu)', 'GOOGLE_SERVER_CLIENT_ID ayarlı', '§17.1');
  } else if (code === 503) {
    bad('Google (sunucu)', 'GOOGLE_SERVER_CLIENT_ID YOK (Vercel)', '§16.3');
  } else {
    warn('Google (sunucu)', `beklenmeyen HTTP ${code}`, '§17.3-D');
  }
}

// ── 3) RevenueCat webhook ────────────────────────────────────────────────────
{
  const { code } = await status('/api/iap/revenuecat', jsonPost({}));
  if (code === 401) ok('RevenueCat webhook', 'sır ayarlı (fail-closed çalışıyor)', '§10.9');
  else if (code === 503) warn('RevenueCat webhook', 'REVENUECAT_WEBHOOK_SECRET yok', '§16.6');
  else if (code === 404) bad('RevenueCat webhook', 'uç DAĞITILMAMIŞ', '§10.8');
  else warn('RevenueCat webhook', `beklenmeyen HTTP ${code}`, '§19.5');
}

// ── 4) Akan AI ───────────────────────────────────────────────────────────────
{
  const { code, res } = await status(
    '/api/ai/ask/stream',
    jsonPost({ question: 'Kırmızı ışıkta ne yapmalıyım?' })
  );
  if (code !== 200) {
    bad('Akan AI', `HTTP ${code}`, '§19.6');
  } else {
    const text = await res.text();
    if (text.includes('"streamed":true')) ok('Akan AI', 'gerçek akış çalışıyor', '§14.4');
    else if (text.includes('"streamed":false'))
      warn('Akan AI', 'tek parça — ANTHROPIC_API_KEY yok/hatalı', '§16.8');
    else warn('Akan AI', 'beklenmeyen yanıt biçimi', '§19.6');
  }
}

// ── 5) Firebase OAuth istemcileri ────────────────────────────────────────────
{
  const path = 'apps/mobile/android/app/google-services.json';
  try {
    const d = JSON.parse(readFileSync(path, 'utf8'));
    const n = (d.client?.[0]?.oauth_client ?? []).length;
    const pkg = d.client?.[0]?.client_info?.android_client_info?.package_name;
    if (pkg !== 'com.ehliyetegitim.ehliyet_akademi') {
      bad('Firebase paket adı', `"${pkg}" — uygulama kimliğiyle uyuşmuyor`, '§8.2');
    }
    if (n === 0) bad('Firebase OAuth istemcisi', 'oauth_client: 0 — SHA eklenmemiş', '§8.3');
    else if (n === 1)
      warn('Firebase OAuth istemcisi', 'yalnız 1 istemci — Web eksik olabilir', '§9.2');
    else ok('Firebase OAuth istemcisi', `${n} istemci`, '§8.4');
  } catch {
    warn('Firebase yapılandırması', `${path} okunamadı (git'te izlenmiyor olabilir)`, '§8.4');
  }
}

// ── 6) İmzalama anahtarı ─────────────────────────────────────────────────────
{
  try {
    const props = readFileSync('apps/mobile/android/key.properties', 'utf8');
    const get = (k) => props.match(new RegExp(`^${k}=(.*)$`, 'm'))?.[1]?.trim();
    const store = get('storeFile');
    const alias = get('keyAlias');
    const pass = get('storePassword');
    const out = execFileSync(
      'keytool',
      [
        '-list',
        '-v',
        '-keystore',
        store?.startsWith('/') ? store : `apps/mobile/android/${store}`,
        '-alias',
        alias ?? 'upload',
        '-storepass',
        pass ?? '',
      ],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }
    );
    const sha1 = out.match(/SHA1:\s*([0-9A-F:]+)/)?.[1];
    if (out.includes('CN=Android Debug')) {
      bad('İmzalama anahtarı', 'HATA AYIKLAMA anahtarı — yayınlanamaz', '§21.4');
    } else {
      ok('İmzalama anahtarı', `upload · SHA1 ${sha1?.slice(0, 17)}…`, '§6.5');
    }
  } catch {
    warn('İmzalama anahtarı', 'key.properties yok — release imzalanamaz', '§6.4');
  }
}

// ── Özet ─────────────────────────────────────────────────────────────────────
console.log('');
if (blockers === 0) {
  console.log(`${C.ok}Yayın engelleyici bulgu yok.${C.off}\n`);
} else {
  console.log(`${C.err}${blockers} engelleyici bulgu.${C.off} Ayrıntı: OPERATIONS_MANUAL.md\n`);
  process.exitCode = 1;
}
