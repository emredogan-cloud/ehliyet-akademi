/**
 * Üretim veritabanı temizliği — Beta Faz 13 (B5).
 *
 * VARSAYILAN **KURU ÇALIŞTIRMA**: ne silineceğini sayar, hiçbir şey silmez.
 * Uygulamak için:  BACKUP_PATH=/güvenli/yol.json node scripts/db-cleanup.mjs --apply
 *
 * SİLİNENLER (yalnız bunlar):
 *  · `@ea.dev` ve `@example.com` test/fixture kullanıcıları — E2E ve geliştirme artıkları,
 *  · süresi DOLMUŞ e-posta doğrulama ve parola sıfırlama jetonları.
 *
 * ASLA SİLİNMEYENLER — sorgu bunları yapısal olarak dışarıda bırakır:
 *  · gerçek kullanıcılar (`@gmail.com` vb.) ve onların satın almaları,
 *  · **üretim içeriği** üretmiş hesaplar (`content_items.created_by`,
 *    `content_versions.changed_by`, `media_assets.created_by`),
 *  · **denetim/analitik** kaydı olan hesaplar (`audit_logs.user_id`).
 *
 * Sondaki üç FK `NO ACTION`'dır: o hesapları silmek ya hata verir ya da üretim içeriğini
 * öksüz bırakırdı. Bu yüzden dışlama listesi bir tercih değil, bir ZORUNLULUKTUR.
 *
 * Silme tek bir işlemde (transaction) yapılır; hata olursa tamamı geri alınır.
 * `--apply` önce silinecek satırların TAMAMINI JSON olarak yedekler (rollback için).
 * Yedek e-posta ve parola özeti içerir → **depo dışına** yazılmalıdır.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import pg from 'pg';
const DRY = !process.argv.includes('--apply');
const env = readFileSync(new URL('../.env', import.meta.url), 'utf8');
const url = env.match(/^DATABASE_URL=(.*)$/m)?.[1]?.replace(/^["']|["']$/g, '');
const c = new pg.Client({ connectionString: url, ssl: { rejectUnauthorized: false } });
await c.connect();

// Üretim içeriği veya denetim kaydı üretmiş HİÇBİR kullanıcı silinmez (FK: NO ACTION).
const SAFE_IDS = `
  select id from users
  where (email like '%@ea.dev' or email like '%@example.com')
    and id not in (
      select created_by from content_items where created_by is not null
      union select changed_by from content_versions where changed_by is not null
      union select created_by from media_assets where created_by is not null
      union select user_id from audit_logs where user_id is not null
    )`;

const { rows: users } = await c.query(
  `select id, email, name, role, created_at from users where id in (${SAFE_IDS})`
);
const { rows: purch } = await c.query(`select * from purchases where user_id in (${SAFE_IDS})`);
const { rows: expTok } = await c.query(
  `select * from email_verification_tokens where expires_at < now()`
);
const { rows: expRst } = await c.query(
  `select * from password_reset_tokens where expires_at < now()`
);

console.log('SİLİNECEK kullanıcı:', users.length);
console.log(
  '  bunlara bağlı satın alma:',
  purch.length,
  purch.map((p) => `${p.provider}/${p.external_ref}`).join(', ')
);
console.log('SÜRESİ DOLMUŞ doğrulama jetonu:', expTok.length);
console.log('SÜRESİ DOLMUŞ sıfırlama jetonu:', expRst.length);

if (DRY) {
  console.log('\n[KURU ÇALIŞTIRMA — hiçbir şey silinmedi]');
  await c.end();
  process.exit(0);
}

const backup = {
  at: new Date().toISOString(),
  users,
  purchases: purch,
  expiredVerificationTokens: expTok,
  expiredResetTokens: expRst,
};
const path = process.env.BACKUP_PATH || './db_cleanup_backup.json';
writeFileSync(path, JSON.stringify(backup, null, 2));
console.log('\nYedek yazıldı:', path, `(${users.length} kullanıcı)`);

await c.query('begin');
try {
  const d1 = await c.query(`delete from email_verification_tokens where expires_at < now()`);
  const d2 = await c.query(`delete from password_reset_tokens where expires_at < now()`);
  const d3 = await c.query(`delete from users where id in (${SAFE_IDS})`);
  await c.query('commit');
  console.log(
    'SİLİNDİ → doğrulama jetonu:',
    d1.rowCount,
    '· sıfırlama jetonu:',
    d2.rowCount,
    '· kullanıcı:',
    d3.rowCount
  );
} catch (e) {
  await c.query('rollback');
  console.log('GERİ ALINDI:', e.message);
  process.exitCode = 1;
}
await c.end();
