/**
 * Faz 8 — davet sisteminin SAF kural katmanı.
 */
import { describe, it, expect } from 'vitest';
import {
  REFERRAL_ALPHABET,
  REFERRAL_CODE_LENGTH,
  REFERRAL_MAX_PER_IP,
  REFERRAL_MILESTONES,
  evaluateReferral,
  generateReferralCode,
  hasActiveReward,
  isValidReferralCodeFormat,
  nextMilestone,
  normalizeReferralCode,
  pendingMilestones,
  rewardExpiry,
} from './referrals';

describe('kod biçimi', () => {
  it('alfabede karıştırılabilir harf YOKTUR (0/O, 1/I/L)', () => {
    for (const ch of ['0', '1', 'I', 'L', 'O']) {
      expect(REFERRAL_ALPHABET.includes(ch)).toBe(false);
    }
  });

  it('normalleştirme: büyük harf, boşluk/tire atılır, kırpılır', () => {
    expect(normalizeReferralCode(' ab-cd ef gh ')).toBe('ABCDEFGH');
    expect(normalizeReferralCode('abcdefghIJK')).toBe('ABCDEFGH');
  });

  /// Kullanıcı `O` yerine `0`, `I` yerine `1` yazarsa kabul edilir — alfabede o rakamlar yok,
  /// yani niyet açık.
  it('sık yapılan okuma hataları düzeltilir', () => {
    expect(normalizeReferralCode('AB0DEF1H')).toBe('ABODEFIH');
  });

  it('geçerlilik: uzunluk ve alfabe', () => {
    expect(isValidReferralCodeFormat('ABCDEFGH')).toBe(true);
    expect(isValidReferralCodeFormat('ABCDEFG')).toBe(false); // kısa
    expect(isValidReferralCodeFormat('ABCDEFG0')).toBe(false); // alfabe dışı
  });

  it('üretilen kod her zaman geçerlidir', () => {
    let i = 0;
    const code = generateReferralCode((max) => (i++ * 7) % max);
    expect(code).toHaveLength(REFERRAL_CODE_LENGTH);
    expect(isValidReferralCodeFormat(code)).toBe(true);
  });
});

describe('davet kabul kuralı', () => {
  const base = {
    code: 'ABCDEFGH',
    referrerUserId: 'u-referrer',
    referredUserId: 'u-new',
    alreadyReferred: false,
    sameIpCount: 0,
  };

  it('temiz durumda kabul eder', () => {
    expect(evaluateReferral(base)).toEqual({ ok: true });
  });

  it('KENDİNİ davet etmek reddedilir', () => {
    const r = evaluateReferral({ ...base, referredUserId: 'u-referrer' });
    expect(r).toEqual({ ok: false, reason: 'self' });
  });

  it('bilinmeyen kod reddedilir', () => {
    expect(evaluateReferral({ ...base, referrerUserId: null })).toEqual({
      ok: false,
      reason: 'unknown-code',
    });
  });

  it('bozuk biçim reddedilir (kod aramaya bile gidilmez)', () => {
    expect(evaluateReferral({ ...base, code: 'kısa' })).toEqual({
      ok: false,
      reason: 'bad-format',
    });
  });

  it('bir kullanıcı İKİ KEZ davet edilemez', () => {
    expect(evaluateReferral({ ...base, alreadyReferred: true })).toEqual({
      ok: false,
      reason: 'already-referred',
    });
  });

  /// Sıfır tolerans DOĞRU DEĞİL: aynı evden iki kardeş gerçek davettir. Sınıra kadar kabul,
  /// sınırda ret.
  it('aynı IP sınırına kadar kabul, sınırda ret', () => {
    expect(evaluateReferral({ ...base, sameIpCount: REFERRAL_MAX_PER_IP - 1 })).toEqual({
      ok: true,
    });
    expect(evaluateReferral({ ...base, sameIpCount: REFERRAL_MAX_PER_IP })).toEqual({
      ok: false,
      reason: 'ip-limit',
    });
  });
});

describe('ödül merdiveni', () => {
  it('beşinci davette ilk ödül gelir', () => {
    expect(pendingMilestones(4, [])).toEqual([]);
    expect(pendingMilestones(5, [])).toEqual([{ count: 5, months: 1 }]);
  });

  it('aynı basamak iki kez ödüllendirilmez', () => {
    expect(pendingMilestones(7, [5])).toEqual([]);
  });

  /// Geriye dönük: sisteme sonradan bakan bir kullanıcı hak ettiği TÜM basamakları alır.
  it('atlanmış basamaklar toplu verilir', () => {
    expect(pendingMilestones(12, [])).toEqual([
      { count: 5, months: 1 },
      { count: 10, months: 2 },
    ]);
  });

  it('sonraki hedef doğru; hepsi alınınca null', () => {
    expect(nextMilestone(0)?.count).toBe(5);
    expect(nextMilestone(5)?.count).toBe(10);
    const last = REFERRAL_MILESTONES[REFERRAL_MILESTONES.length - 1]!;
    expect(nextMilestone(last.count)).toBeNull();
  });
});

describe('ödül süresi', () => {
  const now = new Date('2026-07-29T12:00:00Z');

  it('ödülü olmayan kullanıcıda şimdiden başlar', () => {
    expect(rewardExpiry(1, now, null).toISOString()).toBe('2026-08-29T12:00:00.000Z');
  });

  /// Hâlâ etkin bir ödülü olan kullanıcı yeni ödülle süre KAYBETMEZ — üstüne eklenir.
  it('etkin ödülün ÜSTÜNE eklenir', () => {
    const current = new Date('2026-09-01T12:00:00Z');
    expect(rewardExpiry(2, now, current).toISOString()).toBe('2026-11-01T12:00:00.000Z');
  });

  it('süresi dolmuş ödül üstüne eklenmez, şimdiden başlar', () => {
    const expired = new Date('2026-01-01T12:00:00Z');
    expect(rewardExpiry(1, now, expired).toISOString()).toBe('2026-08-29T12:00:00.000Z');
  });

  it('etkin ödül tespiti', () => {
    expect(hasActiveReward([new Date('2026-08-01T00:00:00Z')], now)).toBe(true);
    expect(hasActiveReward([new Date('2026-01-01T00:00:00Z')], now)).toBe(false);
    expect(hasActiveReward([], now)).toBe(false);
  });
});
