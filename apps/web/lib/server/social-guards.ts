import { and, eq, or } from 'drizzle-orm';
import { getDb, communityBlocks, communityProfiles } from '@ea/db';

/**
 * Sosyal uçların ORTAK kapıları (Evolution Faz E9).
 *
 * NEDEN AYRI DOSYA: engel kontrolü HER okuma ve yazma yolunda çalışmak zorundadır. Her uç kendi
 * sorgusunu yazsaydı, bir uçta unutulması sessiz bir güvenlik açığı olurdu. Tek bir yardımcıya
 * indirgemek, "her yolda uygulanıyor" iddiasını denetlenebilir kılar.
 */

/** İki taraf arasında (her iki yönde) engel var mı? */
export async function isBlockedBetween(a: string, b: string): Promise<boolean> {
  const db = await getDb();
  const rows = await db
    .select({ blockerId: communityBlocks.blockerId })
    .from(communityBlocks)
    .where(
      or(
        and(eq(communityBlocks.blockerId, a), eq(communityBlocks.blockedId, b)),
        and(eq(communityBlocks.blockerId, b), eq(communityBlocks.blockedId, a))
      )
    )
    .limit(1);
  return rows.length > 0;
}

/** Kullanıcının engellediği + onu engelleyen herkesin kimlikleri (liste süzmek için). */
export async function hiddenUserIds(self: string): Promise<Set<string>> {
  const db = await getDb();
  const byMe = await db
    .select({ id: communityBlocks.blockedId })
    .from(communityBlocks)
    .where(eq(communityBlocks.blockerId, self));
  const meBy = await db
    .select({ id: communityBlocks.blockerId })
    .from(communityBlocks)
    .where(eq(communityBlocks.blockedId, self));
  return new Set<string>([...byMe.map((r) => r.id), ...meBy.map((r) => r.id)]);
}

export type PublicProfile = {
  userId: string;
  displayName: string;
  avatarId: string;
  licence: string;
};

/** Görünen ad/avatar sözlüğü — listelerde kimlikleri isimlendirmek için (PII içermez). */
export async function profilesByIds(ids: string[]): Promise<Map<string, PublicProfile>> {
  const map = new Map<string, PublicProfile>();
  if (ids.length === 0) return map;
  const db = await getDb();
  const rows = await db
    .select({
      userId: communityProfiles.userId,
      displayName: communityProfiles.displayName,
      avatarId: communityProfiles.avatarId,
      licence: communityProfiles.licence,
    })
    .from(communityProfiles);
  const wanted = new Set(ids);
  for (const r of rows) if (wanted.has(r.userId)) map.set(r.userId, r);
  return map;
}

/** Kullanıcının topluluk profili var mı (katıldı mı)? Sosyal özellikler katılıma bağlıdır. */
export async function hasCommunityProfile(userId: string): Promise<boolean> {
  const db = await getDb();
  const rows = await db
    .select({ userId: communityProfiles.userId })
    .from(communityProfiles)
    .where(eq(communityProfiles.userId, userId))
    .limit(1);
  return rows.length > 0;
}
