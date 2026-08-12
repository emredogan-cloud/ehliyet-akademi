/**
 * Veri saklama politikası — **tek doğru kaynak**.
 *
 * ## Neden bu dosya var
 *
 * Saklama süresi iki yerde yaşarsa (yayımlanan yasal sayfa ve temizleme işi) ikisi kaçınılmaz
 * olarak birbirinden ayrılır ve sayfa, sunucunun yapmadığı bir şeyi vaat eder. Bu dosya
 * politikayı **veri** hâline getirir: `/gizlilik` ve `/hesap-silme` bu listeyi RENDER eder,
 * `purgeExpiredData` aynı listeyi UYGULAR. Bir süreyi değiştirmek tek satırdır ve her iki taraf
 * birlikte değişir.
 *
 * ## Denetimin bulduğu iki uyuşmazlık (bu dosya ikisini de kapatır)
 *
 * 1. `/hesap-silme` §4, satın alma/fatura kayıtlarının "mevzuatın öngördüğü süre boyunca"
 *    tutulduğunu söylüyordu. Oysa `purchases.user_id` şemada `ON DELETE CASCADE` taşır:
 *    hesap silindiğinde satın alma kayıtları **aynı işlemde yok olur**. Sayfa, kodun yapmadığı
 *    bir şeyi anlatıyordu. Doğru olan koddur — bizim `purchases` tablomuz muhasebe faturası
 *    değil, **hak sahipliği defteridir**; malî kayıt Google Play / ödeme sağlayıcısında durur.
 *    Sayfa buna göre düzeltildi.
 *
 * 2. `analytics_events` ve `error_reports`, `ON DELETE SET NULL` taşıdıkları için hesap
 *    silindikten sonra **kimliksizleşerek kalır** — ve hiçbir yerde bir üst sınır yoktu, yani
 *    fiilen **süresiz** saklanıyorlardı. Süresiz saklama, KVKK m.4/2-(d) "ilgili mevzuatta
 *    öngörülen veya işlendikleri amaç için gerekli olan süre kadar muhafaza" ilkesiyle
 *    bağdaşmaz. Aşağıdaki süreler bu boşluğu kapatır.
 *
 * ## Süreler nereden geliyor
 *
 * **Uydurulmuş bir yasal yükümlülük değildir.** Hiçbiri "kanun şu kadar diyor" iddiası taşımaz;
 * her biri, ürün analitiği ve hata izleme araçlarının yaygın **varsayılan** saklama süresidir ve
 * amaç için gereken en kısa makul süre seçilmiştir:
 *
 * · 365 gün analitik  — yıllık mevsimsellik (sınav dönemleri) tek bir karşılaştırma penceresine
 *                       sığsın diye; bundan kısası yıl-yıla kıyası imkânsız kılar.
 * · 90 gün hata kaydı — bir sürümün sahada yaşadığı ömür; daha eski yığın izleri, kodu artık
 *                       var olmayan bir sürüme ait olduğu için tanı değeri taşımaz.
 * · 180 gün moderasyon — kapanmış şikâyetlerin tekrar eden taciz örüntüsünü gösterebilmesi için.
 *
 * Üçü de ortam değişkeniyle **yapılandırılabilir**: kurucunun hukuk danışmanı farklı bir süre
 * belirlerse kod değişmez (bkz. `FOUNDER_RELEASE_HANDOOK.md` F-06).
 */

/** Bir veri sınıfının saklama kuralı. */
export interface RetentionRule {
  /** Kararlı anahtar — sayfa metni ve testler buna bakar. */
  key: string;
  /** Kullanıcının anlayacağı ad. */
  label: string;
  /** Hangi veri. */
  what: string;
  /** Neden tutuluyor. */
  why: string;
  /**
   * Hesaptan BAĞIMSIZ saklama süresi (gün).
   * `null` → bağımsız saklama yoktur; veri hesapla birlikte aynı anda silinir.
   */
  days: number | null;
  /** Süreyi değiştiren ortam değişkeni; `null` ise süre yapılandırılamaz. */
  envKey: string | null;
  /** Silme mekanizması — nasıl yok oluyor. */
  deletion: string;
}

/** Varsayılan süreler. Ortam değişkeni verilmemişse bunlar geçerlidir. */
export const RETENTION_DEFAULT_DAYS = {
  analytics: 365,
  errorReports: 90,
  moderation: 180,
} as const;

type EnvLike = Record<string, string | undefined>;

/**
 * Ortamdan gün sayısı oku.
 *
 * Geçersiz değer (harf, negatif, 0, sayı değil) **sessizce varsayılana** düşer. Nedeni:
 * yanlış yazılmış bir `RETENTION_ANALYTICS_DAYS=abc`, "0 gün" gibi yorumlanıp verinin tamamını
 * silmemelidir. Temizleme işinde sessiz veri kaybı, fazladan saklamadan çok daha kötüdür.
 */
