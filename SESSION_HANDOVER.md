# Oturum Devir Belgesi

**Yazıldı:** 2026-07-26 (Beta Faz 3 sonu) · **Neden:** proje yalnız diskten sürdürülebilmeli.
**Bu belgedeki hiçbir bilgi sohbet geçmişine bağlı değildir.**

---

## 1. Proje durumu — tek bakışta

| Alan                  | Değer                                                                                                                           |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Proje                 | Ehliyet Akademi — Türkiye ehliyet sınavı hazırlık uygulaması                                                                    |
| Yapı                  | pnpm monorepo · `apps/web` (Next.js/Vercel) · `apps/mobile` (Flutter) · `packages/{db,content-schema,question-bank,srs-engine}` |
| Uygulama kimliği      | `com.ehliyetegitim.ehliyet_akademi` — **yayından sonra DEĞİŞTİRİLEMEZ**                                                         |
| Sürüm                 | `1.0.0+1`                                                                                                                       |
| Üretim                | https://www.ehliyetegitim.com (Vercel, canlı)                                                                                   |
| **Önceki program**    | **Evolution E1–E13 — TAMAMLANDI.** Dokunulmaz, yeniden başlatılmaz                                                              |
| **Aktif program**     | **Beta Readiness** — Google Play Kapalı Test (12 test kullanıcısı)                                                              |
| **Tamamlanan fazlar** | **0–12 · düzeltme fazları R1, R2, R3**                                                                                          |
| **Sıradaki faz**      | **13 — Nihai yayın denetimi**                                                                                                   |

## 2. Git durumu

| Alan          | Değer                                                        |
| ------------- | ------------------------------------------------------------ |
| Dal           | `main`                                                       |
| Son commit    | **Beta R2 — Onboarding doluluğu** (bu belgeyi içeren commit) |
| Çalışma ağacı | temiz                                                        |
| CI            | CI ✅ · Mobile CI ✅ · CodeQL ✅                             |

> `Mobile CI` yalnız `apps/mobile/**` değiştiğinde çalışır. Yalnız belge değiştiren commit'lerde
> tetiklenmemesi **beklenen** davranıştır, hata değildir.

Faz 3 öncesi commit'ler (yeniden eskiye):

```
3471378 docs: BAĞLAM KONTROL NOKTASI — proje yalnız diskten sürdürülebilir
21fac08 docs(beta): Faz 2 raporu + proje belleği
bb27882 feat(auth): Beta Faz 2 — Google ile giriş (sunucu doğrulamalı)
21b9fd9 docs(beta): Faz 1 — tam varlık denetimi tamamlandı
9efb20c docs(beta): Faz 0 — yayın hazırlığı belgeleri (9 dosya)
c2e4887 feat(mobile): Evolution E13 — cila, varlık optimizasyonu ve PROGRAM KAPANIŞI
```

## 3. Test sayıları — ÖLÇÜLDÜ (2026-07-26, Faz 3 sonu)

