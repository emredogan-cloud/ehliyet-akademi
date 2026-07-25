/**
 * Topluluk uçları entegrasyon testi (Evolution Faz E8, PGlite bellek-içi).
 *
 * Kapsam: yetkilendirme · OPT-IN görünürlük · anti-hile sınırlama · engelleme (her iki yön) ·
 * şikâyet kuyruğu · sayfalama · PII sızmaması.
 */
import { describe, it, expect } from 'vitest';
import { POST as register } from '@/app/api/auth/register/route';
import {
  GET as profileGet,
  PUT as profilePut,
  DELETE as profileDelete,
} from '@/app/api/community/profile/route';
import { POST as statsPost } from '@/app/api/community/stats/route';
import { GET as leaderboardGet } from '@/app/api/community/leaderboard/route';
import { POST as reportPost } from '@/app/api/community/report/route';
import {
  GET as blockGet,
  POST as blockPost,
  DELETE as blockDelete,
} from '@/app/api/community/block/route';
import { GET as userGet } from '@/app/api/community/user/[id]/route';
import { MAX_XP_DELTA_PER_WINDOW } from './community';

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

const get = (path: string, token?: string) => req(path, 'GET', token);

let seq = 0;
async function newUser(): Promise<{ token: string; id: string }> {
  seq += 1;
  const res = await register(
    req('/api/auth/register', 'POST', undefined, {
      name: 'Topluluk',
      email: `topluluk-${Date.now()}-${seq}-${Math.floor(Math.random() * 1e6)}@ea.dev`,
      password: 'topluluk-parola-123',
    })
  );
  const body = (await res.json()) as { token: string; user: { id: string } };
  return { token: body.token, id: body.user.id };
}

/** Katılan (public) bir kullanıcı üretir ve istatistiklerini yazar. */
async function joinedUser(opts: {
  displayName: string;
  licence?: string;
  xp?: number;
  visibility?: string;
}): Promise<{ token: string; id: string }> {
  const u = await newUser();
  const put = await profilePut(
    req('/api/community/profile', 'PUT', u.token, {
      displayName: opts.displayName,
      avatarId: 'owl-wave',
      licence: opts.licence ?? 'b',
      visibility: opts.visibility ?? 'public',
    })
  );
  expect(put.status).toBe(200);
  if (opts.xp !== undefined) {
    const s = await statsPost(
      req('/api/community/stats', 'POST', u.token, { xp: opts.xp, streak: 1, answered: 10 })
    );
    expect(s.status).toBe(200);
  }
  return u;
}

describe('topluluk profili', () => {
  it('oturumsuz erişim 401', async () => {
    expect((await profileGet(get('/api/community/profile'))).status).toBe(401);
    expect(
      (await profilePut(req('/api/community/profile', 'PUT', undefined, { displayName: 'Ali' })))
        .status
    ).toBe(401);
  });

  it('katılmamış kullanıcıda profil NULL döner (opt-in)', async () => {
    const u = await newUser();
    const res = await profileGet(get('/api/community/profile', u.token));
    expect(res.status).toBe(200);
    const body = (await res.json()) as { profile: unknown; stats: unknown };
    expect(body.profile).toBeNull();
    expect(body.stats).toBeNull();
  });

  it('görünürlük GÖNDERİLMEZSE gizli kalır (opt-in varsayılanı)', async () => {
    const u = await newUser();
    const res = await profilePut(
      req('/api/community/profile', 'PUT', u.token, { displayName: 'Sessiz Kullanıcı' })
    );
    const body = (await res.json()) as { profile: { visibility: string } };
    expect(body.profile.visibility).toBe('private');
  });

  it('geçersiz görünen adı ve avatarı reddeder', async () => {
    const u = await newUser();
    expect(
      (await profilePut(req('/api/community/profile', 'PUT', u.token, { displayName: 'ab' })))
        .status
    ).toBe(400);
    expect(
      (
        await profilePut(
          req('/api/community/profile', 'PUT', u.token, { displayName: 'kisi@ornek.com' })
        )
      ).status
    ).toBe(400);
    expect(
      (
        await profilePut(
          req('/api/community/profile', 'PUT', u.token, {
            displayName: 'Geçerli Ad',
            avatarId: '../../gizli',
          })
        )
      ).status
    ).toBe(400);
  });

  it('katılımdan çıkınca profil ve istatistik SİLİNİR', async () => {
    const u = await joinedUser({ displayName: 'Ayrılan', xp: 100 });
    expect((await profileDelete(req('/api/community/profile', 'DELETE', u.token))).status).toBe(
      200
    );
    const after = (await (await profileGet(get('/api/community/profile', u.token))).json()) as {
      profile: unknown;
      stats: unknown;
    };
    expect(after.profile).toBeNull();
    expect(after.stats).toBeNull();
  });

  it('profil yanıtı e-posta/gerçek ad SIZDIRMAZ', async () => {
    const u = await joinedUser({ displayName: 'Gizli Kalsın', xp: 50 });
    const raw = await (await profileGet(get('/api/community/profile', u.token))).text();
    expect(raw).not.toContain('@ea.dev');
    expect(raw).not.toContain('Topluluk'); // kayıt sırasındaki gerçek ad
  });
});

