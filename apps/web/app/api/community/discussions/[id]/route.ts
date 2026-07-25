import { and, asc, eq, gt, sql } from 'drizzle-orm';
import { getDb, discussionPosts, discussionThreads } from '@ea/db';
import { getSessionUser, json, guarded, newId } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import {
  parseCursor,
  parseLimit,
  validatePostBody,
  validateQuestionRef,
} from '@/lib/server/social';
import { hasCommunityProfile, hiddenUserIds, profilesByIds } from '@/lib/server/social-guards';

/**
 * Bir tartışma başlığının iletileri (Evolution Faz E9).
 *
 * NOT: `guarded` yalnız `req`'i iletir (Next context argümanını GEÇİRMEZ) → başlık kimliği yol
 * üzerinden okunur. Bu, E8'de öğrenilen ve orada da uygulanan desendir.
 *
 * ENGELLEME: engellenen yazarların iletileri listede görünmez.
 */

function threadIdFrom(req: Request): string {
  const parts = new URL(req.url).pathname.split('/');
  return decodeURIComponent(parts[parts.length - 1] ?? '');
}

export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const threadId = threadIdFrom(req);
  const db = await getDb();
  const [thread] = await db
    .select()
    .from(discussionThreads)
    .where(eq(discussionThreads.id, threadId))
    .limit(1);
  if (!thread) return json({ error: 'Başlık bulunamadı.' }, { status: 404 });

  const hidden = await hiddenUserIds(user.id);
  if (hidden.has(thread.authorId)) {
    // Engelli yazarın başlığı — varlığı sızdırılmaz.
    return json({ error: 'Başlık bulunamadı.' }, { status: 404 });
  }

  const url = new URL(req.url);
  const limit = parseLimit(url.searchParams.get('limit'));
  const cursor = parseCursor(url.searchParams.get('after'));

  const rows = await db
    .select()
    .from(discussionPosts)
    .where(
      cursor
        ? and(eq(discussionPosts.threadId, threadId), gt(discussionPosts.createdAt, cursor))
        : eq(discussionPosts.threadId, threadId)
    )
    .orderBy(asc(discussionPosts.createdAt))
    .limit(limit);

  const visible = rows.filter((p) => !hidden.has(p.authorId));
  const profiles = await profilesByIds([...visible.map((p) => p.authorId), thread.authorId]);

  return json({
    thread: {
      id: thread.id,
      title: thread.title,
      licence: thread.licence,
      questionRef: thread.questionRef,
      postCount: thread.postCount,
      author: {
        userId: thread.authorId,
        displayName: profiles.get(thread.authorId)?.displayName ?? '',
        avatarId: profiles.get(thread.authorId)?.avatarId ?? 'owl-wave',
      },
    },
    posts: visible.map((p) => ({
      id: p.id,
      body: p.body,
      questionRef: p.questionRef,
      createdAt: p.createdAt,
      author: {
        userId: p.authorId,
        displayName: profiles.get(p.authorId)?.displayName ?? '',
        avatarId: profiles.get(p.authorId)?.avatarId ?? 'owl-wave',
      },
      mine: p.authorId === user.id,
    })),
    nextCursor: rows.length === limit ? rows[rows.length - 1]!.createdAt : null,
  });
});

export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'community-posts', limit: 20, windowMs: 60_000 });
  if (limited) return limited;

  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });
  if (!(await hasCommunityProfile(user.id))) {
    return json({ error: 'Önce topluluğa katılmalısın.' }, { status: 409 });
  }

  const threadId = threadIdFrom(req);
  const db = await getDb();
  const [thread] = await db
    .select()
    .from(discussionThreads)
    .where(eq(discussionThreads.id, threadId))
    .limit(1);
  if (!thread) return json({ error: 'Başlık bulunamadı.' }, { status: 404 });

  const hidden = await hiddenUserIds(user.id);
  if (hidden.has(thread.authorId)) return json({ error: 'Başlık bulunamadı.' }, { status: 404 });

  let body: { body?: unknown; questionRef?: unknown };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const text = validatePostBody(body.body);
  if (!text.ok) return json({ error: text.error }, { status: 400 });

  const now = new Date();
  const id = newId();
  await db.insert(discussionPosts).values({
    id,
    threadId,
    authorId: user.id,
    body: text.value,
    questionRef: validateQuestionRef(body.questionRef),
    createdAt: now,
  });
  await db
    .update(discussionThreads)
    .set({ postCount: sql`${discussionThreads.postCount} + 1`, lastActivityAt: now })
    .where(eq(discussionThreads.id, threadId));

  return json({ id, body: text.value, createdAt: now }, { status: 201 });
});
