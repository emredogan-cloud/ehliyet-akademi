import { readFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import pg from 'pg';
const env = readFileSync('../../.env', 'utf8');
const url = env.match(/^DATABASE_URL=(.*)$/m)?.[1]?.replace(/^["']|["']$/g, '');
const c = new pg.Client({ connectionString: url, ssl: { rejectUnauthorized: false } });
await c.connect();
const EMAIL = 'tester@ehliyetakademi.com';
const PRODUCT = 'komple-ehliyet';

const { rows: u } = await c.query('select id, email_verified from users where lower(email)=lower($1)', [EMAIL]);
if (!u.length) { console.log('HATA: kullanıcı yok'); process.exit(1); }
const uid = u[0].id;

await c.query('begin');
try {
  // 1) E-postayı doğrulanmış say — inceleyici doğrulama bağlantısına erişemez.
  const v = await c.query('update users set email_verified = true where id = $1 and email_verified = false', [uid]);
  console.log('email_verified güncellendi:', v.rowCount);

  // 2) PRO yetkisi — mobilin TANIDIĞI tek ürün kimliği.
  const { rows: ex } = await c.query('select id from purchases where user_id=$1 and product_id=$2', [uid, PRODUCT]);
  if (ex.length) {
    console.log('satın alma ZATEN var, tekrar eklenmedi');
  } else {
    await c.query(
      'insert into purchases (id, user_id, product_id, price_try, provider, external_ref) values ($1,$2,$3,$4,$5,$6)',
      [randomUUID(), uid, PRODUCT, 399, 'reviewer_grant', 'play-review-2026']
    );
    console.log('satın alma EKLENDİ:', PRODUCT);
  }
  await c.query('commit');
} catch (e) {
  await c.query('rollback');
  console.log('GERİ ALINDI:', e.message);
  process.exitCode = 1;
}

const { rows: fin } = await c.query(
  'select u.id, u.email, u.email_verified, p.product_id, p.provider, p.price_try from users u left join purchases p on p.user_id=u.id where u.id=$1', [uid]);
console.log('SON DURUM:', JSON.stringify(fin));
await c.end();
