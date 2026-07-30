/**
 * Beta Faz 1/3/4 — davet hunisi ölçümü + telemetri alımı (bellek-içi PGlite).
 *
 * Buradaki testler "veri yazıldı mı" sorusundan fazlasını sorar: **kötüye kullanım kapıları
 * kapalı mı**. Bu uçlar oturum gerektirmez; oturumsuz bir yazma ucu, doğrulaması test edilmediği
 * sürece açık bir kapıdır.
 */
import { describe, it, expect, beforeAll } from 'vitest';
import { eq } from 'drizzle-orm';
import { getDb, analyticsEvents, errorReports, referralVisits, users } from '@ea/db';
import { POST as register } from '@/app/api/auth/register/route';
import { POST as collect } from '@/app/api/analytics/collect/route';
import { POST as reportErrors } from '@/app/api/errors/report/route';
import {
  recordReferralVisit,
  referrerPublicInfoByCode,
  ensureReferralCode,
  visitCountByCode,
  visitDay,
} from '@/lib/server/referrals';
import { sanitizeProps, safeAt, KNOWN_EVENTS } from '@/lib/server/telemetry';
import { parseFingerprints } from '@/app/.well-known/assetlinks.json/route';

const BASE = 'http://test.local';
const T = Date.now();
const PW = 'cok-gizli-123';

function post(path: string, body: unknown, cookie?: string): Request {
  return new Request(BASE + path, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...(cookie ? { cookie } : {}) },
    body: JSON.stringify(body),
  });
}
function cookieOf(res: Response): string {
  return (res.headers.get('set-cookie') ?? '').split(';')[0] ?? '';
}

describe('davet ziyareti (hunideki ilk basamak)', () => {
  it('ziyaret kaydedilir ve AYNI GÜN tekrarı sayıyı şişirmez', async () => {
    const db = await getDb();
    const code = 'VISITAAA';

    const first = await recordReferralVisit({
      db,
      code,
      known: true,
      ip: '10.1.1.1',
      platform: 'android',
    });
    // Sayfayı yenilemek yeni bir ilgi DEĞİLDİR; saymak huniyi iyimser gösterirdi.
    const second = await recordReferralVisit({
      db,
      code,
      known: true,
      ip: '10.1.1.1',
      platform: 'android',
    });

    expect(first).toBe(true);
    expect(second).toBe(false);
    expect(await visitCountByCode(db, code)).toBe(1);
  });

  it('FARKLI kişiler (farklı IP) ayrı ayrı sayılır', async () => {
    const db = await getDb();
    const code = 'VISITBBB';
    await recordReferralVisit({ db, code, known: true, ip: '10.2.2.1', platform: 'web' });
    await recordReferralVisit({ db, code, known: true, ip: '10.2.2.2', platform: 'web' });
    expect(await visitCountByCode(db, code)).toBe(2);
  });

  it('AYNI kişi ertesi gün tekrar sayılır', async () => {
    const db = await getDb();
    const code = 'VISITCCC';
    const day1 = new Date('2026-07-30T10:00:00Z');
    const day2 = new Date('2026-07-31T10:00:00Z');
    await recordReferralVisit({
      db,
      code,
      known: true,
      ip: '10.3.3.3',
      platform: 'web',
      now: day1,
    });
    await recordReferralVisit({
      db,
      code,
      known: true,
      ip: '10.3.3.3',
      platform: 'web',
      now: day2,
    });
    expect(await visitCountByCode(db, code)).toBe(2);
    expect(visitDay(day1)).toBe('2026-07-30');
  });

  it('HAM IP saklanmaz — yalnız tuzlu hash (KVKK)', async () => {
    const db = await getDb();
    const code = 'VISITDDD';
    await recordReferralVisit({ db, code, known: true, ip: '203.0.113.7', platform: 'web' });
    const rows = await db.select().from(referralVisits).where(eq(referralVisits.code, code));
    expect(rows[0]!.ipHash).not.toContain('203.0.113');
    expect(rows[0]!.ipHash).toHaveLength(32);
  });

  it('bilinmeyen kod da ölçülür (yazım hatası tespiti)', async () => {
    const db = await getDb();
    await recordReferralVisit({
      db,
      code: 'NOSUCHAA',
      known: false,
      ip: '10.4.4.4',
      platform: 'web',
    });
    const rows = await db.select().from(referralVisits).where(eq(referralVisits.code, 'NOSUCHAA'));
    expect(rows[0]!.known).toBe(false);
  });
});

