import { and, asc, eq, sql } from 'drizzle-orm';
import { getDb, studyGroups, studyGroupMembers } from '@ea/db';
import { getSessionUser, json, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { canJoinGroup, normalizeJoinCode } from '@/lib/server/groups';
import { hasCommunityProfile, isBlockedBetween } from '@/lib/server/social-guards';

/**
 * Kodla gruba katılma / gruptan ayrılma (Evolution Faz E10).
 *
 * KOD DENEME SALDIRISI: kod 6 karakter × 31 harflik alfabe ≈ 8,9×10⁸ olasılık; ayrıca IP başına
 * dakikada 10 denemeye sınırlanır. Geçersiz kod ile "grup yok" ayrımı yapılmaz — aynı 404.
 * ENGELLEME: grubun SAHİBİYLE aranda engel varsa gruba katılamazsın (E9 ilkesinin devamı).
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, {
    bucket: 'community-group-join',
    limit: 10,
    windowMs: 60_000,
  });
  if (limited) return limited;

  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });
  if (!(await hasCommunityProfile(user.id))) {
    return json({ error: 'Önce topluluğa katılmalısın.' }, { status: 409 });
  }

  let body: { code?: unknown };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }

  const code = normalizeJoinCode(body.code);
  if (!code) return json({ error: 'Kod 6 karakter olmalı.' }, { status: 400 });

  const db = await getDb();
  const [group] = await db
    .select()
    .from(studyGroups)
    .where(eq(studyGroups.joinCode, code))
    .limit(1);
  if (!group) return json({ error: 'Grup bulunamadı.' }, { status: 404 });

  // Engel varsa grubun varlığı bile sızdırılmaz — aynı 404.
  if (await isBlockedBetween(user.id, group.ownerId)) {
    return json({ error: 'Grup bulunamadı.' }, { status: 404 });
  }

  const mine = await db
    .select({ groupId: studyGroupMembers.groupId })
    .from(studyGroupMembers)
    .where(eq(studyGroupMembers.userId, user.id));
  const already = mine.some((m) => m.groupId === group.id);

  const cap = canJoinGroup(mine.length, group.memberCount, already);
  if (!cap.ok) return json({ error: cap.error }, { status: 409 });

  await db
    .insert(studyGroupMembers)
    .values({ groupId: group.id, userId: user.id, role: 'member' })
    .onConflictDoNothing();
  await db
    .update(studyGroups)
    .set({ memberCount: sql`${studyGroups.memberCount} + 1` })
    .where(eq(studyGroups.id, group.id));

  return json(
    { id: group.id, name: group.name, licence: group.licence, memberCount: group.memberCount + 1 },
    { status: 201 }
  );
});

/**
 * Gruptan ayrıl. Sahibi ayrılırsa sahiplik **en eski üyeye** devredilir; başka üye yoksa grup silinir
 * → sahipsiz grup kalmaz.
 */
export const DELETE = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const groupId = new URL(req.url).searchParams.get('groupId') ?? '';
  if (!groupId) return json({ error: 'Grup gerekli.' }, { status: 400 });

  const db = await getDb();
  const [membership] = await db
    .select()
    .from(studyGroupMembers)
    .where(and(eq(studyGroupMembers.groupId, groupId), eq(studyGroupMembers.userId, user.id)))
    .limit(1);
  if (!membership) return json({ error: 'Grup bulunamadı.' }, { status: 404 });

  await db
    .delete(studyGroupMembers)
    .where(and(eq(studyGroupMembers.groupId, groupId), eq(studyGroupMembers.userId, user.id)));

  const remaining = await db
    .select({ userId: studyGroupMembers.userId })
    .from(studyGroupMembers)
    .where(eq(studyGroupMembers.groupId, groupId))
    .orderBy(asc(studyGroupMembers.joinedAt));

  if (remaining.length === 0) {
    // Son üye de ayrıldı → boş grup bırakma.
    await db.delete(studyGroups).where(eq(studyGroups.id, groupId));
    return json({ ok: true, groupDeleted: true });
  }

  if (membership.role === 'owner') {
    const heir = remaining[0]!.userId;
    await db.update(studyGroups).set({ ownerId: heir }).where(eq(studyGroups.id, groupId));
    await db
      .update(studyGroupMembers)
      .set({ role: 'owner' })
      .where(and(eq(studyGroupMembers.groupId, groupId), eq(studyGroupMembers.userId, heir)));
  }

  await db
    .update(studyGroups)
    .set({ memberCount: remaining.length })
    .where(eq(studyGroups.id, groupId));

  return json({ ok: true, groupDeleted: false });
});
