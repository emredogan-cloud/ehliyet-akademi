# FINAL PLATFORM AUDIT — Ehliyet Akademi

_Tarih: 2026-07-15 · Kapsam: Sprint 1–6 uçtan uca · Depo: `emredogan-cloud/ehliyet-akademi` (public) ·
Canlı: https://ehliyet-akademi-nine.vercel.app · Tek doğru kaynak: `ROADMAP.md` (v3.1)_

> **Dürüstlük ilkesi:** Bitmemiş iş "tamamlandı" olarak işaretlenmez. "Mimari hazır / ENV bekliyor"
> ile "canlı ve doğrulandı" AYRI kategorilerdir. Her kalan konu Kritik/Yüksek/Orta/Düşük sınıflandırılır.

---

## 1. Yöntem

Kod tabanı, testler, CI, canlı üretim (curl + gerçek tarayıcı), ve tüm dokümanlar gözden geçirildi.
Doğrulama kanıtı: 164 unit/integration + 44 e2e (production build, CI'da) · GitHub Actions + CodeQL yeşil ·
canlı tarayıcı doğrulaması her sprintte (konsol/CSP 0 hata).

## 2. Genel Verdict

- **🟢 GO — Public Beta (hesapsız/misafir deneyimi):** Öğrenme deneyimi canlı ve sağlam; ürün beta
  kullanıcı trafiği için hazır.
- **🟡 KOŞULLU — Ticari GA (para/hesap/veri):** Mimari tamam; canlı işlevsellik için ENV + hukuki/uzman
  onayları bekliyor (aşağıda Yüksek).
- **🔴 Henüz değil — "Premium V1.0" görsel iddiası:** Görsel katman minimal; `VISUAL_TRANSFORMATION_ROADMAP.md` yol haritası.

## 3. Boyut Bazlı İnceleme

| Boyut                  | Durum       | Not                                                                                                                        |
| ---------------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Mimari**             | 🟢          | Monorepo (pnpm+turbo), sağlayıcı soyutlamaları (ödeme/e-posta/AI/arama), Zod sözleşmeleri, çift-sürücü DB; temiz katmanlar |
| **CI/CD**              | 🟢          | Actions yeşil (quality/e2e/gitleaks/CodeQL) + branch protection + Conventional Commits + Changesets                        |
| **Deployment**         | 🟢          | Vercel prod canlı; tek komut; e2e production build üzerinde (CI-birebir); canlı doğrulama disiplini                        |
| **Auth**               | 🟢 (mimari) | scrypt + DB oturum + RBAC + reset/verify; **prod'da DATABASE_URL yok → uçlar 503** (Yüksek #H1)                            |
| **Database**           | 🟢 (mimari) | Drizzle + PGlite(yerel)/Postgres(prod); idempotent bootstrap; prod bağlantısı bekliyor (Yüksek #H1)                        |
| **Commerce**           | 🟢 (mimari) | LemonSqueezy adaptörü + HMAC webhook + makbuz + idempotency; gerçek tahsilat ENV bekliyor (Yüksek #H2)                     |
| **CMS / Admin**        | 🟢 (mimari) | Şema-öncelikli çekirdek + iş akışı + denetim + RBAC; yazma uçları DATABASE_URL bekliyor                                    |
| **AI**                 | 🟢          | Sunucu grounded + halüsinasyon kapısı + eval %100; gerçek model ENV ile (mock=0 halüsinasyon)                              |
| **Analitik**           | 🟢 (mimari) | Rıza-kapılı sağlayıcı katmanı; **gerçek sağlayıcı yok → üretim telemetrisi henüz yok** (Orta #M7)                          |
| **Gözlemlenebilirlik** | 🟢 (temel)  | /api/health + captureException (Sentry-hazır) + logger; **Sentry DSN yok → aktif izleme yok** (Orta #M7)                   |
| **Güvenlik**           | 🟢          | CSP + başlıklar + CSRF + rate-limit + secrets validation + OWASP review; kalanlar Orta (#M1/#M2)                           |
| **Performans**         | 🟢 (temel)  | SSG, ~103 kB paylaşımlı JS, code-split, streaming; Lighthouse-CI kapısı yok (Orta #M5)                                     |
| **Erişilebilirlik**    | 🟢 (temel)  | Semantik, aria, kontrast, skip-link, reduced-motion; otomatik axe-regresyon kapısı yok (Orta #M5)                          |
| **SEO**                | 🟢 (temel)  | JSON-LD + sitemap + robots + metadata; programatik/pillar içerik ölçeği kalan                                              |
| **Öğrenme deneyimi**   | 🟢          | 19 ders + 198 soru + SRS + deneme + AI koç + çalışma planı + oyunlaştırma — canlı                                          |
| **İçerik kalitesi**    | 🟡          | Özgün + kaynak-izli; **tümü review:draft**; ilk yardım uzman onayı kritik (Yüksek #H3); derinlik (Orta #M3)                |
| **Görsel kalite**      | 🟡          | 12 erişilebilir SVG + emoji; fotoğraf/illüstrasyon/animasyon sistemi yok → premium değil (Orta #M6)                        |
| **Dokümantasyon**      | 🟢          | README/STATUS/MEMORY/CHANGELOG + 11 ADR + ENV + SECURITY_REVIEW + 6 sprint + 3 FINAL rapor; güncel                         |

## 4. Sınıflandırılmış Konu Kaydı

### 🔴 Kritik (0)

Şu an temel işlevi bozan veya veri güvenliğini tehlikeye atan **kritik konu yoktur**. (Misafir akışları
tam çalışır; hesap/ticaret uçları hata değil, bilinçli "yapılandırma bekliyor" 503 döner.)

### 🟠 Yüksek

- **#H1 — Production DATABASE_URL bağlı değil.** Hesap, satın alma kaydı, CMS/admin yazma ve webhook
  kalıcılığı üretimde çalışmaz (bilinçli 503). _Neden yüksek:_ ticari/kişiselleştirilmiş özellikler
  canlıda kapalı. _Aksiyon:_ Neon şartlarını kabul + `vercel integration add neon` (kullanıcı aksiyonu;
  şema ilk bağlantıda kurulur). **Bir kod değişikliği gerekmez.**
- **#H2 — Gerçek tahsilat/e-posta kapalı.** `LEMONSQUEEZY_*` ve `RESEND_API_KEY` yok → ödeme demo modda,
  e-posta console/devToken. _Neden yüksek:_ gelir ve işlemsel iletişim canlı değil. _Aksiyon:_ ENV + hesap kurulumu.
- **#H3 — İlk yardım içeriği uzman onayı yok.** İçerik `review:draft` + uyarı etiketli, ancak tıbbi doğruluk
  bir ilk yardım eğitmeni tarafından onaylanmadan güvenle SUNULMAMALI. _Neden yüksek:_ yanlış tıbbi bilgi
  zarar potansiyeli. _Aksiyon:_ uzman inceleme döngüsü (içerik hattı Sprint 2'de hazır; `review:approved`).
- **#H4 — Yasal metinler taslak/hukukçu onayı yok.** Gizlilik/KVKK/Kullanım/Çerez sayfaları yer-tutuculu
  taslak. _Neden yüksek:_ kişisel veri toplama + ticaret öncesi hukuki zorunluluk. _Aksiyon:_ avukat incelemesi ve gerçek şirket bilgileri.

### 🟡 Orta

- **#M1 — CSP `'unsafe-inline'` (script/style).** SSG kısıtı; nonce-tabanlı CSP dinamik render gerektirir
  (SSG/CWV bozar). _Azaltma:_ tüm HTML enjeksiyonu escape'li, object/base/frame kısıtlı. _İyileştirme:_ ölçekte nonce.
- **#M2 — Rate limiting bellek-içi (serverless örnek-başına).** Global zorlanmaz. _İyileştirme:_ Upstash/Redis adaptörü.
- **#M3 — İçerik derinliği.** 198 soru/82 konu sağlam ama "100+/konu" hedefinin altında; tekrar denemelerde
  çeşitlilik sınırlı. _İyileştirme:_ içerik hattıyla + uzman onayıyla büyütme.
- **#M4 — AI retrieval basit heuristik.** Önek-token eşleşmesi; parafraz/eş anlamlıda ıskalayabilir.
  _İyileştirme:_ gömme (embedding) tabanlı geri-getirme (aynı arayüz).
- **#M5 — Otomatik kalite kapıları eksik.** Lighthouse-CI, axe a11y-regresyon, görsel-regresyon zorunlu-check değil.
  _İyileştirme:_ CI'a ekle.
- **#M6 — Görsel katman minimal.** Fotoğraf/illüstrasyon/animasyon sistemi yok. _İyileştirme:_ `VISUAL_TRANSFORMATION_ROADMAP.md`.
- **#M7 — Üretim telemetrisi/izleme yok.** Analitik + Sentry mimari hazır ama anahtar yok → veri akmıyor.
  _İyileştirme:_ ENV (rıza-kapılı analitik + SENTRY_DSN).
- **#M8 — Dependabot 9 major-bump PR bekliyor.** Bağımlılıklar geride kalabilir. _İyileştirme:_ ayrı hijyen turu.

### 🟢 Düşük

- **#L1 — `/calis?mod=tekrar` ayrı bir mod değil** (adaptif seçim zaten tekrarları önceliklendirir); parametre no-op.
- **#L2 — CI'da Node 20 deprecation uyarısı** (checkout/gitleaks aksiyonları Node 24'e zorlanıyor) — kozmetik.
- **#L3 — `ehliyet-akademi.vercel.app` yalın adı başka projeye ait** — kanonik `-nine`; özel domain ile çözülür.
- **#L4 — Global lider tablosu + arkadaş sistemi mimari-düzeyde** (backend gerektirir) — dürüstçe "gelecek" etiketli.
- **#L5 — Bazı e2e testleri storageState rıza tohumuna bağlı** — test altyapısı, ürün değil.

## 5. Version 1.0 (GA) için gerekenler — öncelik sırasına göre

1. **#H1** DATABASE_URL bağla → hesap/ticaret/CMS canlı.
2. **#H4 + #H3** Yasal metin hukukçu onayı + ilk yardım uzman onayı (yayın öncesi zorunlu).
3. **#H2** Gerçek ödeme + e-posta ENV → gelir + işlemsel iletişim.
4. **#M7** Analitik + Sentry ENV → üretim gözlemi (rıza-kapılı).
5. **Görsel dönüşüm** (`VISUAL_TRANSFORMATION_ROADMAP.md` Faz V1 P0 kalemleri) → premium ilk izlenim.
6. **#M3** İçerik derinliği + uzman onay döngüsü; **#M5** otomatik kalite kapıları.

## 6. Sonuç

Platform **teknik olarak sağlam, test-korumalı, CI-güvenceli ve canlı**. Çekirdek öğrenme ürünü beta
kullanıcı trafiği için hazırdır (GO). Ticari GA ve "premium V1.0" için kalan iş nettir ve büyük ölçüde
**yapılandırma/onay** (kod değil) + **görsel dönüşüm**tür. Hiçbir kalan iş "tamamlandı" olarak
işaretlenmemiştir; her biri yukarıda dürüstçe sınıflandırılmıştır.
