/**
 * CMS şeması (Sprint 2 / ADR-007) — içerik kalemleri, sürüm geçmişi, medya, denetim.
 * Payload JSONB'dir ve yazım anında @ea/content-schema (Zod) ile doğrulanır.
 */
import { pgTable, text, timestamp, integer, jsonb, uniqueIndex, index } from 'drizzle-orm/pg-core';
import { users } from './schema';

/** İçerik türleri — gelecekteki ehliyet sınıfları/tür genişlemesine açık. */
export const CONTENT_TYPES = ['lesson', 'question', 'article', 'seo_page', 'kb'] as const;
export type ContentType = (typeof CONTENT_TYPES)[number];

export const CONTENT_STATUSES = ['draft', 'in_review', 'approved', 'published', 'retired'] as const;
export type ContentStatus = (typeof CONTENT_STATUSES)[number];

export const contentItems = pgTable(
  'content_items',
  {
    id: text('id').primaryKey(),
    type: text('type').notNull(), // ContentType
    slug: text('slug').notNull(),
    locale: text('locale').notNull().default('tr'),
    licence: text('licence').notNull().default('B'), // gelecekteki sınıflar: A1/A2/C/D...
    status: text('status').notNull().default('draft'), // ContentStatus
    version: integer('version').notNull().default(1),
    title: text('title').notNull().default(''),
    tags: jsonb('tags').notNull().default([]),
    difficulty: text('difficulty'), // kolay|orta|zor (soru/ders için)
    payload: jsonb('payload').notNull(), // Zod-doğrulanmış içerik gövdesi
    createdBy: text('created_by')
      .notNull()
      .references(() => users.id),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    publishedAt: timestamp('published_at', { withTimezone: true }),
  },
  (t) => [
    uniqueIndex('content_slug_uq').on(t.type, t.slug, t.locale, t.licence),
    index('content_status_idx').on(t.status),
    index('content_type_idx').on(t.type),
  ]
);

/** Sürüm geçmişi: her kayıtlı değişiklik/geçiş bir satır (geri dönüş + iz). */
export const contentVersions = pgTable(
  'content_versions',
  {
    id: text('id').primaryKey(),
    contentId: text('content_id')
      .notNull()
      .references(() => contentItems.id, { onDelete: 'cascade' }),
    version: integer('version').notNull(),
    status: text('status').notNull(),
    payload: jsonb('payload').notNull(),
    changedBy: text('changed_by')
      .notNull()
      .references(() => users.id),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index('content_versions_content_idx').on(t.contentId)]
);

/** Medya varlıkları — temel: veri DB'de (base64), servis /api/media/[id].
 *  Ölçekte Vercel Blob/S3 adaptörü aynı tablo meta'sıyla takılır. */
export const mediaAssets = pgTable(
  'media_assets',
  {
    id: text('id').primaryKey(),
    kind: text('kind').notNull(), // image | svg | lottie | video
    filename: text('filename').notNull(),
    mime: text('mime').notNull(),
    bytes: integer('bytes').notNull(),
    alt: text('alt').notNull().default(''),
    tags: jsonb('tags').notNull().default([]),
    version: integer('version').notNull().default(1),
    dataBase64: text('data_base64').notNull(),
    createdBy: text('created_by')
      .notNull()
      .references(() => users.id),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index('media_kind_idx').on(t.kind)]
);

/** Denetim kaydı — her ayrıcalıklı işlem izlenir (ROADMAP Faz 25/30). */
export const auditLogs = pgTable(
  'audit_logs',
  {
    id: text('id').primaryKey(),
    userId: text('user_id')
      .notNull()
      .references(() => users.id),
    action: text('action').notNull(), // content.create / content.publish / media.upload / user.role ...
    entity: text('entity').notNull(),
    entityId: text('entity_id').notNull(),
    meta: jsonb('meta').notNull().default({}),
    at: timestamp('at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index('audit_at_idx').on(t.at)]
);