| Paket                         | Sonuç                                                   |
| ----------------------------- | ------------------------------------------------------- |
| `flutter analyze`             | **0 sorun**                                             |
| `flutter test`                | **355 geçti**                                           |
| `@ea/web`                     | **541 geçti** (Faz 7'de +25)                            |
| `@ea/db`                      | **6 geçti**                                             |
| `@ea/content-schema`          | **17 geçti**                                            |
| `@ea/question-bank`           | **10 geçti**                                            |
| `@ea/srs-engine`              | **12 geçti**                                            |
| `pnpm lint`                   | 0 hata (1 uyarı — Next eslint eklentisi notu, zararsız) |
| `pnpm format` · `pnpm verify` | temiz                                                   |
| `pnpm typecheck`              | 9/9 başarılı                                            |

**Komutlar:**

```bash
cd apps/mobile && flutter analyze && flutter test     # PATH: /home/emre/dev/flutter/bin
cd <repo> && pnpm test && pnpm lint && pnpm format && pnpm verify && pnpm typecheck
cd apps/web && npx playwright test                    # içerik değiştiyse ŞART
```

> `pnpm test` turbo önbelleği kullanır. **Ölçülmüş sayı** istiyorsan `pnpm test --force`.

## 4. Mevcut mimari — özet

**Değişmeyen omurga (program boyunca korunuyor):** Riverpod · go_router · dio · drift ·
arayüz/uygulama ayrımı · tek kaynaklı tasarım token'ları → `ThemeData` · `@ea/db` çift sürücü
(PGlite test / Postgres üretim) · `guarded`/`json`/`checkRateLimit` sunucu yardımcıları ·
Bearer oturum.

**Yerleşik desenler (bozulmamalı):**

1. **Platforma bağlı her şey arayüz + uygulama** — `CommunityApi`, `SocialApi`, `GroupsApi`,
   `PlaybackController`, `GoogleAuthService`, **`BillingGateway`**. Widget testleri sahte
   uygulamayla, platform kanalı olmadan çalışır.
2. **Saf kural katmanı ekrandan/uçtan ayrı** — `apps/web/lib/server/*.ts` ve
   `apps/mobile/lib/domain/**` (Faz 3'te **`entitlement_status.dart`** eklendi). Doğrudan test edilir.
3. **Engelleme tek modülde** — `apps/web/lib/server/social-guards.ts`.
4. **Türetilen içerik tek kaynaktan** — `apps/web/scripts/video-scenes.mjs`.
5. **Dürüstlük testle zorunlu** — `design_tokens_test.dart` (sabit renk yasağı),
   `videos.test.ts` (animasyon etiketi), `pnpm verify` (yer tutucu/sır taraması).

**Faz 3'te eklenen ödeme katmanı:**

```
BillingGateway (arayüz, eklenti türü sızdırmaz)
 ├── PlayBillingGateway  → IapService'i SARAR (dosyaya dokunulmadı) · köprü: clientReceipt
 └── RevenueCatGateway   → purchases_flutter 10.4.3 · köprü: revenueCatWebhook
billingGatewayProvider: REVENUECAT_PUBLIC_KEY varsa RevenueCat, yoksa mevcut yol
```

## 5. Yayın durumu ve ENGELLER

| #      | Engel                                              | Durum                                  | Faz      |
| ------ | -------------------------------------------------- | -------------------------------------- | -------- |
| **B1** | Release imzalama                                   | ✅ **KAPANDI** (upload key)            | 4        |
| **B2** | Gradle şablon yer-tutucuları                       | ✅ **KAPANDI**                         | 4        |
| **B3** | Google Sign-In yok                                 | ✅ **KAPANDI**                         | 2        |
| **B4** | RevenueCat yok                                     | ✅ **KAPANDI** (istemci tarafı)        | 3        |
| **B5** | Üretim veritabanında Evolution doğrulama artıkları | ⛔ AÇIK — **kullanıcı onayı bekliyor** | 13       |
| **B6** | Play Console kaydı/beyanları yok                   | ⛔ AÇIK — **elle**, belgeler hazır     | 4 → elle |

**B1 nasıl kapandı:** `build.gradle.kts` release bloğu `android/key.properties`'ten gerçek upload
key'i okuyor. Anahtar yoksa **debug'a düşmez**, release derlemesi dürüst hatayla durur (debug
derlemesi ve CI etkilenmez). Sertifika SHA-1/SHA-256 `keytool` çıktısıyla birebir aynı.

**⚠️ Google girişi HENÜZ ÇALIŞMAZ:** `google-services.json` eklendi ama `oauth_client` dizisi
**boş** → Firebase'e SHA eklenmemiş ve Web istemcisi (`GOOGLE_SERVER_CLIENT_ID`) yok.
Adımlar: `GOOGLE_AUTH_SETUP.md` §9.5. Gereken SHA'lar §3.2'de ölçülü hâlde duruyor.

**B4 notu:** istemci tarafı tamam. RevenueCat **panosu** kurulumu (hesap, ürünler, servis hesabı,
Pub/Sub, entitlement, offering) elle yapılacaktır — `REVENUECAT_SETUP.md` §7. Ayrıca **sunucu
tarafı RevenueCat webhook'u yazılmadı**; gerekçesi `BETA_PHASE_3_REPORT.md` §8.3.

**B5 uyarısı:** üretim veritabanı temizliği **geri alınamaz bir işlemdir**; bilinçli olarak
yapılmadı ve kullanıcı onayına bırakıldı. **Onay almadan silme.**

## 6. Ortam gereksinimleri

**Geliştirme makinesi:**

```bash
export PATH="$PATH:/home/emre/dev/flutter/bin"   # Flutter 3.41.9 · Dart 3.11.5
# Node 24.13.1 · pnpm 10.33.4 · ffmpeg · Playwright (kurulu) · ImageMagick
# cwebp YOK — webp yeniden sıkıştırma yapılamıyor (bilinen kısıt)
```

### ⚠️ CİHAZ SABİT DEĞİL — İKİ TELEFON DÖNÜŞÜMLÜ

Bu oturumda **iki farklı cihaz** dönüşümlü takıldı. **Sabit kimlik varsaymayın.**

| Kimlik             | Model             | Android | Ekran               | Kullanıldığı faz |
| ------------------ | ----------------- | ------- | ------------------- | ---------------- |
| `AYXSUKIVJVPZ7HPZ` | Redmi M1908C3JGG  | **11**  | 1080×2340 · 440 dpi | Evolution, **5** |
| `jfzxugsgnnvsrsg6` | Xiaomi 22095RA98C | **13**  | 1080×2408 · 440 dpi | **3, 4**         |

İkisi de arm64-v8a · ~393 dp genişlik. Birlikte **Android 11 + 13** kapsamı veriyorlar.

**Her fazın başında `adb devices -l` ile doğrula.** Yardımcı betikte cihazı otomatik algıla:

```bash
D1=$(adb devices | grep -w device | head -1 | cut -f1)
```

`MOBILE_ENGINEERING_DISCIPLINE.md` kural 6'daki tek sabit kimlik artık geçerli değildir; o dosya
bilinçli olarak değiştirilmedi (ona yalnız kural eklenir).

**Cihaz dersleri:** ekran kapalıysa `screencap` siyah kare döndürür → önce
`input keyevent KEYCODE_WAKEUP`. Uzun derleme/kurulum sırasında cihaz **kilitlenebilir**;
uyandırmak yetmez, ayrıca `input swipe 540 1900 540 600` ile kilit açılmalı.

Yardımcı betikler scratchpad'dedir ve **yeniden başlatmada silinir**; gerekirse yeniden yazılır.

## 7. `.env` gereksinimleri

**Depoda gerçek gizli değer YOKTUR.** Şablonlar: `apps/web/.env.example` ve
**`apps/mobile/.env.example`** (Faz 3'te eklendi) — **örnek değer bile yazılmaz**, yalnız boş
anahtar + açıklama. Tam liste: `ENV_TEMPLATE.md`.

> **Faz 3'te düzeltilen açık:** `.env.example` şablonları `.gitignore` yüzünden depoya **hiç
> girmemişti** (`.env*` kalıbı `!.env.example` istisnasını geçersiz kılıyordu). İkisi de artık
> izleniyor. **Yeni bir şablon dosyası eklerken `git check-ignore -v <dosya>` ile doğrula.**

**Sunucu (Vercel):** `DATABASE_URL` (zorunlu) · `GOOGLE_SERVER_CLIENT_ID` (**WEB** istemci
kimliği) · `ANTHROPIC_API_KEY` · `RESEND_API_KEY` · LemonSqueezy anahtarları ·
`GOOGLE_PLAY_SA_JSON` · (webhook yazılırsa) `REVENUECAT_SECRET_KEY`.
**Üretimde ASLA ayarlanmaz:** `IAP_DEV_ACCEPT`, `RATE_LIMIT_DISABLED`.

**Mobil (derleme zamanı `--dart-define`):** `GOOGLE_SERVER_CLIENT_ID` · `REVENUECAT_PUBLIC_KEY` ·
`REVENUECAT_PROJECT_ID` · `REVENUECAT_ENTITLEMENT` · `REVENUECAT_MONTHLY_PRODUCT` ·
`REVENUECAT_YEARLY_PRODUCT` · `API_BASE_URL`.

**Kural:** hiçbiri zorunlu değildir — verilmezse uygulama **çökmez**, ilgili yüzey dürüst bir
"yapılandırılmadı" durumu gösterir. Bu davranış testle korunuyor.

## 8. Bekleyen ELLE kurulum (kod yapamaz)

1. Google Play geliştirici hesabı (25 USD) + kimlik doğrulama
2. Upload key üretimi → `android/key.properties` (**Git dışı**) — Faz 4 kodlayacak
3. Firebase projesi + Android uygulaması + **üç SHA** (debug · upload · **Play App Signing**) +
   `google-services.json`
4. OAuth onay ekranı + test kullanıcıları
5. RevenueCat hesabı + Play ürünleri + servis hesabı + Pub/Sub bildirimleri + entitlement/offering
6. Play Console: uygulama, beyanlar, mağaza varlıkları (simge 512², **Öne Çıkan Grafik 1024×500**,
   2+ ekran görüntüsü)
7. Gizlilik politikası sayfası + URL
8. İncelemeci test hesabı — **çalıştığı sınanmalı** (girilemezse kesin ret)
9. Üretim veritabanı temizliği (B5) — **onay bekliyor**

**⚠️ EN KRİTİK:** Play App Signing SHA'sı **kapalı teste ilk yüklemeden sonra** görünür.
Firebase'e eklenmezse **Play'den kurulan yapıda Google girişi ÇALIŞMAZ**.

## 9. Cihaz doğrulama durumu

| Faz       | Doğrulandı mı | Not                                                                                        |
| --------- | ------------- | ------------------------------------------------------------------------------------------ |
| Faz 0, 1  | —             | Kod yok, cihaz gerekmedi                                                                   |
| **Faz 2** | ✅            | İki derleme: `--dart-define` olmadan → Google düğmesi YOK; ile → düğme var (eski cihazda)  |
| **Faz 3** | ✅            | İki derleme: anahtarsız → mevcut yol; **geçersiz anahtarlı → RevenueCat seçildi, çökmedi** |

**Faz 3'ün kanıt yöntemi (kaydedilmeye değer):** iki derleme **görsel olarak aynı** görünüyordu;
hangi kod yolunun çalıştığı **`logcat`** ile kanıtlandı (`PurchasesFactory.createPurchases` +
`InvalidCredentialsError` + `logcat -b crash` boş).

**Faz 3'te doğrulanamayan:** gerçek satın alma (Play Billing yalnız Play'den yüklenmiş imzalı
yapıda çalışır) ve gerçek RevenueCat anahtarıyla uçtan uca akış.

## 10. Bilinen sınırlar

**Altyapıya bağlı:** gerçek zamanlı yok (WebSocket yok, kısa yoklama) · push bildirimi yok
(FCM yok) · **iOS N/A** (macOS yok) · gerçek Play satın alma yalnız Play'den yüklenmiş yapıda
çalışır · haftalık devir tembel (cron yok) · meydan okumalar otomatik dönmez.

**Kapsam kararı:** PiP yok · çevrimdışı video indirme yok · video sesi yok · iki video hâlâ
`planned` · moderasyon reaktif · golden test yok.

**Ölçülemeyen:** kare düzeyinde jank — `dumpsys gfxinfo` Flutter için 0 kare döndürüyor.
Faz 13'te `--profile` derlemesiyle denenecek. **Uydurma sayı raporlanmadı ve raporlanmamalı.**
Ayrıca **RevenueCat'in APK boyutuna tek başına katkısı ölçülmedi** (karşılaştırma tabanı Faz 2
öncesineydi) ve tahmin edilmedi.

**Teknik borç:** `assets/vehicle` (11 MB, web) yeniden sıkıştırılmadı (`cwebp` yok) ·
`BETA_PHASE_0/1_REPORT.md` yazılmadı (bilinçli) · sunucu tarafı RevenueCat webhook'u yazılmadı
(secret key + genel URL yok).

## 11. Faz 9 için ÖLÇÜLMÜŞ zemin

**DoD'nin istediği ölçüm Faz 8 sonunda yapıldı** (tekrarlamaya gerek yok):

| Ölçüt                            | Sonuç                                            |
| -------------------------------- | ------------------------------------------------ |
| `/api/ai/ask` akış desteği       | **YOK** — düz JSON POST                          |
| SSE / `ReadableStream` / `chunk` | Kod tabanında **hiç yok**                        |
| Anthropic çağrısı                | `lib/server/ai.ts:90` — **ham `fetch`**, SDK yok |

Gerçek akış kurulabilir (Anthropic SSE destekliyor, araya girmek kolay). **Mevcut uç
bozulmamalı** — Faz 3'teki "mevcut yol sökülmez" kalıbı izlenmeli.

⚠️ **Anlık yanıt ASLA sahte akış gibi gösterilmez** — gecikme uydurulmaz (dürüstlük disiplini).

## 11b. Faz 5 için hazır olan zemin

Faz 5 = **giriş ekranı yeniden tasarımı**. Girdiler `ASSET_GENERATION_LIBRARY.md` §4.2'de hazır:

- `apps/assets/interface-assets/022-assets.png` (1536×1024) **hero olarak sevk edilir** →
  1080×720 WebP. ⚠️ **Renault logosu okunuyor** — rötuşlanmalı veya markasız varyant üretilmeli.
- `023-assets.png` ve `024-assets.png` **arayüz mockup'ıdır**, raster sevk **EDİLMEZ** →
  widget olarak uygulanır (gömülü metin temaya uymaz, yazı tipi ölçeğiyle büyümez, çevrilemez).
- **"Apple ile giriş" KONMAZ** — iOS yok, çalışmayan düğme ölü gezinmedir (disiplin kural 3).
- **"MEB müfredatına uygun"** ifadesi doğrulanabilir bir iddiadır; kaynak gösterilemiyorsa
  kullanılmaz.
- Mevcut tasarım sistemi korunur; `design_tokens_test.dart` sabit renk kullanımını engelliyor.

**Faz 4'ten devreden uyarılar:**

- `pnpm verify` `.md` dosyalarında yasaklı kalıp tarıyor — kanıt alıntılarken dikkat (Faz 0 dersi).
- Yeni dosya eklerken `git check-ignore -v` ile gerçekten istenen sonucu doğrula (Faz 3/4 dersi).
- Commit öncesi **izlenmeyen dosyaları** da gözden geçir: `git status` yalnız senin
  değiştirdiklerin değildir (Faz 4'te 12 MB varlık ve `google-services.json` böyle yakalandı).

## 12. Belge haritası

| Belge                              | İçerik                                                                    |
| ---------------------------------- | ------------------------------------------------------------------------- |
| `MOBILE_ENGINEERING_DISCIPLINE.md` | **Değişmez kurallar** — her fazdan önce okunur                            |
| `MOBILE_PROJECT_MEMORY.md`         | **Ekleme-only** mühendislik belleği; sonunda Beta kontrol noktası + Faz 3 |
| `MOBILE_EVOLUTION_FINAL_REPORT.md` | Evolution E1–E13 kapanışı                                                 |
| `BETA_READINESS_ROADMAP.md`        | Beta 13 fazı + ilerleme işaretleri                                        |
| `RELEASE_CHECKLIST.md`             | Her yükleme öncesi kapı listesi                                           |
| `GOOGLE_AUTH_SETUP.md`             | Firebase + Google Sign-In sıfırdan                                        |
| `PLAY_CONSOLE_SETUP.md`            | Play Console sıfırdan + beyanlar (**Faz 4 kaynağı**)                      |
| `REVENUECAT_SETUP.md`              | RevenueCat sıfırdan                                                       |
| `CLOSED_TEST_GUIDE.md`             | 12 test kullanıcısı akışı                                                 |
| `ENV_TEMPLATE.md`                  | Ortam değişkenleri                                                        |
| `ASSET_GENERATION_LIBRARY.md`      | 19 görsel + üretime hazır promptlar                                       |
| `RELEASE_AUDIT_PLAN.md`            | Faz 13 denetim planı                                                      |
| `BETA_PHASE_2_REPORT.md`           | Faz 2 raporu                                                              |
| `BETA_PHASE_3_REPORT.md`           | Faz 3 raporu                                                              |
| `NEXT_SESSION_START.md`            | **Yeni oturumun ilk okuyacağı belge**                                     |
