/**
 * Sosyal grafik entegrasyon testi (Evolution Faz E9, PGlite bellek-içi).
 *
 * DoD gereği asıl kanıt: **engelleme HER yolda uygulanır** — arkadaşlık, mesajlaşma, tartışma
 * listesi ve tartışma detayı. Ayrıca: arkadaşlık yaşam döngüsü, mesaj sınırları, sayfalama,
 * soru paylaşımının referansla olması ve şikâyet kuyruğunun içerik hedefleri.
 */
import { describe, it, expect } from 'vitest';
import { POST as register } from '@/app/api/auth/register/route';
import { PUT as profilePut } from '@/app/api/community/profile/route';
import { POST as blockPost } from '@/app/api/community/block/route';
import { POST as reportPost } from '@/app/api/community/report/route';
import {
  GET as friendsGet,
  POST as friendsPost,
  DELETE as friendsDelete,
} from '@/app/api/community/friends/route';
import { GET as messagesGet, POST as messagesPost } from '@/app/api/community/messages/route';
import {
  GET as discussionsGet,
  POST as discussionsPost,
} from '@/app/api/community/discussions/route';
import { GET as threadGet, POST as threadPost } from '@/app/api/community/discussions/[id]/route';
import { MESSAGE_MAX_LENGTH } from './social';

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
/** Topluluğa KATILMIŞ bir kullanıcı (sosyal özellikler katılıma bağlıdır). */
async function member(displayName: string, licence = 'b'): Promise<{ token: string; id: string }> {
  seq += 1;
  const reg = await register(
    req('/api/auth/register', 'POST', undefined, {
      name: 'Sosyal',
      email: `sosyal-${Date.now()}-${seq}-${Math.floor(Math.random() * 1e6)}@ea.dev`,
      password: 'sosyal-parola-123',
    })
  );
  const body = (await reg.json()) as { token: string; user: { id: string } };
  const put = await profilePut(
    req('/api/community/profile', 'PUT', body.token, {
      displayName,
      avatarId: 'owl-wave',
      licence,
      visibility: 'public',
    })
  );
  expect(put.status).toBe(200);
  return { token: body.token, id: body.user.id };
}

async function befriend(a: { token: string; id: string }, b: { token: string; id: string }) {
  const r1 = await friendsPost(
    req('/api/community/friends', 'POST', a.token, { targetUserId: b.id, action: 'request' })
  );
  expect(r1.status).toBe(201);
  const r2 = await friendsPost(
    req('/api/community/friends', 'POST', b.token, { targetUserId: a.id, action: 'accept' })
  );
  expect(r2.status).toBe(200);
}