describe('istatistik bildirimi (anti-hile)', () => {
  it('katılmadan bildirim 409', async () => {
    const u = await newUser();
    const res = await statsPost(req('/api/community/stats', 'POST', u.token, { xp: 10 }));
    expect(res.status).toBe(409);
  });

  it('ilk bildirimde bile tavan uygulanır', async () => {
    const u = await joinedUser({ displayName: 'Hilebaz' });
    const res = await statsPost(
      req('/api/community/stats', 'POST', u.token, { xp: 10_000_000, answered: 99_999 })
    );
    const body = (await res.json()) as { stats: { xp: number }; clamped: boolean };
    expect(body.stats.xp).toBe(MAX_XP_DELTA_PER_WINDOW);
    expect(body.clamped).toBe(true);
  });

  it('pencere dolmadan ikinci bildirim XP ARTIRMAZ', async () => {
    const u = await joinedUser({ displayName: 'Hizli Bildirim', xp: 100 });
    const res = await statsPost(
      req('/api/community/stats', 'POST', u.token, { xp: 5_000, streak: 9 })
    );
    const body = (await res.json()) as { stats: { xp: number; streak: number }; clamped: boolean };
    expect(body.stats.xp).toBe(100); // artmadı
    expect(body.clamped).toBe(true);
    expect(body.stats.streak).toBe(9); // türetilmiş alan tazelenir
  });

  it('geri giden sayacı yok sayar ve işaretler', async () => {
    const u = await joinedUser({ displayName: 'Geri Giden', xp: 500 });
    const res = await statsPost(req('/api/community/stats', 'POST', u.token, { xp: 1 }));
    const body = (await res.json()) as { stats: { xp: number }; regressed: boolean };
    expect(body.stats.xp).toBe(500);
    expect(body.regressed).toBe(true);
  });

  it('rozetler eklenir ve tekrar gönderim çoğaltmaz', async () => {
    const u = await joinedUser({ displayName: 'Rozetli', xp: 60 });
    await statsPost(
      req('/api/community/stats', 'POST', u.token, {
        xp: 60,
        achievements: ['ilk-adim', 'ilk-adim', 'seri-3', 'GEÇERSİZ KİMLİK'],
      })
    );
    const res = await userGet(get(`/api/community/user/${u.id}`, u.token));
    const body = (await res.json()) as { achievements: string[] };
    expect(body.achievements.sort()).toEqual(['ilk-adim', 'seri-3']);
  });
});

