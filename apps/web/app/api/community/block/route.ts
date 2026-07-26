import { and, eq } from 'drizzle-orm';
import { getDb, communityBlocks, communityProfiles } from '@ea/db';
import { getSessionUser, json, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { avatarUrlFor } from '@/lib/server/community';

/**
 * Engelleme (Evolution Faz E8).
 *
 * Engelleme SUNUCUDA uygulanır: sıralama ve profil uçları her iki yönü de düşürür (engellediğin ve
 * seni engelleyen). İstemci tarafı filtreye güvenilmez — engellenen kullanıcı istemciyi değiştirerek
 * görünür hâle gelemez.
 */

async function requireUser(req: Request) {
  const user = await getSessionUser(req);
  return user;
}

export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await requireUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const db = await getDb();
  const rows = await db
    .select({
      userId: communityBlocks.blockedId,
      displayName: communityProfiles.displayName,
      avatarId: communityProfiles.avatarId,
      avatarMediaId: communityProfiles.avatarMediaId,
    })
    .from(communityBlocks)
    .leftJoin(communityProfiles, eq(communityProfiles.userId, communityBlocks.blockedId))
    .where(eq(communityBlocks.blockerId, user.id));

  return json({
    blocked: rows.map(({ avatarMediaId, ...rest }) => ({
      ...rest,
      avatarUrl: avatarUrlFor(avatarMediaId),
    })),
  });
});

export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'community-block', limit: 30, windowMs: 60_000 });
  if (limited) return limited;

  const user = await requireUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  let body: { targetUserId?: unknown };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const targetUserId = typeof body.targetUserId === 'string' ? body.targetUserId : '';
  if (!targetUserId) return json({ error: 'Kullanıcı gerekli.' }, { status: 400 });
  if (targetUserId === user.id) return json({ error: 'Kendini engelleyemezsin.' }, { status: 400 });

  const db = await getDb();
  const [target] = await db
    .select({ userId: communityProfiles.userId })
    .from(communityProfiles)
    .where(eq(communityProfiles.userId, targetUserId))
    .limit(1);
  if (!target) return json({ error: 'Kullanıcı bulunamadı.' }, { status: 404 });

  await db
    .insert(communityBlocks)
    .values({ blockerId: user.id, blockedId: targetUserId })
    .onConflictDoNothing();

  return json({ ok: true }, { status: 201 });
});

export const DELETE = guarded(async (req: Request): Promise<Response> => {
  const user = await requireUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const url = new URL(req.url);
  const targetUserId = url.searchParams.get('targetUserId') ?? '';
  if (!targetUserId) return json({ error: 'Kullanıcı gerekli.' }, { status: 400 });

  const db = await getDb();
  await db
    .delete(communityBlocks)
    .where(
      and(eq(communityBlocks.blockerId, user.id), eq(communityBlocks.blockedId, targetUserId))
    );
  return json({ ok: true });
});