describe('arkadaşlık yaşam döngüsü', () => {
  it('istek → kabul → her iki tarafta arkadaş görünür', async () => {
    const a = await member('Arkadas A');
    const b = await member('Arkadas B');

    // İstek gönderildi → A'da giden, B'de gelen.
    expect(
      (
        await friendsPost(
          req('/api/community/friends', 'POST', a.token, { targetUserId: b.id, action: 'request' })
        )
      ).status
    ).toBe(201);

    const aList = (await (await friendsGet(get('/api/community/friends', a.token))).json()) as {
      outgoing: Array<{ userId: string }>;
    };
    expect(aList.outgoing.map((x) => x.userId)).toContain(b.id);

    const bList = (await (await friendsGet(get('/api/community/friends', b.token))).json()) as {
      incoming: Array<{ userId: string; displayName: string }>;
    };
    expect(bList.incoming.map((x) => x.userId)).toContain(a.id);
    expect(bList.incoming[0]!.displayName).toBe('Arkadas A');

    // Kabul → iki tarafta da "friends".
    await friendsPost(
      req('/api/community/friends', 'POST', b.token, { targetUserId: a.id, action: 'accept' })
    );
    const aAfter = (await (await friendsGet(get('/api/community/friends', a.token))).json()) as {
      friends: Array<{ userId: string }>;
    };
    expect(aAfter.friends.map((x) => x.userId)).toContain(b.id);
  });

  it('aynı isteği tekrar göndermek 409 (spam engeli); kendine istek 400', async () => {
    const a = await member('Tekrarci');
    const b = await member('Hedef');
    await friendsPost(
      req('/api/community/friends', 'POST', a.token, { targetUserId: b.id, action: 'request' })
    );
    expect(
      (
        await friendsPost(
          req('/api/community/friends', 'POST', a.token, { targetUserId: b.id, action: 'request' })
        )
      ).status
    ).toBe(409);
    expect(
      (
        await friendsPost(
          req('/api/community/friends', 'POST', a.token, { targetUserId: a.id, action: 'request' })
        )
      ).status
    ).toBe(400); // kendine istek bir çakışma değil, istemci hatasıdır
  });

  it('isteği gönderen kendi isteğini KABUL EDEMEZ', async () => {
    const a = await member('Gonderen');
    const b = await member('Alici');
    await friendsPost(
      req('/api/community/friends', 'POST', a.token, { targetUserId: b.id, action: 'request' })
    );
    const res = await friendsPost(
      req('/api/community/friends', 'POST', a.token, { targetUserId: b.id, action: 'accept' })
    );
    expect(res.status).toBe(409);
  });

  it('arkadaşlık kaldırılabilir', async () => {
    const a = await member('Kaldiran');
    const b = await member('Kaldirilan');
    await befriend(a, b);
    expect(
      (await friendsDelete(req(`/api/community/friends?targetUserId=${b.id}`, 'DELETE', a.token)))
        .status
    ).toBe(200);
    const after = (await (await friendsGet(get('/api/community/friends', a.token))).json()) as {
      friends: unknown[];
    };
    expect(after.friends).toHaveLength(0);
  });

  it('topluluğa katılmayan istek gönderemez; katılmayan hedef 404', async () => {
    seq += 1;
    const reg = await register(
      req('/api/auth/register', 'POST', undefined, {
        name: 'Katilmayan',
        email: `katilmayan-${Date.now()}-${seq}@ea.dev`,
        password: 'katilmayan-parola-123',
      })
    );
    const outsider = (await reg.json()) as { token: string; user: { id: string } };
    const insider = await member('Katilan');

    expect(
      (
        await friendsPost(
          req('/api/community/friends', 'POST', outsider.token, {
            targetUserId: insider.id,
            action: 'request',
          })
        )
      ).status
    ).toBe(409);

    expect(
      (
        await friendsPost(
          req('/api/community/friends', 'POST', insider.token, {
            targetUserId: outsider.user.id,
            action: 'request',
          })
        )
      ).status
    ).toBe(404);
  });
});

describe('ENGELLEME her yolda uygulanır', () => {
  it('engelli kullanıcıya arkadaşlık isteği 404 (varlık sızdırılmaz)', async () => {
    const a = await member('Engelleyen A');
    const b = await member('Engellenen B');
    await blockPost(req('/api/community/block', 'POST', a.token, { targetUserId: b.id }));

    expect(
      (
        await friendsPost(
          req('/api/community/friends', 'POST', a.token, { targetUserId: b.id, action: 'request' })
        )
      ).status
    ).toBe(404);
    // Ters yönde de.
    expect(
      (
        await friendsPost(
          req('/api/community/friends', 'POST', b.token, { targetUserId: a.id, action: 'request' })
        )
      ).status
    ).toBe(404);
  });

  it('engellenince mevcut arkadaşlık LİSTEDEN düşer', async () => {
    const a = await member('Liste A');
    const b = await member('Liste B');
    await befriend(a, b);
    await blockPost(req('/api/community/block', 'POST', a.token, { targetUserId: b.id }));

    const aList = (await (await friendsGet(get('/api/community/friends', a.token))).json()) as {
      friends: Array<{ userId: string }>;
    };
    expect(aList.friends.map((x) => x.userId)).not.toContain(b.id);
    const bList = (await (await friendsGet(get('/api/community/friends', b.token))).json()) as {
      friends: Array<{ userId: string }>;
    };
    expect(bList.friends.map((x) => x.userId)).not.toContain(a.id);
  });

  it('engelli kişiye MESAJ gönderilemez ve konuşma okunamaz', async () => {
    const a = await member('Mesaj A');
    const b = await member('Mesaj B');
    await befriend(a, b);
    await messagesPost(
      req('/api/community/messages', 'POST', a.token, { targetUserId: b.id, body: 'selam' })
    );
    await blockPost(req('/api/community/block', 'POST', b.token, { targetUserId: a.id }));

    expect(
      (
        await messagesPost(
          req('/api/community/messages', 'POST', a.token, { targetUserId: b.id, body: 'tekrar' })
        )
      ).status
    ).toBe(404);
    expect((await messagesGet(get(`/api/community/messages?with=${b.id}`, a.token))).status).toBe(
      404
    );

    // Konuşma listesinde de görünmez.
    const list = (await (await messagesGet(get('/api/community/messages', a.token))).json()) as {
      threads: Array<{ userId: string }>;
    };
    expect(list.threads.map((t) => t.userId)).not.toContain(b.id);
  });

  it('engelli yazarın TARTIŞMA başlığı listede ve detayda görünmez', async () => {
    const author = await member('Yazar');
    const reader = await member('Okur');
    const created = await discussionsPost(
      req('/api/community/discussions', 'POST', author.token, {
        title: 'Kavşakta öncelik sorusu',
        licence: 'b',
      })
    );
    const { id } = (await created.json()) as { id: string };

    // Engelden ÖNCE görünür.
    const before = (await (
      await discussionsGet(get('/api/community/discussions?licence=b', reader.token))
    ).json()) as { threads: Array<{ id: string }> };
    expect(before.threads.map((t) => t.id)).toContain(id);
    expect((await threadGet(get(`/api/community/discussions/${id}`, reader.token))).status).toBe(
      200
    );

    await blockPost(req('/api/community/block', 'POST', reader.token, { targetUserId: author.id }));

    const after = (await (
      await discussionsGet(get('/api/community/discussions?licence=b', reader.token))
    ).json()) as { threads: Array<{ id: string }> };
    expect(after.threads.map((t) => t.id)).not.toContain(id);
    expect((await threadGet(get(`/api/community/discussions/${id}`, reader.token))).status).toBe(
      404
    );
    // Engelli başlığa ileti de yazılamaz.
    expect(
      (
        await threadPost(
          req(`/api/community/discussions/${id}`, 'POST', reader.token, { body: 'x' })
        )
      ).status
    ).toBe(404);
  });
});