describe('davet sayfasının gösterdiği bilgi', () => {
  it('YALNIZ ilk ad döner — tam ad/e-posta sızmaz', async () => {
    const db = await getDb();
    const res = await register(
      post('/api/auth/register', {
        email: `inviter-${T}@ea.dev`,
        password: PW,
        name: 'Ayşe Yılmaz Demir',
      })
    );
    expect(res.status).toBe(201);
    const userId = (await res.json()).user.id as string;
    const code = await ensureReferralCode(db, userId);

    const info = await referrerPublicInfoByCode(db, code);
    expect(info.known).toBe(true);
    expect(info.firstName).toBe('Ayşe');
    // Sayfa herkese açık: soyadın ve e-postanın orada işi yok.
    expect(info.firstName).not.toContain('Yılmaz');
  });

  /// Adı boş olan kullanıcının kodu GEÇERLİDİR. İki alan ayrı olmasa, adsız davet eden
  /// "bilinmeyen kod" sayılır ve davetliye yanlış uyarı gösterilirdi.
  it('adı olmayan kullanıcının kodu yine BİLİNİR', async () => {
    const db = await getDb();
    const res = await register(
      post('/api/auth/register', { email: `noname-${T}@ea.dev`, password: PW, name: '' })
    );
    const userId = (await res.json()).user.id as string;
    const code = await ensureReferralCode(db, userId);

    const info = await referrerPublicInfoByCode(db, code);
    expect(info.known).toBe(true);
    expect(info.firstName).toBeNull();
  });

  it('var olmayan kod bilinmiyor', async () => {
    const db = await getDb();
    expect(await referrerPublicInfoByCode(db, 'ZZZZZZZZ')).toEqual({
      known: false,
      firstName: null,
    });
  });
});

