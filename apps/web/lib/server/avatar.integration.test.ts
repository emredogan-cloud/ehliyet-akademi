/**
 * Beta Faz 7 — profil fotoğrafı uçları entegrasyon testi (PGlite bellek-içi).
 *
 * ⚠️ NEDEN AYRI VE AYRINTILI: E8'de "kullanıcı fotoğrafı yüklenmez" bilinçli bir karardı ve
 * bütün bir moderasyon/PII sınıfını ortadan kaldırıyordu. Bu faz o kararı değiştiriyor,
 * dolayısıyla geri gelen saldırı yüzeyinin sınırları **uçtan uca** sabitlenmelidir:
 * yetkilendirme · katılım şartı · tür/boyut reddi · tek-fotoğraf · maskota dönüş · sızıntısızlık.
 */
import { describe, it, expect } from 'vitest';
import { POST as register } from '@/app/api/auth/register/route';
import { PUT as profilePut, GET as profileGet } from '@/app/api/community/profile/route';
import { POST as avatarPost, DELETE as avatarDelete } from '@/app/api/community/avatar/route';
import { GET as userGet } from '@/app/api/community/user/[id]/route';
import { GET as mediaGet } from '@/app/api/media/[id]/route';
import { AVATAR_MAX_BYTES } from './community';

const BASE = 'http://test.local';

const req = (path: string, method: string, token?: string, body?: unknown) =>
  new Request(BASE + path, {
    method,
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });

let seq = 0;
async function newUser(): Promise<{ token: string; id: string }> {
  seq += 1;
  const res = await register(
    req('/api/auth/register', 'POST', undefined, {
      name: 'Avatar',
      email: `avatar-${Date.now()}-${seq}-${Math.floor(Math.random() * 1e6)}@ea.dev`,
      password: 'avatar-parola-123',
    })
  );
  const body = (await res.json()) as { token: string; user: { id: string } };
  return { token: body.token, id: body.user.id };
}

async function joinedUser(displayName: string): Promise<{ token: string; id: string }> {
  const u = await newUser();
  const put = await profilePut(
    req('/api/community/profile', 'PUT', u.token, {
      displayName,
      avatarId: 'owl-wave',
      licence: 'b',
      visibility: 'public',
    })
  );
  expect(put.status).toBe(200);
  return u;
}

/** `bytes` uzunluğunda geçerli base64 gövdesi. */
const png = (bytes = 64) => Buffer.alloc(bytes, 0x41).toString('base64');

describe('yetkilendirme', () => {
  it('oturumsuz yükleme 401', async () => {
    const res = await avatarPost(
      req('/api/community/avatar', 'POST', undefined, { mime: 'image/png', dataBase64: png() })
    );
    expect(res.status).toBe(401);
  });

  it('oturumsuz kaldırma 401', async () => {
    const res = await avatarDelete(req('/api/community/avatar', 'DELETE'));
    expect(res.status).toBe(401);
  });

  it('TOPLULUĞA KATILMAMIŞ kullanıcı yükleyemez (409)', async () => {
    const u = await newUser(); // profil YOK
    const res = await avatarPost(
      req('/api/community/avatar', 'POST', u.token, { mime: 'image/png', dataBase64: png() })
    );
    expect(res.status).toBe(409);
  });
});

