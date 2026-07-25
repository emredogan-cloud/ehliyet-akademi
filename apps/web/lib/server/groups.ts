/**
 * Çalışma grupları + meydan okumalar — SAF mantık (Evolution Faz E10).
 *
 * Bu dosyada veritabanı YOKTUR. Tavanlar, kod üretimi/normalleştirme, meydan okuma ilerlemesi ve
 * haftalık anlık görüntünün BELİRLENİMCİ sıralaması burada yaşar; böylece hepsi doğrudan test edilir.
 *
 * İKİ İLKE:
 *  1. **Sınırsız büyüme yolu yok.** Grup kurma / katılma / mevcut tavanları burada tanımlıdır ve
 *     uçlar bunları çağırmak zorundadır.
 *  2. **Meydan okuma ilerlemesi türetilir, bildirilmez.** İstemci "ilerledim" diyemez; ilerleme
 *     E8'de kırpılmış `community_stats` sayaçlarından hesaplanır → ayrı bir hile yüzeyi doğmaz.
 */

// ── Tavanlar ────────────────────────────────────────────────────────────────
export const MAX_GROUPS_OWNED = 3;
export const MAX_GROUPS_JOINED = 10;
export const MAX_GROUP_MEMBERS = 50;
export const GROUP_NAME_MIN = 3;
export const GROUP_NAME_MAX = 40;

/**
 * Katılım kodu alfabesi. Karışabilen karakterler (0/O, 1/I/L) BİLEREK yoktur — kod telefonda
 * sesli okunup elle yazılacak.
 */
export const JOIN_CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
export const JOIN_CODE_LENGTH = 6;

/**
 * Verilen rastgelelik kaynağından katılım kodu üretir. `rand` 0..1 aralığında değer döndürmelidir
 * (üretimde `Math.random`, testte belirlenimci bir üreteç) → fonksiyon SAF ve test edilebilir kalır.
 */
export function makeJoinCode(rand: () => number): string {
  let out = '';
  for (let i = 0; i < JOIN_CODE_LENGTH; i++) {
    const idx = Math.floor(rand() * JOIN_CODE_ALPHABET.length) % JOIN_CODE_ALPHABET.length;
    out += JOIN_CODE_ALPHABET[idx];
  }
  return out;
}

/**
 * Kullanıcının yazdığı kodu normalleştirir: büyük harf yapar, boşluk ve tireleri atar, sonra
 * alfabeye göre doğrular. Geçersizse `null`.
 *
 * KARIŞAN KARAKTER EŞLEMESİ BİLEREK YOKTUR. Alfabe her karışan çiftin **iki tarafını birden**
 * dışarıda bırakıyor (`0` ve `O`, `1` ve `I` ve `L`) → belirsizliği çözecek bir hedef harf yok.
 * `0`'ı `O`'ya, oradan başka bir harfe eşlemek yazım hatasını sessizce BAŞKA bir gruba
 * çevirirdi; bu yüzden geçersiz karakter reddedilir ve kullanıcı açık hata görür.
 */
export function normalizeJoinCode(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const cleaned = raw.toUpperCase().replace(/[\s-]/g, '');
  if (cleaned.length !== JOIN_CODE_LENGTH) return null;
  for (const ch of cleaned) if (!JOIN_CODE_ALPHABET.includes(ch)) return null;
  return cleaned;
}

export function validateGroupName(
  raw: unknown
): { ok: true; value: string } | { ok: false; error: string } {
  if (typeof raw !== 'string') return { ok: false, error: 'Grup adı gerekli.' };
  const value = raw.trim().replace(/\s+/g, ' ');
  if (value.length < GROUP_NAME_MIN) {
    return { ok: false, error: `Grup adı en az ${GROUP_NAME_MIN} karakter olmalı.` };
  }
  if (value.length > GROUP_NAME_MAX) {
    return { ok: false, error: `Grup adı en fazla ${GROUP_NAME_MAX} karakter olabilir.` };
  }
  if (!/^[\p{L}\p{N} _-]+$/u.test(value)) {
    return { ok: false, error: 'Yalnız harf, rakam, boşluk, _ ve - kullanılabilir.' };
  }
  return { ok: true, value };
}