describe('analitik alımı', () => {
  it('oturumsuz olay kabul edilir (misafir kullanım ölçülmeli)', async () => {
    const db = await getDb();
    const res = await collect(
      post('/api/analytics/collect', {
        events: [
          {
            id: `ev-guest-${T}`,
            name: 'guest_session',
            props: { foo: 'bar' },
            at: new Date().toISOString(),
            anonId: 'anon-guest',
            platform: 'android',
            appVersion: 'v1.0.0 (4)',
          },
        ],
      })
    );
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ accepted: 1, rejected: 0 });

    const rows = await db
      .select()
      .from(analyticsEvents)
      .where(eq(analyticsEvents.id, `ev-guest-${T}`));
    expect(rows[0]!.userId).toBeNull();
    expect(rows[0]!.anonId).toBe('anon-guest');
  });

  it('oturum varsa olay kullanıcıya BAĞLANIR', async () => {
    const db = await getDb();
    const reg = await register(
      post('/api/auth/register', { email: `ev-user-${T}@ea.dev`, password: PW, name: 'E' })
    );
    const cookie = cookieOf(reg);
    const userId = (await reg.json()).user.id as string;

    await collect(
      post(
        '/api/analytics/collect',
        {
          events: [
            { id: `ev-bound-${T}`, name: 'login', at: new Date().toISOString(), anonId: 'a1' },
          ],
        },
        cookie
      )
    );
    const rows = await db
      .select()
      .from(analyticsEvents)
      .where(eq(analyticsEvents.id, `ev-bound-${T}`));
    expect(rows[0]!.userId).toBe(userId);
  });

  /// GÜVENLİK: istemcinin gönderdiği `userId` GÜVENİLMEZ. Kabul edilse, herhangi biri başkasının
  /// kimliğine olay yazabilir ve panoyu kirletebilirdi.
  it('istemcinin gönderdiği userId YOK SAYILIR', async () => {
    const db = await getDb();
    const victim = await register(
      post('/api/auth/register', { email: `victim-${T}@ea.dev`, password: PW, name: 'V' })
    );
    const victimId = (await victim.json()).user.id as string;

    await collect(
      post('/api/analytics/collect', {
        events: [
          {
            id: `ev-spoof-${T}`,
            name: 'purchase_completed',
            at: new Date().toISOString(),
            anonId: 'a2',
            userId: victimId,
          },
        ],
      })
    );
    const rows = await db
      .select()
      .from(analyticsEvents)
      .where(eq(analyticsEvents.id, `ev-spoof-${T}`));
    expect(rows[0]!.userId).toBeNull();
  });

  it('sözlük DIŞI olay adı atılır — tablo şişirilemez', async () => {
    const res = await collect(
      post('/api/analytics/collect', {
        events: [
          { id: `ev-bad-${T}`, name: 'uydurma_olay', at: new Date().toISOString() },
          { id: `ev-ok-${T}`, name: 'app_opened', at: new Date().toISOString() },
        ],
      })
    );
    expect(await res.json()).toEqual({ accepted: 1, rejected: 1 });
  });

  /// İstemci kuyruğu ağ hatasından sonra partiyi TEKRAR gönderir. İkinci yazma çakışır; çakışma
  /// hata değil beklenen durumdur (kayıp yerine tekrar seçildi — `analytics_sink.dart`).
  it('aynı olay iki kez gönderilirse İKİ SATIR olmaz', async () => {
    const db = await getDb();
    const body = {
      events: [{ id: `ev-dup-${T}`, name: 'app_opened', at: new Date().toISOString() }],
    };
    await collect(post('/api/analytics/collect', body));
    const res2 = await collect(post('/api/analytics/collect', body));
    // Uç nokta "kabul" der (istemci kaydı kuyruktan düşürsün), ama satır tekilliği korunur.
    expect(res2.status).toBe(200);
    const rows = await db
      .select()
      .from(analyticsEvents)
      .where(eq(analyticsEvents.id, `ev-dup-${T}`));
    expect(rows).toHaveLength(1);
  });

  it('parti sınırı aşılırsa fazlası yazılmaz', async () => {
    const events = Array.from({ length: 80 }, (_, i) => ({
      id: `ev-batch-${T}-${i}`,
      name: 'app_opened',
      at: new Date().toISOString(),
    }));
    const res = await collect(post('/api/analytics/collect', { events }));
    expect((await res.json()).accepted).toBe(50);
  });

  it('bozuk gövde 400 döner, çökmez', async () => {
    const res = await collect(
      new Request(BASE + '/api/analytics/collect', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: 'bu json değil',
      })
    );
    expect(res.status).toBe(400);
  });
});

describe('hata raporu alımı', () => {
  it('rapor yazılır ve bağlam korunur', async () => {
    const db = await getDb();
    const res = await reportErrors(
      post('/api/errors/report', {
        reports: [
          {
            id: `er-${T}`,
            kind: 'flutter',
            fingerprint: 'RangeError@exam_runner',
            message: 'RangeError (index): Invalid value',
            stack: '#0 ExamRunner.build',
            route: '/practice/exam',
            anonId: 'anon-x',
            appVersion: 'v1.0.0 (4)',
            context: { device: 'Redmi Note 11R', android: 13, online: false },
            fatal: true,
            at: new Date().toISOString(),
          },
        ],
      })
    );
    expect(await res.json()).toEqual({ accepted: 1, rejected: 0 });

    const rows = await db
      .select()
      .from(errorReports)
      .where(eq(errorReports.id, `er-${T}`));
    expect(rows[0]!.route).toBe('/practice/exam');
    expect(rows[0]!.fatal).toBe(true);
    expect(rows[0]!.context).toMatchObject({ device: 'Redmi Note 11R', online: false });
  });

  it('bilinmeyen tür ve mesajsız rapor atılır', async () => {
    const res = await reportErrors(
      post('/api/errors/report', {
        reports: [
          { id: `er-bad1-${T}`, kind: 'uydurma', message: 'x', at: new Date().toISOString() },
          { id: `er-bad2-${T}`, kind: 'flutter', message: '', at: new Date().toISOString() },
        ],
      })
    );
    expect(await res.json()).toEqual({ accepted: 0, rejected: 2 });
  });
});

