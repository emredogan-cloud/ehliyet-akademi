/**
 * @ea/db şema (ROADMAP Faz 27 / Sprint 1) — Drizzle ORM, Postgres lehçesi.
 * Aynı şema PGlite (yerel/test) ve gerçek Postgres'te (Neon/Vercel) çalışır.
 */
import {
  pgTable,
  text,
  timestamp,
  integer,
  boolean,
  jsonb,
  primaryKey,
  uniqueIndex,
} from 'drizzle-orm/pg-core';

export const users = pgTable(
  'users',
  {
    id: text('id').primaryKey(), // uuid (uygulama üretir)
    email: text('email').notNull(),
    name: text('name').notNull().default(''),
    passwordHash: text('password_hash').notNull(),
    role: text('role').notNull().default('user'), // user | editor | admin (Sprint 2 RBAC)
    emailVerified: boolean('email_verified').notNull().default(false), // Sprint 4 — e-posta doğrulama
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex('users_email_uq').on(t.email)]
);

/** E-posta doğrulama tokenları (Sprint 4). */
export const emailVerificationTokens = pgTable('email_verification_tokens', {
  tokenHash: text('token_hash').primaryKey(),
  userId: text('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
});

/** Çok-cihaz oturumlar: her giriş bir satır; token'ın yalnız SHA-256 hash'i saklanır. */
export const sessions = pgTable('sessions', {
  tokenHash: text('token_hash').primaryKey(),
  userId: text('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  userAgent: text('user_agent').notNull().default(''),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
});

export const passwordResetTokens = pgTable('password_reset_tokens', {
  tokenHash: text('token_hash').primaryKey(),
  userId: text('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
});

/** Cihazlar-arası senkron: anahtar-değer kullanıcı durumu (answers/cards/streak/theme/...). */
export const userState = pgTable(
  'user_state',
  {
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    key: text('key').notNull(),
    value: jsonb('value').notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [primaryKey({ columns: [t.userId, t.key] })]
);

/** Tek-seferlik satın almalar (Faz 16) — abonelik YOK; satır = kalıcı sahiplik. */
export const purchases = pgTable(
  'purchases',
  {
    id: text('id').primaryKey(), // uuid
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    productId: text('product_id').notNull(),
    priceTRY: integer('price_try').notNull(),
    provider: text('provider').notNull().default('mock'), // mock | lemonsqueezy | stripe
    externalRef: text('external_ref'), // Sprint 4 — sağlayıcı sipariş/makbuz id'si (idempotent webhook)
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex('purchases_user_product_uq').on(t.userId, t.productId)]
);

// ─────────────────────────────────────────────────────────────────────────────
// Davet (referral) sistemi — Faz 8.
//
// TASARIM: üç tablo, üç ayrı sorumluluk.
// · `referral_codes`  — kimin hangi kodu var (kullanıcı başına TEK kod).
// · `referrals`       — kim kimi davet etti ve davet HANGİ DURUMDA.
// · `referral_rewards`— hangi ödül, ne zaman verildi, ne zaman biter.
//
// Ödülü `purchases` tablosuna yazmıyoruz ÇÜNKÜ orada süre kavramı yok (ömür boyu tek ürün).
// Süreli erişim ayrı tutulur ve `GET /api/purchases` etkin ödülü sahipliğe EKLER; böylece mobil
// tarafta tek satır kod değişmeden premium açılır.
// ─────────────────────────────────────────────────────────────────────────────

/** Kullanıcının davet kodu — kullanıcı başına tek, değişmez. */
export const referralCodes = pgTable(
  'referral_codes',
  {
    userId: text('user_id')
      .primaryKey()
      .references(() => users.id, { onDelete: 'cascade' }),
    code: text('code').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex('referral_codes_code_uq').on(t.code)]
);

/**
 * Bir davet ilişkisi.
 *
 * `status`:
 * · `pending`   — kayıt oldu, e-postası HENÜZ doğrulanmadı (ödüle sayılmaz).
 * · `qualified` — e-postası doğrulandı; "başarılı kayıt" budur.
 * · `void`      — sahtecilik/iade nedeniyle yönetici tarafından iptal edildi.
 *
 * `signupIpHash` ham IP DEĞİLDİR: tuzlanmış SHA-256. Sahtecilik tespitine yeter, kişisel veriyi
 * saklamaz (KVKK veri minimizasyonu).
 */
export const referrals = pgTable(
  'referrals',
  {
    id: text('id').primaryKey(),
    referrerUserId: text('referrer_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    // Davet edilen kullanıcı silinirse davet de düşer — silinmiş bir hesap ödüle sayılamaz.
    referredUserId: text('referred_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    code: text('code').notNull(),
    status: text('status').notNull().default('pending'),
    signupIpHash: text('signup_ip_hash').notNull().default(''),
    voidReason: text('void_reason'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    qualifiedAt: timestamp('qualified_at', { withTimezone: true }),
  },
  // Bir kullanıcı YALNIZ BİR KEZ davet edilebilir — aynı kişiyi iki kez saymanın önündeki set.
  (t) => [uniqueIndex('referrals_referred_uq').on(t.referredUserId)]
);

/** Verilen ödül — süreli premium erişim. */
export const referralRewards = pgTable('referral_rewards', {
  id: text('id').primaryKey(),
  userId: text('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  /** Kaçıncı eşik için verildi (5, 10, 15 …). Aynı eşik iki kez ödüllendirilmez. */
  milestone: integer('milestone').notNull(),
  months: integer('months').notNull(),
  grantedAt: timestamp('granted_at', { withTimezone: true }).notNull().defaultNow(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
});

/**
 * Beta Faz 1 — bir davet bağlantısının AÇILMASI (`/davet/<KOD>`).
 *
 * NEDEN gerekli: davet hunisinin ilk basamağı buydu ve ölçülmüyordu. `referrals` yalnız KAYIT OLMUŞ
 * daveti bilir; kaç kişinin bağlantıyı açıp vazgeçtiği görünmüyordu. Huni artık üç basamak:
 * ziyaret → kayıt (`referrals.pending`) → nitelikli (`referrals.qualified`).
 *
 * GÜN BAŞINA TEK SATIR (`day` + `code` + `ip_hash` tekil): aynı kişinin sayfayı yenilemesi ziyareti
 * şişirmesin. Sayfa yenilemesi yeni bir ilgi DEĞİLDİR; onu saymak huniyi iyimser gösterirdi.
 *
 * `ipHash` ham IP DEĞİLDİR — `referrals.signupIpHash` ile aynı tuzlu SHA-256 (KVKK).
 */
export const referralVisits = pgTable(
  'referral_visits',
  {
    id: text('id').primaryKey(),
    code: text('code').notNull(),
    /** Kod gerçekten bir kullanıcıya mı ait? Yanlış/uydurma kodlar da ölçülür (yazım hatası tespiti). */
    known: boolean('known').notNull().default(false),
    ipHash: text('ip_hash').notNull().default(''),
    /** `YYYY-MM-DD` — tekil indeksin gün bileşeni. */
    day: text('day').notNull(),
    /** `web` | `android` — bağlantı hangi yüzeyde açıldı. */
    platform: text('platform').notNull().default('web'),
    at: timestamp('at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex('referral_visits_uq').on(t.code, t.ipHash, t.day)]
);

/**
 * Beta Faz 3 — ürün analitiği olayları (sunucu tarafı havuz).
 *
 * NEDEN kendi tablomuz: uygulama üçüncü taraf bir SDK (Firebase/Amplitude) taşımıyor ve taşımak
 * KVKK açısından ayrı bir karar. Olaylar kendi sunucumuzda toplanır; yönetici paneli doğrudan
 * bunları okur. Üçüncü taraf eklenirse bu tablo yine kalır (kaynak doğruluk).
 *
 * `userId` NULL OLABİLİR: misafir kullanım gerçek ve ölçülmesi gereken bir durumdur. Kimliksiz
 * olayları `anonId` (cihaz başına rastgele, kişisel veri içermeyen) birbirine bağlar.
 *
 * `props` serbest JSON'dur ama **kişisel veri içermez** — istemci tarafındaki olay sözlüğü bunu
 * kural olarak dayatır (`lib/core/analytics/events.dart`).
 */
export const analyticsEvents = pgTable(
  'analytics_events',
  {
    id: text('id').primaryKey(),
    name: text('name').notNull(),
    userId: text('user_id').references(() => users.id, { onDelete: 'set null' }),
    /** Cihaz başına rastgele kimlik — oturumsuz kullanımı birbirine bağlar, kişiyi tanımlamaz. */
    anonId: text('anon_id').notNull().default(''),
    platform: text('platform').notNull().default('android'),
    appVersion: text('app_version').notNull().default(''),
    props: jsonb('props').notNull().default({}),
    /** Olayın CİHAZDA gerçekleştiği an (çevrimdışı kuyruklanmış olabilir). */
    at: timestamp('at', { withTimezone: true }).notNull(),
    /** Sunucuya ULAŞTIĞI an — kuyruk gecikmesi bu ikisinin farkıdır. */
    receivedAt: timestamp('received_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex('analytics_events_id_uq').on(t.id)]
);

/**
 * Beta Faz 4 — istemciden gelen hata raporları (çökme gözlemlenebilirliği).
 *
 * Üçüncü taraf (Crashlytics/Sentry) YOK; rapor kendi sunucumuza gelir. `fingerprint` aynı hatayı
 * gruplamak içindir (tür + en üstteki kendi kod çerçevemiz) — sayım "kaç farklı hata" sorusunu
 * cevaplayabilsin.
 */
export const errorReports = pgTable(
  'error_reports',
  {
    id: text('id').primaryKey(),
    /** `flutter` | `async` | `platform` | `network` | `store` | `google-signin` | `isolate` */
    kind: text('kind').notNull(),
    fingerprint: text('fingerprint').notNull(),
    message: text('message').notNull(),
    stack: text('stack').notNull().default(''),
    /** Hatanın olduğu ekran/rota — "nerede" sorusunun cevabı. */
    route: text('route').notNull().default(''),
    userId: text('user_id').references(() => users.id, { onDelete: 'set null' }),
    anonId: text('anon_id').notNull().default(''),
    platform: text('platform').notNull().default('android'),
    appVersion: text('app_version').notNull().default(''),
    /** Cihaz/oturum bağlamı: model, Android sürümü, ağ durumu, son olaylar. */
    context: jsonb('context').notNull().default({}),
    fatal: boolean('fatal').notNull().default(false),
    at: timestamp('at', { withTimezone: true }).notNull(),
    receivedAt: timestamp('received_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex('error_reports_id_uq').on(t.id)]
);

/** Soru bildirimleri (QIP Faz 6 · Part 13 — topluluk incelemesi). Anonim de olabilir (user_id null). */
export const questionReports = pgTable('question_reports', {
  id: text('id').primaryKey(), // uuid
  questionId: text('question_id').notNull(),
  kind: text('kind').notNull(), // wrong-answer | unclear | typo | suggestion | other
  message: text('message').notNull().default(''),
  userId: text('user_id'), // opsiyonel — oturum varsa
  status: text('status').notNull().default('open'), // open | resolved | dismissed
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

// ─────────────────────────────────────────────────────────────────────────────
// Topluluk (Evolution Faz E8) — kimlik, istatistik, sıralama, moderasyon.
//
// GİZLİLİK İLKESİ: katılım OPT-IN'dir (`visibility` varsayılan 'private') ve topluluk yüzeyleri
// ASLA e-posta, gerçek ad veya konum döndürmez. Görünen kimlik, kullanıcının seçtiği
// `displayName` ile bir avatardır.
//
// ⚠️ E8'DE ALINAN KARAR BETA FAZ 7'DE DEĞİŞTİ. E8, "kullanıcı fotoğrafı YÜKLENMEZ" diyordu; bu,
// bütün bir moderasyon/PII sınıfını baştan ortadan kaldırıyordu. Faz 7 fotoğraf yüklemeyi
// getiriyor, dolayısıyla o sınıf geri geliyor ve **aynı fazda** karşılanıyor:
//   · Yükleme İSTEĞE BAĞLIDIR — `avatarMediaId` null ise paketlenmiş maskot (`avatarId`) kullanılır.
//   · `avatar` zaten bir şikâyet sebebiydi (`communityReports.reason`); artık gerçek bir hedefi var.
//   · Yönetici bir avatarı kaldırabilir → satır maskota geri döner (veri silinmez, bağ koparılır).
//   · Yükleme yalnız DAR bir görsel türü kümesini kabul eder (SVG YOK — gömülü script riski).
// Play Veri Güvenliği beyanındaki "Fotoğraflar" satırı bu yüzden GÜNCELLENMİŞTİR
// (`PLAY_CONSOLE_SETUP.md` §5.6) — yanlış beyan mağazadan kaldırılma sebebidir.
// ─────────────────────────────────────────────────────────────────────────────

/** Topluluk kimliği. Satırın VARLIĞI katılım anlamına gelmez; görünürlük `visibility` ile belirlenir. */
export const communityProfiles = pgTable('community_profiles', {
  userId: text('user_id')
    .primaryKey()
    .references(() => users.id, { onDelete: 'cascade' }),
  displayName: text('display_name').notNull(),
  avatarId: text('avatar_id').notNull().default('owl-wave'),
  /// Beta Faz 7 — yüklenen profil fotoğrafı (`media_assets.id`). **null → maskot kullanılır.**
  /// Silme ON DELETE SET NULL: medya kaydı giderse profil maskota döner, satır kaybolmaz.
  avatarMediaId: text('avatar_media_id'),
  licence: text('licence').notNull().default('b'), // b | a | d
  visibility: text('visibility').notNull().default('private'), // private | public
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

/**
 * Sunucunun sahip olduğu istatistikler. İstemci ham sayaç bildirir; sunucu artışları
 * pencere başına SINIRLAR ve geri gidişi reddeder (anti-hile). `submittedXp` denetim için saklanır.
 */
export const communityStats = pgTable('community_stats', {
  userId: text('user_id')
    .primaryKey()
    .references(() => users.id, { onDelete: 'cascade' }),
  xp: integer('xp').notNull().default(0),
  streak: integer('streak').notNull().default(0),
  lessons: integer('lessons').notNull().default(0),
  exams: integer('exams').notNull().default(0),
  answered: integer('answered').notNull().default(0),
  accuracy: integer('accuracy').notNull().default(0), // 0..100 (tam sayı yüzde)
  /** İstemcinin son bildirdiği ham XP — kabul edilen değerle karşılaştırmak için (denetim). */
  submittedXp: integer('submitted_xp').notNull().default(0),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

/** Kazanılan rozetler (mobil `computeAchievements` ile aynı kimlikler). */
export const communityAchievements = pgTable(
  'community_achievements',
  {
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    achievementId: text('achievement_id').notNull(),
    earnedAt: timestamp('earned_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [primaryKey({ columns: [t.userId, t.achievementId] })]
);

/**
 * Haftalık sıralama anlık görüntüsü (sınıf başına). Hafta sınırı Europe/Istanbul'dur — bildirimlerde
 * de kullanılan tek saat dilimi kararı. Anlık görüntü ALINDIĞI ANDA dondurulur; böylece geçmiş hafta
 * sonradan değişmez.
 */
export const leaderboardSnapshots = pgTable(
  'leaderboard_snapshots',
  {
    id: text('id').primaryKey(), // `${weekStart}:${licence}`
    weekStart: text('week_start').notNull(), // YYYY-MM-DD (Europe/Istanbul pazartesi)
    licence: text('licence').notNull(),
    rows: jsonb('rows').notNull(), // [{userId, displayName, avatarId, xp}]
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex('leaderboard_week_licence_uq').on(t.weekStart, t.licence)]
);

/** Kullanıcı şikâyetleri — mağaza politikası gereği UGC'den ÖNCE devrede (E8). */
export const communityReports = pgTable('community_reports', {
  id: text('id').primaryKey(),
  /** Faz E9 — şikâyet hedefi: kullanıcı, birebir mesaj veya tartışma iletisi. */
  targetType: text('target_type').notNull().default('user'), // user | message | post
  /** Hedef içeriğin kimliği (kullanıcı şikâyetinde null). */
  targetRef: text('target_ref'),
  reporterId: text('reporter_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  targetUserId: text('target_user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  reason: text('reason').notNull(), // isim | avatar | taciz | spam | diger
  note: text('note').notNull().default(''),
  status: text('status').notNull().default('open'), // open | reviewed | dismissed
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

/** Engelleme — her okuma/yazma yolunda SUNUCUDA uygulanır (istemci filtresine güvenilmez). */
export const communityBlocks = pgTable(
  'community_blocks',
  {
    blockerId: text('blocker_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    blockedId: text('blocked_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [primaryKey({ columns: [t.blockerId, t.blockedId] })]
);

// ─────────────────────────────────────────────────────────────────────────────
// Sosyal grafik ve mesajlaşma (Evolution Faz E9)
//
// ENGELLEME İLKESİ (E8'den devam): engel HER okuma ve yazma yolunda SUNUCUDA kontrol edilir.
// Bu tablolar engeli kendileri saklamaz; `community_blocks` tek kaynaktır.
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Arkadaşlık. Tek satır iki kişiyi temsil eder; yön `requesterId` ile bellidir.
 * Durum: `pending` → `accepted`. Reddetme/kaldırma satırı SİLER (durum enflasyonu olmaz).
 */
export const friendships = pgTable(
  'friendships',
  {
    requesterId: text('requester_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    addresseeId: text('addressee_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    status: text('status').notNull().default('pending'), // pending | accepted
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    respondedAt: timestamp('responded_at', { withTimezone: true }),
  },
  (t) => [primaryKey({ columns: [t.requesterId, t.addresseeId] })]
);

/**
 * Birebir mesaj. `threadKey` iki kimliğin SIRALI birleşimidir (`min:max`) → aynı konuşma her iki
 * yönde de aynı anahtarı verir, ayrı bir "konuşma" tablosu gerekmez.
 */
export const directMessages = pgTable(
  'direct_messages',
  {
    id: text('id').primaryKey(),
    threadKey: text('thread_key').notNull(),
    senderId: text('sender_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    recipientId: text('recipient_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    body: text('body').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    readAt: timestamp('read_at', { withTimezone: true }),
  },
  (t) => [uniqueIndex('dm_thread_created_id_uq').on(t.threadKey, t.createdAt, t.id)]
);

/** Konu başlığı — ehliyet sınıfı topluluklarına göre kapsamlanır. */
export const discussionThreads = pgTable('discussion_threads', {
  id: text('id').primaryKey(),
  licence: text('licence').notNull().default('b'),
  title: text('title').notNull(),
  authorId: text('author_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  /** Soru paylaşımı REFERANSLADIR: yalnız bankadaki soru kimliği tutulur, metin KOPYALANMAZ. */
  questionRef: text('question_ref'),
  postCount: integer('post_count').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  lastActivityAt: timestamp('last_activity_at', { withTimezone: true }).notNull().defaultNow(),
});

/** Konu altındaki iletiler. */
export const discussionPosts = pgTable('discussion_posts', {
  id: text('id').primaryKey(),
  threadId: text('thread_id')
    .notNull()
    .references(() => discussionThreads.id, { onDelete: 'cascade' }),
  authorId: text('author_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  body: text('body').notNull(),
  questionRef: text('question_ref'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

// ─────────────────────────────────────────────────────────────────────────────
// Çalışma grupları ve meydan okumalar (Evolution Faz E10)
//
// BÜYÜME SINIRI: bu tabloların hiçbirinde sınırsız büyüme yolu YOKTUR — grup kurma, gruba katılma
// ve grup mevcudu tavanları sunucuda uygulanır (`lib/server/groups.ts`).
// ENGELLEME (E8/E9'dan devam): engel `community_blocks`'ta tek kaynaktır; grup listeleri de
// `social-guards` üzerinden süzülür. Bu tablolar engeli kendileri saklamaz.
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Çalışma grubu. `joinCode` insan tarafından okunup yazılabilen KISA koddur (karışabilen
 * karakterler alfabede yoktur) ve benzersizdir → davet bağlantısı/altyapısı gerektirmez.
 */
export const studyGroups = pgTable(
  'study_groups',
  {
    id: text('id').primaryKey(),
    name: text('name').notNull(),
    joinCode: text('join_code').notNull(),
    licence: text('licence').notNull().default('b'),
    ownerId: text('owner_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    /** Denormalize mevcut — mevcut tavanını her katılımda tek sorguda kontrol edebilmek için. */
    memberCount: integer('member_count').notNull().default(1),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex('study_groups_join_code_uq').on(t.joinCode)]
);

/** Grup üyeliği. `role` yalnız `owner` | `member`. */
export const studyGroupMembers = pgTable(
  'study_group_members',
  {
    groupId: text('group_id')
      .notNull()
      .references(() => studyGroups.id, { onDelete: 'cascade' }),
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    role: text('role').notNull().default('member'),
    joinedAt: timestamp('joined_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [primaryKey({ columns: [t.groupId, t.userId] })]
);

/**
 * Meydan okuma. **Sunucu tanımlıdır** — istemci meydan okuma OLUŞTURAMAZ; yalnız katılır.
 * İlerleme `community_stats`'tan (yani KIRPILMIŞ istatistiklerden) türetilir → hile yüzeyi yoktur.
 */
export const challenges = pgTable(
  'challenges',
  {
    id: text('id').primaryKey(),
    slug: text('slug').notNull(),
    title: text('title').notNull(),
    description: text('description').notNull().default(''),
    /** Hangi sayaç: xp | answered | lessons | exams */
    metric: text('metric').notNull(),
    target: integer('target').notNull(),
    /** null = bütün sınıflar */
    licence: text('licence'),
    startsAt: timestamp('starts_at', { withTimezone: true }).notNull(),
    endsAt: timestamp('ends_at', { withTimezone: true }).notNull(),
  },
  (t) => [uniqueIndex('challenges_slug_uq').on(t.slug)]
);

/**
 * Meydan okuma ilerlemesi. `baseline`, kullanıcı katıldığı ANDAKİ sayaç değeridir; ilerleme
 * `güncel - baseline` olarak hesaplanır → daha önce kazanılmış XP meydan okumayı anında bitiremez.
 */
export const challengeProgress = pgTable(
  'challenge_progress',
  {
    challengeId: text('challenge_id')
      .notNull()
      .references(() => challenges.id, { onDelete: 'cascade' }),
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    baseline: integer('baseline').notNull().default(0),
    joinedAt: timestamp('joined_at', { withTimezone: true }).notNull().defaultNow(),
    completedAt: timestamp('completed_at', { withTimezone: true }),
  },
  (t) => [primaryKey({ columns: [t.challengeId, t.userId] })]
);
