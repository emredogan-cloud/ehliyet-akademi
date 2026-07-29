/**
 * Faz 8 — davet sistemi uçtan uca (bellek-içi PGlite).
 *
 * Buradaki testler zinciri BÜTÜN olarak kurar: kayıt → davet → e-posta doğrulama → nitelik →
 * ödül → premium erişim. Parça parça test etmek, aradaki bağlantı kopsa bile yeşil kalırdı.
 */
import { describe, it, expect } from 'vitest';
import { eq } from 'drizzle-orm';
import { getDb, emailVerificationTokens, referrals, users } from '@ea/db';
import { POST as register } from '@/app/api/auth/register/route';
import { POST as verify } from '@/app/api/auth/verify/route';
import { GET as referralsGet } from '@/app/api/referrals/route';
import { GET as purchasesGet } from '@/app/api/purchases/route';
import {
  GET as adminReferralsGet,
  POST as adminReferralsPost,
} from '@/app/api/admin/referrals/route';
import { ensureReferralCode, grantDueRewards } from '@/lib/server/referrals';

const BASE = 'http://test.local';
const T = Date.now();
const PW = 'cok-gizli-123';

function post(path: string, body: unknown, cookie?: string, ip?: string): Request {
  return new Request(BASE + path, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(cookie ? { cookie } : {}),
      ...(ip ? { 'x-forwarded-for': ip } : {}),
    },
    body: JSON.stringify(body),
  });
}
function get(path: string, cookie?: string): Request {
  return new Request(BASE + path, { headers: cookie ? { cookie } : {} });
}
function cookieOf(res: Response): string {
  return (res.headers.get('set-cookie') ?? '').split(';')[0] ?? '';
}

/** Kayıt ol ve çerezi + kullanıcı kimliğini döndür. */
async function signUp(email: string, opts: { code?: string; ip?: string } = {}) {
  const res = await register(
    post(
      '/api/auth/register',
      { email, password: PW, name: 'T', ...(opts.code ? { referralCode: opts.code } : {}) },
      undefined,
      opts.ip ?? '10.0.0.1'
    )
  );
  const body = (await res.json()) as {
    user: { id: string };
    referral?: { ok: boolean; reason?: string };
  };
  return {
    cookie: cookieOf(res),
    userId: body.user.id,
    referral: body.referral,
    status: res.status,
  };
}

/** Kullanıcının e-postasını doğrula (davetin nitelik kazandığı an). */
async function verifyEmail(userId: string) {
  const db = await getDb();
  const rows = await db
    .select({ tokenHash: emailVerificationTokens.tokenHash })
    .from(emailVerificationTokens)
    .where(eq(emailVerificationTokens.userId, userId));
  // Token'ın kendisi saklanmıyor (yalnız hash) → test doğrudan kullanıcıyı doğrulanmış yapar ve
  // motoru elle çağırır. Uç noktanın motoru çağırdığı ayrıca test ediliyor (aşağıda).
  expect(rows.length).toBeGreaterThan(0);
  const { qualifyReferralOnVerification } = await import('@/lib/server/referrals');
  await db.update(users).set({ emailVerified: true }).where(eq(users.id, userId));
  await qualifyReferralOnVerification(db, userId);
}