describe('mesajlaşma kuralları', () => {
  it('YALNIZ arkadaşlar yazışabilir', async () => {
    const a = await member('Yabanci A');
    const b = await member('Yabanci B');
    const res = await messagesPost(
      req('/api/community/messages', 'POST', a.token, { targetUserId: b.id, body: 'selam' })
    );
    expect(res.status).toBe(403);
  });

  it('arkadaşlar yazışır; konuşma iki tarafta da okunur', async () => {
    const a = await member('Konusan A');
    const b = await member('Konusan B');
    await befriend(a, b);

    expect(
      (
        await messagesPost(
          req('/api/community/messages', 'POST', a.token, { targetUserId: b.id, body: 'Merhaba' })
        )
      ).status
    ).toBe(201);

    const bView = (await (
      await messagesGet(get(`/api/community/messages?with=${a.id}`, b.token))
    ).json()) as { messages: Array<{ body: string; mine: boolean }> };
    expect(bView.messages).toHaveLength(1);
    expect(bView.messages[0]!.body).toBe('Merhaba');
    expect(bView.messages[0]!.mine).toBe(false);

    const aView = (await (
      await messagesGet(get(`/api/community/messages?with=${b.id}`, a.token))
    ).json()) as { messages: Array<{ mine: boolean }> };
    expect(aView.messages[0]!.mine).toBe(true);
  });

  it('boş ve aşırı uzun mesaj reddedilir', async () => {
    const a = await member('Sinir A');
    const b = await member('Sinir B');
    await befriend(a, b);
    expect(
      (
        await messagesPost(
          req('/api/community/messages', 'POST', a.token, { targetUserId: b.id, body: '   ' })
        )
      ).status
    ).toBe(400);
    expect(
      (
        await messagesPost(
          req('/api/community/messages', 'POST', a.token, {
            targetUserId: b.id,
            body: 'a'.repeat(MESSAGE_MAX_LENGTH + 1),
          })
        )
      ).status
    ).toBe(400);
  });

  it('ani gönderim sınırı 429 döner', async () => {
    const a = await member('Hizli');
    const b = await member('Alan');
    await befriend(a, b);
    let sawLimit = false;
    for (let i = 0; i < 15; i++) {
      const res = await messagesPost(
        req('/api/community/messages', 'POST', a.token, { targetUserId: b.id, body: `m${i}` })
      );
      if (res.status === 429) {
        sawLimit = true;
        break;
      }
    }
    expect(sawLimit).toBe(true);
  });

  it('konuşma sayfa boyutu sunucu sınırına çekilir', async () => {
    const a = await member('Sayfa A');
    const b = await member('Sayfa B');
    await befriend(a, b);
    await messagesPost(
      req('/api/community/messages', 'POST', a.token, { targetUserId: b.id, body: 'tek' })
    );
    const res = (await (
      await messagesGet(get(`/api/community/messages?with=${b.id}&limit=9999`, a.token))
    ).json()) as { messages: unknown[] };
    expect(res.messages.length).toBeLessThanOrEqual(50);
  });

  it('oturumsuz erişim 401', async () => {
    expect((await messagesGet(get('/api/community/messages'))).status).toBe(401);
    expect(
      (await messagesPost(req('/api/community/messages', 'POST', undefined, { body: 'x' }))).status
    ).toBe(401);
  });
});

