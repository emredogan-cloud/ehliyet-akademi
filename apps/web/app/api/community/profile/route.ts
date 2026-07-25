import { eq } from 'drizzle-orm';
import { getDb, communityProfiles, communityStats } from '@ea/db';
import { getSessionUser, json, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import {
  isAvatarId,
  isLicence,
  isVisibility,
  validateDisplayName,
  type Visibility,
} from '@/lib/server/community';

/**
 * Topluluk profili (Evolution Faz E8) — kendi profilini oku/güncelle.
 *
 * GİZLİLİK: profil satırının VARLIĞI katılım demek değildir. `visibility` varsayılanı `private`'tır;
 * yalnız kullanıcı açıkça `public` yaptığında sıralamalarda/başkalarına görünür olur. Bu uç nokta
 * e-posta veya gerçek ad DÖNDÜRMEZ — yalnız kullanıcının kendi seçtiği görünen ad ve avatar kimliği.
 */

type ProfileBody = {
  displayName?: unknown;
  avatarId?: unknown;
  licence?: unknown;
  visibility?: unknown;
};

export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const db = await getDb();
  const [profile] = await db
    .select()
    .from(communityProfiles)
    .where(eq(communityProfiles.userId, user.id))
    .limit(1);
  const [stats] = await db
    .select()
    .from(communityStats)
    .where(eq(communityStats.userId, user.id))
    .limit(1);

  return json({
    // Profil yoksa katılım henüz yapılmamıştır — istemci onay ekranını gösterir.
    profile: profile
      ? {
          displayName: profile.displayName,
          avatarId: profile.avatarId,
          licence: profile.licence,
          visibility: profile.visibility,
        }
      : null,
    stats: stats
      ? {
          xp: stats.xp,
          streak: stats.streak,
          lessons: stats.lessons,
          exams: stats.exams,
          answered: stats.answered,
          accuracy: stats.accuracy,
        }
      : null,
  });
});

export const PUT = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'community-profile', limit: 20, windowMs: 60_000 });
  if (limited) return limited;

  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  let body: ProfileBody;
  try {
    body = (await req.json()) as ProfileBody;
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }

  const name = validateDisplayName(body.displayName);
  if (!name.ok) return json({ error: name.error }, { status: 400 });
  if (body.avatarId !== undefined && !isAvatarId(body.avatarId)) {
    return json({ error: 'Geçersiz avatar.' }, { status: 400 });
  }
  if (body.licence !== undefined && !isLicence(body.licence)) {
    return json({ error: 'Geçersiz ehliyet sınıfı.' }, { status: 400 });
  }
  // Görünürlük AÇIKÇA gönderilmelidir; gönderilmezse gizli kalır (opt-in).
  const visibility: Visibility = isVisibility(body.visibility) ? body.visibility : 'private';

  const db = await getDb();
  const now = new Date();
  const values = {
    userId: user.id,
    displayName: name.value,
    avatarId: isAvatarId(body.avatarId) ? body.avatarId : 'owl-wave',
    licence: isLicence(body.licence) ? body.licence : 'b',
    visibility,
    updatedAt: now,
  };

  await db
    .insert(communityProfiles)
    .values(values)
    .onConflictDoUpdate({
      target: communityProfiles.userId,
      set: {
        displayName: values.displayName,
        avatarId: values.avatarId,
        licence: values.licence,
        visibility: values.visibility,
        updatedAt: now,
      },
    });

  return json({
    profile: {
      displayName: values.displayName,
      avatarId: values.avatarId,
      licence: values.licence,
      visibility: values.visibility,
    },
  });
});

/**
 * Katılımdan çıkış: profil satırı ve istatistikler SİLİNİR (yalnız gizlenmez). Kullanıcının
 * topluluk izi bırakmadan ayrılabilmesi, opt-in tasarımın diğer yarısıdır.
 */
export const DELETE = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const db = await getDb();
  await db.delete(communityStats).where(eq(communityStats.userId, user.id));
  await db.delete(communityProfiles).where(eq(communityProfiles.userId, user.id));
  return json({ ok: true });
});
