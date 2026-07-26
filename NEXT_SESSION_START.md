# ▶ SONRAKİ OTURUM — BURADAN BAŞLA

> Bu belge, tamamen yeni bir Claude oturumunun **beş dakikadan kısa sürede** işe devam etmesi için
> yazıldı. Önceki oturumun sohbet geçmişi **yok**; ihtiyacın olan her şey diskte.

---

## 1. Önce şu dosyaları oku — BU SIRAYLA

| #   | Dosya                                                           | Neden                                         | Süre |
| --- | --------------------------------------------------------------- | --------------------------------------------- | ---- |
| 1   | `MOBILE_ENGINEERING_DISCIPLINE.md`                              | Değişmez kurallar. **Her fazdan önce okunur** | 2 dk |
| 2   | `SESSION_HANDOVER.md`                                           | Mevcut durum, git, testler, engeller, ortam   | 4 dk |
| 3   | `BETA_READINESS_ROADMAP.md`                                     | 13 faz + ilerleme işaretleri                  | 4 dk |
| 4   | `MOBILE_PROJECT_MEMORY.md` → **son iki bölüm** (BAĞLAM + FAZ 3) | Beta 0–3'te öğrenilen her şey                 | 8 dk |
| 5   | `PLAY_CONSOLE_SETUP.md`                                         | **Aktif fazın kaynak belgesi**                | 6 dk |

Gerekince bakılacaklar: `RELEASE_CHECKLIST.md` · `GOOGLE_AUTH_SETUP.md` · `REVENUECAT_SETUP.md` ·
`ENV_TEMPLATE.md` · `ASSET_GENERATION_LIBRARY.md` · `RELEASE_AUDIT_PLAN.md` ·
`BETA_PHASE_2_REPORT.md` · `BETA_PHASE_3_REPORT.md`.

**`MOBILE_PROJECT_MEMORY.md` çok uzun** — baştan sona okuma; **sondaki iki bölüm** (⛳ BAĞLAM
KONTROL NOKTASI ve ⛳ BETA FAZ 3) Beta programı için yeterlidir. Evolution ayrıntısı gerekirse
`MOBILE_EVOLUTION_FINAL_REPORT.md`.

## 2. Tamamlanan fazlar

| Program              | Durum                                                              |
| -------------------- | ------------------------------------------------------------------ |
| **Evolution E1–E13** | ✅ **TAMAMLANDI** — dokunulmaz, yeniden başlatılmaz, değiştirilmez |
| **Beta Faz 0**       | ✅ Yayın hazırlığı belgeleri (9 dosya)                             |
| **Beta Faz 1**       | ✅ Tam varlık denetimi                                             |
| **Beta Faz 2**       | ✅ Google Sign-In (sunucu doğrulamalı)                             |
| **Beta Faz 3**       | ✅ RevenueCat (`BillingGateway` soyutlaması)                       |

## 3. Aktif faz

# 🔵 Beta Faz 4 — Google Play yayın hazırlığı

Kaynak belge: **`PLAY_CONSOLE_SETUP.md`** · Roadmap bölümü: `BETA_READINESS_ROADMAP.md` → "Faz 4".
Bu faz **B1 + B2**'yi kapatır (release imzalama + şablon notları) ve **B6**'yı belgeler.

## 4. Kalan yol haritası

`4` (aktif) → `5` Giriş ekranı → `6` Onboarding cilası → `7` Profil avatarları →
`8` Karşılama deneyimi → `9` Akan AI → `10` Kabin kumandaları → `11` Ders yeniden tasarımı →
`12` Video hattı araştırması → `13` Nihai denetim → `BETA_READINESS_FINAL_REPORT.md`.

## 5. Değişmez mühendislik kuralları

