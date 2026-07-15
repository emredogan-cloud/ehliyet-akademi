/**
 * CMS servis katmanı (Sprint 2 / ADR-007) — içerik hattı çekirdeği:
 * oluştur → doğrula(Zod) → sürümle → iş-akışı geçişi → yayınla → (arama indeksle) → denetle.
 */
import { and, desc, eq, sql } from 'drizzle-orm';
import {
  getDb,
  contentItems,
  contentVersions,
  mediaAssets,
  auditLogs,
  users,
  CONTENT_TYPES,
  type ContentType,
  type ContentStatus,
} from '@ea/db';
import { canTransition, validatePayload } from '@ea/content-schema';
import { newId, type SessionUser } from './auth';

/* ---------- denetim ---------- */
export async function audit(
  userId: string,
  action: string,
  entity: string,
  entityId: string,
  meta: object = {}
): Promise<void> {
  const db = await getDb();
  await db.insert(auditLogs).values({ id: newId(), userId, action, entity, entityId, meta });
}

/* ---------- içerik ---------- */
export interface CreateContentInput {
  type: string;
  slug: string;
  title: string;
  payload: unknown;
  locale?: string;
  licence?: string;
  difficulty?: string;
  tags?: string[];
}

export async function createContent(
  user: SessionUser,
  input: CreateContentInput
): Promise<{ ok: true; id: string } | { ok: false; errors: string[] }> {
  if (!CONTENT_TYPES.includes(input.type as ContentType))
    return { ok: false, errors: [`Geçersiz tür: ${input.type}`] };
  if (!/^[a-z0-9-]{3,}$/.test(input.slug))
    return { ok: false, errors: ['Slug: küçük harf/rakam/tire, en az 3 karakter.'] };
  const v = validatePayload(input.type, input.payload);
  if (!v.ok) return { ok: false, errors: v.errors };

  const db = await getDb();
  const id = newId();
  try {
    await db.insert(contentItems).values({
      id,
      type: input.type,
      slug: input.slug,
      title: input.title,
      payload: input.payload as object,
      locale: input.locale ?? 'tr',
      licence: input.licence ?? 'B',
      difficulty: input.difficulty,
      tags: input.tags ?? [],
      createdBy: user.id,
    });
  } catch {
    return { ok: false, errors: ['Bu tür+slug+dil için içerik zaten var.'] };
  }
  await db.insert(contentVersions).values({
    id: newId(),
    contentId: id,
    version: 1,
    status: 'draft',
    payload: input.payload as object,
    changedBy: user.id,
  });
  await audit(user.id, 'content.create', input.type, id, { slug: input.slug });
  return { ok: true, id };
}

export async function updateContent(
  user: SessionUser,
  id: string,
  patch: { title?: string; payload?: unknown; tags?: string[]; difficulty?: string }
): Promise<{ ok: true; version: number } | { ok: false; errors: string[] }> {
  const db = await getDb();
  const rows = await db.select().from(contentItems).where(eq(contentItems.id, id));
  const item = rows[0];
  if (!item) return { ok: false, errors: ['İçerik bulunamadı.'] };
  const payload = patch.payload ?? item.payload;
  const v = validatePayload(item.type, payload);
  if (!v.ok) return { ok: false, errors: v.errors };

  const version = item.version + 1;
  await db
    .update(contentItems)
    .set({
      title: patch.title ?? item.title,
      payload: payload as object,
      tags: (patch.tags ?? item.tags) as object,
      difficulty: patch.difficulty ?? item.difficulty,
      version,
      updatedAt: new Date(),
    })
    .where(eq(contentItems.id, id));
  await db.insert(contentVersions).values({
    id: newId(),
    contentId: id,
    version,
    status: item.status,
    payload: payload as object,
    changedBy: user.id,
  });
  await audit(user.id, 'content.update', item.type, id, { version });
  return { ok: true, version };
}

export async function transitionContent(
  user: SessionUser,
  id: string,
  to: ContentStatus
): Promise<{ ok: true; status: ContentStatus } | { ok: false; errors: string[] }> {
  const db = await getDb();
  const rows = await db.select().from(contentItems).where(eq(contentItems.id, id));
  const item = rows[0];
  if (!item) return { ok: false, errors: ['İçerik bulunamadı.'] };
  if (!canTransition(item.status, to))
    return { ok: false, errors: [`Geçersiz geçiş: ${item.status} → ${to}`] };

  await db
    .update(contentItems)
    .set({
      status: to,
      publishedAt: to === 'published' ? new Date() : item.publishedAt,
      updatedAt: new Date(),
    })
    .where(eq(contentItems.id, id));
  await db.insert(contentVersions).values({
    id: newId(),
    contentId: id,
    version: item.version,
    status: to,
    payload: item.payload as object,
    changedBy: user.id,
  });
  await audit(user.id, `content.${to}`, item.type, id, { from: item.status });

  // Arama indeksleme kancası (Epic 5): yayınla/emekliye ayır → sağlayıcıya bildir.
  if (to === 'published' || to === 'retired') {
    const { getSearchProvider } = await import('../search');
    await getSearchProvider().indexContent([
      { id: item.id, type: item.type, title: item.title, status: to },
    ]);
  }
  return { ok: true, status: to };
}

