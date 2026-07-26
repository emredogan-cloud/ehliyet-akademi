# Oturum Devir Belgesi

**Yazıldı:** 2026-07-26 · **Neden:** oturum sonlanıyor, bilgisayar yeniden başlatılacak, yeni bir
Claude oturumu sıfırdan devralacak. **Bu belgedeki hiçbir bilgi sohbet geçmişine bağlı değildir.**

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
| **Tamamlanan fazlar** | **0, 1, 2**                                                                                                                     |
| **Sıradaki faz**      | **3 — RevenueCat**                                                                                                              |

## 2. Git durumu

| Alan          | Değer                                                                  |
| ------------- | ---------------------------------------------------------------------- |
| Dal           | `main`                                                                 |
| Son commit    | **`21fac08`** — `docs(beta): Faz 2 raporu + proje belleği`             |
| Son push      | `21fac08` → `origin/main` (gönderildi)                                 |
| Çalışma ağacı | **temiz**                                                              |
| Son yeşil CI  | `21fac08` → CI ✅ CodeQL ✅ · `bb27882` → CI ✅ Mobile CI ✅ CodeQL ✅ |

> `Mobile CI` yalnız `apps/mobile/**` değiştiğinde çalışır; `21fac08` yalnız belge değiştirdiği
> için orada tetiklenmedi. Bu **beklenen** davranıştır, hata değildir.

Son commit'ler (yeniden eskiye):

```
21fac08 docs(beta): Faz 2 raporu + proje belleği
bb27882 feat(auth): Beta Faz 2 — Google ile giriş (sunucu doğrulamalı)
21b9fd9 docs(beta): Faz 1 — tam varlık denetimi tamamlandı
8abe6ed docs(beta): verify kapısına takılan alıntı düzeltildi
9efb20c docs(beta): Faz 0 — yayın hazırlığı belgeleri (9 dosya)
c2e4887 feat(mobile): Evolution E13 — cila, varlık optimizasyonu ve PROGRAM KAPANIŞI
```

## 3. Test sayıları — ÖLÇÜLDÜ (2026-07-26)

| Paket                         | Sonuç                                                   |
| ----------------------------- | ------------------------------------------------------- |
| `flutter analyze`             | **0 sorun**                                             |
| `flutter test`                | **275 geçti**                                           |
| `@ea/web`                     | **516 geçti**                                           |
| `@ea/db`                      | **6 geçti**                                             |
| `@ea/content-schema`          | **17 geçti**                                            |
| `@ea/question-bank`           | **10 geçti**                                            |
| `@ea/srs-engine`              | **12 geçti**                                            |
| `pnpm lint`                   | 0 hata (1 uyarı — Next eslint eklentisi notu, zararsız) |
| `pnpm format` · `pnpm verify` | temiz                                                   |

**Komutlar:**

```bash
cd apps/mobile && flutter analyze && flutter test     # PATH: /home/emre/dev/flutter/bin
cd <repo> && pnpm test && pnpm lint && pnpm format && pnpm verify && pnpm typecheck
cd apps/web && npx playwright test                    # içerik değiştiyse ŞART
```

## 4. Mevcut mimari — özet

**Değişmeyen omurga (program boyunca korunuyor):** Riverpod · go_router · dio · drift ·
arayüz/uygulama ayrımı · tek kaynaklı tasarım token'ları → `ThemeData` · `@ea/db` çift sürücü
(PGlite test / Postgres üretim) · `guarded`/`json`/`checkRateLimit` sunucu yardımcıları ·
Bearer oturum.

**Yerleşik desenler (bozulmamalı):**

1. **Platforma bağlı her şey arayüz + uygulama** — `CommunityApi`, `SocialApi`, `GroupsApi`,
   `PlaybackController`, `GoogleAuthService`. Widget testleri sahte uygulamayla, platform kanalı
   olmadan çalışır.
2. **Saf kural katmanı ekrandan/uçtan ayrı** — `apps/web/lib/server/*.ts` ve
   `apps/mobile/lib/domain/**`. Doğrudan test edilir.
3. **Engelleme tek modülde** — `apps/web/lib/server/social-guards.ts`.
4. **Türetilen içerik tek kaynaktan** — `apps/web/scripts/video-scenes.mjs` tek nesneden video,
   bölüm, VTT ve `content/videos.generated.ts` üretir.
5. **Dürüstlük testle zorunlu** — `apps/mobile/test/design_tokens_test.dart` (sabit renk yasağı),
   `apps/web/content/videos.test.ts` (animasyon etiketi), `pnpm verify` (yer tutucu/sır taraması).

## 5. Yayın durumu ve ENGELLER

