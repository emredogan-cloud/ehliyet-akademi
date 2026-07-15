# Ehliyet Akademi — Güvenlik İncelemesi (Security Review)

**Tarih:** 2026-07-15
**Kapsam:** Next.js 15 (App Router) tabanlı direksiyon sınavı hazırlık web uygulaması
**Teslimat:** Sprint 5 — ROADMAP Faz 30 çıktısı
**Doküman durumu:** Yaşayan doküman (living document). Herkese açık lansman (public launch) öncesinde yeniden gözden geçirilecektir.

Bu doküman, uygulamada **fiilen uygulanmış** güvenlik kontrollerini OWASP Top 10 (2021) kategorileriyle eşler; ayrıca bir girdi doğrulama denetimi ve bağımlılık denetimi bölümü içerir. Kısmi veya ertelenmiş kontroller açıkça belirtilmiştir; belge dürüstlük ilkesiyle yazılmıştır.

---

## 1. OWASP Top 10 (2021) Eşlemesi

| #   | Kategori                                                               | Genel Durum                  |
| --- | ---------------------------------------------------------------------- | ---------------------------- |
| A01 | Broken Access Control (Bozuk Erişim Kontrolü)                          | Uygulandı                    |
| A02 | Cryptographic Failures (Kriptografik Zafiyetler)                       | Uygulandı                    |
| A03 | Injection (Enjeksiyon)                                                 | Uygulandı                    |
| A04 | Insecure Design (Güvensiz Tasarım)                                     | Uygulandı                    |
| A05 | Security Misconfiguration (Güvenlik Yanlış Yapılandırması)             | Uygulandı                    |
| A06 | Vulnerable and Outdated Components (Zafiyetli/Eski Bileşenler)         | Kısmi — hijyen turu bekliyor |
| A07 | Identification and Authentication Failures (Kimlik Doğrulama Hataları) | Uygulandı                    |
| A08 | Software and Data Integrity Failures (Yazılım/Veri Bütünlüğü)          | Uygulandı                    |
| A09 | Security Logging and Monitoring Failures (Loglama/İzleme)              | Uygulandı                    |
| A10 | Server-Side Request Forgery (SSRF)                                     | Uygulandı                    |

### A01 — Broken Access Control (Bozuk Erişim Kontrolü)

- **Veritabanı destekli oturum (DB-backed session):** 256-bit rastgele oturum tokenı üretilir; sunucuda **yalnızca SHA-256 hash'i** saklanır (token'ın kendisi tutulmaz).
- **Çerez güvenliği:** Oturum çerezi `httpOnly` + `SameSite=Lax`, 30 günlük ömür.
- **Korumalı rotalar:** Kimlik gerektiren rotalarda `getSessionUser` ile oturum doğrulaması yapılır.
- **RBAC (Rol Tabanlı Erişim Kontrolü):** Tüm `/api/admin/*` uçlarında `requireRole` (user / editor / admin) uygulanır. Kimlik yoksa **401**, yetki yoksa **403** döner.
- **Admin kendini düşürme kilidi:** Bir admin'in kendini yetkisiz bırakmasını (self-demotion) önleyen koruma (lockout guard) mevcuttur.
- **Premium erişim kontrolü:** Entitlement (hak) tabanlıdır; **sunucu tarafındaki satın alma kaydı tek doğruluk kaynağıdır** (source of truth).
- **Public/guest yüzeyler:** Salt-okunur (read-only).

### A02 — Cryptographic Failures (Kriptografik Zafiyetler)

- **Parola saklama:** `node:crypto` **scrypt** KDF (N=16384, r=8, p=1, 64-byte çıktı, **kullanıcı başına rastgele salt**). Doğrulama `timingSafeEqual` ile yapılır (zamanlama saldırılarına karşı).
- **Tokenlar:** Oturum / parola sıfırlama / e-posta doğrulama tokenları 256-bit rastgeledir; sunucuda **yalnızca SHA-256 hash'i** saklanır.
- **Webhook imzaları:** **HMAC-SHA256** + `timingSafeEqual` ile doğrulanır.
- **Taşıma güvenliği:** **HSTS** başlığı (max-age 2 yıl, `preload`); çerezler production'da `Secure`.

### A03 — Injection (Enjeksiyon)

