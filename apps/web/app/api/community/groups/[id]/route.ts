import { and, desc, eq } from 'drizzle-orm';
import { getDb, studyGroups, studyGroupMembers, communityStats } from '@ea/db';
import { getSessionUser, json, guarded } from '@/lib/server/auth';
import { hiddenUserIds, profilesByIds } from '@/lib/server/social-guards';

/**
 * Grup ayrıntısı + üye listesi (Evolution Faz E10).
 *
 * ERİŞİM: yalnız ÜYELER görebilir — üye olmayana grup adı bile verilmez (aynı 404).
 * ENGELLEME: engellediğin üyeler listede GÖRÜNMEZ (E9 `social-guards` yeniden kullanılıyor);
 * ancak `memberCount` gerçek mevcudu gösterir — aksi hâlde engelleyen kişi grubu eksik sanırdı.
 *
 * NOT: `guarded` Next'in context argümanını iletmez → kimlik yoldan okunur (E8'de öğrenilen desen).
 */
function groupIdFrom(req: Request): string {
  const parts = new URL(req.url).pathname.split('/');
  return decodeURIComponent(parts[parts.length - 1] ?? '');
}

export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const groupId = groupIdFrom(req);
  const db = await getDb();

  const [membership] = await db
    .select({ role: studyGroupMembers.role })
    .from(studyGroupMembers)
    .where(and(eq(studyGroupMembers.groupId, groupId), eq(studyGroupMembers.userId, user.id)))
    .limit(1);
  if (!membership) return json({ error: 'Grup bulunamadı.' }, { status: 404 });

  const [group] = await db.select().from(studyGroups).where(eq(studyGroups.id, groupId)).limit(1);
  if (!group) return json({ error: 'Grup bulunamadı.' }, { status: 404 });

  const members = await db
    .select({
      userId: studyGroupMembers.userId,
      role: studyGroupMembers.role,
      xp: communityStats.xp,
      streak: communityStats.streak,
      answered: communityStats.answered,
    })
    .from(studyGroupMembers)
    .leftJoin(communityStats, eq(communityStats.userId, studyGroupMembers.userId))
    .where(eq(studyGroupMembers.groupId, groupId))
    .orderBy(desc(communityStats.xp));

  const hidden = await hiddenUserIds(user.id);
  const visible = members.filter((m) => !hidden.has(m.userId));
  const profiles = await profilesByIds(visible.map((m) => m.userId));

  // Toplamlar GERÇEK mevcut üzerinden — engelleme yalnız GÖRÜNÜRLÜĞÜ etkiler, grubun gücünü değil.
  const totalXp = members.reduce((s, m) => s + (m.xp ?? 0), 0);
  const totalAnswered = members.reduce((s, m) => s + (m.answered ?? 0), 0);

  return json({
    group: {
      id: group.id,
      name: group.name,
      licence: group.licence,
      joinCode: group.joinCode, // yalnız üyeye döner
      isOwner: group.ownerId === user.id,
      memberCount: group.memberCount,
      totalXp,
      totalAnswered,
    },
    members: visible.map((m, i) => ({
      userId: m.userId,
      displayName: profiles.get(m.userId)?.displayName ?? '',
      avatarId: profiles.get(m.userId)?.avatarId ?? 'owl-wave',
      role: m.role,
      xp: m.xp ?? 0,
      streak: m.streak ?? 0,
      rank: i + 1,
      isSelf: m.userId === user.id,
    })),
  });
});
