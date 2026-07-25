import { and, desc, eq, lt } from 'drizzle-orm';
import { getDb, discussionThreads } from '@ea/db';
import { getSessionUser, json, guarded, newId } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { isLicence } from '@/lib/server/community';
import {
  parseCursor,
  parseLimit,
  validateQuestionRef,
  validateThreadTitle,
} from '@/lib/server/social';
import { hasCommunityProfile, hiddenUserIds, profilesByIds } from '@/lib/server/social-guards';

/**
 * Tartışma başlıkları (Evolution Faz E9) — ehliyet sınıfına göre kapsamlanır.
 *
 * SORU PAYLAŞIMI REFERANSLADIR: `questionRef` yalnız bankadaki soru KİMLİĞİDİR. Soru metni asla
 * kopyalanmaz; istemci kimliği kendi yerel bankasından çözer. Böylece banka bir tartışma akışına
 * dökülemez (roadmap: "share by reference — never a copied dump of the bank").
 *
 * ENGELLEME: engellenen kullanıcıların başlıkları listede GÖRÜNMEZ.
 */

export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const url = new URL(req.url);
  const licenceParam = url.searchParams.get('licence');
  const licence = isLicence(licenceParam) ? licenceParam : null;
  const limit = parseLimit(url.searchParams.get('limit'));
  const cursor = parseCursor(url.searchParams.get('before'));

  const db = await getDb();
  const where = [
    licence ? eq(discussionThreads.licence, licence) : undefined,
    cursor ? lt(discussionThreads.lastActivityAt, cursor) : undefined,
  ].filter(Boolean);

  const rows = await db
    .select()
    .from(discussionThreads)
    .where(where.length === 0 ? undefined : where.length === 1 ? where[0] : and(...where))
    .orderBy(desc(discussionThreads.lastActivityAt))
    .limit(limit);

  const hidden = await hiddenUserIds(user.id);
  const visible = rows.filter((t) => !hidden.has(t.authorId));
  const profiles = await profilesByIds(visible.map((t) => t.authorId));

  return json({
    licence: licence ?? 'all',
    threads: visible.map((t) => ({
      id: t.id,
      title: t.title,
      licence: t.licence,
      questionRef: t.questionRef,
      postCount: t.postCount,
      lastActivityAt: t.lastActivityAt,
      author: {
        userId: t.authorId,
        displayName: profiles.get(t.authorId)?.displayName ?? '',
        avatarId: profiles.get(t.authorId)?.avatarId ?? 'owl-wave',
      },
    })),
    nextCursor: rows.length === limit ? rows[rows.length - 1]!.lastActivityAt : null,
  });
});

export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, {
    bucket: 'community-discussions',
    limit: 10,
    windowMs: 60_000,
  });
  if (limited) return limited;

  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });
  if (!(await hasCommunityProfile(user.id))) {
    return json({ error: 'Önce topluluğa katılmalısın.' }, { status: 409 });
  }

  let body: { title?: unknown; licence?: unknown; questionRef?: unknown };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }

  const title = validateThreadTitle(body.title);
  if (!title.ok) return json({ error: title.error }, { status: 400 });
  const licence = isLicence(body.licence) ? body.licence : 'b';
  // Geçersiz referans sessizce DÜŞÜRÜLÜR (soru metni buraya asla girmez).
  const questionRef = validateQuestionRef(body.questionRef);

  const db = await getDb();
  const id = newId();
  const now = new Date();
  await db.insert(discussionThreads).values({
    id,
    licence,
    title: title.value,
    authorId: user.id,
    questionRef,
    postCount: 0,
    createdAt: now,
    lastActivityAt: now,
  });

  return json({ id, title: title.value, licence, questionRef }, { status: 201 });
});