- **SQL enjeksiyonu:** **Drizzle ORM** ile parametreli sorgular kullanılır; string birleştirme (concat) ile SQL üretilmez.
- **Payload doğrulama:** Tüm içerik/API girdileri **Zod** ile doğrulanır (`validatePayload`, soru/ders şemaları).
- **XSS (Cross-Site Scripting):**
  - React tüm render edilen metni varsayılan olarak escape eder.
  - Tek `dangerouslySetInnerHTML` kullanımları (`mdBold` / `mdLite` — ders ve AI markdown'ı için) **önce `& < >` karakterlerini HTML-escape eder**, ardından yalnızca küçük bir kalın/link alt kümesini uygular → ham HTML enjeksiyonu mümkün değildir.
  - **CSP** ile ek kısıtlama: `object-src none`, `base-uri self`, `frame-ancestors none`.

### A04 — Insecure Design (Güvensiz Tasarım)

- **Sağlayıcı soyutlamaları (provider abstractions):** Ödeme / e-posta / AI / arama için soyutlama katmanı; **mock (sahte) varsayılanlar** ile gelir.
- **Fail-closed tasarım:** `guarded()`, DB yapılandırılmamışsa dostane bir **503** döner; asla stack trace sızdırmaz.
- **Fiyat bütünlüğü:** Fiyat, **sunucu tarafında katalogdan** zorlanır; istemciden gelen fiyata asla güvenilmez.
- **Tek seferlik satın alma modeli:** Yinelenen (recurring) faturalandırma yoktur → o saldırı yüzeyi hiç oluşmaz.

### A05 — Security Misconfiguration (Güvenlik Yanlış Yapılandırması)

- **`poweredByHeader: false`** (teknoloji ifşasını azaltır).
- **Tam güvenlik başlığı seti:** CSP, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy`, `Permissions-Policy`, HSTS, `X-DNS-Prefetch-Control`.
- **Secret tarama:** CI'da **gitleaks** ile sır (secret) taraması.
- **Sır yönetimi:** Sırlar yalnızca ortam değişkenlerinde (env) tutulur, asla commit edilmez; `.env*` git-ignore'da.
- **Env/secret doğrulama:** `checkEnv`, başlangıçta eksik production yapılandırması için uyarı verir.

### A06 — Vulnerable and Outdated Components (Zafiyetli ve Eski Bileşenler)

- **Minimal bağımlılık yüzeyi:** Ağır CMS/ödeme SDK'ları yerine sağlayıcı soyutlamaları kullanılır.
- **Dependabot** etkin.
- **CodeQL** statik analizi CI'da çalışır.
- **`pnpm audit`** çalıştırılır.
- **Durum notu (dürüst):** Dependabot'tan **9 adet major-bump PR'ı** açık; ayrı bir hijyen turuna bırakılmıştır. Bu durum belgelenmiştir — sessizce göz ardı edilmemektedir. (Bkz. Bölüm 4 ve 6.)

### A07 — Identification and Authentication Failures (Kimlik Doğrulama Hataları)

- **Özel credentials (kimlik bilgisi) akışı:** Güçlü **scrypt** KDF ile.
- **Rate limiting (hız sınırlama):** login / register / forgot / checkout / support / ai uçlarında sabit pencere (fixed-window); aşımda **429** + `Retry-After`.
- **Parola sıfırlama:** Sıfırlama, kullanıcının **TÜM oturumlarını ve tokenlarını** geçersiz kılar.
- **E-posta doğrulama akışı** mevcuttur.
- **Hesap sızıntısı önleme:** Forgot-password akışı hesabın var olup olmadığını sızdırmaz — her durumda "gönderildi" (always "sent") döner.

### A08 — Software and Data Integrity Failures (Yazılım ve Veri Bütünlüğü Hataları)

- **Webhook bütünlüğü:** Hak (entitlement) tanınmadan önce **HMAC imza doğrulaması** + **fatura/receipt doğrulaması** (ürün + fiyat eşleşmesi) + **idempotency** (`external_ref` ile) uygulanır.
- **İçerik bankası bütünlüğü:** İçerik **yükleme anında parse/validate edilir**; bozuk içerik build'i kırar.
- **CI/branch koruması:** CI'da zorunlu kontroller (required checks) + branch protection (force-push yok, linear history).

### A09 — Security Logging and Monitoring Failures (Güvenlik Loglama ve İzleme Hataları)

- **Yapısal logger:** Production'da JSON; **sır redaksiyonu** ile (key / secret / token / password / authorization / cookie alanları maskelenir).
- **Denetim kayıtları (`audit_logs`):** Her ayrıcalıklı admin/içerik işlemi için audit kaydı.
- **Gözlemlenebilirlik soyutlaması:** `captureException`, `SENTRY_DSN` ile Sentry'ye hazır.
- **Sağlık kontrolü:** `/api/health` health check ucu.

### A10 — Server-Side Request Forgery (SSRF)

- Uygulama yalnızca **sabit, kod içine gömülü (hardcoded)** sağlayıcı host'larına dışa çağrı yapar: `api.anthropic.com`, `api.resend.com`, `api.lemonsqueezy.com`.
- **Kullanıcı kontrollü URL'ler** sunucu tarafında **fetch edilmez**.
- Medya, uzak fetch ile değil, uygulamanın **kendi veritabanından** servis edilir.

---

## 2. CSRF (Cross-Site Request Forgery)

- **Çerez tabanlı temel savunma:** Oturum çerezi `SameSite=Lax`.
- **Origin-header kontrolü:** **Middleware**, tüm değiştirici (mutating) `/api/*` isteklerinde (POST/PUT/PATCH/DELETE) **same-origin** Origin başlığı kontrolü yapar; cross-origin isteklerde **403** döner.
- **Webhook istisnası:** Webhook'lar bu kontrolden muaftır — dış origin'den geldikleri için **HMAC** ile kimliği doğrulanır (Origin kontrolü yerine).

---

## 3. Girdi Doğrulama Denetimi (Input Validation Audit)

Anahtar uçlar ve uyguladıkları doğrulama:

| Uç (Endpoint)                     | Doğrulama                                     |
| --------------------------------- | --------------------------------------------- |
| register / login                  | E-posta format kontrolü + parola uzunluğu ≥ 8 |
| İçerik oluşturma (content create) | Zod `validatePayload` + slug regex            |
| Medya yükleme (media upload)      | MIME allowlist (izin listesi) + 2MB üst sınır |
| checkout                          | `productId` katalogda (∈ catalog) olmalı      |
| support                           | E-posta format kontrolü + minimum uzunluk     |
| AI ask                            | Minimum uzunluk + 500 karakter üst sınırı     |

**Genel not:** İstek gövdeleri (request body) `try/catch` içinde JSON olarak parse edilir; hatalı biçimli (malformed) gövde → **400**.

---

## 4. Bağımlılık Denetimi (Dependency Audit)

- **`pnpm audit`** denendi; npm'in eski `quick` denetim uç noktası kullanımdan kaldırıldığı için (HTTP 410) bulk uç noktasına geçilmelidir. Otomatik zafiyet taraması bu nedenle **CodeQL + Dependabot** (CI'da aktif) üzerinden sağlanır — tek nokta bağımlılık değildir.
- Bağımlılık yüzeyi minimaldir (ağır SDK'lar yerine sağlayıcı soyutlamaları).
- **Dependabot** ve **CodeQL** aktiftir.
- **9 adet major-bump PR'ı** beklemede; sprint ortasında kırıcı (breaking) değişiklik riskinden kaçınmak için **otomatik uygulanmamış**, ayrı bir hijyen turu için sıraya alınmıştır.

---

## 5. Bilinen Kısıtlar / Kalan İş (Known Limitations / Remaining Work)

Aşağıdaki maddeler açıkça bilinen kısıtlardır ve lansman öncesi değerlendirmeye tabidir:

- **CSP `'unsafe-inline'` kullanımı (script/style):** SSG (Static Site Generation) kısıtı nedeniyle — React inline stilleri, Next bootstrap script'i ve inline theme/JSON-LD script'leri gereği. **Nonce tabanlı CSP ertelendi**, çünkü dinamik render'ı zorunlu kılar ve SSG/CWV (Core Web Vitals) performansını olumsuz etkiler.
- **Rate limiting bellek-içi ve örnek (instance) başına:** Serverless ortamda örnekler arası paylaşılmaz. Ölçek için **Upstash/Redis adaptörü** planlanmaktadır.
- **WAF / sızma testi (pen-test) henüz yok.**
- **Yasal metinler şablon halinde:** Avukat incelemesi beklemektedir.
- **9 major-bump bağımlılık PR'ı:** Ayrı hijyen turunda ele alınacaktır (bkz. Bölüm 4 ve A06).

---

_Bu doküman yaşayan bir belgedir. Herkese açık lansman öncesinde tüm bölümler yeniden gözden geçirilecek; ertelenen kontroller (nonce tabanlı CSP, dağıtık rate limiting, WAF/pen-test, bağımlılık hijyen turu, yasal metin incelemesi) tekrar değerlendirilecektir._
