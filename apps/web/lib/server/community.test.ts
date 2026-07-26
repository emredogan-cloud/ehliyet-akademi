/**
 * Topluluk saf mantığı — anti-hile, hafta sınırı, sıralama, doğrulama (Evolution Faz E8).
 */
import { describe, it, expect } from 'vitest';
import {
  clampStats,
  parseCounters,
  rankRows,
  validateDisplayName,
  weekStartIstanbul,
  parsePageSize,
  isAvatarId,
  isLicence,
  isReportReason,
  isVisibility,
  MAX_XP_DELTA_PER_WINDOW,
  SUBMIT_WINDOW_MS,
  PAGE_SIZE_MAX,
} from './community';

const zero = { xp: 0, streak: 0, lessons: 0, exams: 0, answered: 0, accuracy: 0 };

describe('görünen ad doğrulama', () => {
  it('geçerli adı normalleştirir', () => {
    const r = validateDisplayName('  Ayşe   K_1 ');
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.value).toBe('Ayşe K_1');
  });

  it('çok kısa/uzun adı reddeder', () => {
    expect(validateDisplayName('ab').ok).toBe(false);
    expect(validateDisplayName('a'.repeat(21)).ok).toBe(false);
  });

  it('e-postayı reddeder (kimlik ifşasını önler)', () => {
    expect(validateDisplayName('kisi@ornek.com').ok).toBe(false);
  });

  it('yasak karakterleri reddeder', () => {
    expect(validateDisplayName('kötü<script>').ok).toBe(false);
    expect(validateDisplayName('ad/soyad').ok).toBe(false);
  });

  it('metin olmayan girişi reddeder', () => {
    expect(validateDisplayName(42).ok).toBe(false);
    expect(validateDisplayName(null).ok).toBe(false);
  });
});

describe('sayaç ayrıştırma', () => {
  it('negatif ve kesirli değerleri güvene alır', () => {
    const c = parseCounters({ xp: -5, streak: 2.7, accuracy: 250 });
    expect(c.xp).toBe(0);
    expect(c.streak).toBe(2);
    expect(c.accuracy).toBe(100);
  });

  it('BULUNMAYAN veya bozuk alan `undefined` kalır (0 bildirimi ile karışmaz)', () => {
    const c = parseCounters({ xp: 10, answered: 'x' });
    expect(c.xp).toBe(10);
    expect(c.answered).toBeUndefined();
    expect(c.accuracy).toBeUndefined();
    expect(c.streak).toBeUndefined();
  });
});

describe('kısmi gövde mevcut değerleri KORUR', () => {
  it('bildirilmeyen türetilmiş alan sıfırlanmaz (üretimde ölçülen hata)', () => {
    const current = { xp: 500, streak: 7, lessons: 3, exams: 2, answered: 120, accuracy: 88 };
    const r = clampStats({
      current,
      incoming: parseCounters({ xp: 600 }),
      msSinceLastSubmit: SUBMIT_WINDOW_MS + 1,
    });
    expect(r.next.xp).toBe(600);
    expect(r.next.accuracy).toBe(88); // sıfırlanmadı
    expect(r.next.streak).toBe(7);
    expect(r.next.answered).toBe(120);
    expect(r.regressed).toBe(false); // eksik alan "geri gitme" sayılmaz
  });

  it('boş gövde hiçbir şeyi değiştirmez', () => {
    const current = { xp: 500, streak: 7, lessons: 3, exams: 2, answered: 120, accuracy: 88 };
    const r = clampStats({
      current,
      incoming: parseCounters({}),
      msSinceLastSubmit: SUBMIT_WINDOW_MS + 1,
    });
    expect(r.next).toEqual(current);
    expect(r.regressed).toBe(false);
    expect(r.clamped).toBe(false);
  });

  it('AÇIKÇA 0 bildirmek hâlâ geri gitme sayılır', () => {
    const current = { xp: 500, streak: 7, lessons: 3, exams: 2, answered: 120, accuracy: 88 };
    const r = clampStats({
      current,
      incoming: parseCounters({ xp: 0 }),
      msSinceLastSubmit: SUBMIT_WINDOW_MS + 1,
    });
    expect(r.next.xp).toBe(500);
    expect(r.regressed).toBe(true);
  });
});

