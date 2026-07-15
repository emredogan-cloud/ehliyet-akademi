/**
 * @ea/db — çift-sürücü veritabanı istemcisi (ADR-003):
 * - DATABASE_URL varsa: gerçek Postgres (Neon/Vercel) + node-postgres havuzu
 * - yoksa: PGlite (yerel dosya; testte bellek-içi) — sıfır kurulum
 * Şema her açılışta idempotent bootstrap DDL ile garanti edilir (CREATE IF NOT EXISTS).
 */
import { drizzle as drizzlePg, type NodePgDatabase } from 'drizzle-orm/node-postgres';
import { drizzle as drizzlePglite, type PgliteDatabase } from 'drizzle-orm/pglite';
import { Pool } from 'pg';
import type { PGlite as PGliteType } from '@electric-sql/pglite';
import * as schema from './schema';

/**
 * PGlite ESM-only'dir; Next/webpack onu require ile externalize EDEMEZ ve bundle'lar —
 * bundle içindeki URL sınıfı Node fs tarafından reddedilir (ERR_INVALID_ARG_TYPE).
 * Çözüm: bundler analizinden kaçan NATIVE dynamic import → paket node_modules'tan
 * gerçek Node ESM olarak yüklenir (wasm yolları doğru çözülür).
 */
async function loadPGlite(): Promise<typeof import('@electric-sql/pglite')> {
  // webpackIgnore: webpack/Turbopack importu OLDUĞU GİBİ bırakır (native ESM, bundle yok);
  // Vite/vitest yorumu yok sayar ve normal işler. Her iki dünyada da doğru davranış.
  return import(/* webpackIgnore: true */ '@electric-sql/pglite');
}

export * from './schema';
export { schema };

export type Db = NodePgDatabase<typeof schema> | PgliteDatabase<typeof schema>;

/** İdempotent şema — hem PGlite hem Postgres'te güvenle tekrar çalışır. */
const BOOTSTRAP_DDL = `
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT NOT NULL DEFAULT '',
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS users_email_uq ON users(email);

CREATE TABLE IF NOT EXISTS sessions (
  token_hash TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_agent TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS sessions_user_idx ON sessions(user_id);

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  token_hash TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS user_state (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, key)
);

CREATE TABLE IF NOT EXISTS purchases (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  price_try INTEGER NOT NULL,
  provider TEXT NOT NULL DEFAULT 'mock',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS purchases_user_product_uq ON purchases(user_id, product_id);
`;

let _db: Db | null = null;
let _mode: 'postgres' | 'pglite' | null = null;

async function applyBootstrap(raw: {
  query?: (sql: string) => Promise<unknown>;
  exec?: (sql: string) => Promise<unknown>;
}) {
  if (raw.exec)
    await raw.exec(BOOTSTRAP_DDL); // PGlite
  else if (raw.query) {
    for (const stmt of BOOTSTRAP_DDL.split(';')) {
      const sql = stmt.trim();
      if (sql) await raw.query(sql);
    }
  }
}

/** Tekil bağlantı; ilk çağrıda bootstrap uygular. */
export async function getDb(): Promise<Db> {
  if (_db) return _db;
  const url = process.env.DATABASE_URL;
  // Serverless (Vercel) dosya sistemi salt-okunur/geçicidir: PGlite fallback'i orada ÇALIŞMAZ.
  // Dürüst davran: yapılandırma eksikse tipli hata → API katmanı 503 + net mesaj döner.
  if (!url && process.env.VERCEL) {
    throw new Error('DB_NOT_CONFIGURED');
  }
  if (url) {
    const pool = new Pool({ connectionString: url, max: 5 });
    await applyBootstrap({ query: (s) => pool.query(s) });
    _db = drizzlePg(pool, { schema });
    _mode = 'postgres';
  } else {
    // Test: bellek-içi; geliştirme: .pglite dizininde kalıcı dosya
    const dataDir =
      process.env.NODE_ENV === 'test'
        ? 'memory://'
        : (process.env.PGLITE_DIR ?? `${process.cwd()}/.pglite`);
    const { PGlite } = await loadPGlite();
    const lite: PGliteType = new PGlite(dataDir);
    await applyBootstrap({ exec: (s) => lite.exec(s) });
    _db = drizzlePglite(lite, { schema });
    _mode = 'pglite';
  }
  return _db;
}

export function dbMode(): 'postgres' | 'pglite' | null {
  return _mode;
}

/** Test yardımcıları: taze bellek-içi DB. */
export async function freshTestDb(): Promise<Db> {
  const { PGlite } = await loadPGlite();
  const lite: PGliteType = new PGlite('memory://');
  await applyBootstrap({ exec: (s) => lite.exec(s) });
  return drizzlePglite(lite, { schema });
}
export function _resetDbForTests(): void {
  _db = null;
  _mode = null;
}
