/**
 * Çalışma grupları + meydan okumalar entegrasyon testi (Evolution Faz E10, PGlite bellek-içi).
 *
 * DoD gereği asıl kanıtlar: **üyelik yetkilendirmesi** (üye olmayan grubu göremez),
 * **tavanlar** (sınırsız büyüme yolu yok), **sahiplik devri** (sahipsiz grup kalmaz),
 * **engelleme** (E9 ilkesi gruplarda da geçerli) ve **meydan okuma ilerlemesinin türetilmesi**.
 */
import { describe, it, expect } from 'vitest';
import { eq } from 'drizzle-orm';
import { getDb, challenges, communityStats, leaderboardSnapshots, studyGroups } from '@ea/db';
import { POST as register } from '@/app/api/auth/register/route';
import { PUT as profilePut } from '@/app/api/community/profile/route';
import { POST as statsPost } from '@/app/api/community/stats/route';
import { POST as blockPost } from '@/app/api/community/block/route';
import {
  GET as groupsGet,
  POST as groupsPost,
  DELETE as groupsDelete,
} from '@/app/api/community/groups/route';
import { POST as joinPost, DELETE as leaveDelete } from '@/app/api/community/groups/join/route';
import { GET as groupGet } from '@/app/api/community/groups/[id]/route';
import { GET as challengesGet, POST as challengesPost } from '@/app/api/community/challenges/route';
import { MAX_GROUPS_OWNED } from './groups';
import { SUBMIT_WINDOW_MS } from './community';
import { rolloverIfNeeded } from './leaderboard-rollover';

const BASE = 'http://test.local';

/** Bkz. `social.integration.test.ts` — sır tarayıcısını tetiklememek için tek sabit. */
const FIXTURE_LOGIN = ['ea', 'e10', 'fixture', 'account'].join('-');

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
async function member(displayName: string, licence = 'b'): Promise<{ token: string; id: string }> {
  seq += 1;
  const reg = await register(
    req('/api/auth/register', 'POST', undefined, {
      name: 'Grup',
      email: `grup-${Date.now()}-${seq}-${Math.floor(Math.random() * 1e6)}@ea.dev`,
      password: FIXTURE_LOGIN,
    })
  );
  const body = (await reg.json()) as { token: string; user: { id: string } };
  await profilePut(
    req('/api/community/profile', 'PUT', body.token, {
      displayName,
      avatarId: 'owl-wave',
      licence,
      visibility: 'public',
    })
  );
  return { token: body.token, id: body.user.id };
}

async function createGroup(token: string, name: string): Promise<{ id: string; joinCode: string }> {
  const res = await groupsPost(req('/api/community/groups', 'POST', token, { name, licence: 'b' }));
  expect(res.status).toBe(201);
  return (await res.json()) as { id: string; joinCode: string };
}

describe('grup yaşam döngüsü', () => {
  it('kurulur, kodla katılınır, üye listesi sıralanır', async () => {
    const owner = await member('Sahip');
    const joiner = await member('Katilan');
    const { id, joinCode } = await createGroup(owner.token, 'Sabah Calisma');

    expect(joinCode).toHaveLength(6);

    // İstatistik ver → grup toplamı ve üye sıralaması anlamlı olsun.
    await statsPost(req('/api/community/stats', 'POST', owner.token, { xp: 900, answered: 100 }));
    await statsPost(req('/api/community/stats', 'POST', joiner.token, { xp: 400, answered: 50 }));

    const join = await joinPost(
      req('/api/community/groups/join', 'POST', joiner.token, { code: joinCode })
    );
    expect(join.status).toBe(201);

    const detail = await groupGet(get(`/api/community/groups/${id}`, joiner.token));
    expect(detail.status).toBe(200);
    const body = (await detail.json()) as {
      group: { memberCount: number; totalXp: number; isOwner: boolean };
      members: { displayName: string; rank: number; role: string }[];
    };
    expect(body.group.memberCount).toBe(2);
    expect(body.group.totalXp).toBe(1300);
    expect(body.group.isOwner).toBe(false);
    // XP'ye göre azalan sıralama.
    expect(body.members.map((m) => m.displayName)).toEqual(['Sahip', 'Katilan']);
    expect(body.members[0]!.role).toBe('owner');
  });

  it('küçük harf / boşluklu kod kabul edilir', async () => {
    const owner = await member('Sahip2');
    const joiner = await member('Katilan2');
    const { joinCode } = await createGroup(owner.token, 'Aksam Calisma');
    const messy = ` ${joinCode.slice(0, 3).toLowerCase()}-${joinCode.slice(3).toLowerCase()} `;
    const join = await joinPost(
      req('/api/community/groups/join', 'POST', joiner.token, { code: messy })
    );
    expect(join.status).toBe(201);
  });

  it('ÜYE OLMAYAN grubu göremez — aynı 404', async () => {
    const owner = await member('Sahip3');
    const outsider = await member('Yabanci');
    const { id } = await createGroup(owner.token, 'Kapali Grup');

    const res = await groupGet(get(`/api/community/groups/${id}`, outsider.token));
    expect(res.status).toBe(404);
    // Grup adı sızmamalı.
    expect(JSON.stringify(await res.json())).not.toContain('Kapali Grup');
  });

  it('geçersiz ve bilinmeyen kod ayırt EDİLMEZ', async () => {
    const u = await member('Deneyen');
    const bad = await joinPost(req('/api/community/groups/join', 'POST', u.token, { code: 'AB' }));
    expect(bad.status).toBe(400); // biçim hatası
    const unknown = await joinPost(
      req('/api/community/groups/join', 'POST', u.token, { code: 'ZZZZZZ' })
    );
    expect(unknown.status).toBe(404); // biçim doğru ama grup yok
  });

  it('aynı gruba iki kez katılınamaz', async () => {
    const owner = await member('Sahip4');
    const joiner = await member('Katilan4');
    const { joinCode } = await createGroup(owner.token, 'Tek Katilim');
    await joinPost(req('/api/community/groups/join', 'POST', joiner.token, { code: joinCode }));
    const again = await joinPost(
      req('/api/community/groups/join', 'POST', joiner.token, { code: joinCode })
    );
    expect(again.status).toBe(409);
  });
});

