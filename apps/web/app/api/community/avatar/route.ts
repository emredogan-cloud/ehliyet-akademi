import { eq } from 'drizzle-orm';
import { getDb, communityProfiles, mediaAssets } from '@ea/db';
import { getSessionUser, json, newId, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { avatarUrlFor, validateAvatarUpload } from '@/lib/server/community';

/**
 * Beta Faz 7 — profil fotoğrafı yükleme / kaldırma.
 *
 * ⚠️ E8 KARARININ DEĞİŞTİĞİ YER. E8 "kullanıcı fotoğrafı yüklenmez" diyordu ve bu, bütün bir
 * moderasyon/PII sınıfını baştan kaldırıyordu. Bu uç o sınıfı geri getiriyor; bu yüzden
 * savunmalar burada topluca duruyor:
 *
 * 1. **Oturum şart** — anonim yükleme yok. (Yönetici yetkisi GEREKMEZ; bu kullanıcının kendi
 *    profilidir. `/api/admin/media` ise editör/yönetici içindir ve ayrı kalır.)
 * 2. **Topluluğa katılmış olmak şart** — profili olmayan kullanıcı fotoğraf yükleyemez;
 *    depolamanın katılım dışından doldurulması engellenir.
 * 3. **Dar tür listesi** — yalnız JPEG/PNG/WebP. SVG **kabul edilmez** (gömülü script riski);
 *    medya servisindeki sandbox CSP iyi bir savunmadır ama tek hat değildir.
 * 4. **Sıkı boyut sınırı** — 512 KB (CMS'in genel 2 MB sınırından çok altı).
 * 5. **Hız sınırı** — depolama doldurma denemelerine karşı.
 * 6. **Tek fotoğraf** — yeni yükleme eskisini SİLER; kullanıcı başına birikme olmaz.
 * 7. **DELETE ile maskota dönüş** — kullanıcı her zaman fotoğrafsız hâle dönebilir.
 *
 * Maskot kimliği (`avatarId`) HER ZAMAN saklı kalır: fotoğraf kaldırıldığında geri dönülecek yer
 * odur, yani "avatarsız" bir durum hiç oluşmaz.
 */

/** Bu kullanıcının varsa eski avatar medyasını siler (tek fotoğraf kuralı). */
async function dropPreviousAvatar(userId: string): Promise<void> {
  const db = await getDb();
  const [profile] = await db
    .select({ avatarMediaId: communityProfiles.avatarMediaId })
    .from(communityProfiles)
    .where(eq(communityProfiles.userId, userId))
    .limit(1);
  const previous = profile?.avatarMediaId;
  if (!previous) return;
  await db
    .update(communityProfiles)
    .set({ avatarMediaId: null, updatedAt: new Date() })
    .where(eq(communityProfiles.userId, userId));
  await db.delete(mediaAssets).where(eq(mediaAssets.id, previous));
}

export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'avatar', limit: 6, windowMs: 60_000 });
  if (limited) return limited;

  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  let body: { mime?: unknown; dataBase64?: unknown };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }

  const parsed = validateAvatarUpload(body);
  if (!parsed.ok) return json({ error: parsed.error }, { status: 400 });

  const db = await getDb();
  const [profile] = await db
    .select({ userId: communityProfiles.userId })
    .from(communityProfiles)
    .where(eq(communityProfiles.userId, user.id))
    .limit(1);
  if (!profile) {
    return json({ error: 'Önce topluluğa katılman gerekiyor.' }, { status: 409 });
  }

  await dropPreviousAvatar(user.id);

  const id = newId();
  await db.insert(mediaAssets).values({
    id,
    kind: 'image',
    filename: `avatar-${user.id}`,
    mime: parsed.mime,
    bytes: parsed.bytes,
    alt: 'Profil fotoğrafı',
    tags: ['avatar'],
    dataBase64: parsed.dataBase64,
    createdBy: user.id,
  });
  await db
    .update(communityProfiles)
    .set({ avatarMediaId: id, updatedAt: new Date() })
    .where(eq(communityProfiles.userId, user.id));

  return json({ ok: true, avatarUrl: avatarUrlFor(id) }, { status: 201 });
});

/** Fotoğrafı kaldır → paketlenmiş maskota dön. Fotoğraf yoksa da başarı döner (idempotent). */
export const DELETE = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });
  await dropPreviousAvatar(user.id);
  return json({ ok: true, avatarUrl: null });
});