export function retentionDays(
  key: keyof typeof RETENTION_DEFAULT_DAYS,
  env: EnvLike = process.env
): number {
  const envKey = RETENTION_ENV_KEYS[key];
  const raw = (env[envKey] ?? '').trim();
  if (!raw) return RETENTION_DEFAULT_DAYS[key];
  const n = Number(raw);
  if (!Number.isFinite(n) || !Number.isInteger(n) || n < 1) return RETENTION_DEFAULT_DAYS[key];
  return n;
}

/** Ortam değişkeni adları — Founder Handbook F-06 ile birebir aynı olmalıdır. */
export const RETENTION_ENV_KEYS = {
  analytics: 'RETENTION_ANALYTICS_DAYS',
  errorReports: 'RETENTION_ERROR_REPORTS_DAYS',
  moderation: 'RETENTION_MODERATION_DAYS',
} as const satisfies Record<keyof typeof RETENTION_DEFAULT_DAYS, string>;

/**
 * Yayımlanan saklama tablosu.
 *
 * `/gizlilik` ve `/hesap-silme` bunu doğrudan render eder; elle yazılmış ikinci bir liste YOKTUR.
 */
export function retentionRules(env: EnvLike = process.env): RetentionRule[] {
  return [
    {
      key: 'account',
      label: 'Hesap ve öğrenme verisi',
      what: 'E-posta, ad, parola özeti, ders/soru ilerlemesi, deneme sınavı sonuçları, seri ve hedefler',
      why: 'Uygulamanın çalışması için gereklidir; hesap silinince amacı kalmaz',
      days: null,
      envKey: null,
      deletion: 'Hesap silindiği anda aynı işlemde silinir (veritabanı ON DELETE CASCADE)',
    },
    {
      key: 'purchases',
      label: 'Satın alma (hak sahipliği) kayıtları',
      what: 'Hangi paketin alındığı, tutar, sağlayıcı ve mağaza referansı',
      why: 'Premium erişimin cihazlar arasında geri yüklenebilmesi için',
      days: null,
      envKey: null,
      deletion:
        'Hesap silindiği anda silinir. Malî/fatura kaydının aslı bizde değil, ödemeyi alan Google Play tarafında tutulur',
    },
    {
      key: 'community',
      label: 'Topluluk içeriği',
      what: 'Profil, mesajlar, tartışma iletileri, grup üyelikleri, arkadaşlıklar, profil fotoğrafı',
      why: 'Topluluk özelliklerinin çalışması için',
      days: null,
      envKey: null,
      deletion:
        'Hesap silindiği anda silinir; profil fotoğrafı ayrıca dosya kaydıyla birlikte silinir',
    },
    {
      key: 'analytics',
      label: 'Kimliksiz kullanım olayları',
      what: 'Hangi ekranın açıldığı, hangi özelliğin kullanıldığı, uygulama sürümü, platform',
      why: 'Ürünün hangi bölümünün işe yaradığını ölçmek; kişiye değil, toplama bakılır',
      days: retentionDays('analytics', env),
      envKey: RETENTION_ENV_KEYS.analytics,
      deletion:
        'Hesap silinince kullanıcı bağı koparılır (kayıt kimliksizleşir); süre dolunca kayıt tamamen silinir',
    },
    {
      key: 'errorReports',
      label: 'Hata ve çökme kayıtları',
      what: 'Hata mesajı, yığın izi, ekran adı, cihaz modeli ve uygulama sürümü',
      why: 'Çökmeleri teşhis edip gidermek',
      days: retentionDays('errorReports', env),
      envKey: RETENTION_ENV_KEYS.errorReports,
      deletion: 'Hesap silinince kullanıcı bağı koparılır; süre dolunca kayıt tamamen silinir',
    },
    {
      key: 'moderation',
      label: 'Kapanmış topluluk şikâyetleri',
      what: 'Şikâyet nedeni, hedef içerik referansı ve sonuç',
      why: 'Tekrar eden taciz örüntülerini görebilmek',
      days: retentionDays('moderation', env),
      envKey: RETENTION_ENV_KEYS.moderation,
      deletion:
        'İncelemesi kapanan şikâyet süre dolunca silinir; taraflardan biri hesabını silerse şikâyet zaten o anda silinir',
    },
  ];
}

/** Kullanıcıya "silme talebiniz ne kadar sürede sonuçlanır" cevabı — sayfa ile tek kaynaktan. */
export const DELETION_REQUEST_SLA_DAYS = 30;

/** Bir kuralın süresini insan diline çevir. */
export function retentionText(rule: RetentionRule): string {
  if (rule.days === null) return 'Hesapla birlikte silinir';
  if (rule.days % 365 === 0) {
    const y = rule.days / 365;
    return `${rule.days} gün (${y} yıl)`;
  }
  return `${rule.days} gün`;
}
