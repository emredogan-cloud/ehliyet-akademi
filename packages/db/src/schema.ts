/**
 * @ea/db şema (ROADMAP Faz 27 / Sprint 1) — Drizzle ORM, Postgres lehçesi.
 * Aynı şema PGlite (yerel/test) ve gerçek Postgres'te (Neon/Vercel) çalışır.
 */
import {
  pgTable,
  text,
  timestamp,
  integer,
  jsonb,
  primaryKey,
  uniqueIndex,
} from 'drizzle-orm/pg-core';

export const users = pgTable(
  'users',
  {
    id: text('id').primaryKey(), // uuid (uygulama üretir)
    email: text('email').notNull(),
    name: text('name').notNull().default(''),
    passwordHash: text('password_hash').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex('users_email_uq').on(t.email)]
);

/** Çok-cihaz oturumlar: her giriş bir satır; token'ın yalnız SHA-256 hash'i saklanır. */
export const sessions = pgTable('sessions', {
  tokenHash: text('token_hash').primaryKey(),
  userId: text('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  userAgent: text('user_agent').notNull().default(''),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
});

export const passwordResetTokens = pgTable('password_reset_tokens', {
  tokenHash: text('token_hash').primaryKey(),
  userId: text('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
});

/** Cihazlar-arası senkron: anahtar-değer kullanıcı durumu (answers/cards/streak/theme/...). */
export const userState = pgTable(
  'user_state',
  {
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    key: text('key').notNull(),
    value: jsonb('value').notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [primaryKey({ columns: [t.userId, t.key] })]
);

/** Tek-seferlik satın almalar (Faz 16) — abonelik YOK; satır = kalıcı sahiplik. */
export const purchases = pgTable(
  'purchases',
  {
    id: text('id').primaryKey(), // uuid
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    productId: text('product_id').notNull(),
    priceTRY: integer('price_try').notNull(),
    provider: text('provider').notNull().default('mock'), // mock | lemonsqueezy | stripe
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex('purchases_user_product_uq').on(t.userId, t.productId)]
);