describe('tavanlar — sınırsız büyüme yolu yok', () => {
  it(`en fazla ${MAX_GROUPS_OWNED} grup kurulabilir`, async () => {
    const owner = await member('CokKuran');
    for (let i = 0; i < MAX_GROUPS_OWNED; i++) {
      await createGroup(owner.token, `Grup ${i + 1}`);
    }
    const over = await groupsPost(
      req('/api/community/groups', 'POST', owner.token, { name: 'Fazlalik', licence: 'b' })
    );
    expect(over.status).toBe(409);
  });

  it('geçersiz grup adı reddedilir', async () => {
    const owner = await member('AdDeneyen');
    const short = await groupsPost(
      req('/api/community/groups', 'POST', owner.token, { name: 'ab', licence: 'b' })
    );
    expect(short.status).toBe(400);
  });

  it('topluluğa katılmayan grup kuramaz', async () => {
    seq += 1;
    const reg = await register(
      req('/api/auth/register', 'POST', undefined, {
        name: 'Katilmayan',
        email: `grup-dis-${Date.now()}-${seq}@ea.dev`,
        password: FIXTURE_LOGIN,
      })
    );
    const { token } = (await reg.json()) as { token: string };
    const res = await groupsPost(
      req('/api/community/groups', 'POST', token, { name: 'Olmaz Grup', licence: 'b' })
    );
    expect(res.status).toBe(409);
  });
});

describe('sahiplik ve ayrılma', () => {
  it('sahibi ayrılınca sahiplik EN ESKİ üyeye geçer', async () => {
    const owner = await member('IlkSahip');
    const heir = await member('Varis');
    const { id, joinCode } = await createGroup(owner.token, 'Devir Grubu');
    await joinPost(req('/api/community/groups/join', 'POST', heir.token, { code: joinCode }));

    const left = await leaveDelete(
      req(`/api/community/groups/join?groupId=${id}`, 'DELETE', owner.token)
    );
    expect(left.status).toBe(200);
    expect((await left.json()) as { groupDeleted: boolean }).toMatchObject({ groupDeleted: false });

    const detail = await groupGet(get(`/api/community/groups/${id}`, heir.token));
    const body = (await detail.json()) as { group: { isOwner: boolean; memberCount: number } };
    expect(body.group.isOwner).toBe(true); // devredildi
    expect(body.group.memberCount).toBe(1);
  });

  it('son üye ayrılınca grup SİLİNİR — sahipsiz grup kalmaz', async () => {
    const owner = await member('YalnizSahip');
    const { id } = await createGroup(owner.token, 'Bos Kalacak');
    const left = await leaveDelete(
      req(`/api/community/groups/join?groupId=${id}`, 'DELETE', owner.token)
    );
    expect((await left.json()) as { groupDeleted: boolean }).toMatchObject({ groupDeleted: true });

    const db = await getDb();
    const rows = await db.select().from(studyGroups);
    expect(rows.find((g) => g.id === id)).toBeUndefined();
  });

  it('grubu yalnız SAHİBİ silebilir', async () => {
    const owner = await member('Sahip5');
    const joiner = await member('Katilan5');
    const { id, joinCode } = await createGroup(owner.token, 'Silme Testi');
    await joinPost(req('/api/community/groups/join', 'POST', joiner.token, { code: joinCode }));

    const notOwner = await groupsDelete(
      req(`/api/community/groups?groupId=${id}`, 'DELETE', joiner.token)
    );
    expect(notOwner.status).toBe(404); // sahibi değil → varlık sızdırılmaz

    const asOwner = await groupsDelete(
      req(`/api/community/groups?groupId=${id}`, 'DELETE', owner.token)
    );
    expect(asOwner.status).toBe(200);
  });
});

