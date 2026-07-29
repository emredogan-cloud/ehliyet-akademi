/**
 * Faz 8 — davet sisteminin SUNUCU tarafı: kod üretimi, davet kaydı, nitelik kazanma ve ödül motoru.
 *
 * Kurallar burada TEKRAR YAZILMAZ; hepsi `lib/referrals.ts` içindeki saf katmandan gelir. Bu dosya
 * yalnız veritabanına dokunur ve o kuralları uygular.
 */
import { and, eq, inArray } from 'drizzle-orm';
import { randomBytes, createHash } from 'node:crypto';
import { getDb, referralCodes, referralRewards, referrals, users, type Db } from '@ea/db';
import { newId } from '@/lib/server/auth';
import { logger } from '@/lib/server/logger';
import {
  REFERRAL_ALPHABET,
  evaluateReferral,
  generateReferralCode,
  normalizeReferralCode,
  pendingMilestones,
  qualifiesOnVerification,
  rewardExpiry,
  type ReferralRejection,
} from '@/lib/referrals';

/**
 * IP'yi TUZLU hash'le.
 *
 * Ham IP saklanmaz (KVKK veri minimizasyonu); sahtecilik tespiti için gereken tek şey "aynı mı"
 * sorusunun cevabıdır. Tuz ortamdan gelir — tuzsuz bir hash, IPv4 uzayı küçük olduğu için
 * kaba kuvvetle geri çevrilebilirdi.
 */
export function hashIp(ip: string): string {
  if (!ip) return '';
  const salt = process.env.REFERRAL_IP_SALT ?? 'ea-referral-dev-salt';
  return createHash('sha256').update(`${salt}:${ip}`).digest('hex').slice(0, 32);
}

/** İstekten istemci IP'sini çıkar (ters vekil başlıkları dâhil). */
export function clientIp(req: Request): string {
  const fwd = req.headers.get('x-forwarded-for') ?? '';
  const first = fwd.split(',')[0]?.trim();
  return first || req.headers.get('x-real-ip') || '';
}

function randomInt(maxExclusive: number): number {
  // `randomBytes` ile modulo sapmasını önleyerek düzgün dağılım.
  const limit = Math.floor(256 / maxExclusive) * maxExclusive;
  for (;;) {
    const b = randomBytes(1)[0]!;
    if (b < limit) return b % maxExclusive;
  }
}

/**
 * Kullanıcının davet kodunu getir; yoksa üret.
 *
 * Çakışma olasılığı düşüktür (31^8 ≈ 8.5×10^11) ama SIFIR DEĞİLDİR; birkaç deneme yapılır ve
 * hepsinde çakışırsa hata fırlatılır — sessizce yanlış kod döndürmek çok daha kötüdür.
 */
export async function ensureReferralCode(db: Db, userId: string): Promise<string> {
  const existing = await db
    .select({ code: referralCodes.code })
    .from(referralCodes)
    .where(eq(referralCodes.userId, userId));
  if (existing[0]) return existing[0].code;

  for (let attempt = 0; attempt < 8; attempt++) {
    const code = generateReferralCode(randomInt);
    try {
      await db.insert(referralCodes).values({ userId, code });
      return code;
    } catch {
      // Ya kod çakıştı ya da kullanıcı için satır bu arada açıldı; ikinci ihtimali kontrol et.
      const again = await db
        .select({ code: referralCodes.code })
        .from(referralCodes)
        .where(eq(referralCodes.userId, userId));
      if (again[0]) return again[0].code;
    }
  }
  throw new Error('referral code could not be generated');
}

/** Koddan davet edeni bul (yoksa null). */
export async function referrerByCode(db: Db, code: string): Promise<string | null> {
  const rows = await db
    .select({ userId: referralCodes.userId })
    .from(referralCodes)
    .where(eq(referralCodes.code, code));
  return rows[0]?.userId ?? null;
}

