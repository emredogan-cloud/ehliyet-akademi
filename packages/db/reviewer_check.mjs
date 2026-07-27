import { readFileSync } from 'node:fs';
import pg from 'pg';
const env = readFileSync('../../.env', 'utf8');
const url = env.match(/^DATABASE_URL=(.*)$/m)?.[1]?.replace(/^["']|["']$/g, '');
const c = new pg.Client({ connectionString: url, ssl: { rejectUnauthorized: false } });
await c.connect();
const EMAIL = 'tester@ehliyetakademi.com';
const { rows: u } = await c.query(
  'select id, email, name, role, email_verified, created_at from users where lower(email)=lower($1)', [EMAIL]);
console.log('KULLANICI:', u.length ? JSON.stringify(u[0]) : 'YOK');
if (u.length) {
  const { rows: p } = await c.query('select product_id, provider, external_ref, created_at from purchases where user_id=$1', [u[0].id]);
  console.log('SATIN ALMALAR:', p.length ? JSON.stringify(p) : 'YOK');
}
const { rows: cons } = await c.query(
  "select conname, pg_get_constraintdef(oid) def from pg_constraint where conrelid='purchases'::regclass");
console.log('PURCHASES KISITLARI:');
for (const r of cons) console.log('  ', r.conname, '=>', r.def);
await c.end();
