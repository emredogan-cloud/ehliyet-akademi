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
  /** Ticaret unvanı ya da gerçek kişinin adı — veri sorumlusunun tam yasal adı. */
  companyName: string;
  /** Vergi kimlik numarası (10 hane) veya T.C. kimlik numarası (11 hane). */
  taxId: string;
  /** Tebligata elverişli açık adres. */
  address: string;
  /**
   * Kayıtlı elektronik posta adresi — **isteğe bağlı**.
   *
   * KEP zorunluluğu TTK m.18/3 uyarınca **sermaye şirketlerine** (anonim, limited, sermayesi
   * paylara bölünmüş komandit) özgüdür. Veri sorumlusu bir **gerçek kişi** ise KEP hesabı tutmak
   * zorunda değildir ve çoğu tutmaz.
   *
   * Bu alan bir dönem ZORUNLUYDU ve tam da bu durumu kilitliyordu: gerçek kişi olan kurucu diğer
   * dört alanı doğru doldurduğu hâlde sayfa "henüz yayımlanmadı" demeye devam ediyordu. Var
   * olmayan bir KEP adresi uydurmak ise sahte tescil bilgisi yayımlamak olurdu — yer tutucudan
   * çok daha ağır bir kusur. Doğru çözüm alanı isteğe bağlı yapmak: yoksa satır hiç basılmaz.
   */
  kepAddress: string | null;
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

/**
 * Kimliğin yayımlanabilmesi için DOLU olması gereken alanlar.
 *
 * `kepAddress` bilerek dışarıda: gerekçesi [LegalEntity.kepAddress] üzerinde.
 */
export const REQUIRED_LEGAL_FIELDS = [
  'companyName',
  'taxId',
  'address',
  'supportEmail',
] as const satisfies ReadonlyArray<keyof LegalEntity>;

type EnvLike = Record<string, string | undefined>;

/**
 * Yasal kimliği ortamdan oku.
 *
 * ZORUNLU alanlardan biri bile boşsa `null` döner — kısmi kimlik yayımlanmaz (bkz. dosya başlığı).
 * KEP boşsa kimlik yine de geçerlidir; yalnız `kepAddress` `null` olur ve sayfada satır çıkmaz.
 */
export function readLegalEntity(env: EnvLike = process.env): LegalEntity | null {
  const read = (field: keyof LegalEntity): string => (env[LEGAL_ENV_KEYS[field]] ?? '').trim();

  for (const field of REQUIRED_LEGAL_FIELDS) {
    if (!read(field)) return null;
  }
  const kep = read('kepAddress');
  return {
    companyName: read('companyName'),
    taxId: read('taxId'),
    address: read('address'),
    kepAddress: kep === '' ? null : kep,
    supportEmail: read('supportEmail'),
  };
}

/** Yasal kimlik yayına hazır mı? Sayfalardaki "hazır değil" uyarısı buna bakar. */
export function isLegalIdentityConfigured(env: EnvLike = process.env): boolean {
  return readLegalEntity(env) !== null;
}

/**
 * Eksik olan ZORUNLU ortam değişkenlerinin adları — kurucuya ne gireceğini söylemek için.
 *
 * `LEGAL_KEP_ADDRESS` burada listelenmez: yokluğu bir eksiklik değil, geçerli bir durumdur.
 */
export function missingLegalEnvKeys(env: EnvLike = process.env): string[] {
  return REQUIRED_LEGAL_FIELDS.map((f) => LEGAL_ENV_KEYS[f]).filter((k) => !(env[k] ?? '').trim());
}

/**
 * Kimlik numarasının DOĞRU etiketi.
 *
 * Sayfa bir dönem her numarayı `VKN:` diye basıyordu. 11 haneli bir değer T.C. kimlik
 * numarasıdır, vergi kimlik numarası değildir — yayımlanan yasal bir metinde yanlış etiket,
 * yanlış beyandır. Uzunluk tek ayırt edici bilgi olduğu için karar oradan verilir; tanınmayan
 * bir uzunlukta nötr ve doğru olan "Kimlik No" kullanılır.
 */
export function taxIdLabel(taxId: string): string {
  const digits = taxId.replace(/\D/g, '');
  if (digits.length === 11) return 'T.C. Kimlik No';
  if (digits.length === 10) return 'VKN';
  return 'Kimlik No';
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