/**
 * Kayıt sırasında daveti KAYDET.
 *
 * SESSİZ BAŞARISIZLIK BİLİNÇLİDİR: geçersiz bir davet kodu KAYDI ENGELLEMEZ. Kullanıcı hesabını
 * açmıştır; kodu yanlış yazdı diye onu geri çevirmek, davet sistemini kayıt akışının önüne
 * koymak olurdu. Reddin nedeni günlüğe yazılır ve çağırana döner (istemci isterse gösterir).
 */
export async function recordReferral(args: {
  db: Db;
  rawCode: string;
  referredUserId: string;
  ip: string;
}): Promise<{ ok: true } | { ok: false; reason: ReferralRejection }> {
  const { db, referredUserId } = args;
  const code = normalizeReferralCode(args.rawCode);
  const referrerUserId = await referrerByCode(db, code);
  const ipHash = hashIp(args.ip);

  const alreadyRows = await db
    .select({ id: referrals.id })
    .from(referrals)
    .where(eq(referrals.referredUserId, referredUserId));

  // Aynı IP'den kaç davet KABUL EDİLMİŞ? (İptal edilenler sayılmaz.)
  let sameIpCount = 0;
  if (ipHash) {
    const ipRows = await db
      .select({ id: referrals.id })
      .from(referrals)
      .where(eq(referrals.signupIpHash, ipHash));
    sameIpCount = ipRows.length;
  }

  const verdict = evaluateReferral({
    code,
    referrerUserId,
    referredUserId,
    alreadyReferred: alreadyRows.length > 0,
    sameIpCount,
  });
  if (!verdict.ok) {
    logger.info('referral_rejected', { reason: verdict.reason, referredUserId });
    return verdict;
  }

  await db.insert(referrals).values({
    id: newId(),
    referrerUserId: referrerUserId!,
    referredUserId,
    code,
    status: 'pending',
    signupIpHash: ipHash,
  });
  logger.info('referral_recorded', { referrerUserId, referredUserId });
  return { ok: true };
}

/**
 * E-posta doğrulandığında daveti NİTELİKLİ yap ve ödül motorunu çalıştır.
 *
 * "Başarılı kayıt" tanımı budur: doğrulanmamış bir e-posta ile açılan hesap sayılmaz. Bu tek
 * kural, sahte hesapla ödül toplamanın maliyetini kullanılabilir bir e-posta kutusuna çıkarır.
 */
export async function qualifyReferralOnVerification(db: Db, referredUserId: string): Promise<void> {
  const rows = await db
    .select({
      id: referrals.id,
      status: referrals.status,
      referrerUserId: referrals.referrerUserId,
    })
    .from(referrals)
    .where(eq(referrals.referredUserId, referredUserId));
  const row = rows[0];
  if (!row || !qualifiesOnVerification(row.status)) return;

  await db
    .update(referrals)
    .set({ status: 'qualified', qualifiedAt: new Date() })
    .where(eq(referrals.id, row.id));
  logger.info('referral_qualified', { referrerUserId: row.referrerUserId, referredUserId });

  await grantDueRewards(db, row.referrerUserId);
}

/** Kullanıcının nitelikli davet sayısı. */
export async function qualifiedCount(db: Db, userId: string): Promise<number> {
  const rows = await db
    .select({ id: referrals.id })
    .from(referrals)
    .where(and(eq(referrals.referrerUserId, userId), eq(referrals.status, 'qualified')));
  return rows.length;
}

/**
 * Hak edilmiş ama verilmemiş ödülleri ver.
 *
 * Geriye dönük çalışır: bir kullanıcı 12 davete ulaşmışsa hem 5 hem 10 basamağı verilir. Aynı
 * basamak iki kez ödüllendirilmez (`milestone` kaydı bunun kapısıdır).
 */