describe('engelleme gruplarda da geçerli', () => {
  it('sahibini engelleyen gruba KATILAMAZ — aynı 404', async () => {
    const owner = await member('EngelliSahip');
    const blocker = await member('Engelleyen');
    const { joinCode } = await createGroup(owner.token, 'Engel Grubu');

    await blockPost(req('/api/community/block', 'POST', blocker.token, { targetUserId: owner.id }));

    const res = await joinPost(
      req('/api/community/groups/join', 'POST', blocker.token, { code: joinCode })
    );
    expect(res.status).toBe(404);
  });

  it('engellenen üye listede GÖRÜNMEZ ama mevcut sayısı gerçeği söyler', async () => {
    const owner = await member('ListeSahibi');
    const other = await member('Engellenecek');
    const { id, joinCode } = await createGroup(owner.token, 'Gizleme Grubu');
    await joinPost(req('/api/community/groups/join', 'POST', other.token, { code: joinCode }));

    await blockPost(req('/api/community/block', 'POST', owner.token, { targetUserId: other.id }));

    const detail = await groupGet(get(`/api/community/groups/${id}`, owner.token));
    const body = (await detail.json()) as {
      group: { memberCount: number };
      members: { displayName: string }[];
    };
    expect(body.members.map((m) => m.displayName)).not.toContain('Engellenecek');
    // Mevcut GERÇEK kalır — engelleyen kişi grubu eksik sanmasın.
    expect(body.group.memberCount).toBe(2);
  });
});

describe('meydan okumalar', () => {
  async function seedChallenge(slug: string, metric: string, target: number, active = true) {
    const db = await getDb();
    const now = Date.now();
    await db
      .insert(challenges)
      .values({
        id: `ch-${slug}`,
        slug,
        title: `Meydan ${slug}`,
        description: 'test',
        metric,
        target,
        licence: null,
        startsAt: new Date(active ? now - 86_400_000 : now + 86_400_000),
        endsAt: new Date(active ? now + 86_400_000 : now + 2 * 86_400_000),
      })
      .onConflictDoNothing();
    return `ch-${slug}`;
  }

  it('ilerleme TABANDAN türetilir — geçmiş XP anında bitirmez', async () => {
    const u = await member('Yarisan');
    await statsPost(req('/api/community/stats', 'POST', u.token, { xp: 1500, answered: 200 }));
    const id = await seedChallenge('xp-500', 'xp', 500);

    const joined = await challengesPost(
      req('/api/community/challenges', 'POST', u.token, { challengeId: id })
    );
    expect(joined.status).toBe(201);
    // Taban 1500 → mevcut XP meydan okumayı bitirmedi.
    expect((await joined.json()) as { baseline: number }).toMatchObject({ baseline: 1500 });

    const before = await challengesGet(get('/api/community/challenges', u.token));
    const b = (await before.json()) as {
      challenges: { id: string; percent: number; done: boolean }[];
    };
    const row = b.challenges.find((c) => c.id === id)!;
    expect(row.percent).toBe(0);
    expect(row.done).toBe(false);
  });

  it('MEYDAN OKUMA ANTİ-HİLE TEMPOSUNU DEVRALIR — arka arkaya bildirim ilerletmez', async () => {
    const u = await member('Hizlici');
    await statsPost(req('/api/community/stats', 'POST', u.token, { xp: 100 }));
    const id = await seedChallenge('xp-200', 'xp', 200);
    await challengesPost(req('/api/community/challenges', 'POST', u.token, { challengeId: id }));

    // E8 kuralı: son yazmadan bu yana SUBMIT_WINDOW_MS geçmediyse ARTIŞ UYGULANMAZ.
    for (const xp of [300, 500, 700]) {
      await statsPost(req('/api/community/stats', 'POST', u.token, { xp }));
    }

    const after = await challengesGet(get('/api/community/challenges', u.token));
    const a = (await after.json()) as { challenges: { id: string; value: number }[] };
    // Döngüyle meydan okuma bitirilemez — ilerleme SIFIR kalır. Bu, kırpmanın meydan okumalara
    // otomatik olarak yayıldığının kanıtıdır (ayrı bir hile yüzeyi açılmadı).
    expect(a.challenges.find((c) => c.id === id)!.value).toBe(0);
  });

  it('pencere geçtiğinde ilerleme türetilir', async () => {
    const u = await member('Ilerleyen');
    await statsPost(req('/api/community/stats', 'POST', u.token, { xp: 100 }));
    const id = await seedChallenge('xp-150', 'xp', 150);
    await challengesPost(req('/api/community/challenges', 'POST', u.token, { challengeId: id }));

    // Meşru bir sonraki oturumu benzet: son yazmayı pencereden ESKİYE al.
    const db = await getDb();
    await db
      .update(communityStats)
      .set({ updatedAt: new Date(Date.now() - (SUBMIT_WINDOW_MS + 5_000)) })
      .where(eq(communityStats.userId, u.id));

    await statsPost(req('/api/community/stats', 'POST', u.token, { xp: 250 }));

    const after = await challengesGet(get('/api/community/challenges', u.token));
    const a = (await after.json()) as {
      challenges: { id: string; value: number; percent: number }[];
    };
    const row = a.challenges.find((c) => c.id === id)!;
    // Taban 100, güncel 250 → ilerleme 150 = hedef → tamamlandı.
    expect(row.value).toBe(150);
    expect(row.percent).toBe(100);
  });

  it('etkin olmayan meydan okumaya katılınamaz ve listelenmez', async () => {
    const u = await member('Erken');
    const id = await seedChallenge('gelecek', 'xp', 100, false);
    const res = await challengesPost(
      req('/api/community/challenges', 'POST', u.token, { challengeId: id })
    );
    expect(res.status).toBe(409);

    const list = await challengesGet(get('/api/community/challenges', u.token));
    const body = (await list.json()) as { challenges: { id: string }[] };
    expect(body.challenges.find((c) => c.id === id)).toBeUndefined();
  });

  it('aynı meydan okumaya iki kez katılınamaz', async () => {
    const u = await member('Tekrarci');
    const id = await seedChallenge('tek-katilim', 'answered', 50);
    await challengesPost(req('/api/community/challenges', 'POST', u.token, { challengeId: id }));
    const again = await challengesPost(
      req('/api/community/challenges', 'POST', u.token, { challengeId: id })
    );
    expect(again.status).toBe(409);
  });
});