1. **Her fazdan önce** disiplin + bellek + roadmap okunur.
2. **Tek faz, tam bitirme.** Atlama yok, birleştirme yok, yarım bırakma yok.
3. **Yer tutucu / yapılacak-notu / ölü gezinme / eksik ekran YASAK.** (`pnpm verify` bunu tarar.)
4. **Test atlanmaz.** `flutter analyze` 0 · `flutter test` tam · yeni uç → entegrasyon testi.
5. **CI atlanmaz.** CI + Mobile CI + CodeQL **yeşil** olana kadar beklenir. Kırmızıda devam edilmez.
6. **Gerçek cihazda doğrulama** + ekran görüntüsü kanıtı. **CİHAZ DEĞİŞTİ → §9.**
7. **iOS derlemesi N/A** (macOS yok) — sahte iOS derlemesi yapılmaz.
8. **Tasarım token'ları dışında sabit renk yok** (`design_tokens_test.dart` zorluyor).
9. **Bellek EKLENEREK güncellenir**, asla üzerine yazılmaz.
10. **Ölçülmeyen şey ölçülmüş gibi yazılmaz.** Uydurma sayı yok.
11. **Yeni `.md`/`.ts` yazdıktan sonra** `npx prettier --write <dosya>` → sonra `pnpm format`.
12. **Gizli değer depoya girmez** — yalnız `.example` şablonları, örnek değer bile yazılmadan.
13. **"Belgede yazıyor" ≠ "depoda var"** — teslim demeden önce `git ls-files` ile doğrula
    (Faz 3'te `.env.example`'ın hiç commit'lenmemiş olduğu böyle bulundu).

## 6. DEĞİŞTİRİLMEMESİ GEREKENLER

- ❌ **Evolution E1–E13'ün hiçbir çıktısı** — tamamlandı, geçersiz kılınmaz.
- ❌ **`iap_service.dart`** — Faz 3'te tek satır dokunulmadı, öyle kalmalı. RevenueCat onun
  **yanında** duruyor (`BillingGateway`'in iki uygulaması).
- ❌ **`BillingServerBridge` ayrımı** — RevenueCat ham Play token'ı sunmaz; bu ayrım kaldırılırsa
  "satın alma başarılı ama sunucu görmedi" sessiz hatası geri gelir.
- ❌ **E-posta/parola ve misafir giriş yolları** — Google girişi onların yerine geçmez.
- ❌ **Bearer oturum mimarisi** — yeni oturum sistemi getirilmez.
- ❌ **Arayüz + sahte uygulama deseni** — platforma bağlı her şey böyle yazılır.
- ❌ **`social-guards.ts` engelleme modülü** — dağıtılmaz.
- ❌ **`video-scenes.mjs` tek kaynak kuralı** — bölüm/altyazı elle ikinci kopyada tutulmaz.
- ❌ **E8 gizlilik ilkeleri** — opt-in, PII yok, sızıntısız 404.
  (Faz 7 fotoğraf yüklemeyi getirecek → moderasyon **aynı fazda** ele alınmalı.)
- ❌ **CI kapıları gevşetilmez.** Kapı kırıldıysa kodu/metni düzelt, kapıyı değil.

## 7. Açık yayın engelleri

| #      | Engel                                                                          | Faz           |
| ------ | ------------------------------------------------------------------------------ | ------------- |
| **B1** | Release derlemesi **DEBUG anahtarıyla** imzalanıyor → Play kabul etmez         | **4 — AKTİF** |
| **B2** | `android/app/build.gradle.kts` şablon notları                                  | **4 — AKTİF** |
| **B5** | Üretim veritabanı test artıkları — **kullanıcı onayı bekliyor, izinsiz silme** | 13            |
| **B6** | Play Console kaydı/beyanları (elle)                                            | **4 — AKTİF** |

**Kapananlar:** B3 (Faz 2) · B4 (Faz 3 — istemci tarafı; RevenueCat panosu kurulumu elle).

## 8. Test gereksinimleri — mevcut taban (ÖLÇÜLDÜ 2026-07-26)

Bir faz bitmeden bu sayıların **altına düşülmemeli**:

```
flutter analyze  → 0
flutter test     → 311
@ea/web          → 516
@ea/db           → 6
@ea/content-schema → 17 · @ea/question-bank → 10 · @ea/srs-engine → 12
pnpm lint (0 hata) · pnpm format (temiz) · pnpm verify (temiz) · pnpm typecheck (0)
```

Komutlar:

```bash
export PATH="$PATH:/home/emre/dev/flutter/bin"
cd apps/mobile && flutter analyze && flutter test
cd <repo>      && pnpm test && pnpm lint && pnpm format && pnpm verify && pnpm typecheck
cd apps/web    && npx playwright test          # içerik/metin değiştiyse ŞART
```

## 9. ⚠️ CİHAZ DEĞİŞTİ

Belgelerde geçen `AYXSUKIVJVPZ7HPZ` (Redmi M1908C3JGG, Android 11) **artık bağlı değil.**
Yeniden başlatma sonrası takılı cihaz:

| Alan    | Değer                                |
| ------- | ------------------------------------ |
| Kimlik  | **`jfzxugsgnnvsrsg6`**               |
| Model   | Xiaomi **22095RA98C**                |
| Android | **13 (SDK 33)**                      |
| Ekran   | **1080×2408 · 440 dpi** (393×876 dp) |
| ABI     | arm64-v8a                            |

`MOBILE_ENGINEERING_DISCIPLINE.md` kural 6'daki kimlik **geçersizdir**; disiplin dosyası
bilinçli olarak değiştirilmedi (o dosyaya yalnız kural eklenir). Sapma burada,
`SESSION_HANDOVER.md`'de ve `MOBILE_PROJECT_MEMORY.md` §G'de kayıtlıdır.

**Cihazı her fazın başında doğrula:** `adb devices -l`.

## 10. Faz 4'ün ilk görevi — TAM OLARAK BU

> **Görev:** `PLAY_CONSOLE_SETUP.md` §2'yi oku, sonra **release imzalamasını gerçek anahtara
> bağla** (B1) ve **şablon notlarını temizle** (B2).

Adımlar:

1. `apps/mobile/android/app/build.gradle.kts` dosyasını oku. Şu an: `release` bloğu
   `signingConfigs.getByName("debug")` kullanıyor ve `defaultConfig` ile `release` içinde Flutter
   şablonundan kalan yapılacak-notları duruyor.
2. `android/release-keystore.properties.example` (**yeni**) — imzalama şablonu, **değer yazılmadan**.
3. `android/key.properties` **`.gitignore`'a eklenir** (kök `.gitignore`'daki `!.env.example`
   deseninin aynısı gerekebilir — **`git check-ignore -v` ile doğrula**).
4. `build.gradle.kts` release bloğu `key.properties`'i okuyacak biçimde güncellenir.
   **Dosya yoksa derleme anlaşılır bir hata vermeli**, sessizce debug anahtarına düşmemeli.
5. Şablon yapılacak-notları temizlenir (B2). **Dikkat:** `pnpm verify` yasaklı kalıp tarıyor —
   belgede bu notları **birebir alıntılama** (Faz 0'da CI tam bu yüzden kırıldı).
6. Testler: `key.properties` yokken derlemenin dürüst hata verdiği doğrulanır.
7. **DoD:** gerçek upload key ile imzalanmış AAB üretilir ve
   `apksigner verify --print-certs` çıktısında **`androiddebugkey` GEÇMEZ**.
   ⚠️ Upload key üretimi **elle** bir adımdır (`keytool -genkey`); anahtar üretilemiyorsa bu
   **dürüstçe** rapora yazılır, sahte "imzalandı" denmez.
8. `BETA_PHASE_4_REPORT.md` + `MOBILE_PROJECT_MEMORY.md`'ye **ekleme** + commit + push +
   **CI yeşil bekle**.

## 11. İlk 60 saniyede çalıştırılacak doğrulama

```bash
cd /home/emre/Downloads/OTHER-RESEARCH/other_report/ehliyet-akademi
git log --oneline -3          # en üstte Faz 3 commit'i olmalı
git status --short            # boş olmalı
gh run list --limit 3         # son çalışmalar yeşil olmalı
adb devices -l                # jfzxugsgnnvsrsg6 görmelisin (§9)
```

Farklıysa önce `SESSION_HANDOVER.md` §2 ile karşılaştır. **Depo belgeden üstündür** — fark varsa
depoya güven, belgeyi güncelle, devam et.