export async function grantDueRewards(db: Db, userId: string): Promise<number> {
  const count = await qualifiedCount(db, userId);
  const existing = await db
    .select({ milestone: referralRewards.milestone, expiresAt: referralRewards.expiresAt })
    .from(referralRewards)
    .where(eq(referralRewards.userId, userId));

  const due = pendingMilestones(
    count,
    existing.map((r) => r.milestone)
  );
  if (due.length === 0) return 0;

  const now = new Date();
  // Süreler ÜST ÜSTE EKLENİR: hâlâ etkin bir ödülü olan kullanıcı yeni ödülle süre KAYBETMEZ.
  let currentExpiry: Date | null =
    existing.map((r) => r.expiresAt).sort((a, b) => b.getTime() - a.getTime())[0] ?? null;

  for (const m of due) {
    const expiresAt = rewardExpiry(m.months, now, currentExpiry);
    await db.insert(referralRewards).values({
      id: newId(),
      userId,
      milestone: m.count,
      months: m.months,
      expiresAt,
    });
    currentExpiry = expiresAt;
    logger.info('referral_reward_granted', { userId, milestone: m.count, months: m.months });
  }
  return due.length;
}

/** Kullanıcının ödül bitiş tarihleri. */
export async function rewardExpiries(db: Db, userId: string): Promise<Date[]> {
  const rows = await db
    .select({ expiresAt: referralRewards.expiresAt })
    .from(referralRewards)
    .where(eq(referralRewards.userId, userId));
  return rows.map((r) => r.expiresAt);
}

/** Kullanıcının davet özeti (arayüzün ihtiyaç duyduğu her şey). */
export async function referralSummary(userId: string) {
  const db = await getDb();
  const code = await ensureReferralCode(db, userId);
  const all = await db
    .select({ status: referrals.status, createdAt: referrals.createdAt })
    .from(referrals)
    .where(eq(referrals.referrerUserId, userId));
  const rewards = await db
    .select({
      milestone: referralRewards.milestone,
      months: referralRewards.months,
      grantedAt: referralRewards.grantedAt,
      expiresAt: referralRewards.expiresAt,
    })
    .from(referralRewards)
    .where(eq(referralRewards.userId, userId));

  return {
    code,
    invited: all.length,
    qualified: all.filter((r) => r.status === 'qualified').length,
    pending: all.filter((r) => r.status === 'pending').length,
    rewards,
  };
}

/**
 * YÖNETİCİ — bir daveti iptal et (sahtecilik).
 *
 * Ödüller GERİ ALINMAZ: verilmiş bir erişimi geri çekmek, iyi niyetli kullanıcıyı da vurabilecek
 * bir işlemdir ve elle karar gerektirir. İptal, GELECEKTEKİ basamakların sayımını düşürür.
 */
export async function voidReferral(db: Db, referralId: string, reason: string): Promise<boolean> {
  const rows = await db
    .select({ id: referrals.id })
    .from(referrals)
    .where(eq(referrals.id, referralId));
  if (!rows[0]) return false;
  await db
    .update(referrals)
    .set({ status: 'void', voidReason: reason.slice(0, 200) })
    .where(eq(referrals.id, referralId));
  logger.info('referral_voided', { referralId, reason });
  return true;
}

/** YÖNETİCİ — davet listesi (en yeni önce), kullanıcı e-postalarıyla. */
export async function listReferrals(db: Db, limit = 200) {
  const rows = await db
    .select({
      id: referrals.id,
      status: referrals.status,
      code: referrals.code,
      createdAt: referrals.createdAt,
      qualifiedAt: referrals.qualifiedAt,
      signupIpHash: referrals.signupIpHash,
      referrerUserId: referrals.referrerUserId,
      referredUserId: referrals.referredUserId,
    })
    .from(referrals);

  const ids = [...new Set(rows.flatMap((r) => [r.referrerUserId, r.referredUserId]))];
  const people = ids.length
    ? await db
        .select({ id: users.id, email: users.email })
        .from(users)
        .where(inArray(users.id, ids))
    : [];
  const emailById = new Map(people.map((p) => [p.id, p.email]));

  return rows
    .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
    .slice(0, limit)
    .map((r) => ({
      ...r,
      referrerEmail: emailById.get(r.referrerUserId) ?? '',
      referredEmail: emailById.get(r.referredUserId) ?? '',
    }));
}

/** Kod alfabesi dışa açılır — istemci aynı kuralla doğrulama yapabilsin diye. */
export { REFERRAL_ALPHABET };
