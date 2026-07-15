/**
 * Topluluk (ROADMAP Faz 32/33 · Sprint 6). Gizlilik-öncelikli, DÜRÜST tasarım:
 * - Lider tablosu: XP KADEMELERİ (Bronz→Elmas) — kullanıcının kendi ilerlemesi; UYDURMA rakip yok.
 * - Günlük meydan okuma: tarihten deterministik (sunucusuz).
 * - Davet (referral): istemci-üretimi kod + paylaşım bağlantısı.
 * - Arkadaş sistemi: sosyal grafik SUNUCU/backend gerektirir → arayüz + gelecek mimarisi (aşağıda).
 */

/* ---- XP kademeleri (tek-oyunculu, dürüst lider tablosu) ---- */
export interface Tier {
  name: string;
  minXp: number;
  icon: string;
}
export const TIERS: Tier[] = [
  { name: 'Bronz', minXp: 0, icon: '🥉' },
  { name: 'Gümüş', minXp: 500, icon: '🥈' },
  { name: 'Altın', minXp: 1500, icon: '🥇' },
  { name: 'Platin', minXp: 3500, icon: '💎' },
  { name: 'Elmas', minXp: 7000, icon: '🏆' },
];

export interface TierStanding {
  current: Tier;
  next?: Tier;
  toNext: number; // sonraki kademeye kalan XP (yoksa 0)
  progress: number; // mevcut kademe içindeki ilerleme 0..1
}

export function tierForXp(xp: number): TierStanding {
  let idx = 0;
  for (let i = 0; i < TIERS.length; i++) if (xp >= TIERS[i]!.minXp) idx = i;
  const current = TIERS[idx]!;
  const next = TIERS[idx + 1];
  const span = next ? next.minXp - current.minXp : 1;
  return {
    current,
    next,
    toNext: next ? Math.max(0, next.minXp - xp) : 0,
    progress: next ? Math.min(1, (xp - current.minXp) / span) : 1,
  };
}

/* ---- Günlük meydan okuma (deterministik) ---- */
export interface DailyChallenge {
  id: string;
  title: string;
  detail: string;
  target: number;
  href: string;
}
const CHALLENGE_TEMPLATES: Array<Omit<DailyChallenge, 'id'>> = [
  {
    title: 'Günün 15 sorusu',
    detail: 'Bugün 15 soru çöz — serini besle.',
    target: 15,
    href: '/calis',
  },
  { title: 'Trafik turu', detail: 'Trafik konusundan 12 soru çöz.', target: 12, href: '/calis' },
  {
    title: 'Deneme günü',
    detail: 'Bir deneme sınavı bitir (50 soru).',
    target: 50,
    href: '/deneme-sinavi',
  },
  {
    title: 'İlk yardım tekrarı',
    detail: 'İlk yardım dersini gözden geçir + 10 soru çöz.',
    target: 10,
    href: '/dersler',
  },
  {
    title: 'Zayıf konu avı',
    detail: 'Çalışma planındaki ilk adımı tamamla.',
    target: 10,
    href: '/calisma-plani',
  },
  {
    title: 'Hız & mesafe',
    detail: 'Hız/takip mesafesi dersini oku + 8 soru.',
    target: 8,
    href: '/dersler/hiz-takip',
  },
  {
    title: 'Direksiyon hazırlığı',
    detail: 'Sürüş Akademisi dersinden 8 soru çöz.',
    target: 8,
    href: '/dersler',
  },
];

/** Yılın gününe göre günü belirleyen deterministik meydan okuma. */
export function dailyChallenge(now = Date.now()): DailyChallenge {
  const d = new Date(now);
  const dayOfYear = Math.floor(
    (Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()) - Date.UTC(d.getFullYear(), 0, 0)) /
      86_400_000
  );
  const t = CHALLENGE_TEMPLATES[dayOfYear % CHALLENGE_TEMPLATES.length]!;
  return { id: `dc-${dayOfYear}`, ...t };
}

/* ---- Davet (referral) ---- */
const REF_KEY = 'ea:referral:v1';
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/** 6 haneli okunur kod üret. */
function randomCode(): string {
  let s = '';
  for (let i = 0; i < 6; i++) {
    // Math.random tarayıcıda kabul edilebilir (kripto-kritik değil; yalnız davet kodu).
    s += ALPHABET[Math.floor(Math.random() * ALPHABET.length)];
  }
  return s;
}

/** İstemci: kalıcı davet kodunu getir ya da oluştur. */
export function getOrCreateReferralCode(): string {
  if (typeof window === 'undefined') return '';
  try {
    const cur = window.localStorage.getItem(REF_KEY);
    if (cur) return cur;
    const code = randomCode();
    window.localStorage.setItem(REF_KEY, code);
    return code;
  } catch {
    return randomCode();
  }
}

export function referralLink(base: string, code: string): string {
  const b = base.replace(/\/$/, '');
  return `${b}/?davet=${encodeURIComponent(code)}`;
}

/* ---- Arkadaş sistemi mimarisi (gelecek — backend gerektirir) ----
 * Sosyal grafik kalıcı sunucu + gizlilik onayı gerektirir. Sözleşme:
 *   interface FriendGraph { list(): Promise<Friend[]>; add(code: string): Promise<void>; }
 * DATABASE_URL + kullanıcı-ilişki tablosu geldiğinde `ServerFriendGraph` bu arayüzü uygular;
 * lider tablosu global XP sıralamasına yükseltilebilir. Şimdilik tek-oyunculu kademe sistemi
 * (yukarıda) motivasyonu gizlilik-dostu biçimde sağlar. */
export interface Friend {
  code: string;
  name: string;
  xp: number;
}
