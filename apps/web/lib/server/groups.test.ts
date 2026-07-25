import { describe, it, expect } from 'vitest';
import {
  JOIN_CODE_ALPHABET,
  JOIN_CODE_LENGTH,
  MAX_GROUPS_JOINED,
  MAX_GROUPS_OWNED,
  MAX_GROUP_MEMBERS,
  canCreateGroup,
  canJoinGroup,
  challengeProgressValue,
  isChallengeActive,
  isChallengeMetric,
  makeJoinCode,
  normalizeJoinCode,
  orderSnapshotRows,
  shouldSnapshot,
  snapshotId,
  validateGroupName,
} from './groups';
import { previousWeekStart } from './community';

/** Belirlenimci sözde-rastgele üreteç — kod üretimini test edilebilir kılar. */
function seeded(seed: number): () => number {
  let s = seed;
  return () => {
    s = (s * 1664525 + 1013904223) % 4294967296;
    return s / 4294967296;
  };
}

describe('katılım kodu', () => {
  it('alfabede karışan karakter YOK (0/O/1/I/L)', () => {
    for (const ch of '0O1IL') expect(JOIN_CODE_ALPHABET).not.toContain(ch);
  });

  it('doğru uzunlukta ve yalnız alfabeden üretir', () => {
    const rand = seeded(42);
    for (let i = 0; i < 200; i++) {
      const code = makeJoinCode(rand);
      expect(code).toHaveLength(JOIN_CODE_LENGTH);
      for (const ch of code) expect(JOIN_CODE_ALPHABET).toContain(ch);
    }
  });

  it('aynı tohum aynı kodu verir (belirlenimci)', () => {
    expect(makeJoinCode(seeded(7))).toBe(makeJoinCode(seeded(7)));
  });

  it('normalleştirme: küçük harf, boşluk ve tire kabul edilir', () => {
    const code = makeJoinCode(seeded(3));
    const messy = `  ${code.slice(0, 3).toLowerCase()} - ${code.slice(3).toLowerCase()} `;
    expect(normalizeJoinCode(messy)).toBe(code);
  });

  it('KARIŞAN KARAKTER SESSİZCE EŞLENMEZ — geçersiz kod reddedilir', () => {
    // Alfabede ne 0 ne O var; "0" yazan kullanıcı BAŞKA bir gruba düşmemeli.
    expect(normalizeJoinCode('ABC0EF')).toBeNull();
    expect(normalizeJoinCode('ABC1EF')).toBeNull();
    expect(normalizeJoinCode('ABCLEF')).toBeNull();
    expect(normalizeJoinCode('ABCIEF')).toBeNull();
  });

  it('yanlış uzunluk ve tür reddedilir', () => {
    expect(normalizeJoinCode('ABC')).toBeNull();
    expect(normalizeJoinCode('ABCDEFG')).toBeNull();
    expect(normalizeJoinCode(null)).toBeNull();
    expect(normalizeJoinCode(42)).toBeNull();
  });
});

describe('grup adı', () => {
  it('boşlukları sadeleştirir', () => {
    const r = validateGroupName('  Sabah   Çalışma  ');
    expect(r).toEqual({ ok: true, value: 'Sabah Çalışma' });
  });

  it('kısa/uzun/geçersiz karakter reddedilir', () => {
    expect(validateGroupName('ab').ok).toBe(false);
    expect(validateGroupName('x'.repeat(41)).ok).toBe(false);
    expect(validateGroupName('grup <script>').ok).toBe(false);
    expect(validateGroupName(123).ok).toBe(false);
  });
});

describe('tavanlar — sınırsız büyüme yolu yok', () => {
  it('grup kurma tavanı', () => {
    expect(canCreateGroup(MAX_GROUPS_OWNED - 1).ok).toBe(true);
    expect(canCreateGroup(MAX_GROUPS_OWNED).ok).toBe(false);
  });

  it('katılma tavanı', () => {
    expect(canJoinGroup(MAX_GROUPS_JOINED - 1, 1, false).ok).toBe(true);
    expect(canJoinGroup(MAX_GROUPS_JOINED, 1, false).ok).toBe(false);
  });

  it('grup mevcudu tavanı', () => {
    expect(canJoinGroup(0, MAX_GROUP_MEMBERS - 1, false).ok).toBe(true);
    expect(canJoinGroup(0, MAX_GROUP_MEMBERS, false).ok).toBe(false);
  });

  it('zaten üye olan tekrar katılamaz', () => {
    expect(canJoinGroup(0, 1, true).ok).toBe(false);
  });
});

