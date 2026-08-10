/**
 * Hesap silme — AVATAR YÜKLEMİŞ kullanıcı (yayın öncesi denetim bulgusu N4).
 *
 * ## Bulunan kusur
 *
 * `media_assets.created_by` sütunu `NOT NULL REFERENCES users(id)` idi ve **ON DELETE yan tümcesi
 * yoktu**. PostgreSQL varsayılanı `NO ACTION`'dır: bağlı satır varken ana satır SİLİNEMEZ.
 *
 * Bu sütunun yalnız yönetici/CMS tarafından yazıldığı sanılıyordu. Gerçekte topluluk avatar yükleme
 * ucu da yazıyor (`app/api/community/avatar/route.ts`). Sonuç: **avatar yüklemiş HERHANGİ bir
 * kullanıcı hesabını silemiyordu** — `DELETE FROM users` yabancı anahtar ihlaliyle patlıyordu.
 *
 * Google Play, hesap oluşturmaya izin veren uygulamalarda çalışan bir silme yolu ister. Bu kusur
 * o gereksinimi normal bir kullanıcı akışında kırıyordu.
 *
 * Bu test kusuru yeniden üretir ve düzeltmeyi kilitler.
 */
import { describe, it, expect } from 'vitest';
import { eq } from 'drizzle-orm';
import { communityProfiles, getDb, mediaAssets, users } from '@ea/db';
import { POST as register } from '@/app/api/auth/register/route';
import { DELETE as deleteAccount } from '@/app/api/account/route';
import { newId } from '@/lib/server/auth';

const BASE = 'http://test.local';

async function newUser(): Promise<{ token: string; id: string }> {
  const res = await register(
    new Request(`${BASE}/api/auth/register`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        name: 'Avatar',
        email: `avatar-${Date.now()}-${Math.floor(Math.random() * 1e6)}@ea.dev`,
        password: 'avatar-parola-123',
      }),
    })
  );
  const body = (await res.json()) as { token: string; user: { id: string } };
  return { token: body.token, id: body.user.id };
}

describe('hesap silme — avatar yüklemiş kullanıcı', () => {
  it('media_assets satırı olan kullanıcı hesabını SİLEBİLİR', async () => {
    const db = await getDb();
    const { token, id } = await newUser();

    // Avatar yükleme ucunun yazdığı satırın birebir aynısı.
    const mediaId = newId();
    await db.insert(mediaAssets).values({
      id: mediaId,
      kind: 'image',
      filename: `avatar-${id}`,
      mime: 'image/png',
      bytes: 128,
      alt: 'Profil fotoğrafı',
      tags: ['avatar'],
      dataBase64: 'AAAA',
      createdBy: id,
    });

    // Gerçek akış: avatar yüklendiğinde topluluk profiline bağlanır.
    await db.insert(communityProfiles).values({
      userId: id,
      displayName: 'Avatar Kullanıcı',
      avatarMediaId: mediaId,
    });

    const res = await deleteAccount(
      new Request(`${BASE}/api/account`, {
        method: 'DELETE',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify({ password: 'avatar-parola-123' }),
      })
    );

    expect(res.status, 'avatarı olan kullanıcı silinemiyor — FK ihlali').toBe(200);

    const left = await db.select({ id: users.id }).from(users).where(eq(users.id, id));
    expect(left, 'kullanıcı satırı silinmedi').toHaveLength(0);
  });

  it('kullanıcının kendi avatar görseli de silinir — yetim kayıt kalmaz', async () => {
    const db = await getDb();
    const { token, id } = await newUser();

    const mediaId = newId();
    await db.insert(mediaAssets).values({
      id: mediaId,
      kind: 'image',
      filename: `avatar-${id}`,
      mime: 'image/png',
      bytes: 128,
      alt: 'Profil fotoğrafı',
      tags: ['avatar'],
      dataBase64: 'AAAA',
      createdBy: id,
    });

    // Gerçek akış: avatar yüklendiğinde topluluk profiline bağlanır.
    await db.insert(communityProfiles).values({
      userId: id,
      displayName: 'Avatar Kullanıcı',
      avatarMediaId: mediaId,
    });

    await deleteAccount(
      new Request(`${BASE}/api/account`, {
        method: 'DELETE',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify({ password: 'avatar-parola-123' }),
      })
    );

    // KVKK/Play açısından kritik: kullanıcının FOTOĞRAFI da gitmeli, yalnız bağı kopmamalı.
    const media = await db
      .select({ id: mediaAssets.id })
      .from(mediaAssets)
      .where(eq(mediaAssets.id, mediaId));
    expect(media, 'kullanıcının avatar görseli veritabanında kaldı').toHaveLength(0);
  });
});
