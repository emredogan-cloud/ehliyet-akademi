/**
 * Topluluk platformu — saf sunucu mantığı (Evolution Faz E8).
 *
 * NOT: `apps/web/lib/community.ts` AYRI bir şeydir (web'in tek-oyunculu XP kademeleri, günlük
 * meydan okuma, davet bağlantısı) ve DEĞİŞMEZ. Bu dosya, mobilin çok-kullanıcılı topluluk
 * uçlarının kurallarını taşır: anti-hile sınırlama, hafta sınırı, sıralama, doğrulama.
 *
 * Burada veritabanı YOKTUR: hepsi saf fonksiyondur, böylece kurallar doğrudan test edilir ve uç
 * noktalar yalnız "oku → uygula → yaz" işini yapar.
 */

export const LICENCES = ['b', 'a', 'd'] as const;
export type Licence = (typeof LICENCES)[number];

export const VISIBILITIES = ['private', 'public'] as const;
export type Visibility = (typeof VISIBILITIES)[number];

/** Kullanıcı fotoğrafı YOKTUR — avatar, uygulamayla gelen sabit varlıklardan seçilir. */
export const AVATAR_IDS = [
  'owl-wave',
  'owl-reading',
  'owl-teacher',
  'owl-wheel',
  'owl-clipboard',
  'owl-shield',
] as const;
export type AvatarId = (typeof AVATAR_IDS)[number];

export const REPORT_REASONS = ['isim', 'avatar', 'taciz', 'spam', 'diger'] as const;
export type ReportReason = (typeof REPORT_REASONS)[number];

export function isLicence(v: unknown): v is Licence {
  return typeof v === 'string' && (LICENCES as readonly string[]).includes(v);
}
export function isAvatarId(v: unknown): v is AvatarId {
  return typeof v === 'string' && (AVATAR_IDS as readonly string[]).includes(v);
}
export function isVisibility(v: unknown): v is Visibility {
  return typeof v === 'string' && (VISIBILITIES as readonly string[]).includes(v);
}
export function isReportReason(v: unknown): v is ReportReason {
  return typeof v === 'string' && (REPORT_REASONS as readonly string[]).includes(v);
}

// ─────────────────────────────────────────────────────────────────────────────
// Görünen ad
// ─────────────────────────────────────────────────────────────────────────────

export const DISPLAY_NAME_MIN = 3;
export const DISPLAY_NAME_MAX = 20;

/**
 * Görünen ad, gerçek ad olmak ZORUNDA DEĞİLDİR (gizlilik). E-posta benzeri girişler reddedilir ki
 * kullanıcı yanlışlıkla kimliğini ifşa etmesin.
 */
export function validateDisplayName(
  raw: unknown
): { ok: true; value: string } | { ok: false; error: string } {
  if (typeof raw !== 'string') return { ok: false, error: 'Görünen ad gerekli.' };
  const value = raw.trim().replace(/\s+/g, ' ');
  if (value.length < DISPLAY_NAME_MIN) {
    return { ok: false, error: `Görünen ad en az ${DISPLAY_NAME_MIN} karakter olmalı.` };
  }
  if (value.length > DISPLAY_NAME_MAX) {
    return { ok: false, error: `Görünen ad en fazla ${DISPLAY_NAME_MAX} karakter olabilir.` };
  }
  if (value.includes('@')) return { ok: false, error: 'Görünen ad e-posta olamaz.' };
  if (!/^[\p{L}\p{N} _-]+$/u.test(value)) {
    return { ok: false, error: 'Görünen ad yalnız harf, rakam, boşluk, _ ve - içerebilir.' };
  }
  return { ok: true, value };
}

// ─────────────────────────────────────────────────────────────────────────────
// Anti-hile: istemci sayaçlarının sunucuda sınırlanması
// ─────────────────────────────────────────────────────────────────────────────

/** Bir bildirim penceresinde kabul edilen en çok XP artışı. */
export const MAX_XP_DELTA_PER_WINDOW = 2000;
/** İki bildirim arasında beklenen en kısa süre (ms); daha sık gelirse artış uygulanmaz. */
export const SUBMIT_WINDOW_MS = 60_000;
export const MAX_ANSWERED_DELTA_PER_WINDOW = 300;
export const MAX_LESSONS_DELTA_PER_WINDOW = 30;
export const MAX_EXAMS_DELTA_PER_WINDOW = 20;
/** Seri için makul üst sınır (10 yıl) — bozuk istemci verisine karşı. */
export const MAX_STREAK = 3650;