describe('sıralama', () => {
  it('yalnız KATILAN (public) kullanıcıları listeler', async () => {
    const visible = await joinedUser({ displayName: 'Gorunur Kisi', licence: 'd', xp: 900 });
    await joinedUser({
      displayName: 'Gizli Kisi',
      licence: 'd',
      xp: 950,
      visibility: 'private',
    });

    const res = await leaderboardGet(get('/api/community/leaderboard?licence=d', visible.token));
    expect(res.status).toBe(200);
    const body = (await res.json()) as { rows: Array<{ displayName: string }> };
    const names = body.rows.map((r) => r.displayName);
    expect(names).toContain('Gorunur Kisi');
    expect(names).not.toContain('Gizli Kisi');
  });

  it('sınıfa göre süzer ve kendi sırasını döner', async () => {
    const me = await joinedUser({ displayName: 'A Sinifi Ben', licence: 'a', xp: 400 });
    await joinedUser({ displayName: 'A Sinifi Rakip', licence: 'a', xp: 800 });

    const body = (await (
      await leaderboardGet(get('/api/community/leaderboard?licence=a', me.token))
    ).json()) as {
      rows: Array<{ displayName: string; licence: string; rank: number }>;
      me: { rank: number } | null;
      licence: string;
      weekStart: string;
    };
    expect(body.licence).toBe('a');
    expect(body.weekStart).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(body.rows.every((r) => r.licence === 'a')).toBe(true);
    expect(body.me).not.toBeNull();
    expect(body.me!.rank).toBeGreaterThanOrEqual(1);
  });

  it('sayfa boyutunu sunucu sınırına çeker', async () => {
    const u = await joinedUser({ displayName: 'Sayfalayan', xp: 10 });
    const body = (await (
      await leaderboardGet(get('/api/community/leaderboard?limit=9999', u.token))
    ).json()) as { limit: number };
    expect(body.limit).toBeLessThanOrEqual(50);
  });

  it('sıralama yanıtı e-posta SIZDIRMAZ', async () => {
    const u = await joinedUser({ displayName: 'Sizinti Yok', xp: 10 });
    const raw = await (await leaderboardGet(get('/api/community/leaderboard', u.token))).text();
    expect(raw).not.toContain('@ea.dev');
  });

  it('oturumsuz 401', async () => {
    expect((await leaderboardGet(get('/api/community/leaderboard'))).status).toBe(401);
  });
});

describe('engelleme (sunucuda uygulanır)', () => {
  it('engellenen kullanıcı SIRALAMADAN düşer — her iki yönde', async () => {
    const a = await joinedUser({ displayName: 'Engelleyen', licence: 'b', xp: 300 });
    const b = await joinedUser({ displayName: 'Engellenen', licence: 'b', xp: 700 });

    expect(
      (await blockPost(req('/api/community/block', 'POST', a.token, { targetUserId: b.id }))).status
    ).toBe(201);

    // Engelleyen, engellediğini görmez.
    const aView = (await (
      await leaderboardGet(get('/api/community/leaderboard?licence=b', a.token))
    ).json()) as { rows: Array<{ displayName: string }> };
    expect(aView.rows.map((r) => r.displayName)).not.toContain('Engellenen');

    // Engellenen de engelleyeni görmez (karşılıklı uygulanır).
    const bView = (await (
      await leaderboardGet(get('/api/community/leaderboard?licence=b', b.token))
    ).json()) as { rows: Array<{ displayName: string }> };
    expect(bView.rows.map((r) => r.displayName)).not.toContain('Engelleyen');
  });

  it('engellenen kullanıcının profili 404 döner (gizli mi engelli mi sızmaz)', async () => {
    const a = await joinedUser({ displayName: 'Bakan Kisi', xp: 10 });
    const b = await joinedUser({ displayName: 'Bakilan Kisi', xp: 10 });

    // Engelden ÖNCE görünür.
    expect((await userGet(get(`/api/community/user/${b.id}`, a.token))).status).toBe(200);

    await blockPost(req('/api/community/block', 'POST', a.token, { targetUserId: b.id }));
    expect((await userGet(get(`/api/community/user/${b.id}`, a.token))).status).toBe(404);
    // Ters yönde de.
    expect((await userGet(get(`/api/community/user/${a.id}`, b.token))).status).toBe(404);
  });

  it('engel kaldırılınca yeniden görünür', async () => {
    const a = await joinedUser({ displayName: 'Vazgecen', xp: 10 });
    const b = await joinedUser({ displayName: 'Affedilen', xp: 10 });
    await blockPost(req('/api/community/block', 'POST', a.token, { targetUserId: b.id }));
    expect((await userGet(get(`/api/community/user/${b.id}`, a.token))).status).toBe(404);

    const del = await blockDelete(
      req(`/api/community/block?targetUserId=${b.id}`, 'DELETE', a.token)
    );
    expect(del.status).toBe(200);
    expect((await userGet(get(`/api/community/user/${b.id}`, a.token))).status).toBe(200);
  });

  it('engel listesi döner; kendini engelleme reddedilir', async () => {
    const a = await joinedUser({ displayName: 'Liste Sahibi', xp: 10 });
    const b = await joinedUser({ displayName: 'Listedeki', xp: 10 });
    await blockPost(req('/api/community/block', 'POST', a.token, { targetUserId: b.id }));

    const list = (await (await blockGet(get('/api/community/block', a.token))).json()) as {
      blocked: Array<{ userId: string; displayName: string | null }>;
    };
    expect(list.blocked.map((x) => x.userId)).toContain(b.id);

    expect(
      (await blockPost(req('/api/community/block', 'POST', a.token, { targetUserId: a.id }))).status
    ).toBe(400);
  });
});