describe('reddedilmesi gereken yüklemeler', () => {
  it('SVG reddedilir — gömülü script riski', async () => {
    const u = await joinedUser('Svg Deneme');
    const res = await avatarPost(
      req('/api/community/avatar', 'POST', u.token, {
        mime: 'image/svg+xml',
        dataBase64: Buffer.from('<svg onload="alert(1)"/>').toString('base64'),
      })
    );
    expect(res.status).toBe(400);
  });

  it('Lottie/JSON reddedilir', async () => {
    const u = await joinedUser('Lottie Deneme');
    const res = await avatarPost(
      req('/api/community/avatar', 'POST', u.token, {
        mime: 'application/json',
        dataBase64: Buffer.from('{}').toString('base64'),
      })
    );
    expect(res.status).toBe(400);
  });

  it('boyut sınırını aşan görsel reddedilir', async () => {
    const u = await joinedUser('Buyuk Gorsel');
    const res = await avatarPost(
      req('/api/community/avatar', 'POST', u.token, {
        mime: 'image/jpeg',
        dataBase64: png(AVATAR_MAX_BYTES + 1),
      })
    );
    expect(res.status).toBe(400);
  });

  it('bozuk base64 reddedilir', async () => {
    const u = await joinedUser('Bozuk Veri');
    const res = await avatarPost(
      req('/api/community/avatar', 'POST', u.token, {
        mime: 'image/png',
        dataBase64: 'data:image/png;base64,AAAA',
      })
    );
    expect(res.status).toBe(400);
  });

  it('bozuk gövde 400', async () => {
    const u = await joinedUser('Bozuk Govde');
    const res = await avatarPost(
      new Request(BASE + '/api/community/avatar', {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${u.token}` },
        body: 'bu json degil',
      })
    );
    expect(res.status).toBe(400);
  });
});

describe('yükleme ve görünürlük', () => {
  it('yükleme sonrası profil avatarUrl döndürür ve medya servis edilir', async () => {
    const u = await joinedUser('Fotografli Kisi');
    const up = await avatarPost(
      req('/api/community/avatar', 'POST', u.token, { mime: 'image/png', dataBase64: png(128) })
    );
    expect(up.status).toBe(201);
    const { avatarUrl } = (await up.json()) as { avatarUrl: string };
    expect(avatarUrl).toMatch(/^\/api\/media\//);

    // Kendi profilim
    const me = await profileGet(req('/api/community/profile', 'GET', u.token));
    const meBody = (await me.json()) as { profile: { avatarUrl: string | null; avatarId: string } };
    expect(meBody.profile.avatarUrl).toBe(avatarUrl);
    // Maskot kimliği KORUNUR — fotoğraf kaldırılınca geri dönülecek yer odur.
    expect(meBody.profile.avatarId).toBe('owl-wave');

    // Medya gerçekten servis ediliyor ve sertleştirilmiş başlıklar duruyor.
    const media = await mediaGet(new Request(BASE + avatarUrl));
    expect(media.status).toBe(200);
    expect(media.headers.get('content-type')).toBe('image/png');
    expect(media.headers.get('x-content-type-options')).toBe('nosniff');
    expect(media.headers.get('content-security-policy')).toContain('sandbox');
  });

  it('başkasının profilinde de görünür', async () => {
    const owner = await joinedUser('Goruen Kisi');
    const viewer = await joinedUser('Bakan Kisi');
    const up = await avatarPost(
      req('/api/community/avatar', 'POST', owner.token, { mime: 'image/webp', dataBase64: png(90) })
    );
    const { avatarUrl } = (await up.json()) as { avatarUrl: string };

    const res = await userGet(req(`/api/community/user/${owner.id}`, 'GET', viewer.token));
    const body = (await res.json()) as { profile: { avatarUrl: string | null; email?: string } };
    expect(body.profile.avatarUrl).toBe(avatarUrl);
    // PII sızmaz (E8 ilkesi bozulmadı).
    expect(JSON.stringify(body)).not.toContain('@ea.dev');
  });
});

describe('tek fotoğraf kuralı ve maskota dönüş', () => {
  it('yeni yükleme eskisini DEĞİŞTİRİR ve eski medya artık servis edilmez', async () => {
    const u = await joinedUser('Iki Kez Yukleyen');
    const first = (await (
      await avatarPost(
        req('/api/community/avatar', 'POST', u.token, { mime: 'image/png', dataBase64: png(80) })
      )
    ).json()) as { avatarUrl: string };
    const second = (await (
      await avatarPost(
        req('/api/community/avatar', 'POST', u.token, { mime: 'image/jpeg', dataBase64: png(96) })
      )
    ).json()) as { avatarUrl: string };

    expect(second.avatarUrl).not.toBe(first.avatarUrl);
    // Eski medya silinmiştir — kullanıcı başına birikme olmaz.
    const old = await mediaGet(new Request(BASE + first.avatarUrl));
    expect(old.status).toBe(404);
  });

  it('DELETE fotoğrafı kaldırır → maskota dönülür', async () => {
    const u = await joinedUser('Kaldiran Kisi');
    const up = (await (
      await avatarPost(
        req('/api/community/avatar', 'POST', u.token, { mime: 'image/png', dataBase64: png(70) })
      )
    ).json()) as { avatarUrl: string };

    const del = await avatarDelete(req('/api/community/avatar', 'DELETE', u.token));
    expect(del.status).toBe(200);

    const me = await profileGet(req('/api/community/profile', 'GET', u.token));
    const body = (await me.json()) as { profile: { avatarUrl: string | null; avatarId: string } };
    expect(body.profile.avatarUrl).toBeNull();
    expect(body.profile.avatarId).toBe('owl-wave'); // maskot her zaman duruyordu

    const gone = await mediaGet(new Request(BASE + up.avatarUrl));
    expect(gone.status).toBe(404);
  });

  it('fotoğraf yokken DELETE de başarılıdır (etkisiz-tekrarlı)', async () => {
    const u = await joinedUser('Fotografsiz Kisi');
    const del = await avatarDelete(req('/api/community/avatar', 'DELETE', u.token));
    expect(del.status).toBe(200);
    expect(((await del.json()) as { avatarUrl: null }).avatarUrl).toBeNull();
  });
});