describe('davet zinciri', () => {
  let inviter = { cookie: '', userId: '' };
  let code = '';

  it('davet eden kayıt olur ve kodunu alır', async () => {
    const r = await signUp(`inviter-${T}@ea.dev`);
    inviter = { cookie: r.cookie, userId: r.userId };

    const res = await referralsGet(get('/api/referrals', inviter.cookie));
    expect(res.status).toBe(200);
    const body = (await res.json()) as { code: string; link: string; qualified: number };
    code = body.code;
    expect(code).toHaveLength(8);
    expect(body.link).toContain(code);
    expect(body.qualified).toBe(0);
  });

  it('kod SABİTTİR — ikinci istek aynı kodu döner', async () => {
    const res = await referralsGet(get('/api/referrals', inviter.cookie));
    expect(((await res.json()) as { code: string }).code).toBe(code);
  });

  it('davetle kayıt olan kullanıcı BEKLEMEDE sayılır (henüz ödül yok)', async () => {
    const r = await signUp(`friend1-${T}@ea.dev`, { code, ip: '10.0.1.1' });
    expect(r.referral?.ok).toBe(true);

    const res = await referralsGet(get('/api/referrals', inviter.cookie));
    const body = (await res.json()) as { invited: number; qualified: number; pending: number };
    expect(body.invited).toBe(1);
    expect(body.pending).toBe(1);
    expect(body.qualified).toBe(0);
  });

  /// "Başarılı kayıt" = e-postası DOĞRULANMIŞ hesap. Bu tek kural, sahte hesapla ödül toplamanın
  /// maliyetini kullanılabilir bir e-posta kutusuna çıkarır.
  it('e-posta doğrulanınca davet NİTELİKLİ olur', async () => {
    const db = await getDb();
    const rows = await db
      .select({ referredUserId: referrals.referredUserId })
      .from(referrals)
      .where(eq(referrals.referrerUserId, inviter.userId));
    await verifyEmail(rows[0]!.referredUserId);

    const res = await referralsGet(get('/api/referrals', inviter.cookie));
    const body = (await res.json()) as { qualified: number; pending: number };
    expect(body.qualified).toBe(1);
    expect(body.pending).toBe(0);
  });

  it('beşinci nitelikli davette PREMIUM açılır', async () => {
    // Dört davetli daha (her biri farklı IP — IP sınırı gerçek kullanımı engellememeli).
    for (let i = 2; i <= 5; i++) {
      const r = await signUp(`friend${i}-${T}@ea.dev`, { code, ip: `10.0.${i}.1` });
      expect(r.referral?.ok).toBe(true);
      await verifyEmail(r.userId);
    }

    const res = await referralsGet(get('/api/referrals', inviter.cookie));
    const body = (await res.json()) as {
      qualified: number;
      rewards: { milestone: number; months: number }[];
    };
    expect(body.qualified).toBe(5);
    expect(body.rewards).toHaveLength(1);
    expect(body.rewards[0]!.milestone).toBe(5);
    expect(body.rewards[0]!.months).toBe(1);

    // ASIL İDDİA: sahiplik ucu premium'u gerçekten açıyor mu?
    const purchases = await purchasesGet(get('/api/purchases', inviter.cookie));
    const owned = ((await purchases.json()) as { purchases: { productId: string }[] }).purchases;
    expect(owned.map((p) => p.productId)).toContain('komple-ehliyet');
  });

  it('altıncı davet yeni ödül üretmez (aynı basamak iki kez verilmez)', async () => {
    const r = await signUp(`friend6-${T}@ea.dev`, { code, ip: '10.0.6.1' });
    await verifyEmail(r.userId);
    const res = await referralsGet(get('/api/referrals', inviter.cookie));
    const body = (await res.json()) as { qualified: number; rewards: unknown[] };
    expect(body.qualified).toBe(6);
    expect(body.rewards).toHaveLength(1);
  });
});

describe('sahtecilik koruması', () => {
  it('KENDİ kodunla kayıt olmak davet yaratmaz', async () => {
    const me = await signUp(`self-${T}@ea.dev`);
    const db = await getDb();
    const myCode = await ensureReferralCode(db, me.userId);
    // Kendi kodunu kullanan İKİNCİ bir kayıt değil, birinci kaydın kendisi denenemez; bu yüzden
    // motoru doğrudan çağırıp aynı kullanıcıyı davetli yapmayı deniyoruz.
    const { recordReferral } = await import('@/lib/server/referrals');
    const verdict = await recordReferral({
      db,
      rawCode: myCode,
      referredUserId: me.userId,
      ip: '10.9.9.9',
    });
    expect(verdict).toEqual({ ok: false, reason: 'self' });
  });

  it('bilinmeyen kod kaydı ENGELLEMEZ, yalnız davet yaratmaz', async () => {
    const r = await signUp(`badcode-${T}@ea.dev`, { code: 'ZZZZZZZZ', ip: '10.8.8.8' });
    expect(r.status).toBe(201); // hesap AÇILDI
    expect(r.referral?.ok).toBe(false);
    expect(r.referral?.reason).toBe('unknown-code');
  });

  it('aynı IP’den dördüncü davet reddedilir', async () => {
    const inviter = await signUp(`ipinviter-${T}@ea.dev`);
    const db = await getDb();
    const c = await ensureReferralCode(db, inviter.userId);
    const ip = '77.77.77.77';

    for (let i = 1; i <= 3; i++) {
      const r = await signUp(`ip${i}-${T}@ea.dev`, { code: c, ip });
      expect(r.referral?.ok).toBe(true);
    }
    const fourth = await signUp(`ip4-${T}@ea.dev`, { code: c, ip });
    expect(fourth.referral).toEqual({ ok: false, reason: 'ip-limit' });
    expect(fourth.status).toBe(201); // hesap yine açıldı
  });
});