| #      | Engel                                                                      | Durum                                  | Faz              |
| ------ | -------------------------------------------------------------------------- | -------------------------------------- | ---------------- |
| **B1** | Release derlemesi **DEBUG ANAHTARIYLA** imzalanıyor → **Play kabul etmez** | ⛔ **AÇIK**                            | 4                |
| **B2** | `android/app/build.gradle.kts` içinde Flutter şablon notları               | ⛔ AÇIK                                | 4                |
| **B3** | Google Sign-In yok                                                         | ✅ **KAPANDI**                         | 2                |
| **B4** | RevenueCat yok                                                             | ⛔ AÇIK                                | **3 (sıradaki)** |
| **B5** | Üretim veritabanında Evolution doğrulama artıkları                         | ⛔ AÇIK — **kullanıcı onayı bekliyor** | 13               |
| **B6** | Play Console kaydı/beyanları yok                                           | ⛔ AÇIK (elle)                         | 4                |

**B1'in tam yeri:**

```
apps/mobile/android/app/build.gradle.kts → buildTypes { release { signingConfig = ...("debug") } }
```

**B5 uyarısı:** üretim veritabanı temizliği **geri alınamaz bir işlemdir**; önceki oturumda
bilinçli olarak yapılmadı ve kullanıcı onayına bırakıldı. Onay almadan silme.

## 6. Ortam gereksinimleri

**Geliştirme makinesi:**

```bash
export PATH="$PATH:/home/emre/dev/flutter/bin"   # Flutter 3.41.9
# Node 22.23.1 · pnpm · ffmpeg · Playwright (kurulu) · ImageMagick (identify/convert)
# cwebp YOK — webp yeniden sıkıştırma yapılamıyor (bilinen kısıt)
```

**Cihaz:** `AYXSUKIVJVPZ7HPZ` — Redmi M1908C3JGG · Android 11 · 1080×2340.
Yardımcı betikler: `/tmp/claude-1000/.../scratchpad/dev.sh` (yeniden başlatmada **silinir**,
gerekirse yeniden yazılır: `adb -s $D1 exec-out screencap -p > x.png`, `input tap`, `input swipe`).

## 7. `.env` gereksinimleri