export function canCreateGroup(ownedCount: number): { ok: true } | { ok: false; error: string } {
  if (ownedCount >= MAX_GROUPS_OWNED) {
    return { ok: false, error: `En fazla ${MAX_GROUPS_OWNED} grup kurabilirsin.` };
  }
  return { ok: true };
}

export function canJoinGroup(
  joinedCount: number,
  memberCount: number,
  alreadyMember: boolean
): { ok: true } | { ok: false; error: string } {
  if (alreadyMember) return { ok: false, error: 'Bu gruba zaten üyesin.' };
  if (joinedCount >= MAX_GROUPS_JOINED) {
    return { ok: false, error: `En fazla ${MAX_GROUPS_JOINED} gruba katılabilirsin.` };
  }
  if (memberCount >= MAX_GROUP_MEMBERS) {
    return { ok: false, error: 'Grup dolu.' };
  }
  return { ok: true };
}

// ── Meydan okumalar ─────────────────────────────────────────────────────────

export type ChallengeMetric = 'xp' | 'answered' | 'lessons' | 'exams';

export function isChallengeMetric(v: unknown): v is ChallengeMetric {
  return v === 'xp' || v === 'answered' || v === 'lessons' || v === 'exams';
}

export interface ChallengeLike {
  metric: string;
  target: number;
  startsAt: Date;
  endsAt: Date;
}

/** Meydan okuma `at` anında etkin mi? Sınırlar dâhil değil/dâhil: [startsAt, endsAt). */
export function isChallengeActive(c: ChallengeLike, at: Date): boolean {
  return c.startsAt.getTime() <= at.getTime() && at.getTime() < c.endsAt.getTime();
}

/**
 * İlerleme = (güncel sayaç − katılım anındaki taban), 0'ın altına düşmez ve hedefi aşmaz.
 * Taban kullanılması, geçmişte kazanılmış XP'nin meydan okumayı anında bitirmesini engeller.
 */
export function challengeProgressValue(
  current: number,
  baseline: number,
  target: number
): { value: number; percent: number; done: boolean } {
  const raw = current - baseline;
  const value = Math.max(0, Math.min(raw, target));
  const percent = target <= 0 ? 0 : Math.round((value / target) * 100);
  return { value, percent, done: target > 0 && value >= target };
}

// ── Haftalık anlık görüntü (belirlenimci devir) ─────────────────────────────

export interface SnapshotRow {
  userId: string;
  displayName: string;
  avatarId: string;
  xp: number;
}

/** Anlık görüntü kimliği — `hafta:sınıf`. Benzersiz dizinle birlikte devri ETKİSİZ-TEKRARLI yapar. */
export function snapshotId(weekStart: string, licence: string): string {
  return `${weekStart}:${licence}`;
}

/**
 * Anlık görüntü satırlarını BELİRLENİMCİ sıraya sokar: XP azalan, eşitlikte `userId` artan.
 * İkinci ölçüt şart — yoksa aynı XP'li iki kullanıcı için sıra veritabanı dönüş sırasına kalır ve
 * aynı hafta iki kez alınan görüntü FARKLI çıkabilirdi.
 */
export function orderSnapshotRows(rows: SnapshotRow[]): SnapshotRow[] {
  return [...rows].sort((a, b) => b.xp - a.xp || a.userId.localeCompare(b.userId));
}

/**
 * Devir kararı: `weekStart` **geçmiş** bir haftaysa ve o hafta için görüntü yoksa alınmalıdır.
 * İçinde bulunulan hafta için görüntü ALINMAZ — hafta bitmeden dondurmak yanlış olurdu.
 */
export function shouldSnapshot(
  weekStartOfRows: string,
  currentWeekStart: string,
  exists: boolean
): boolean {
  if (exists) return false;
  return weekStartOfRows < currentWeekStart;
}