describe('tartışma ve soru paylaşımı', () => {
  it('başlık açılır, ileti eklenir, sayaç artar', async () => {
    const a = await member('Konu Acan');
    const created = await discussionsPost(
      req('/api/community/discussions', 'POST', a.token, {
        title: 'Sollama kuralları hakkında',
        licence: 'a',
      })
    );
    expect(created.status).toBe(201);
    const { id } = (await created.json()) as { id: string };

    expect(
      (
        await threadPost(
          req(`/api/community/discussions/${id}`, 'POST', a.token, { body: 'İlk ileti' })
        )
      ).status
    ).toBe(201);

    const body = (await (
      await threadGet(get(`/api/community/discussions/${id}`, a.token))
    ).json()) as {
      thread: { postCount: number; licence: string };
      posts: Array<{ body: string; mine: boolean }>;
    };
    expect(body.thread.postCount).toBe(1);
    expect(body.thread.licence).toBe('a');
    expect(body.posts[0]!.body).toBe('İlk ileti');
    expect(body.posts[0]!.mine).toBe(true);
  });

  it('soru paylaşımı REFERANSLADIR; geçersiz referans düşürülür, soru metni saklanmaz', async () => {
    const a = await member('Soru Paylasan');
    const ok = await discussionsPost(
      req('/api/community/discussions', 'POST', a.token, {
        title: 'Bu soruyu tartışalım',
        questionRef: 'trafik-101',
      })
    );
    expect(((await ok.json()) as { questionRef: string }).questionRef).toBe('trafik-101');

    // Soru METNİ referans olarak kabul EDİLMEZ → banka bir başlığa dökülemez.
    const bad = await discussionsPost(
      req('/api/community/discussions', 'POST', a.token, {
        title: 'Metin referans olmaz',
        questionRef: 'Kırmızı ışıkta ne yapılır? A) Geç B) Dur',
      })
    );
    expect(((await bad.json()) as { questionRef: string | null }).questionRef).toBeNull();
  });

  it('geçersiz başlık ve boş ileti reddedilir', async () => {
    const a = await member('Dogrulayan');
    expect(
      (await discussionsPost(req('/api/community/discussions', 'POST', a.token, { title: 'kısa' })))
        .status
    ).toBe(400);
    const created = await discussionsPost(
      req('/api/community/discussions', 'POST', a.token, { title: 'Geçerli bir başlık' })
    );
    const { id } = (await created.json()) as { id: string };
    expect(
      (await threadPost(req(`/api/community/discussions/${id}`, 'POST', a.token, { body: '  ' })))
        .status
    ).toBe(400);
  });

  it('sınıfa göre süzülür', async () => {
    const a = await member('Sinif Suzen', 'd');
    await discussionsPost(
      req('/api/community/discussions', 'POST', a.token, { title: 'Otobüs konusu', licence: 'd' })
    );
    const body = (await (
      await discussionsGet(get('/api/community/discussions?licence=d', a.token))
    ).json()) as { threads: Array<{ licence: string }>; licence: string };
    expect(body.licence).toBe('d');
    expect(body.threads.every((t) => t.licence === 'd')).toBe(true);
  });

  it('bilinmeyen başlık 404; oturumsuz 401', async () => {
    const a = await member('Bakan');
    expect((await threadGet(get('/api/community/discussions/yok-boyle', a.token))).status).toBe(
      404
    );
    expect((await discussionsGet(get('/api/community/discussions'))).status).toBe(401);
  });
});

describe('şikâyet: içerik hedefleri (E9)', () => {
  it('mesaj ve ileti bildirilebilir; uydurma referans 404', async () => {
    const a = await member('Sikayet Eden');
    const b = await member('Sikayet Edilen');
    await befriend(a, b);

    const sent = await messagesPost(
      req('/api/community/messages', 'POST', b.token, { targetUserId: a.id, body: 'kaba mesaj' })
    );
    const { id: messageId } = (await sent.json()) as { id: string };

    expect(
      (
        await reportPost(
          req('/api/community/report', 'POST', a.token, {
            targetUserId: b.id,
            reason: 'taciz',
            targetType: 'message',
            targetRef: messageId,
          })
        )
      ).status
    ).toBe(201);

    // Var olmayan içerik referansı → kayıt AÇILMAZ.
    expect(
      (
        await reportPost(
          req('/api/community/report', 'POST', a.token, {
            targetUserId: b.id,
            reason: 'taciz',
            targetType: 'message',
            targetRef: 'uydurma-id',
          })
        )
      ).status
    ).toBe(404);
  });
});
