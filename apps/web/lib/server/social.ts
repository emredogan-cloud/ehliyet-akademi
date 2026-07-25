/**
 * Sosyal grafik ve mesajlaşma — saf sunucu mantığı (Evolution Faz E9).
 *
 * E8'deki `community.ts` ile aynı disiplin: veritabanı YOKTUR, hepsi saf fonksiyondur; uçlar
 * yalnız "oku → uygula → yaz" yapar ve kurallar doğrudan test edilir.
 */

// ─────────────────────────────────────────────────────────────────────────────
// Konuşma anahtarı
// ─────────────────────────────────────────────────────────────────────────────

/**
 * İki kişilik konuşmanın KANONİK anahtarı: kimlikler sıralanıp birleştirilir.
 * Böylece A→B ve B→A aynı anahtarı üretir ve ayrı bir "konuşma" tablosu gerekmez.
 */
export function threadKey(a: string, b: string): string {
  return a < b ? `${a}:${b}` : `${b}:${a}`;
}

/** Anahtardaki diğer tarafı verir (kendi kimliğini bilerek). */
export function otherParty(key: string, self: string): string | null {
  const [x, y] = key.split(':');
  if (!x || !y) return null;
  if (x === self) return y;
  if (y === self) return x;
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Arkadaşlık durum makinesi
// ─────────────────────────────────────────────────────────────────────────────

export type FriendshipStatus = 'pending' | 'accepted';

export type FriendshipRow = {
  requesterId: string;
  addresseeId: string;
  status: FriendshipStatus;
};

export type FriendState =
  | 'none' // ilişki yok
  | 'outgoing' // ben istedim, bekliyor
  | 'incoming' // bana istek geldi
  | 'friends'; // kabul edildi

/** Bir satırın, bakan kişiye göre anlamı. */
export function friendStateFor(row: FriendshipRow | null, self: string): FriendState {
  if (!row) return 'none';
  if (row.status === 'accepted') return 'friends';
  return row.requesterId === self ? 'outgoing' : 'incoming';
}

/**
 * İstek gönderilebilir mi? Kurallar:
 * - kendine istek yok,
 * - zaten arkadaşsa yok,
 * - kendi bekleyen isteğini tekrarlayamaz (spam),
 * - KARŞI taraf zaten istek gönderdiyse "gönder" değil "kabul et" gerekir (çift satır oluşmaz).
 */
export function canSendRequest(
  existing: FriendshipRow | null,
  self: string,
  target: string
): { ok: true } | { ok: false; error: string; state: FriendState } {
  if (self === target) {
    return { ok: false, error: 'Kendine arkadaşlık isteği gönderemezsin.', state: 'none' };
  }
  const state = friendStateFor(existing, self);
  switch (state) {
    case 'none':
      return { ok: true };
    case 'friends':
      return { ok: false, error: 'Zaten arkadaşsınız.', state };
    case 'outgoing':
      return { ok: false, error: 'İstek zaten gönderildi.', state };
    case 'incoming':
      return { ok: false, error: 'Bu kişi sana istek göndermiş; kabul edebilirsin.', state };
  }
}

/** Kabul yalnız İSTEĞİN GELDİĞİ taraf tarafından ve yalnız `pending` iken yapılabilir. */
export function canAccept(
  existing: FriendshipRow | null,
  self: string
): { ok: true } | { ok: false; error: string } {
  if (!existing) return { ok: false, error: 'İstek bulunamadı.' };
  if (existing.status === 'accepted') return { ok: false, error: 'Zaten arkadaşsınız.' };
  if (existing.addresseeId !== self) return { ok: false, error: 'Bu isteği kabul edemezsin.' };
  return { ok: true };
}

// ─────────────────────────────────────────────────────────────────────────────
// Mesaj kuralları
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Görünmez kontrol karakterlerini siler (satır sonu \u000A KORUNUR). Bunlar hem görsel kandırmaca
 * hem de kayıt/görüntüleme katmanlarında bozulma kaynağıdır.
 *
 * `no-control-regex` burada BİLEREK kapatılır: kuralın amacı kontrol karakterini yanlışlıkla
 * yazmayı engellemektir; bu fonksiyonun amacı ise tam olarak onları temizlemektir (testli).
 */
// eslint-disable-next-line no-control-regex
const _CONTROL_CHARS = /[\u0000-\u0009\u000B-\u001F\u007F]/g;

export function stripControlChars(value: string): string {
  return value.replace(_CONTROL_CHARS, '');
}

export const MESSAGE_MAX_LENGTH = 500;
/** Bir pencerede gönderilebilecek en çok mesaj (taciz/spam sınırı). */
export const MESSAGE_BURST_LIMIT = 10;
export const MESSAGE_BURST_WINDOW_MS = 60_000;

export function validateMessageBody(
  raw: unknown
): { ok: true; value: string } | { ok: false; error: string } {
  if (typeof raw !== 'string') return { ok: false, error: 'Mesaj gerekli.' };
  // Görünmez/kontrol karakterleri temizlenir (satır sonu korunur).
  const value = stripControlChars(raw).trim();
  if (value.length === 0) return { ok: false, error: 'Mesaj boş olamaz.' };
  if (value.length > MESSAGE_MAX_LENGTH) {
    return { ok: false, error: `Mesaj en fazla ${MESSAGE_MAX_LENGTH} karakter olabilir.` };
  }
  return { ok: true, value };
}

/**
 * Ani gönderim (burst) sınırı: son pencerede [MESSAGE_BURST_LIMIT] mesajı aşan gönderim reddedilir.
 * IP tabanlı genel hız sınırının ÜSTÜNE, kişi-başına uygulanır (aynı IP'den farklı hesaplar veya
 * farklı IP'lerden aynı hesap için de korur).
 */
export function withinBurstLimit(recentCount: number): boolean {
  return recentCount < MESSAGE_BURST_LIMIT;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tartışma kuralları
// ─────────────────────────────────────────────────────────────────────────────

export const THREAD_TITLE_MIN = 5;
export const THREAD_TITLE_MAX = 100;
export const POST_MAX_LENGTH = 1000;

export function validateThreadTitle(
  raw: unknown
): { ok: true; value: string } | { ok: false; error: string } {
  if (typeof raw !== 'string') return { ok: false, error: 'Başlık gerekli.' };
  const value = raw.replace(/\s+/g, ' ').trim();
  if (value.length < THREAD_TITLE_MIN) {
    return { ok: false, error: `Başlık en az ${THREAD_TITLE_MIN} karakter olmalı.` };
  }
  if (value.length > THREAD_TITLE_MAX) {
    return { ok: false, error: `Başlık en fazla ${THREAD_TITLE_MAX} karakter olabilir.` };
  }
  return { ok: true, value };
}

export function validatePostBody(
  raw: unknown
): { ok: true; value: string } | { ok: false; error: string } {
  if (typeof raw !== 'string') return { ok: false, error: 'İleti gerekli.' };
  const value = stripControlChars(raw).trim();
  if (value.length === 0) return { ok: false, error: 'İleti boş olamaz.' };
  if (value.length > POST_MAX_LENGTH) {
    return { ok: false, error: `İleti en fazla ${POST_MAX_LENGTH} karakter olabilir.` };
  }
  return { ok: true, value };
}

/**
 * Soru paylaşımı REFERANSLADIR. Yalnız banka soru kimliği saklanır (ör. `trafik-101`);
 * soru METNİ hiçbir zaman kopyalanmaz — banka bir tartışma başlığına dökülemez.
 */
export function validateQuestionRef(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const value = raw.trim();
  return /^[a-z]+-\d{1,4}$/.test(value) ? value : null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sayfalama (imleç)
// ─────────────────────────────────────────────────────────────────────────────

export const PAGE_SIZE_DEFAULT = 30;
export const PAGE_SIZE_MAX = 50;

export function parseLimit(raw: string | null): number {
  const n = Number(raw);
  if (!Number.isFinite(n) || n <= 0) return PAGE_SIZE_DEFAULT;
  return Math.min(Math.floor(n), PAGE_SIZE_MAX);
}

/**
 * İmleç = ISO zaman damgası. Geçersiz imleç sessizce yok sayılır (istemciyi kilitlemez);
 * sunucu her hâlükârda sayfa boyutunu uygular → sınırsız büyüme yolu yoktur.
 */
export function parseCursor(raw: string | null): Date | null {
  if (!raw) return null;
  const t = Date.parse(raw);
  return Number.isFinite(t) ? new Date(t) : null;
}
