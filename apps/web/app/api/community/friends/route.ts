import { and, eq, or } from 'drizzle-orm';
import { getDb, friendships } from '@ea/db';
import { getSessionUser, json, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { canAccept, canSendRequest, friendStateFor, type FriendshipRow } from '@/lib/server/social';
import {
  hasCommunityProfile,
  hiddenUserIds,
  isBlockedBetween,
  profilesByIds,
} from '@/lib/server/social-guards';

/**
 * Arkadaşlık grafiği (Evolution Faz E9).
 *
 * ENGELLEME: her yolda kontrol edilir — engelli biriyle istek gönderilemez, kabul edilemez ve
 * listelerde görünmez. Engel varlığı SIZDIRILMAZ: "kullanıcı bulunamadı" ile aynı 404 döner.
 *
 * KATILIM: sosyal özellikler topluluk profiline (E8 opt-in) bağlıdır; katılmayan kullanıcı ne
 * istek gönderebilir ne de hedef olabilir.
 */

async function findRow(a: string, b: string): Promise<FriendshipRow | null> {
  const db = await getDb();
  const rows = await db
    .select()
    .from(friendships)
    .where(
      or(
        and(eq(friendships.requesterId, a), eq(friendships.addresseeId, b)),
        and(eq(friendships.requesterId, b), eq(friendships.addresseeId, a))
      )
    )
    .limit(1);
  const r = rows[0];
  return r
    ? {
        requesterId: r.requesterId,
        addresseeId: r.addresseeId,
        status: r.status === 'accepted' ? 'accepted' : 'pending',
      }
    : null;
}

/** Arkadaşlar + bekleyen istekler (gelen/giden ayrı). */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const db = await getDb();
  const rows = await db
    .select()
    .from(friendships)
    .where(or(eq(friendships.requesterId, user.id), eq(friendships.addresseeId, user.id)));

  const hidden = await hiddenUserIds(user.id);
  const visible = rows.filter(
    (r) => !hidden.has(r.requesterId === user.id ? r.addresseeId : r.requesterId)
  );
  const otherIds = visible.map((r) => (r.requesterId === user.id ? r.addresseeId : r.requesterId));
  const profiles = await profilesByIds(otherIds);

  const shape = (r: (typeof visible)[number]) => {
    const otherId = r.requesterId === user.id ? r.addresseeId : r.requesterId;
    const p = profiles.get(otherId);
    return {
      userId: otherId,
      displayName: p?.displayName ?? '',
      avatarId: p?.avatarId ?? 'owl-wave',
      avatarUrl: p?.avatarUrl ?? null,
      licence: p?.licence ?? 'b',
      state: friendStateFor(
        {
          requesterId: r.requesterId,
          addresseeId: r.addresseeId,
          status: r.status === 'accepted' ? 'accepted' : 'pending',
        },
        user.id
      ),
    };
  };

  const all = visible.map(shape).filter((x) => x.displayName !== '');
  return json({
    friends: all.filter((x) => x.state === 'friends'),
    incoming: all.filter((x) => x.state === 'incoming'),
    outgoing: all.filter((x) => x.state === 'outgoing'),
  });
});

/** İstek gönder veya geleni kabul et (`action: 'request' | 'accept'`). */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'community-friends', limit: 30, windowMs: 60_000 });
  if (limited) return limited;

  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });
  if (!(await hasCommunityProfile(user.id))) {
    return json({ error: 'Önce topluluğa katılmalısın.' }, { status: 409 });
  }

  let body: { targetUserId?: unknown; action?: unknown };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const targetUserId = typeof body.targetUserId === 'string' ? body.targetUserId : '';
  if (!targetUserId) return json({ error: 'Kullanıcı gerekli.' }, { status: 400 });
  // Kendine istek bir ÇAKIŞMA değil, istemci hatasıdır → 400 (409 ile karıştırılmasın).
  if (targetUserId === user.id) {
    return json({ error: 'Kendine arkadaşlık isteği gönderemezsin.' }, { status: 400 });
  }

  // Engel ve katılım kontrolü — ikisi de AYNI 404 ile cevaplanır (durum sızdırılmaz).
  if (await isBlockedBetween(user.id, targetUserId)) {
    return json({ error: 'Kullanıcı bulunamadı.' }, { status: 404 });
  }
  if (!(await hasCommunityProfile(targetUserId))) {
    return json({ error: 'Kullanıcı bulunamadı.' }, { status: 404 });
  }

  const db = await getDb();
  const existing = await findRow(user.id, targetUserId);
  const action = body.action === 'accept' ? 'accept' : 'request';

  if (action === 'accept') {
    const check = canAccept(existing, user.id);
    if (!check.ok) return json({ error: check.error }, { status: 409 });
    await db
      .update(friendships)
      .set({ status: 'accepted', respondedAt: new Date() })
      .where(
        and(
          eq(friendships.requesterId, existing!.requesterId),
          eq(friendships.addresseeId, existing!.addresseeId)
        )
      );
    return json({ state: 'friends' });
  }

  const check = canSendRequest(existing, user.id, targetUserId);
  if (!check.ok) return json({ error: check.error, state: check.state }, { status: 409 });

  await db
    .insert(friendships)
    .values({ requesterId: user.id, addresseeId: targetUserId, status: 'pending' })
    .onConflictDoNothing();
  return json({ state: 'outgoing' }, { status: 201 });
});

/** İsteği reddet / arkadaşlığı kaldır — her iki durumda satır SİLİNİR. */
export const DELETE = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const url = new URL(req.url);
  const targetUserId = url.searchParams.get('targetUserId') ?? '';
  if (!targetUserId) return json({ error: 'Kullanıcı gerekli.' }, { status: 400 });

  const db = await getDb();
  await db
    .delete(friendships)
    .where(
      or(
        and(eq(friendships.requesterId, user.id), eq(friendships.addresseeId, targetUserId)),
        and(eq(friendships.requesterId, targetUserId), eq(friendships.addresseeId, user.id))
      )
    );
  return json({ state: 'none' });
});