describe('anti-hile sınırlama', () => {
  it('ilk bildirimde bile tavan uygulanır', () => {
    const r = clampStats({
      current: null,
      incoming: { ...zero, xp: 999_999, answered: 10_000 },
      msSinceLastSubmit: null,
    });
    expect(r.next.xp).toBe(MAX_XP_DELTA_PER_WINDOW);
    expect(r.clamped).toBe(true);
  });

  it('normal artışı olduğu gibi kabul eder', () => {
    const r = clampStats({
      current: { ...zero, xp: 100, answered: 10 },
      incoming: { ...zero, xp: 250, answered: 30, accuracy: 80 },
      msSinceLastSubmit: SUBMIT_WINDOW_MS + 1,
    });
    expect(r.next.xp).toBe(250);
    expect(r.next.answered).toBe(30);
    expect(r.next.accuracy).toBe(80);
    expect(r.clamped).toBe(false);
    expect(r.regressed).toBe(false);
  });

  it('tek bildirimde tavanı aşan artışı KISAR', () => {
    const r = clampStats({
      current: { ...zero, xp: 100 },
      incoming: { ...zero, xp: 100 + MAX_XP_DELTA_PER_WINDOW * 3 },
      msSinceLastSubmit: SUBMIT_WINDOW_MS + 1,
    });
    expect(r.next.xp).toBe(100 + MAX_XP_DELTA_PER_WINDOW);
    expect(r.clamped).toBe(true);
  });

  it('geri giden sayacı YOK SAYAR (mevcut korunur) ve işaretler', () => {
    const r = clampStats({
      current: { ...zero, xp: 500, answered: 100, lessons: 5, exams: 2 },
      incoming: { ...zero, xp: 10, answered: 1, lessons: 0, exams: 0 },
      msSinceLastSubmit: SUBMIT_WINDOW_MS + 1,
    });
    expect(r.next.xp).toBe(500);
    expect(r.next.answered).toBe(100);
    expect(r.next.lessons).toBe(5);
    expect(r.regressed).toBe(true);
  });

  it('pencere dolmadan gelen bildirimde ARTIŞ UYGULANMAZ (döngüyle şişirme engeli)', () => {
    const r = clampStats({
      current: { ...zero, xp: 500 },
      incoming: { ...zero, xp: 900, streak: 7, accuracy: 90 },
      msSinceLastSubmit: 1_000,
    });
    expect(r.next.xp).toBe(500);
    expect(r.clamped).toBe(true);
    // Türetilmiş alanlar yine tazelenir.
    expect(r.next.streak).toBe(7);
    expect(r.next.accuracy).toBe(90);
  });

  it('seri ve doğruluk makul aralığa çekilir', () => {
    const r = clampStats({
      current: { ...zero },
      incoming: { ...zero, streak: 999_999, accuracy: 100 },
      msSinceLastSubmit: SUBMIT_WINDOW_MS + 1,
    });
    expect(r.next.streak).toBeLessThanOrEqual(3650);
    expect(r.next.accuracy).toBe(100);
  });
});

describe('hafta sınırı (Europe/Istanbul)', () => {
  it('pazartesi başlangıcını verir', () => {
    // 2026-07-25 Cumartesi 09:00Z → İstanbul 12:00, o haftanın pazartesi 2026-07-20
    expect(weekStartIstanbul(Date.parse('2026-07-25T09:00:00Z'))).toBe('2026-07-20');
  });

  it('pazartesi gününde kendi tarihini verir', () => {
    expect(weekStartIstanbul(Date.parse('2026-07-20T10:00:00Z'))).toBe('2026-07-20');
  });

  it('pazar gecesi hâlâ önceki pazartesiye aittir', () => {
    expect(weekStartIstanbul(Date.parse('2026-07-26T20:00:00Z'))).toBe('2026-07-20');
  });

  it('UTC pazar 22:00 İstanbul’da PAZARTESİ’dir → yeni hafta', () => {
    // 2026-07-26T22:00Z = İstanbul 2026-07-27T01:00 (pazartesi)
    expect(weekStartIstanbul(Date.parse('2026-07-26T22:00:00Z'))).toBe('2026-07-27');
  });

  it('deterministiktir', () => {
    const t = Date.parse('2026-01-01T00:00:00Z');
    expect(weekStartIstanbul(t)).toBe(weekStartIstanbul(t));
  });
});

describe('sıralama', () => {
  const row = (id: string, xp: number, streak = 0, name = id) => ({
    userId: id,
    displayName: name,
    avatarId: 'owl-wave',
    // Beta Faz 7: sıralama satırları artık yüklenmiş fotoğrafı da taşıyor. Sıralama mantığı
    // fotoğrafa BAKMAZ; burada yalnız tip bütünlüğü için null verilir.
    avatarUrl: null,
    licence: 'b',
    xp,
    streak,
  });

  it('XP azalan sırada dizer', () => {
    const r = rankRows([row('a', 10), row('b', 30), row('c', 20)]);
    expect(r.map((x) => x.userId)).toEqual(['b', 'c', 'a']);
    expect(r.map((x) => x.rank)).toEqual([1, 2, 3]);
  });

  it('eşit XP aynı sırayı alır (1,2,2,4)', () => {
    const r = rankRows([row('a', 50), row('b', 30), row('c', 30), row('d', 10)]);
    expect(r.map((x) => x.rank)).toEqual([1, 2, 2, 4]);
  });

  it('eşitlikte seri, sonra ad ile deterministik çözülür', () => {
    const r = rankRows([row('x', 30, 1, 'Zeynep'), row('y', 30, 5, 'Ali')]);
    expect(r[0]!.userId).toBe('y'); // daha uzun seri önce
    const same = rankRows([row('x', 30, 2, 'Zeynep'), row('y', 30, 2, 'Ali')]);
    expect(same[0]!.displayName).toBe('Ali'); // ad ile deterministik
  });

  it('girdiyi değiştirmez', () => {
    const input = [row('a', 10), row('b', 30)];
    rankRows(input);
    expect(input.map((x) => x.userId)).toEqual(['a', 'b']);
  });
});

describe('sayfalama ve alan doğrulama', () => {
  it('sayfa boyutu sunucu sınırlarına çekilir', () => {
    expect(parsePageSize(null)).toBeGreaterThan(0);
    expect(parsePageSize('9999')).toBe(PAGE_SIZE_MAX);
    expect(parsePageSize('-3')).toBeGreaterThan(0);
    expect(parsePageSize('abc')).toBeGreaterThan(0);
    expect(parsePageSize('10')).toBe(10);
  });

  it('sabit alan kümeleri korunur', () => {
    expect(isLicence('b')).toBe(true);
    expect(isLicence('c')).toBe(false);
    expect(isAvatarId('owl-wave')).toBe(true);
    expect(isAvatarId('../../etc/passwd')).toBe(false);
    expect(isVisibility('public')).toBe(true);
    expect(isVisibility('herkese')).toBe(false);
    expect(isReportReason('taciz')).toBe(true);
    expect(isReportReason('hack')).toBe(false);
  });
});