**Depoda gerçek gizli değer YOKTUR.** Şablon: `apps/web/.env.example` (Faz 2'de eklendi) —
**örnek değer bile yazılmaz**, yalnız boş anahtar + açıklama. Tam liste: `ENV_TEMPLATE.md`.

**Sunucu (Vercel):** `DATABASE_URL` (zorunlu) · `GOOGLE_SERVER_CLIENT_ID` (Faz 2 — **WEB** istemci
kimliği) · `ANTHROPIC_API_KEY` · `RESEND_API_KEY` · LemonSqueezy anahtarları ·
`GOOGLE_PLAY_SA_JSON`. **Üretimde ASLA ayarlanmaz:** `IAP_DEV_ACCEPT`, `RATE_LIMIT_DISABLED`.

**Mobil (derleme zamanı `--dart-define`):** `GOOGLE_SERVER_CLIENT_ID` · (Faz 3'te eklenecek)
`REVENUECAT_PUBLIC_KEY`, `REVENUECAT_PROJECT_ID`, `REVENUECAT_ENTITLEMENT`,
`REVENUECAT_MONTHLY_PRODUCT`, `REVENUECAT_YEARLY_PRODUCT`.

**Kural:** hiçbiri zorunlu değildir — verilmezse uygulama **çökmez**, ilgili yüzey dürüst bir
"yapılandırılmadı" durumu gösterir. Bu davranış testle korunuyor.

## 8. Bekleyen ELLE kurulum (kod yapamaz)

1. Google Play geliştirici hesabı (25 USD) + kimlik doğrulama
2. Upload key üretimi → `android/key.properties` (**Git dışı**)
3. Firebase projesi + Android uygulaması + **üç SHA** (debug · upload · **Play App Signing**) +
   `google-services.json`
4. OAuth onay ekranı + test kullanıcıları
5. RevenueCat hesabı + Play ürünleri + servis hesabı + Pub/Sub bildirimleri
6. Play Console: uygulama, beyanlar, mağaza varlıkları (simge 512², **Öne Çıkan Grafik 1024×500**,
   2+ ekran görüntüsü)
7. Gizlilik politikası sayfası + URL
8. İncelemeci test hesabı — **çalıştığı sınanmalı** (girilemezse kesin ret)
9. Üretim veritabanı temizliği (B5) — **onay bekliyor**

**⚠️ EN KRİTİK:** Play App Signing SHA'sı **kapalı teste ilk yüklemeden sonra** görünür.
Firebase'e eklenmezse **Play'den kurulan yapıda Google girişi ÇALIŞMAZ**.

## 9. Cihaz doğrulama durumu

| Faz       | Doğrulandı mı | Not                                                                                                                   |
| --------- | ------------- | --------------------------------------------------------------------------------------------------------------------- |
| Faz 0, 1  | —             | Kod yok, cihaz gerekmedi                                                                                              |
| **Faz 2** | ✅            | İki ayrı derleme: `--dart-define` **olmadan** → Google düğmesi YOK; **ile** → ayırıcı + düğme + dört renkli G işareti |

**Faz 2'de doğrulanamayan:** gerçek Google hesabıyla uçtan uca giriş — Firebase kurulumu elle
yapılacak bir adım olduğu için bu ortamda mümkün değil. Dürüstçe rapora yazıldı.

## 10. Bilinen sınırlar (Evolution'dan devreden + yeni)

**Altyapıya bağlı:** gerçek zamanlı yok (WebSocket yok, kısa yoklama) · push bildirimi yok
(FCM yok) · **iOS N/A** (macOS yok) · gerçek Play satın alma yalnız Play'den yüklenmiş yapıda
çalışır · haftalık devir tembel (cron yok) · meydan okumalar otomatik dönmez.

**Kapsam kararı:** PiP yok · çevrimdışı video indirme yok · video sesi yok · iki video hâlâ
`planned` (gerçek çekim gerekiyor) · moderasyon reaktif · golden test yok.

**Ölçülemeyen:** kare düzeyinde jank — `dumpsys gfxinfo` Flutter için 0 kare döndürüyor,
`SurfaceFlinger --latency` sıfır verdi. Faz 13'te `--profile` derlemesiyle denenecek.
**Uydurma sayı raporlanmadı ve raporlanmamalı.**

**Teknik borç:** `assets/vehicle` (11 MB, web) yeniden sıkıştırılmadı (`cwebp` yok) · evrensel
APK 69,9 MB (küçülme yalnız split-APK/AAB ile) · `BETA_PHASE_0/1_REPORT.md` yazılmadı (bilinçli).

## 11. Faz 3 için hazır olan zemin

- **"Anahtar yoksa dürüst davran" kalıbı** Faz 2'de kuruldu ve testle korunuyor — Faz 3 aynısını
  kullanacak.
- **Model çakışması kayıtlı:** uygulama bugün tek seferlik ömür boyu paket satıyor
  (`komple-ehliyet`, 399 TL); program aylık/yıllık istiyor. **Ürün kararı verilmedi.** Çözüm:
  `entitlement` soyutlaması — her iki model de aynı `premium` yetkisini açar.
- **Mevcut `in_app_purchase` yolu SÖKÜLMEZ** — `BillingGateway` arayüzü eklenir, RevenueCat onun
  bir uygulaması olur.
- Tam anlatım: **`REVENUECAT_SETUP.md`**.

## 12. Belge haritası

| Belge                              | İçerik                                                                |
| ---------------------------------- | --------------------------------------------------------------------- |
| `MOBILE_ENGINEERING_DISCIPLINE.md` | **Değişmez kurallar** — her fazdan önce okunur                        |
| `MOBILE_PROJECT_MEMORY.md`         | **Ekleme-only** mühendislik belleği; sonunda Beta 0–2 kontrol noktası |
| `MOBILE_EVOLUTION_FINAL_REPORT.md` | Evolution E1–E13 kapanışı                                             |
| `BETA_READINESS_ROADMAP.md`        | Beta 13 fazı + ilerleme işaretleri                                    |
| `RELEASE_CHECKLIST.md`             | Her yükleme öncesi kapı listesi                                       |
| `GOOGLE_AUTH_SETUP.md`             | Firebase + Google Sign-In sıfırdan                                    |
| `PLAY_CONSOLE_SETUP.md`            | Play Console sıfırdan + beyanlar                                      |
| `REVENUECAT_SETUP.md`              | RevenueCat sıfırdan (**Faz 3 kaynağı**)                               |
| `CLOSED_TEST_GUIDE.md`             | 12 test kullanıcısı akışı                                             |
| `ENV_TEMPLATE.md`                  | Ortam değişkenleri                                                    |
| `ASSET_GENERATION_LIBRARY.md`      | 19 görsel + üretime hazır promptlar                                   |
| `RELEASE_AUDIT_PLAN.md`            | Faz 13 denetim planı                                                  |
| `BETA_PHASE_2_REPORT.md`           | Faz 2 raporu                                                          |
| `NEXT_SESSION_START.md`            | **Yeni oturumun ilk okuyacağı belge**                                 |