describe('gizli profil ve şikâyet', () => {
  it('gizli profil başkasına 404, kendine 200', async () => {
    const hidden = await joinedUser({ displayName: 'Gizli Profil', visibility: 'private', xp: 10 });
    const other = await joinedUser({ displayName: 'Baskasi', xp: 10 });

    expect((await userGet(get(`/api/community/user/${hidden.id}`, other.token))).status).toBe(404);
    const self = await userGet(get(`/api/community/user/${hidden.id}`, hidden.token));
    expect(self.status).toBe(200);
    expect(((await self.json()) as { isSelf: boolean }).isSelf).toBe(true);
  });

  it('şikâyet kuyruğa yazılır; kendini/bilinmeyeni bildirmek reddedilir', async () => {
    const a = await joinedUser({ displayName: 'Sikayetci', xp: 10 });
    const b = await joinedUser({ displayName: 'Sikayet Edilen', xp: 10 });

    const ok = await reportPost(
      req('/api/community/report', 'POST', a.token, {
        targetUserId: b.id,
        reason: 'taciz',
        note: 'Uygunsuz görünen ad.',
      })
    );
    expect(ok.status).toBe(201);

    expect(
      (
        await reportPost(
          req('/api/community/report', 'POST', a.token, { targetUserId: a.id, reason: 'spam' })
        )
      ).status
    ).toBe(400);
    expect(
      (
        await reportPost(
          req('/api/community/report', 'POST', a.token, { targetUserId: b.id, reason: 'hack' })
        )
      ).status
    ).toBe(400);
    expect(
      (
        await reportPost(
          req('/api/community/report', 'POST', a.token, {
            targetUserId: 'yok-boyle-kullanici',
            reason: 'spam',
          })
        )
      ).status
    ).toBe(404);
  });

  it('şikâyet ve engelleme oturum ister', async () => {
    expect(
      (
        await reportPost(
          req('/api/community/report', 'POST', undefined, { targetUserId: 'x', reason: 'spam' })
        )
      ).status
    ).toBe(401);
    expect(
      (await blockPost(req('/api/community/block', 'POST', undefined, { targetUserId: 'x' })))
        .status
    ).toBe(401);
    expect((await userGet(get('/api/community/user/x'))).status).toBe(401);
  });
});
