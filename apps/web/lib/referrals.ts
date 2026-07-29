/**
 * Faz 8 — davet (referral) sisteminin SAF kural katmanı.
 *
 * Burada veritabanı, istek, oturum YOKTUR. Ödül eşikleri, kod biçimi ve sahtecilik kuralları saf
 * fonksiyonlardır ve doğrudan test edilir. Sunucu tarafı (`lib/server/referrals.ts`) yalnız bu
 * kuralları uygular.
 */

/** Ödül basamağı: kaç nitelikli davette kaç ay premium. */
export interface ReferralMilestone {
  /** Nitelikli davet sayısı. */
  readonly count: number;
  /** Kazanılan premium süresi (ay). */
  readonly months: number;
}

/**
 * Ödül merdiveni.
 *
 * Talep "beş başarılı kayıt → bir ya da iki ay premium" diyordu. Beşte **bir ay** veriliyor;
 * ikinci ay ONUNCU davette geliyor. Neden merdiven: tek basamaklı bir ödül, beşinci davetten
 * sonra daveti anlamsız kılar — davet eden kullanıcı orada durur. Merdiven, sistemin
 * "organik" olmasının şartıdır.
 *
 * Basamaklar arttırılabilir; motor listeyi okur, sabit sayı bilmez.
 */
export const REFERRAL_MILESTONES: readonly ReferralMilestone[] = [
  { count: 5, months: 1 },
  { count: 10, months: 2 },
  { count: 25, months: 6 },
];

/** Daveti "başarılı" sayan eşik (arayüzde gösterilen ilk hedef). */
export const REFERRAL_FIRST_GOAL = REFERRAL_MILESTONES[0]!.count;

/**
 * Kod alfabesi — KARIŞTIRILABİLİR harfler ÇIKARILDI (0/O, 1/I/L).
 *
 * Kod telefonda okunup elle yazılıyor; `0` ile `O` ayırt edilemediğinde kullanıcı kendi hatasını
 * bizim hatamız sanır. Bu, estetik değil destek maliyeti kararıdır.
 */
export const REFERRAL_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
export const REFERRAL_CODE_LENGTH = 8;

/** Kullanıcının yazdığı kodu kanonik biçime getir (büyük harf, boşluk/tire yok). */
export function normalizeReferralCode(raw: string): string {
  return (
    raw
      .toUpperCase()
      .replace(/[\s-]/g, '')
      // Sık yapılan okuma hataları kabul edilir: O→0 DEĞİL, tersi. Alfabede 0/1 yok; kullanıcı
      // yanlışlıkla yazdıysa en yakın geçerli harfe çevrilir.
      .replace(/0/g, 'O')
      .replace(/1/g, 'I')
      .slice(0, REFERRAL_CODE_LENGTH)
  );
}

/** Kod biçimsel olarak geçerli mi? (Var olup olmadığı ayrı bir soru — o veritabanına aittir.) */
export function isValidReferralCodeFormat(code: string): boolean {
  if (code.length !== REFERRAL_CODE_LENGTH) return false;
  for (const ch of code) {
    if (!REFERRAL_ALPHABET.includes(ch)) return false;
  }
  return true;
}

/**
 * Rastgele kod üret. [randomInt] dışarıdan verilir → test deterministik olabilir.
 */
export function generateReferralCode(randomInt: (maxExclusive: number) => number): string {
  let out = '';
  for (let i = 0; i < REFERRAL_CODE_LENGTH; i++) {
    out += REFERRAL_ALPHABET[randomInt(REFERRAL_ALPHABET.length)];
  }
  return out;
}

/** Bir davetin reddedilme nedeni (kullanıcıya gösterilecek metin sunucuda üretilir). */
export type ReferralRejection =
  'self' | 'already-referred' | 'unknown-code' | 'bad-format' | 'ip-limit';

/**
 * Aynı IP'den kaç davetli kabul edilir.
 *
 * SAHTECİLİK: en ucuz saldırı, aynı telefondan/ağdan arka arkaya hesap açmaktır. Sıfır tolerans
 * DOĞRU DEĞİL — aynı evden iki kardeş, aynı okul ağından sınıf arkadaşları gerçek davetlerdir.
 * Üç, gerçek kullanımı engellemeyen ama toplu hesap açmayı anlamsız kılan eşiktir.
 */
export const REFERRAL_MAX_PER_IP = 3;

/**
 * Bir daveti kabul etmenin saf kuralı.
 *
 * Not: "e-posta doğrulanmış mı" burada SORULMAZ — kayıt anında henüz doğrulanmamıştır. Doğrulama,
 * daveti `pending`'den `qualified`'a taşıyan AYRI bir olaydır ([qualifiesOnVerification]).
 */
export function evaluateReferral(input: {
  code: string;
  referrerUserId: string | null;
  referredUserId: string;
  alreadyReferred: boolean;
  sameIpCount: number;
}): { ok: true } | { ok: false; reason: ReferralRejection } {
  if (!isValidReferralCodeFormat(input.code)) return { ok: false, reason: 'bad-format' };
  if (!input.referrerUserId) return { ok: false, reason: 'unknown-code' };
  // Kendini davet etmek: en bariz istismar. İkinci bir hesapla yapılan self-referral'ı IP kuralı
  // yakalar; buradaki kontrol aynı hesabın kendi kodunu girmesini kapatır.
  if (input.referrerUserId === input.referredUserId) return { ok: false, reason: 'self' };
  if (input.alreadyReferred) return { ok: false, reason: 'already-referred' };
  if (input.sameIpCount >= REFERRAL_MAX_PER_IP) return { ok: false, reason: 'ip-limit' };
  return { ok: true };
}

/** Davet, e-posta doğrulandığında niteliklidir. Silinmiş/iptal edilmiş davet yükselmez. */
export function qualifiesOnVerification(status: string): boolean {
  return status === 'pending';
}

/**
 * Nitelikli davet sayısına göre HANGİ basamakların hak edildiğini söyle.
 *
 * [alreadyGranted] daha önce ödüllendirilmiş basamaklar. Dönüş, ŞİMDİ verilmesi gerekenler.
 * Geriye dönük de çalışır: bir kullanıcı 12 davete ulaşmışsa hem 5 hem 10 basamağını alır.
 */
export function pendingMilestones(
  qualifiedCount: number,
  alreadyGranted: readonly number[]
): ReferralMilestone[] {
  const granted = new Set(alreadyGranted);
  return REFERRAL_MILESTONES.filter((m) => qualifiedCount >= m.count && !granted.has(m.count));
}

/** Bir sonraki hedef (hepsi alındıysa null) — arayüzdeki ilerleme çubuğu bunu gösterir. */
export function nextMilestone(qualifiedCount: number): ReferralMilestone | null {
  return REFERRAL_MILESTONES.find((m) => qualifiedCount < m.count) ?? null;
}

/** Ödülün bitiş anı. Var olan bir ödül HENÜZ BİTMEDİYSE üstüne eklenir (kayıp yok). */
export function rewardExpiry(months: number, now: Date, currentExpiry: Date | null): Date {
  const base = currentExpiry && currentExpiry > now ? new Date(currentExpiry) : new Date(now);
  base.setMonth(base.getMonth() + months);
  return base;
}

/** Etkin (süresi dolmamış) ödül var mı? */
export function hasActiveReward(expiries: readonly Date[], now: Date): boolean {
  return expiries.some((e) => e > now);
}