describe('meydan okuma', () => {
  const c = {
    metric: 'xp',
    target: 500,
    startsAt: new Date('2026-07-20T00:00:00Z'),
    endsAt: new Date('2026-07-27T00:00:00Z'),
  };

  it('etkinlik penceresi [başlangıç, bitiş)', () => {
    expect(isChallengeActive(c, new Date('2026-07-19T23:59:59Z'))).toBe(false);
    expect(isChallengeActive(c, new Date('2026-07-20T00:00:00Z'))).toBe(true);
    expect(isChallengeActive(c, new Date('2026-07-26T23:59:59Z'))).toBe(true);
    expect(isChallengeActive(c, new Date('2026-07-27T00:00:00Z'))).toBe(false);
  });

  it('ilerleme TABANDAN hesaplanır — geçmiş XP meydan okumayı bitirmez', () => {
    // Kullanıcı 10.000 XP ile katıldı; taban 10.000. Henüz hiç ilerleme yok.
    expect(challengeProgressValue(10_000, 10_000, 500)).toEqual({
      value: 0,
      percent: 0,
      done: false,
    });
    expect(challengeProgressValue(10_250, 10_000, 500).percent).toBe(50);
    expect(challengeProgressValue(10_500, 10_000, 500).done).toBe(true);
  });

  it('ilerleme hedefi aşmaz ve negatife düşmez', () => {
    expect(challengeProgressValue(99_999, 10_000, 500).value).toBe(500);
    // Sayaç geri gitse bile (olmamalı) ilerleme negatif olamaz.
    expect(challengeProgressValue(9_000, 10_000, 500).value).toBe(0);
  });

  it('geçerli ölçütler', () => {
    for (const m of ['xp', 'answered', 'lessons', 'exams']) expect(isChallengeMetric(m)).toBe(true);
    expect(isChallengeMetric('streak')).toBe(false);
    expect(isChallengeMetric(null)).toBe(false);
  });
});

describe('haftalık anlık görüntü — BELİRLENİMCİ', () => {
  it('kimlik hafta:sınıf', () => {
    expect(snapshotId('2026-07-20', 'b')).toBe('2026-07-20:b');
  });

  it('eşit XP durumunda userId ile kararlı sıralama', () => {
    const rows = [
      { userId: 'u-c', displayName: 'C', avatarId: 'owl-wave', xp: 100 },
      { userId: 'u-a', displayName: 'A', avatarId: 'owl-wave', xp: 100 },
      { userId: 'u-b', displayName: 'B', avatarId: 'owl-wave', xp: 300 },
    ];
    const once = orderSnapshotRows(rows).map((r) => r.userId);
    const twice = orderSnapshotRows([...rows].reverse()).map((r) => r.userId);
    expect(once).toEqual(['u-b', 'u-a', 'u-c']);
    // Girdi sırası ne olursa olsun AYNI çıktı → aynı hafta iki kez alınan görüntü aynıdır.
    expect(twice).toEqual(once);
  });

  it('girdi dizisini değiştirmez', () => {
    const rows = [
      { userId: 'u-b', displayName: 'B', avatarId: 'owl-wave', xp: 1 },
      { userId: 'u-a', displayName: 'A', avatarId: 'owl-wave', xp: 2 },
    ];
    orderSnapshotRows(rows);
    expect(rows[0]!.userId).toBe('u-b');
  });

  it('devir yalnız GEÇMİŞ hafta için ve yalnız bir kez', () => {
    expect(shouldSnapshot('2026-07-13', '2026-07-20', false)).toBe(true);
    // Zaten alınmışsa tekrar alınmaz (etkisiz-tekrarlı).
    expect(shouldSnapshot('2026-07-13', '2026-07-20', true)).toBe(false);
    // İçinde bulunulan hafta dondurulmaz.
    expect(shouldSnapshot('2026-07-20', '2026-07-20', false)).toBe(false);
  });
});

describe('önceki hafta başlangıcı (E10 devri)', () => {
  it('normal hafta', () => {
    expect(previousWeekStart('2026-07-20')).toBe('2026-07-13');
  });

  it('AY sınırını doğru geçer', () => {
    expect(previousWeekStart('2026-07-06')).toBe('2026-06-29');
    expect(previousWeekStart('2026-03-02')).toBe('2026-02-23');
  });

  it('YIL sınırını doğru geçer', () => {
    expect(previousWeekStart('2026-01-05')).toBe('2025-12-29');
  });

  it('artık yıl şubatını doğru geçer', () => {
    // 2028 artık yıl: 29 Şubat var.
    expect(previousWeekStart('2028-03-06')).toBe('2028-02-28');
  });

  it('sonuç her zaman geçerli bir hafta başlangıcı biçimindedir', () => {
    expect(previousWeekStart('2026-07-20')).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
});