describe('sanitizasyon kuralları', () => {
  it('yalnız ilkel değerler geçer; iç içe yapı ATILIR', () => {
    expect(sanitizeProps({ a: 'x', b: 2, c: true, d: { nested: 1 }, e: [1, 2], f: null })).toEqual({
      a: 'x',
      b: 2,
      c: true,
    });
  });

  it('anahtar sayısı ve dize uzunluğu sınırlanır', () => {
    const many = Object.fromEntries(Array.from({ length: 40 }, (_, i) => [`k${i}`, i]));
    expect(Object.keys(sanitizeProps(many))).toHaveLength(24);
    const long = sanitizeProps({ s: 'x'.repeat(500) }).s as string;
    expect(long).toHaveLength(120);
  });

  it('NaN/Infinity atılır (JSONB bunları saklayamaz)', () => {
    expect(sanitizeProps({ a: NaN, b: Infinity, c: 1 })).toEqual({ c: 1 });
  });

  /// Cihaz saati yanlış olabilir. İleri saatli bir olay panoyu geleceğe taşır; çok eski bir olay
  /// da geçmişi bozar. İkisi de sınıra çekilir.
  it('cihaz saati sınırlanır', () => {
    const now = new Date('2026-07-30T12:00:00Z');
    const future = safeAt('2027-01-01T00:00:00Z', now);
    expect(future.getTime()).toBe(now.getTime());

    const ancient = safeAt('2020-01-01T00:00:00Z', now);
    expect(ancient.getTime()).toBe(now.getTime() - 30 * 24 * 3600_000);

    const sane = safeAt('2026-07-30T11:00:00Z', now);
    expect(sane.toISOString()).toBe('2026-07-30T11:00:00.000Z');

    expect(safeAt('bu tarih değil', now).getTime()).toBe(now.getTime());
  });
});

describe('assetlinks.json', () => {
  /// Parmak izi UYDURULAMAZ; ortamdan gelir. Biçimi tutmayan değer sessizce kabul edilirse App
  /// Links doğrulaması bozulur ve nedeni aylarca görünmez.
  it('yalnız geçerli SHA-256 parmak izleri kabul edilir', () => {
    const good = Array.from({ length: 32 }, () => 'AB').join(':');
    expect(parseFingerprints(good)).toEqual([good]);
    expect(parseFingerprints(`${good},kısa:izi`)).toEqual([good]);
    expect(parseFingerprints(undefined)).toEqual([]);
    expect(parseFingerprints('')).toEqual([]);
  });

  it('küçük harfli parmak izi büyütülür', () => {
    const lower = Array.from({ length: 32 }, () => 'ab').join(':');
    expect(parseFingerprints(lower)).toEqual([lower.toUpperCase()]);
  });
});

describe('olay sözlüğü istemciyle eşleşir', () => {
  /// Sunucu beyaz listesi ile istemci sözlüğü ayrı dosyalarda yaşıyor; kayarsa olay SESSİZCE
  /// atılır. Sayı kontrolü, yeni bir olay eklerken iki tarafı birlikte güncellemeyi zorlar.
  it('beyaz liste beklenen olay sayısını taşır', () => {
    expect(KNOWN_EVENTS).toHaveLength(30);
    expect(new Set(KNOWN_EVENTS).size).toBe(KNOWN_EVENTS.length);
  });
});

beforeAll(async () => {
  // Şema bootstrap'ı ilk `getDb()` çağrısında uygulanır; kullanıcı tablosuna dokunarak tetikle.
  const db = await getDb();
  await db.select({ id: users.id }).from(users).limit(1);
});