describe('yönetici yüzeyi', () => {
  it('yönetici davetleri listeler ve sahte olanı iptal eder', async () => {
    const db = await getDb();
    // Rolü admin yapılmış bir kullanıcı gerekir.
    const admin = await signUp(`admin-ref-${T}@ea.dev`);
    await db.update(users).set({ role: 'admin' }).where(eq(users.id, admin.userId));

    const listRes = await adminReferralsGet(get('/api/admin/referrals', admin.cookie));
    expect(listRes.status).toBe(200);
    const list = ((await listRes.json()) as { referrals: { id: string; status: string }[] })
      .referrals;
    expect(list.length).toBeGreaterThan(0);

    const target = list.find((r) => r.status === 'qualified')!;
    const voidRes = await adminReferralsPost(
      post('/api/admin/referrals', { referralId: target.id, reason: 'test' }, admin.cookie)
    );
    expect(voidRes.status).toBe(200);

    const after = await db
      .select({ status: referrals.status })
      .from(referrals)
      .where(eq(referrals.id, target.id));
    expect(after[0]!.status).toBe('void');
  });

  it('yönetici olmayan erişemez', async () => {
    const user = await signUp(`plain-${T}@ea.dev`);
    expect((await adminReferralsGet(get('/api/admin/referrals', user.cookie))).status).toBe(403);
  });

  /// İptal edilen davet GELECEKTEKİ sayımdan düşer; verilmiş ödül geri ALINMAZ (bilinçli).
  it('iptal, sayımı düşürür ama verilmiş ödülü geri almaz', async () => {
    const db = await getDb();
    const inviter = await signUp(`voidcount-${T}@ea.dev`);
    const c = await ensureReferralCode(db, inviter.userId);
    for (let i = 1; i <= 5; i++) {
      const r = await signUp(`vc${i}-${T}@ea.dev`, { code: c, ip: `11.0.${i}.1` });
      await verifyEmail(r.userId);
    }
    const before = await referralsGet(get('/api/referrals', inviter.cookie));
    expect(((await before.json()) as { rewards: unknown[] }).rewards).toHaveLength(1);

    const rows = await db
      .select({ id: referrals.id })
      .from(referrals)
      .where(eq(referrals.referrerUserId, inviter.userId));
    const { voidReferral } = await import('@/lib/server/referrals');
    await voidReferral(db, rows[0]!.id, 'sahte');

    const after = await referralsGet(get('/api/referrals', inviter.cookie));
    const body = (await after.json()) as { qualified: number; rewards: unknown[] };
    expect(body.qualified).toBe(4); // sayım düştü
    expect(body.rewards).toHaveLength(1); // ödül duruyor

    // Yeni ödül de üretilmez (basamak zaten verilmiş).
    expect(await grantDueRewards(db, inviter.userId)).toBe(0);
  });
});

describe('oturumsuz', () => {
  it('davet özeti 401 döner', async () => {
    expect((await referralsGet(get('/api/referrals'))).status).toBe(401);
  });
});

/** Doğrulama UCU davet motorunu gerçekten çağırıyor mu? */
describe('doğrulama ucu motoru tetikler', () => {
  it('token ile doğrulama daveti nitelikli yapar', async () => {
    const db = await getDb();
    const inviter = await signUp(`hook-inviter-${T}@ea.dev`);
    const c = await ensureReferralCode(db, inviter.userId);
    const friend = await signUp(`hook-friend-${T}@ea.dev`, { code: c, ip: '12.0.0.1' });

    // Yeni bir doğrulama tokenı iste (e-posta yapılandırılmadığı için dev modda yanıtta döner).
    const tokenRes = await verify(post('/api/auth/verify', {}, friend.cookie));
    const devToken = ((await tokenRes.json()) as { devToken?: string }).devToken;
    expect(devToken, 'dev token bekleniyordu').toBeTruthy();

    const done = await verify(post('/api/auth/verify', { token: devToken }));
    expect(done.status).toBe(200);

    const rows = await db
      .select({ status: referrals.status })
      .from(referrals)
      .where(eq(referrals.referredUserId, friend.userId));
    expect(rows[0]!.status).toBe('qualified');
  });
});
