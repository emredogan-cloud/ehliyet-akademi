/**
 * Yasal kimlik (veri sorumlusu) — ortam değişkeninden okunur, kodda GÖMÜLÜ DEĞİLDİR.
 *
 * ## Neden ortamdan
 *
 * Şirket unvanı, VKN, adres, KEP ve destek e-postası **kurucunun sağlaması gereken doğrulanmış
 * bilgilerdir**. Bir ajan bunları uyduramaz: yanlış bir VKN ya da var olmayan bir unvan, gizlilik
 * politikasını yalnız eksik değil **yanıltıcı** yapar ve Play'in Kullanıcı Verisi politikası
 * açısından yanlış beyandır.
 *
 * Bu yüzden değerler ortamdan gelir ve **yapılandırılmadıkları sürece sayfa kendini yayına hazır
 * ilan etmez**: [isLegalIdentityConfigured] `false` döndüğü sürece sayfalar bir "hazır değil"
 * uyarısı basar. Kurucu değerleri girdiği anda uyarı kendiliğinden kaybolur — kod değişikliği
 * gerekmez.
 *
 * ## Neden hepsi zorunlu
 *
 * Eksik tek bir alan bile (ör. KEP yok) sayfayı "yarı yapılandırılmış" bırakır ve hangi alanın
 * gerçek hangisinin yer tutucu olduğu okunamaz hâle gelir. Ya hepsi vardır ya hiçbiri.
 */

/** Play/KVKK açısından gerekli asgari yasal kimlik alanları. */
export interface LegalEntity {
  /** Ticaret unvanı — veri sorumlusunun tam yasal adı. */
  companyName: string;
  /** Vergi kimlik numarası (10 hane) veya T.C. kimlik numarası (11 hane). */
  taxId: string;
  /** Tebligata elverişli açık adres. */
  address: string;
  /** Kayıtlı elektronik posta adresi. */
  kepAddress: string;
  /** İzlenen destek e-posta adresi — KVKK başvuruları buraya düşer. */
  supportEmail: string;
}

/** Ortam değişkeni adları — Founder Handbook ile birebir aynı olmalıdır. */
export const LEGAL_ENV_KEYS = {
  companyName: 'LEGAL_COMPANY_NAME',
  taxId: 'LEGAL_TAX_ID',
  address: 'LEGAL_ADDRESS',
  kepAddress: 'LEGAL_KEP_ADDRESS',
  supportEmail: 'LEGAL_SUPPORT_EMAIL',
} as const satisfies Record<keyof LegalEntity, string>;

type EnvLike = Record<string, string | undefined>;

/**
 * Yasal kimliği ortamdan oku.
 *
 * Alanlardan biri bile boşsa `null` döner — kısmi kimlik yayımlanmaz (bkz. dosya başlığı).
 */
export function readLegalEntity(env: EnvLike = process.env): LegalEntity | null {
  const out: Partial<LegalEntity> = {};
  for (const [field, key] of Object.entries(LEGAL_ENV_KEYS) as Array<[keyof LegalEntity, string]>) {
    const value = (env[key] ?? '').trim();
    if (!value) return null;
    out[field] = value;
  }
  return out as LegalEntity;
}

/** Yasal kimlik yayına hazır mı? Sayfalardaki "hazır değil" uyarısı buna bakar. */
export function isLegalIdentityConfigured(env: EnvLike = process.env): boolean {
  return readLegalEntity(env) !== null;
}

/** Eksik olan ortam değişkenlerinin adları — kurucuya ne gireceğini söylemek için. */
export function missingLegalEnvKeys(env: EnvLike = process.env): string[] {
  return (Object.values(LEGAL_ENV_KEYS) as string[]).filter((k) => !(env[k] ?? '').trim());
}

/**
 * Alt işleyiciler (sub-processor) — gizlilik politikasında adıyla anılmak ZORUNDA.
 *
 * Bu liste koddan doğrulanmıştır, tahmin değildir:
 * · Vercel      — Next.js dağıtımı ve API çalıştırma ortamı
 * · Neon        — PostgreSQL (`packages/db`)
 * · Anthropic   — AI Koç yanıtları (`apps/web/app/api/ai/ask`, Claude Haiku 4.5)
 * · Resend      — işlemsel e-posta (`apps/web/lib/server/email.ts`, `RESEND_API_KEY`)
 * · Google      — Play Faturalandırma, Play ile oturum açma
 *
 * Yeni bir üçüncü taraf eklendiğinde BU LİSTE ve gizlilik politikası aynı değişiklikte
 * güncellenir; aksi hâlde beyan ile gerçek birbirinden ayrılır.
 */
export interface SubProcessor {
  name: string;
  purpose: string;
  dataShared: string;
}

export const SUB_PROCESSORS: readonly SubProcessor[] = [
  {
    name: 'Vercel Inc.',
    purpose: 'Uygulamanın ve API uçlarının barındırılması',
    dataShared: 'İstek meta verisi (IP dâhil, geçici işlem günlükleri)',
  },
  {
    name: 'Neon Inc.',
    purpose: 'PostgreSQL veritabanı',
    dataShared: 'Hesap, ilerleme, satın alma ve topluluk kayıtları',
  },
  {
    name: 'Anthropic PBC',
    purpose: 'AI Koç yanıtlarının üretilmesi',
    dataShared: 'Yalnız yazdığınız soru metni ve ilgili ders/soru bağlamı',
  },
  {
    name: 'Resend Inc.',
    purpose: 'Doğrulama, karşılama ve satın alma onay e-postaları',
    dataShared: 'E-posta adresiniz ve görünen adınız',
  },
  {
    name: 'Google LLC',
    purpose: 'Play Faturalandırma ve Google ile oturum açma',
    dataShared: 'Satın alma jetonu; Google girişinde e-posta ve ad',
  },
] as const;
