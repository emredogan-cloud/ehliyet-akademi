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
export const BOOTSTRAP_DDL = `
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

-- ── Topluluk (Evolution Faz E8) ────────────────────────────────────────────────
-- Katılım OPT-IN: visibility varsayılanı 'private'. Topluluk yüzeyleri e-posta/gerçek ad döndürmez.
CREATE TABLE IF NOT EXISTS community_profiles (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  avatar_id TEXT NOT NULL DEFAULT 'owl-wave',
  licence TEXT NOT NULL DEFAULT 'b',
  visibility TEXT NOT NULL DEFAULT 'private',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS community_profiles_licence_idx ON community_profiles(licence);
-- Beta Faz 7 — yüklenen profil fotoğrafı. Var olan kurulumlarda da eklenir (ADD COLUMN IF NOT
-- EXISTS): null ise paketlenmiş maskot kullanılır, yani mevcut satırlar olduğu gibi çalışmaya
-- devam eder. Medya silinirse profil maskota döner (SET NULL) — satır kaybolmaz.
ALTER TABLE community_profiles ADD COLUMN IF NOT EXISTS avatar_media_id TEXT;

CREATE TABLE IF NOT EXISTS community_stats (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  xp INTEGER NOT NULL DEFAULT 0,
  streak INTEGER NOT NULL DEFAULT 0,
  lessons INTEGER NOT NULL DEFAULT 0,
  exams INTEGER NOT NULL DEFAULT 0,
  answered INTEGER NOT NULL DEFAULT 0,
  accuracy INTEGER NOT NULL DEFAULT 0,
  submitted_xp INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS community_stats_xp_idx ON community_stats(xp);

CREATE TABLE IF NOT EXISTS community_achievements (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL,
  earned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, achievement_id)
);

CREATE TABLE IF NOT EXISTS leaderboard_snapshots (
  id TEXT PRIMARY KEY,
  week_start TEXT NOT NULL,
  licence TEXT NOT NULL,
  rows JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS leaderboard_week_licence_uq ON leaderboard_snapshots(week_start, licence);

CREATE TABLE IF NOT EXISTS community_reports (
  id TEXT PRIMARY KEY,
  reporter_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  note TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'open',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS community_reports_status_idx ON community_reports(status);

CREATE TABLE IF NOT EXISTS community_blocks (
  blocker_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (blocker_id, blocked_id)
);

-- ── Sosyal grafik ve mesajlaşma (Evolution Faz E9) ────────────────────────────
-- Engel kontrolü bu tablolarda DEĞİL, her uçta community_blocks üzerinden yapılır.
CREATE TABLE IF NOT EXISTS friendships (
  requester_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  addressee_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at TIMESTAMPTZ,
  PRIMARY KEY (requester_id, addressee_id)
);
CREATE INDEX IF NOT EXISTS friendships_addressee_idx ON friendships(addressee_id);

CREATE TABLE IF NOT EXISTS direct_messages (
  id TEXT PRIMARY KEY,
  thread_key TEXT NOT NULL,
  sender_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipient_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS dm_thread_idx ON direct_messages(thread_key, created_at);
CREATE INDEX IF NOT EXISTS dm_recipient_idx ON direct_messages(recipient_id);

CREATE TABLE IF NOT EXISTS discussion_threads (
  id TEXT PRIMARY KEY,
  licence TEXT NOT NULL DEFAULT 'b',
  title TEXT NOT NULL,
  author_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  question_ref TEXT,
  post_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_activity_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS discussion_threads_licence_idx ON discussion_threads(licence, last_activity_at);

CREATE TABLE IF NOT EXISTS discussion_posts (
  id TEXT PRIMARY KEY,
  thread_id TEXT NOT NULL REFERENCES discussion_threads(id) ON DELETE CASCADE,
  author_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  question_ref TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS discussion_posts_thread_idx ON discussion_posts(thread_id, created_at);

-- Faz E9: şikâyet artık kullanıcıyı DEĞİL, mesaj/iletiyi de hedefleyebilir.
ALTER TABLE community_reports ADD COLUMN IF NOT EXISTS target_type TEXT NOT NULL DEFAULT 'user';
ALTER TABLE community_reports ADD COLUMN IF NOT EXISTS target_ref TEXT;

-- Faz E10: çalışma grupları ve meydan okumalar.
CREATE TABLE IF NOT EXISTS study_groups (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  join_code TEXT NOT NULL,
  licence TEXT NOT NULL DEFAULT 'b',
  owner_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  member_count INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS study_groups_join_code_uq ON study_groups(join_code);

CREATE TABLE IF NOT EXISTS study_group_members (
  group_id TEXT NOT NULL REFERENCES study_groups(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (group_id, user_id)
);
CREATE INDEX IF NOT EXISTS study_group_members_user_idx ON study_group_members(user_id);

CREATE TABLE IF NOT EXISTS challenges (
  id TEXT PRIMARY KEY,
  slug TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  metric TEXT NOT NULL,
  target INTEGER NOT NULL,
  licence TEXT,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS challenges_slug_uq ON challenges(slug);

CREATE TABLE IF NOT EXISTS challenge_progress (
  challenge_id TEXT NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  baseline INTEGER NOT NULL DEFAULT 0,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  PRIMARY KEY (challenge_id, user_id)
);

-- Başlangıç meydan okumaları. Meydan okumalar SUNUCU TANIMLIDIR (istemci oluşturamaz) ve yönetim
-- arayüzü yoktur, bu yüzden ilk küme bootstrap ile ETKİSİZ-TEKRARLI olarak eklenir.
-- DÜRÜST SINIR: zamanlayıcı (cron) sağlanmadığı için pencere UZUNDUR ve otomatik dönmez —
-- yeni dönem yeni satır eklemeyi gerektirir (rapor ve bellekte açıkça belirtildi).
INSERT INTO challenges (id, slug, title, description, metric, target, licence, starts_at, ends_at)
VALUES
  ('ch-soru-200', 'soru-200', '200 soru çöz',
   'Bu dönemde 200 soru çözerek temeli sağlamlaştır.', 'answered', 200, NULL,
   now() - interval '1 day', now() + interval '90 days'),
  ('ch-ders-10', 'ders-10', '10 ders tamamla',
   'Konu anlatımlarından 10 tanesini bitir.', 'lessons', 10, NULL,
   now() - interval '1 day', now() + interval '90 days'),
  ('ch-deneme-5', 'deneme-5', '5 deneme sınavı',
   'Gerçek sınav temposunu 5 denemeyle yakala.', 'exams', 5, NULL,
   now() - interval '1 day', now() + interval '90 days')
ON CONFLICT (id) DO NOTHING;

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

/**
 * DDL'i tek tek çalıştırılabilir ifadelere böler.
 *
 * NEDEN AYRI FONKSİYON: Postgres sürücüsü çok-ifadeli metni kabul etmediği için bölmek gerekiyor;
 * ama naif `split(';')` **yorum satırındaki noktalı virgülde de** böler ve ortaya sözdizimi hatası
 * veren bir parça çıkar. Bu, E10'da ÜRETİMİ DÜŞÜRDÜ: PGlite yolu bütün metni tek seferde
 * çalıştırdığı (`exec`) için testler yeşil kaldı, hata yalnız Postgres'te ortaya çıktı.
 * Bu yüzden bölmeden ÖNCE satır yorumları atılır ve iki sürücü aynı ifade kümesini görür.
 */
export function splitDdlStatements(ddl: string): string[] {
  const withoutComments = ddl
    .split('\n')
    .filter((line) => !line.trimStart().startsWith('--'))
    .join('\n');
  return withoutComments
    .split(';')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

async function applyBootstrap(raw: {
  query?: (sql: string) => Promise<unknown>;
  exec?: (sql: string) => Promise<unknown>;
}) {
  if (raw.exec)
    await raw.exec(BOOTSTRAP_DDL); // PGlite: çok-ifadeli metni tek seferde çalıştırır
  else if (raw.query) {
    for (const sql of splitDdlStatements(BOOTSTRAP_DDL)) await raw.query(sql);
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