export interface ContentFilter {
  type?: string;
  status?: string;
  q?: string;
  limit?: number;
}
export async function listContent(filter: ContentFilter) {
  const db = await getDb();
  const conds = [];
  if (filter.type) conds.push(eq(contentItems.type, filter.type));
  if (filter.status) conds.push(eq(contentItems.status, filter.status));
  const rows = await db
    .select({
      id: contentItems.id,
      type: contentItems.type,
      slug: contentItems.slug,
      title: contentItems.title,
      status: contentItems.status,
      version: contentItems.version,
      updatedAt: contentItems.updatedAt,
      publishedAt: contentItems.publishedAt,
    })
    .from(contentItems)
    .where(conds.length ? and(...conds) : undefined)
    .orderBy(desc(contentItems.updatedAt))
    .limit(Math.min(filter.limit ?? 50, 200));
  const q = (filter.q ?? '').toLocaleLowerCase('tr');
  return q
    ? rows.filter((r) => (r.title + ' ' + r.slug).toLocaleLowerCase('tr').includes(q))
    : rows;
}

export async function getContent(id: string) {
  const db = await getDb();
  const rows = await db.select().from(contentItems).where(eq(contentItems.id, id));
  if (!rows[0]) return null;
  const versions = await db
    .select({
      version: contentVersions.version,
      status: contentVersions.status,
      changedBy: contentVersions.changedBy,
      createdAt: contentVersions.createdAt,
    })
    .from(contentVersions)
    .where(eq(contentVersions.contentId, id))
    .orderBy(desc(contentVersions.createdAt))
    .limit(20);
  return { ...rows[0], versions };
}

/** Yayındaki içerik — halka açık yüzeyler için (dersler/makaleler). */
export async function listPublished(type: ContentType) {
  const db = await getDb();
  return db
    .select({
      id: contentItems.id,
      slug: contentItems.slug,
      title: contentItems.title,
      payload: contentItems.payload,
      publishedAt: contentItems.publishedAt,
    })
    .from(contentItems)
    .where(and(eq(contentItems.type, type), eq(contentItems.status, 'published')))
    .orderBy(desc(contentItems.publishedAt));
}

/* ---------- medya ---------- */
const MAX_MEDIA_BYTES = 2 * 1024 * 1024; // 2MB temel sınır
const ALLOWED_MIME: Record<string, string> = {
  'image/svg+xml': 'svg',
  'image/png': 'image',
  'image/jpeg': 'image',
  'image/webp': 'image',
  'application/json': 'lottie',
};

export async function uploadMedia(
  user: SessionUser,
  input: { filename: string; mime: string; dataBase64: string; alt?: string; tags?: string[] }
): Promise<{ ok: true; id: string } | { ok: false; errors: string[] }> {
  const kind = ALLOWED_MIME[input.mime];
  if (!kind) return { ok: false, errors: [`Desteklenmeyen tür: ${input.mime}`] };
  const bytes = Math.floor((input.dataBase64.length * 3) / 4);
  if (bytes > MAX_MEDIA_BYTES) return { ok: false, errors: ['Dosya 2MB sınırını aşıyor.'] };
  const db = await getDb();
  const id = newId();
  await db.insert(mediaAssets).values({
    id,
    kind,
    filename: input.filename.slice(0, 120),
    mime: input.mime,
    bytes,
    alt: input.alt ?? '',
    tags: input.tags ?? [],
    dataBase64: input.dataBase64,
    createdBy: user.id,
  });
  await audit(user.id, 'media.upload', 'media', id, { filename: input.filename, bytes });
  return { ok: true, id };
}

export async function listMedia() {
  const db = await getDb();
  return db
    .select({
      id: mediaAssets.id,
      kind: mediaAssets.kind,
      filename: mediaAssets.filename,
      mime: mediaAssets.mime,
      bytes: mediaAssets.bytes,
      alt: mediaAssets.alt,
      createdAt: mediaAssets.createdAt,
    })
    .from(mediaAssets)
    .orderBy(desc(mediaAssets.createdAt))
    .limit(200);
}

export async function getMedia(id: string) {
  const db = await getDb();
  const rows = await db.select().from(mediaAssets).where(eq(mediaAssets.id, id));
  return rows[0] ?? null;
}

/* ---------- kullanıcılar / istatistik ---------- */
export async function listUsers() {
  const db = await getDb();
  return db
    .select({
      id: users.id,
      email: users.email,
      name: users.name,
      role: users.role,
      createdAt: users.createdAt,
    })
    .from(users)
    .orderBy(desc(users.createdAt))
    .limit(200);
}

export async function setUserRole(
  actor: SessionUser,
  userId: string,
  role: 'user' | 'editor' | 'admin'
) {
  const db = await getDb();
  await db.update(users).set({ role }).where(eq(users.id, userId));
  await audit(actor.id, 'user.role', 'user', userId, { role });
}

export async function listAudit(limit = 50) {
  const db = await getDb();
  return db
    .select({
      id: auditLogs.id,
      userId: auditLogs.userId,
      action: auditLogs.action,
      entity: auditLogs.entity,
      entityId: auditLogs.entityId,
      at: auditLogs.at,
    })
    .from(auditLogs)
    .orderBy(desc(auditLogs.at))
    .limit(limit);
}

export async function adminStats() {
  const db = await getDb();
  const count = async (t: 'content' | 'media' | 'users' | 'published') => {
    if (t === 'content')
      return Number((await db.select({ n: sql<number>`count(*)` }).from(contentItems))[0]?.n ?? 0);
    if (t === 'published')
      return Number(
        (
          await db
            .select({ n: sql<number>`count(*)` })
            .from(contentItems)
            .where(eq(contentItems.status, 'published'))
        )[0]?.n ?? 0
      );
    if (t === 'media')
      return Number((await db.select({ n: sql<number>`count(*)` }).from(mediaAssets))[0]?.n ?? 0);
    return Number((await db.select({ n: sql<number>`count(*)` }).from(users))[0]?.n ?? 0);
  };
  return {
    content: await count('content'),
    published: await count('published'),
    media: await count('media'),
    users: await count('users'),
  };
}