export type StatCounters = {
  xp: number;
  streak: number;
  lessons: number;
  exams: number;
  answered: number;
  accuracy: number;
};

export type ClampResult = {
  next: StatCounters;
  /** İstemcinin istediği artış kısıldı mı (denetim için). */
  clamped: boolean;
  /** Geri giden (azalan) bir sayaç bildirildi mi. */
  regressed: boolean;
};

function intOrUndefined(value: unknown): number | undefined {
  if (typeof value !== 'number' || !Number.isFinite(value)) return undefined;
  const n = Math.floor(value);
  return n < 0 ? 0 : n;
}

/**
 * Gövdede BULUNMAYAN alan `undefined` kalır — "0 bildirildi" ile "hiç bildirilmedi" ayrılır.
 *
 * NEDEN: kısmi bir gövde (`{xp: 100}`) doğruluk/seri gibi TÜRETİLMİŞ alanları sıfırlamamalıdır.
 * Üretimde ölçüldü: alan atlandığında değer 0'a düşüyordu. Mobil istemci her zaman tam gövde
 * gönderir ama uç herkese açıktır; eksik alan artık mevcut değeri korur.
 */
export type IncomingCounters = { [K in keyof StatCounters]?: number };

export function parseCounters(body: unknown): IncomingCounters {
  const b = (body ?? {}) as Record<string, unknown>;
  const accuracy = intOrUndefined(b.accuracy);
  return {
    xp: intOrUndefined(b.xp),
    streak: intOrUndefined(b.streak),
    lessons: intOrUndefined(b.lessons),
    exams: intOrUndefined(b.exams),
    answered: intOrUndefined(b.answered),
    accuracy: accuracy === undefined ? undefined : Math.min(100, accuracy),
  };
}

/**
 * Anti-hile çekirdeği:
 *
 * 1. **Geri gitme yok** — bildirilen sayaç mevcuttan küçükse mevcut korunur. (Cihaz değişimi veya
 *    kısmi senkron gerçek bir senaryodur; ilerlemeyi silmek yerine yok sayarız.)
 * 2. **Pencere başına tavan** — tek bildirimde XP/cevap/ders/sınav artışı sabit tavanı aşamaz.
 * 3. **Çok sık bildirim** — son yazmadan bu yana [SUBMIT_WINDOW_MS] geçmediyse artış UYGULANMAZ;
 *    yalnız türetilmiş alanlar (seri, doğruluk) tazelenir. Böylece döngüyle XP şişirilemez.
 *
 * Çağıran taraf `submittedXp`'yi ayrıca saklar: kabul edilen ile bildirilen arasındaki fark,
 * sonradan incelenebilir bir denetim izi bırakır.
 */