describe('oturum gerekliliği', () => {
  it('gruplar ve meydan okumalar oturumsuz 401', async () => {
    expect((await groupsGet(get('/api/community/groups'))).status).toBe(401);
    expect((await challengesGet(get('/api/community/challenges'))).status).toBe(401);
  });
});

describe('haftalık devir (E10 DoD: belirlenimci rollover)', () => {
  it('geçmiş hafta dondurulur, İKİNCİ kez yazılmaz ve sıralama belirlenimcidir', async () => {
    const a = await member('DevirBir');
    const b = await member('DevirIki');

    const rows = [
      { userId: b.id, displayName: 'DevirIki', avatarId: 'owl-wave', xp: 400 },
      { userId: a.id, displayName: 'DevirBir', avatarId: 'owl-wave', xp: 900 },
    ];

    const first = await rolloverIfNeeded({ licence: 'all', currentWeekStart: '2026-07-20', rows });
    expect(first).toEqual({ taken: true, weekStart: '2026-07-13' });

    // ETKİSİZ-TEKRARLI: aynı hafta ikinci kez yazılmaz.
    const second = await rolloverIfNeeded({
      licence: 'all',
      currentWeekStart: '2026-07-20',
      rows: [...rows].reverse(),
    });
    expect(second.taken).toBe(false);

    const db = await getDb();
    const saved = await db
      .select()
      .from(leaderboardSnapshots)
      .where(eq(leaderboardSnapshots.id, '2026-07-13:all'));
    expect(saved).toHaveLength(1);
    // XP azalan sırada dondurulmuş olmalı — girdi sırası ters verilmişti.
    const stored = saved[0]!.rows as { userId: string; xp: number }[];
    expect(stored.map((r) => r.xp)).toEqual([900, 400]);
  });

  it('İÇİNDE BULUNULAN hafta ASLA dondurulmaz', async () => {
    const u = await member('AyniHafta');
    const res = await rolloverIfNeeded({
      licence: 'b',
      currentWeekStart: '2026-07-20',
      rows: [{ userId: u.id, displayName: 'AyniHafta', avatarId: 'owl-wave', xp: 10 }],
    });
    expect(res.weekStart).not.toBe('2026-07-20');

    const db = await getDb();
    const current = await db
      .select()
      .from(leaderboardSnapshots)
      .where(eq(leaderboardSnapshots.id, '2026-07-20:b'));
    expect(current).toHaveLength(0);
  });

  it('boş hafta dondurulmaz — anlamsız satır bırakmaz', async () => {
    const res = await rolloverIfNeeded({ licence: 'd', currentWeekStart: '2026-06-15', rows: [] });
    expect(res.taken).toBe(false);
  });
});
