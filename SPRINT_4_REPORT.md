# SPRINT 4 TAMAMLAMA RAPORU — Ticaret, Yasal & Üretim Servisleri

_Tarih: 2026-07-15 · Tek doğru kaynak: `ROADMAP.md` (v3.1 — DEĞİŞTİRİLMEDİ; Faz 16 monetizasyon, 30 güvenlik, 31 gözlemlenebilirlik)_

> Bu sprint ürünü **ticari olarak dağıtılabilir** hâle getirdi: gerçek ödeme mimarisi, e-posta
> platformu, yasal/uyum sayfaları, üretim sağlamlaştırması ve premium deneyim. İçerik eklenmedi.

---

## Sonuç: ✅ TAMAMLANDI (gerçek tahsilat/e-posta için ENV kullanıcı aksiyonu bekliyor — aşağıda)

| Sprint 4 deliverable                  | Durum                                                                                                   |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Tek-seferlik ödeme mimarisi çalışıyor | ✅ LemonSqueezy adaptörü (ADR-008) + webhook (HMAC) + makbuz doğrulaması + idempotency; mock varsayılan |
| Premium sahiplik çalışıyor            | ✅ Entitlements + erişim kontrolü + kilitli dersler + kilit açma — canlıda uçtan uca doğrulandı         |
| E-posta platformu çalışıyor           | ✅ Resend adaptörü (ADR-009) + 5 şablon; kayıt/reset/satın alma/destek akışlarına bağlı                 |
| Yasal sayfalar tamam                  | ✅ Gizlilik · Kullanım Koşulları · Çerez Politikası · KVKK (taslak, gözden geçirme işaretli) + rıza     |
| Üretim sağlamlaştırması tamam         | ✅ Logger + rate-limit + retry + error/not-found sınırları + graceful degradation                       |
| CI yeşil                              | ✅ 130 unit/integration + 37 e2e + typecheck + build + gitleaks + CodeQL                                |
| Production deploy doğrulandı          | ✅ Canlı + **gerçek tarayıcı** (premium unlock, çerez rızası, yasal, API kapıları)                      |

---

## Epic 1 — Tek-Seferlik Ödeme (ADR-008 · LemonSqueezy)

**Değerlendirme:** LemonSqueezy vs Stripe → **LemonSqueezy** seçildi (Merchant of Record: Türkiye
KDV/e-fatura/iade yükünü üstlenir — solo satıcı için kritik; dijital-ürün odaklı; HMAC webhook).

- **`PaymentGateway`** soyutlaması (`lib/server/checkout.ts`): `MockGateway` (varsayılan) + `LemonSqueezyGateway`
  (ENV-kapılı). `getPaymentGateway()` fabrikası; ürün→variant ENV eşlemesi.
- **`POST /api/checkout`** — mock ise sunucu-grant, gerçek ise hosted checkout URL (redirect). Rate-limited.
- **`POST /api/webhooks/lemonsqueezy`** — HAM gövde **HMAC-SHA256 imza doğrulaması** (timingSafeEqual) →
  `order_created` ayrıştırma → **makbuz doğrulaması** (ürün + fiyat) → **idempotent** sahiplik (`external_ref`)
  → onay e-postası. Geçersiz imza 401, geçersiz makbuz 400, tanınmayan olay 200.
- **Fiyat-bütünlüğü:** fiyat her zaman sunucuda katalogdan doğrulanır. **Abonelik YOK.** Gelecek ürünlere açık.

## Epic 2 — E-posta Platformu (ADR-009 · Resend)

**Değerlendirme:** Resend vs Postmark vs SES → **Resend** (en iyi DX/başlangıç dengesi).

- **`EmailProvider`** soyutlaması (`lib/server/email.ts`): `ConsoleEmailProvider` (varsayılan; gitmez, loglanır) +
  `ResendEmailProvider` (ENV-kapılı, `withRetry`). Saf, test edilebilir şablonlar: **hoş geldin, doğrulama,
  parola sıfırlama, satın alma onayı, destek** (kullanıcı girişi HTML-escape).
- **Bağlantılar:** kayıt → hoş geldin + doğrulama; `POST /api/auth/verify` (gönder/onayla) + `/dogrula` sayfası;
  forgot → sıfırlama e-postası + `/sifirla` sayfası; satın alma → onay; `POST /api/support`.
- E-posta doğrulama tablosu + `users.email_verified`. Servis yokken **devToken** dürüst modu.

## Epic 3 — Yasal & Uyum

- **4 yasal sayfa** (marketing kabuğunda, `data-testid=legal-*`): **Gizlilik Politikası**, **Kullanım Koşulları**
  (tek-seferlik/ömür boyu; dijital içerik cayma istisnası), **Çerez Politikası**, **KVKK Aydınlatma Metni**
  (6698; m.5 hukuki sebepler, m.11 haklar). Hepsi **taslak** olarak işaretli; şirket/iletişim bilgileri
  **yer tutucu** — gerçek tüzel kişilik uydurulmadı; yayın öncesi hukukçu incelemesi notu her sayfada.
