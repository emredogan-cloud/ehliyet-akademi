import { and, eq, inArray, sql } from 'drizzle-orm';
import { getDb, studyGroups, studyGroupMembers, communityStats } from '@ea/db';
import { getSessionUser, json, guarded, newId } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { isLicence } from '@/lib/server/community';
import {
  canCreateGroup,
  makeJoinCode,
  validateGroupName,
  JOIN_CODE_LENGTH,
} from '@/lib/server/groups';
import { hasCommunityProfile } from '@/lib/server/social-guards';

/**
 * Çalışma grupları (Evolution Faz E10).
 *
 * KATILIM KODU yalnız ÜYELERE gösterilir — listeleme uçları kodu döndürmez, aksi hâlde kod bir
 * "herkese açık davet" hâline gelir ve grup mevcudu tavanı anlamsızlaşır.
 * TAVANLAR sunucuda uygulanır (`lib/server/groups.ts`): sınırsız büyüme yolu yoktur.
 */

/** Bir grubun toplu istatistiği — üyelerin KIRPILMIŞ sayaçlarından türetilir. */
async function groupTotals(
  groupIds: string[]
): Promise<Map<string, { xp: number; answered: number }>> {
  const out = new Map<string, { xp: number; answered: number }>();
  if (groupIds.length === 0) return out;
  const db = await getDb();
  const rows = await db
    .select({
      groupId: studyGroupMembers.groupId,
      xp: sql<number>`coalesce(sum(${communityStats.xp}), 0)`,
      answered: sql<number>`coalesce(sum(${communityStats.answered}), 0)`,
    })
    .from(studyGroupMembers)
    .leftJoin(communityStats, eq(communityStats.userId, studyGroupMembers.userId))
    .where(inArray(studyGroupMembers.groupId, groupIds))
    .groupBy(studyGroupMembers.groupId);
  for (const r of rows) out.set(r.groupId, { xp: Number(r.xp), answered: Number(r.answered) });
  return out;
}

/** Üyesi olduğum gruplar. */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const db = await getDb();
  const rows = await db
    .select({
      id: studyGroups.id,
      name: studyGroups.name,
      licence: studyGroups.licence,
      joinCode: studyGroups.joinCode,
      ownerId: studyGroups.ownerId,
      memberCount: studyGroups.memberCount,
      role: studyGroupMembers.role,
    })
    .from(studyGroupMembers)
    .innerJoin(studyGroups, eq(studyGroups.id, studyGroupMembers.groupId))
    .where(eq(studyGroupMembers.userId, user.id));

  const totals = await groupTotals(rows.map((r) => r.id));
  return json({
    groups: rows.map((g) => ({
      id: g.id,
      name: g.name,
      licence: g.licence,
      // Üyeyim → kodu görebilirim (davet edebilmek için).
      joinCode: g.joinCode,
      isOwner: g.ownerId === user.id,
      memberCount: g.memberCount,
      totalXp: totals.get(g.id)?.xp ?? 0,
      totalAnswered: totals.get(g.id)?.answered ?? 0,
    })),
  });
});

/** Grup kur. Kuran kişi otomatik olarak `owner` üyedir. */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'community-groups', limit: 10, windowMs: 60_000 });
  if (limited) return limited;

  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });
  if (!(await hasCommunityProfile(user.id))) {
    return json({ error: 'Önce topluluğa katılmalısın.' }, { status: 409 });
  }

  let body: { name?: unknown; licence?: unknown };
  try {
    body = (await req.json()) as typeof body;
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }

  const name = validateGroupName(body.name);
  if (!name.ok) return json({ error: name.error }, { status: 400 });
  const licence = isLicence(body.licence) ? body.licence : 'b';

  const db = await getDb();
  const owned = await db
    .select({ id: studyGroups.id })
    .from(studyGroups)
    .where(eq(studyGroups.ownerId, user.id));
  const cap = canCreateGroup(owned.length);
  if (!cap.ok) return json({ error: cap.error }, { status: 409 });

  // Kod çakışması olasılığı düşük ama SIFIR değil → benzersiz dizine güvenip birkaç kez dene.
  const id = newId();
  let joinCode = '';
  for (let attempt = 0; attempt < 5; attempt++) {
    const candidate = makeJoinCode(Math.random);
    const clash = await db
      .select({ id: studyGroups.id })
      .from(studyGroups)
      .where(eq(studyGroups.joinCode, candidate))
      .limit(1);
    if (clash.length === 0) {
      joinCode = candidate;
      break;
    }
  }
  if (joinCode.length !== JOIN_CODE_LENGTH) {
    return json({ error: 'Kod üretilemedi, tekrar dene.' }, { status: 503 });
  }

  await db
    .insert(studyGroups)
    .values({ id, name: name.value, joinCode, licence, ownerId: user.id, memberCount: 1 });
  await db
    .insert(studyGroupMembers)
    .values({ groupId: id, userId: user.id, role: 'owner' })
    .onConflictDoNothing();

  return json({ id, name: name.value, joinCode, licence, memberCount: 1 }, { status: 201 });
});

/** Grubu sil — YALNIZ sahibi. Üyelikler cascade ile düşer. */
export const DELETE = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const groupId = new URL(req.url).searchParams.get('groupId') ?? '';
  if (!groupId) return json({ error: 'Grup gerekli.' }, { status: 400 });

  const db = await getDb();
  const [group] = await db.select().from(studyGroups).where(eq(studyGroups.id, groupId)).limit(1);
  // Yoksa da, benim değilse de AYNI 404 → başkasının grubunun varlığı sızmaz.
  if (!group || group.ownerId !== user.id) {
    return json({ error: 'Grup bulunamadı.' }, { status: 404 });
  }

  await db
    .delete(studyGroups)
    .where(and(eq(studyGroups.id, groupId), eq(studyGroups.ownerId, user.id)));
  return json({ ok: true });
});
