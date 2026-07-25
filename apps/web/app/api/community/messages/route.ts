import { and, desc, eq, gt, lt, or } from 'drizzle-orm';
import { getDb, directMessages, friendships } from '@ea/db';
import { getSessionUser, json, guarded, newId } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import {
  MESSAGE_BURST_WINDOW_MS,
  otherParty,
  parseCursor,
  parseLimit,
  threadKey,
  validateMessageBody,
  withinBurstLimit,
} from '@/lib/server/social';
import {
  hasCommunityProfile,
  hiddenUserIds,
  isBlockedBetween,
  profilesByIds,
} from '@/lib/server/social-guards';

/**
 * Birebir mesajlaşma (Evolution Faz E9) — YALNIZ METİN.
 *
 * KURALLAR:
 * - Yalnız **arkadaşlar** yazışabilir. Rastgele kullanıcıya mesaj atılamaz (taciz yüzeyini kapatır).
 * - Engel her okuma ve yazma yolunda kontrol edilir; engelli konuşma listelenmez ve yazılamaz.
 * - Mesaj uzunluğu ve **ani gönderim (burst)** sınırı sunucuda uygulanır.
 * - Sayfalama imleçlidir → sınırsız büyüme yolu yoktur.
 *
 * GERÇEK ZAMANLI DEĞİLDİR: kalıcı WebSocket yoktur; istemci ön planda kısa aralıkla yoklar.
 */

async function areFriends(a: string, b: string): Promise<boolean> {
  const db = await getDb();
  const rows = await db
    .select({ status: friendships.status })
    .from(friendships)
    .where(
      or(
        and(eq(friendships.requesterId, a), eq(friendships.addresseeId, b)),
        and(eq(friendships.requesterId, b), eq(friendships.addresseeId, a))
      )
    )
    .limit(1);
  return rows[0]?.status === 'accepted';
}

/** Konuşma listesi (her karşı taraf için son mesaj) veya `?with=<userId>` ile tek konuşma. */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const db = await getDb();
  const url = new URL(req.url);
  const withUser = url.searchParams.get('with');

  if (withUser) {
    // Tek konuşma — engel varsa AYNI 404 (durum sızdırılmaz).
    if (await isBlockedBetween(user.id, withUser)) {
      return json({ error: 'Konuşma bulunamadı.' }, { status: 404 });
    }
    const limit = parseLimit(url.searchParams.get('limit'));
    const cursor = parseCursor(url.searchParams.get('before'));
    const key = threadKey(user.id, withUser);

    const rows = await db
      .select()
      .from(directMessages)
      .where(
        cursor
          ? and(eq(directMessages.threadKey, key), lt(directMessages.createdAt, cursor))
          : eq(directMessages.threadKey, key)
      )
      .orderBy(desc(directMessages.createdAt))
      .limit(limit);

    return json({
      with: withUser,
      messages: rows
        .map((m) => ({
          id: m.id,
          senderId: m.senderId,
          body: m.body,
          createdAt: m.createdAt,
          mine: m.senderId === user.id,
        }))
        .reverse(), // istemciye eskiden yeniye
      nextCursor: rows.length === limit ? rows[rows.length - 1]!.createdAt : null,
    });
  }

  // Konuşma listesi: bu kullanıcının taraf olduğu tüm mesajlardan son olanları topla.
  const rows = await db
    .select()
    .from(directMessages)
    .where(or(eq(directMessages.senderId, user.id), eq(directMessages.recipientId, user.id)))
    .orderBy(desc(directMessages.createdAt))
    .limit(500);

  const hidden = await hiddenUserIds(user.id);
  const latest = new Map<string, { body: string; createdAt: Date; unread: boolean }>();
  for (const m of rows) {
    const other = otherParty(m.threadKey, user.id);
    if (!other || hidden.has(other) || latest.has(other)) continue;
    latest.set(other, {
      body: m.body,
      createdAt: m.createdAt,
      unread: m.recipientId === user.id && m.readAt === null,
    });
  }

  const profiles = await profilesByIds([...latest.keys()]);
  return json({
    threads: [...latest.entries()].map(([userId, v]) => ({
      userId,
      displayName: profiles.get(userId)?.displayName ?? '',
      avatarId: profiles.get(userId)?.avatarId ?? 'owl-wave',
      lastMessage: v.body,
      lastAt: v.createdAt,
      unread: v.unread,
    })),
  });
});

/** Mesaj gönder. */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, {
    bucket: 'community-messages',
    limit: 40,
    windowMs: 60_000,
  });
  if (limited) return limited;

  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });
  if (!(await hasCommunityProfile(user.id))) {
    return json({ error: 'Önce topluluğa katılmalısın.' }, { status: 409 });
  }

  let body: { targetUserId?: unknown; body?: unknown };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const targetUserId = typeof body.targetUserId === 'string' ? body.targetUserId : '';
  if (!targetUserId || targetUserId === user.id) {
    return json({ error: 'Geçersiz alıcı.' }, { status: 400 });
  }

  if (await isBlockedBetween(user.id, targetUserId)) {
    return json({ error: 'Konuşma bulunamadı.' }, { status: 404 });
  }
  // Yalnız arkadaşlar yazışabilir — rastgele kullanıcıya mesaj yüzeyi yoktur.
  if (!(await areFriends(user.id, targetUserId))) {
    return json({ error: 'Yalnız arkadaşlarınla mesajlaşabilirsin.' }, { status: 403 });
  }

  const text = validateMessageBody(body.body);
  if (!text.ok) return json({ error: text.error }, { status: 400 });

  const db = await getDb();
  // Kişi-başına ani gönderim sınırı (IP sınırının üstüne).
  const since = new Date(Date.now() - MESSAGE_BURST_WINDOW_MS);
  const recent = await db
    .select({ id: directMessages.id })
    .from(directMessages)
    .where(and(eq(directMessages.senderId, user.id), gt(directMessages.createdAt, since)));
  if (!withinBurstLimit(recent.length)) {
    return json({ error: 'Çok hızlı mesaj gönderiyorsun. Biraz bekle.' }, { status: 429 });
  }

  const now = new Date();
  const id = newId();
  await db.insert(directMessages).values({
    id,
    threadKey: threadKey(user.id, targetUserId),
    senderId: user.id,
    recipientId: targetUserId,
    body: text.value,
    createdAt: now,
  });

  return json({ id, body: text.value, createdAt: now }, { status: 201 });
});