- **Çerez rıza bannerı** (gizlilik-öncelikli varsayılan: yalnız zorunlu) + **rıza yönetimi** (Ayarlar'dan aç/kapat).
- **Veri dışa aktarma** (JSON) + **hesap silme** (`DELETE /api/account`, KVKK m.7 — FK cascade ile tüm veri).
- Footer + Ayarlar'da yasal bağlantılar.

## Epic 4 — Üretim Sağlamlaştırması

- **Yapısal logger** (`lib/server/logger.ts`): prod'da tek-satır JSON, **sır redaksiyonu** (key/secret/token/…).
- **Hız sınırlama** (`lib/server/rate-limit.ts`): bellek-içi sabit-pencere; auth/checkout/support/webhook uçlarında;
  429 + `retry-after`. Çekirdek saf + birim testli. (Ölçekte Upstash/Redis adaptörü.)
- **Yeniden deneme** (`lib/retry.ts`): üstel geri çekilme (`withRetry`) — e-posta/ödeme dış çağrılarında.
- **Hata sınırları:** `app/error.tsx` (kurtarma) + `app/not-found.tsx` (404). **Graceful degradation:** `guarded()`
  DB yokken 503. Offline: PWA service worker (mevcut).

## Epic 5 — Premium Deneyim

- **`Lesson.premium`** şeması (geriye dönük uyumlu) + **`lib/entitlements.ts`** (`canAccessLesson`, yetenek→ürün eşleme).
- **`PremiumBadge`** (kilitli/sahip), **`PremiumLessonGate`** (istemci erişim kontrolü: teaser açık, derin içerik kilitli),
  **`PurchaseDialog`** (erişilebilir modal: odak tuzağı/Esc/scrim; satın al + geri yükle), **`checkoutClient`** (mock/redirect/misafir demo grant).
- **3 ileri ders premium** (park-manevra, kavşak-uygulama, sollama-şerit) → ilgili paket açar. **Güvenlik ve TÜM
  ilk yardım içeriği ASLA kilitlenmez** (etik ilke, kilit ekranında açıkça belirtilir). Dersler dizininde premium rozetleri.

## Test Kanıtı

- **130 unit/integration** (95 web + 35 paket). Yeni Sprint 4: `retry.test` (4), `rate-limit.test` (3),
  `email.test` (6), `checkout.test` (14), `entitlements.test` (6), **`api.commerce.integration.test` (8)** —
  checkout (mock/401/404), webhook grant + **idempotency** + makbuz reddi + ignore, e-posta doğrulama, hesap silme.
- **37 e2e** (7 spec; +5 Sprint 4 `commerce.spec`): yasal sayfalar, footer bağlantıları, **çerez rıza bannerı**,
  **premium kilitli→demo satın alma→kilit açılır**, ayarlar hesap/yasal. Hepsi production build üzerinde, CI'da.
- typecheck (9 paket) · build (29 sayfa + 20 API rotası) · gitleaks · **CodeQL** — yeşil.

## Production Canlı Doğrulama (gerçek tarayıcı, 2026-07-15)

| Yüzey                                   | Kanıt                                                                                                 |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Premium kilit (`/dersler/park-manevra`) | ✅ "🔒 Premium" başlık rozeti + teaser (görsel/kazanımlar) + "Bu ileri ders premium" kilit kartı      |
| Satın alma diyaloğu + demo unlock       | ✅ Modal (199₺, tek seferlik/ömür boyu, restore) → "Satın al" → **kilit kalktı, ders içeriği açıldı** |
| Çerez rıza bannerı                      | ✅ Görünür ("Yalnız zorunlu / Tümünü kabul et") → kabul → kayboldu                                    |
| Yasal (`/kvkk`)                         | ✅ Marketing kabuğunda; **taslak uyarısı + yer tutucu** ([Şirket Ünvanı]/[VKN]…); KVKK m.5/m.11       |
| API kapıları                            | ✅ `/api/checkout` & `/api/account` oturumsuz **401**; webhook geçersiz gövde güvenli                 |

## Kalan Dış Aksiyonlar (kullanıcı; kod hazır, ENV ile aktifleşir)

1. **Production DATABASE_URL** (Neon şartları — Sprint 1'den beri): hesap/satın alma/webhook yazımını canlıda açar.
2. `LEMONSQUEEZY_*` + variant (ADR-008): gerçek tahsilat. O gelene dek satın alma **demo modda** (etiketli).
3. **RESEND_API_KEY + EMAIL_FROM** (ADR-009): gerçek e-posta gönderimi. Yoksa console/devToken.
4. **Yasal metinler:** taslaklar bir **hukukçu** tarafından + gerçek şirket bilgileriyle sonlandırılmalı.

## Sprint 5 Adaylığı (ROADMAP sırası — BAŞLATILMADI)

Gözlemlenebilirlik (Sentry/Faz 31), güvenlik sertleştirme derinleşmesi (CSP/pen-test/Faz 30), gerçek AI model
adaptörü (Faz 22), ASO/mağaza (Faz 17), topluluk (Faz 32/33), platform zekâsı (Faz 35). **Sprint 4 sonrası
durduruldu — direktif gereği Sprint 5 başlatılmadı.**
