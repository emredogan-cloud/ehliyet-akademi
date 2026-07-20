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
import * as schemaCore from './schema';
import * as schemaCms from './cms';
const schema = { ...schemaCore, ...schemaCms };

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
export * from './cms';
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

ALTER TABLE users ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'user';

-- Sprint 4: e-posta doğrulama + ödeme makbuz referansı
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS external_ref TEXT;

CREATE TABLE IF NOT EXISTS email_verification_tokens (
  token_hash TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS content_items (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  slug TEXT NOT NULL,
  locale TEXT NOT NULL DEFAULT 'tr',
  licence TEXT NOT NULL DEFAULT 'B',
  status TEXT NOT NULL DEFAULT 'draft',
  version INTEGER NOT NULL DEFAULT 1,
  title TEXT NOT NULL DEFAULT '',
  tags JSONB NOT NULL DEFAULT '[]',
  difficulty TEXT,
  payload JSONB NOT NULL,
  created_by TEXT NOT NULL REFERENCES users(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  published_at TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS content_slug_uq ON content_items(type, slug, locale, licence);
CREATE INDEX IF NOT EXISTS content_status_idx ON content_items(status);
CREATE INDEX IF NOT EXISTS content_type_idx ON content_items(type);

CREATE TABLE IF NOT EXISTS content_versions (
  id TEXT PRIMARY KEY,
  content_id TEXT NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  status TEXT NOT NULL,
  payload JSONB NOT NULL,
  changed_by TEXT NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS content_versions_content_idx ON content_versions(content_id);

CREATE TABLE IF NOT EXISTS media_assets (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL,
  filename TEXT NOT NULL,
  mime TEXT NOT NULL,
  bytes INTEGER NOT NULL,
  alt TEXT NOT NULL DEFAULT '',
  tags JSONB NOT NULL DEFAULT '[]',
  version INTEGER NOT NULL DEFAULT 1,
  data_base64 TEXT NOT NULL,
  created_by TEXT NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS media_kind_idx ON media_assets(kind);

CREATE TABLE IF NOT EXISTS audit_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  action TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  meta JSONB NOT NULL DEFAULT '{}',
  at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS audit_at_idx ON audit_logs(at);
CREATE TABLE IF NOT EXISTS question_reports (
  id TEXT PRIMARY KEY,
  question_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  message TEXT NOT NULL DEFAULT '',
  user_id TEXT,
  status TEXT NOT NULL DEFAULT 'open',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS question_reports_status_idx ON question_reports(status);
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
