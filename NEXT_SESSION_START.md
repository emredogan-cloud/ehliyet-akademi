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
`BETA_PHASE_2_REPORT.md` · `BETA_PHASE_3_REPORT.md` · `BETA_PHASE_4_REPORT.md` · `BETA_PHASE_5_REPORT.md` · `BETA_PHASE_6_REPORT.md` · `PLAY_CONSOLE_SETUP.md`.

**`MOBILE_PROJECT_MEMORY.md` çok uzun** — baştan sona okuma; **sondaki üç bölüm** (⛳ BAĞLAM
KONTROL NOKTASI · ⛳ BETA FAZ 3 · 4 · 5 · 6) Beta programı için yeterlidir. Evolution ayrıntısı gerekirse
`MOBILE_EVOLUTION_FINAL_REPORT.md`.

## 2. Tamamlanan fazlar

| Program              | Durum                                                              |
| -------------------- | ------------------------------------------------------------------ |
| **Evolution E1–E13** | ✅ **TAMAMLANDI** — dokunulmaz, yeniden başlatılmaz, değiştirilmez |
| **Beta Faz 0**       | ✅ Yayın hazırlığı belgeleri (9 dosya)                             |
| **Beta Faz 1**       | ✅ Tam varlık denetimi                                             |
| **Beta Faz 2**       | ✅ Google Sign-In (sunucu doğrulamalı)                             |
| **Beta Faz 3**       | ✅ RevenueCat (`BillingGateway` soyutlaması)                       |
| **Beta Faz 4**       | ✅ Play yayın hazırlığı — **B1 + B2 kapandı** (gerçek upload key)  |
| **Beta Faz 5**       | ✅ Giriş ekranı yeniden tasarımı (hero + güven şeridi + sıfırlama) |
| **Beta Faz 6**       | ✅ Onboarding cilası — görsel %37 → %89,8 genişlik                 |

## 3. Aktif faz

# 🔵 Beta Faz 7 — Profil avatarları

Kaynak belgeler: **`BETA_READINESS_ROADMAP.md` → "Faz 7"** · `ASSET_GENERATION_LIBRARY.md` §4.4 ·
`PLAY_CONSOLE_SETUP.md` §5.6 (**Veri Güvenliği**).

## 4. Kalan yol haritası

`7` (aktif) → `8` Karşılama deneyimi → `9` Akan AI → `10` Kabin kumandaları →
`11` Ders yeniden tasarımı → `12` Video hattı araştırması → `13` Nihai denetim →
`BETA_READINESS_FINAL_REPORT.md`.

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

| #      | Engel                                                                          | Durum                        |
| ------ | ------------------------------------------------------------------------------ | ---------------------------- |
| **B5** | Üretim veritabanı test artıkları — **kullanıcı onayı bekliyor, izinsiz silme** | ⛔ Faz 13                    |
| **B6** | Play Console kaydı/beyanları                                                   | ⛔ **ELLE** — belgeler hazır |

**Kapananlar:** B1 + B2 (Faz 4 — gerçek upload key) · B3 (Faz 2) · B4 (Faz 3, istemci tarafı).

### ⚠️ Kod dışı ama yayını bloke eden: Google girişi henüz ÇALIŞMIYOR

`google-services.json` eklendi ama `oauth_client` dizisi **boş** → Firebase'e SHA eklenmemiş ve
Web istemcisi (`GOOGLE_SERVER_CLIENT_ID`) yok. Adımlar: **`GOOGLE_AUTH_SETUP.md` §9.5**.
Gereken SHA-1/SHA-256 §3.2'de ölçülmüş hâlde duruyor. Uygulama çökmez — düğmeyi göstermez.

## 8. Test gereksinimleri — mevcut taban (ÖLÇÜLDÜ 2026-07-26)

Bir faz bitmeden bu sayıların **altına düşülmemeli**:

```
flutter analyze  → 0
flutter test     → 334
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

## 10. Faz 7'nin ilk görevi — TAM OLARAK BU

> **Görev:** profil avatarı yükleme — **ama moderasyon ve Veri Güvenliği beyanı AYNI FAZDA.**

⚠️ **En kritik bağlam:** E8'de "fotoğraf yükleme YOK" **bilinçli bir moderasyon kararıydı**.
Bu faz o kararı değiştiriyor; dolayısıyla üç şey birlikte yapılmak zorundadır.

Adımlar:

1. Galeri + kamera + **kırpma** + **sıkıştırma** + **depolama soyutlaması**
   (platforma bağlı her şey **arayüz + sahte uygulama** — yerleşik desen).
2. **Modern Android'de `image_picker` izin GEREKTİRMEYEN sistem seçicisini kullanır;
   `READ_MEDIA_IMAGES` EKLENMEMELİDİR** (`PLAY_CONSOLE_SETUP.md` §5.8) — eklenirse Play'de
   gerekçe formu açılır ve izin listesi bozulur.
3. **Moderasyon aynı fazda:** avatar şikâyet edilebilir olmalı, engelleme çalışmalı, varsayılan
   maskota dönüş yolu bulunmalı. E8'in sızıntısız-404 ve opt-in ilkeleri **bozulmaz**.
4. **`PLAY_CONSOLE_SETUP.md` §5.6 Veri Güvenliği tablosundaki "Fotoğraflar" satırı
   GÜNCELLENMELİDİR** — yanlış beyan mağazadan kaldırılma sebebidir.
5. Avatar topluluk, sıralama ve profilde görünür; mevcut 6 maskot **varsayılan olarak korunur**
   (`ASSET_GENERATION_LIBRARY.md` §4.4: yeni varlık üretimi GEREKMİYOR).
6. Cihaz: yükleme/kırpma/sıkıştırma **gerçek cihazda** doğrulanır + avatar şikâyet edilebilir.
7. `BETA_PHASE_7_REPORT.md` + bellek **ekleme** + commit + push + **CI yeşil bekle**.

**Faz 6'dan devreden yararlı teknik:** ikinci ekran ölçüsünü gerçek cihazda doğrulamak için
`adb shell wm size 720x1280 && adb shell wm density 320` (sonra **`reset`** — unutma).

## 11. İlk 60 saniyede çalıştırılacak doğrulama

```bash
cd /home/emre/Downloads/OTHER-RESEARCH/other_report/ehliyet-akademi
git log --oneline -3          # en üstte Faz 6 commit'i olmalı
git status --short            # boş olmalı
gh run list --limit 3         # son çalışmalar yeşil olmalı
adb devices -l                # SABİT KİMLİK YOK — §9
```

Farklıysa önce `SESSION_HANDOVER.md` §2 ile karşılaştır. **Depo belgeden üstündür** — fark varsa
depoya güven, belgeyi güncelle, devam et.