export function clampStats(args: {
  current: StatCounters | null;
  incoming: IncomingCounters;
  msSinceLastSubmit: number | null;
}): ClampResult {
  const { current } = args;
  // Bildirilmeyen alan mevcut değerini (yoksa 0) korur.
  const base: StatCounters = current ?? {
    xp: 0,
    streak: 0,
    lessons: 0,
    exams: 0,
    answered: 0,
    accuracy: 0,
  };
  const incoming: StatCounters = {
    xp: args.incoming.xp ?? base.xp,
    streak: args.incoming.streak ?? base.streak,
    lessons: args.incoming.lessons ?? base.lessons,
    exams: args.incoming.exams ?? base.exams,
    answered: args.incoming.answered ?? base.answered,
    accuracy: args.incoming.accuracy ?? base.accuracy,
  };

  if (!current) {
    // İlk bildirimde de tavanlar geçerlidir: sıfırdan devasa değerle başlanamaz.
    const next: StatCounters = {
      xp: Math.min(incoming.xp, MAX_XP_DELTA_PER_WINDOW),
      streak: Math.min(incoming.streak, MAX_STREAK),
      lessons: Math.min(incoming.lessons, MAX_LESSONS_DELTA_PER_WINDOW),
      exams: Math.min(incoming.exams, MAX_EXAMS_DELTA_PER_WINDOW),
      answered: Math.min(incoming.answered, MAX_ANSWERED_DELTA_PER_WINDOW),
      accuracy: incoming.accuracy,
    };
    const clamped =
      next.xp !== incoming.xp ||
      next.lessons !== incoming.lessons ||
      next.exams !== incoming.exams ||
      next.answered !== incoming.answered;
    return { next, clamped, regressed: false };
  }

  const regressed =
    incoming.xp < current.xp ||
    incoming.answered < current.answered ||
    incoming.lessons < current.lessons ||
    incoming.exams < current.exams;

  const tooSoon = args.msSinceLastSubmit !== null && args.msSinceLastSubmit < SUBMIT_WINDOW_MS;

  const grow = (cur: number, inc: number, cap: number): { v: number; clamped: boolean } => {
    if (inc <= cur) return { v: cur, clamped: false }; // geri gitme yok
    if (tooSoon) return { v: cur, clamped: true }; // pencere dolmadan artış yok
    const delta = Math.min(inc - cur, cap);
    return { v: cur + delta, clamped: cur + delta !== inc };
  };

  const xp = grow(current.xp, incoming.xp, MAX_XP_DELTA_PER_WINDOW);
  const answered = grow(current.answered, incoming.answered, MAX_ANSWERED_DELTA_PER_WINDOW);
  const lessons = grow(current.lessons, incoming.lessons, MAX_LESSONS_DELTA_PER_WINDOW);
  const exams = grow(current.exams, incoming.exams, MAX_EXAMS_DELTA_PER_WINDOW);

  return {
    next: {
      xp: xp.v,
      answered: answered.v,
      lessons: lessons.v,
      exams: exams.v,
      streak: Math.min(incoming.streak, MAX_STREAK),
      accuracy: Math.min(100, Math.max(0, incoming.accuracy)),
    },
    clamped: xp.clamped || answered.clamped || lessons.clamped || exams.clamped,
    regressed,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Hafta sınırı — Europe/Istanbul (bildirimlerdeki kararla aynı)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Türkiye 2016'dan beri yıl boyunca UTC+3'tür (yaz saati uygulanmaz) → sabit ofset doğrudur ve
 * saat dilimi veritabanına bağımlılık gerekmeden deterministik/test edilebilir kalır.
 */
export const ISTANBUL_OFFSET_MS = 3 * 60 * 60 * 1000;

/** Verilen anın Europe/Istanbul'daki hafta başlangıcı (pazartesi), `YYYY-MM-DD`. */
export function weekStartIstanbul(nowMs: number): string {
  const local = new Date(nowMs + ISTANBUL_OFFSET_MS);
  const dow = (local.getUTCDay() + 6) % 7; // pazartesi = 0
  const monday = new Date(local.getTime() - dow * 24 * 60 * 60 * 1000);
  const y = monday.getUTCFullYear();
  const m = String(monday.getUTCMonth() + 1).padStart(2, '0');
  const d = String(monday.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sıralama
// ─────────────────────────────────────────────────────────────────────────────

export type LeaderboardRow = {
  userId: string;
  displayName: string;
  avatarId: string;
  licence: string;
  xp: number;
  streak: number;
};

export type RankedRow = LeaderboardRow & { rank: number };

/**
 * XP azalan; eşitlikte seri, sonra görünen ad (deterministik). Eşit XP AYNI sırayı alır
 * (standart rekabet sıralaması: 1, 2, 2, 4).
 */
export function rankRows(rows: LeaderboardRow[]): RankedRow[] {
  const sorted = [...rows].sort(
    (a, b) => b.xp - a.xp || b.streak - a.streak || a.displayName.localeCompare(b.displayName, 'tr')
  );
  const out: RankedRow[] = [];
  let lastXp: number | null = null;
  let lastRank = 0;
  sorted.forEach((row, i) => {
    const rank = lastXp !== null && row.xp === lastXp ? lastRank : i + 1;
    out.push({ ...row, rank });
    lastXp = row.xp;
    lastRank = rank;
  });
  return out;
}

/** Sayfalama sınırları — istemci ne isterse istesin sunucu bunları uygular. */
export const PAGE_SIZE_DEFAULT = 25;
export const PAGE_SIZE_MAX = 50;

export function parsePageSize(raw: string | null): number {
  const n = Number(raw);
  if (!Number.isFinite(n) || n <= 0) return PAGE_SIZE_DEFAULT;
  return Math.min(Math.floor(n), PAGE_SIZE_MAX);
}
