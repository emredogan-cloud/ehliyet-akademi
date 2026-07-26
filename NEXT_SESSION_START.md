# ▶ SONRAKİ OTURUM — BURADAN BAŞLA

> Bu belge, tamamen yeni bir Claude oturumunun **beş dakikadan kısa sürede** işe devam etmesi için
> yazıldı. Önceki oturumun sohbet geçmişi **yok**; ihtiyacın olan her şey diskte.

---

## 1. Önce şu dosyaları oku — BU SIRAYLA

| #   | Dosya                                                                    | Neden                                         | Süre |
| --- | ------------------------------------------------------------------------ | --------------------------------------------- | ---- |
| 1   | `MOBILE_ENGINEERING_DISCIPLINE.md`                                       | Değişmez kurallar. **Her fazdan önce okunur** | 2 dk |
| 2   | `SESSION_HANDOVER.md`                                                    | Mevcut durum, git, testler, engeller, ortam   | 4 dk |
| 3   | `BETA_READINESS_ROADMAP.md`                                              | 13 faz + ilerleme işaretleri                  | 4 dk |
| 4   | `MOBILE_PROJECT_MEMORY.md` → **son bölüm** ("⛳ BAĞLAM KONTROL NOKTASI") | Beta 0–2'de öğrenilen her şey                 | 6 dk |
| 5   | `REVENUECAT_SETUP.md`                                                    | **Aktif fazın kaynak belgesi**                | 6 dk |

Gerekince bakılacaklar: `RELEASE_CHECKLIST.md` · `PLAY_CONSOLE_SETUP.md` ·
`GOOGLE_AUTH_SETUP.md` · `ENV_TEMPLATE.md` · `ASSET_GENERATION_LIBRARY.md` ·
`RELEASE_AUDIT_PLAN.md` · `BETA_PHASE_2_REPORT.md`.

**`MOBILE_PROJECT_MEMORY.md` çok uzun** — baştan sona okuma; **sondaki kontrol noktası bölümü**
Beta programı için yeterlidir. Evolution ayrıntısı gerekirse `MOBILE_EVOLUTION_FINAL_REPORT.md`.

## 2. Tamamlanan fazlar

| Program              | Durum                                                              |
| -------------------- | ------------------------------------------------------------------ |
| **Evolution E1–E13** | ✅ **TAMAMLANDI** — dokunulmaz, yeniden başlatılmaz, değiştirilmez |
| **Beta Faz 0**       | ✅ Yayın hazırlığı belgeleri (9 dosya)                             |
| **Beta Faz 1**       | ✅ Tam varlık denetimi                                             |
| **Beta Faz 2**       | ✅ Google Sign-In (sunucu doğrulamalı)                             |

## 3. Aktif faz

# 🔵 Beta Faz 3 — RevenueCat

Kaynak belge: **`REVENUECAT_SETUP.md`** · Roadmap bölümü: `BETA_READINESS_ROADMAP.md` → "Faz 3".

## 4. Kalan yol haritası

`3` (aktif) → `4` Play yayın hazırlığı → `5` Giriş ekranı → `6` Onboarding cilası →
`7` Profil avatarları → `8` Karşılama deneyimi → `9` Akan AI → `10` Kabin kumandaları →
`11` Ders yeniden tasarımı → `12` Video hattı araştırması → `13` Nihai denetim →
`BETA_READINESS_FINAL_REPORT.md`.

## 5. Değişmez mühendislik kuralları

1. **Her fazdan önce** disiplin + bellek + roadmap okunur.
2. **Tek faz, tam bitirme.** Atlama yok, birleştirme yok, yarım bırakma yok.
3. **Yer tutucu / yapılacak-notu / ölü gezinme / eksik ekran YASAK.** (`pnpm verify` bunu tarar.)
4. **Test atlanmaz.** `flutter analyze` 0 · `flutter test` tam · yeni uç → entegrasyon testi.
5. **CI atlanmaz.** CI + Mobile CI + CodeQL **yeşil** olana kadar beklenir. Kırmızıda devam edilmez.
6. **Gerçek cihazda doğrulama** (`AYXSUKIVJVPZ7HPZ`) + ekran görüntüsü kanıtı.
7. **iOS derlemesi N/A** (macOS yok) — sahte iOS derlemesi yapılmaz.
8. **Tasarım token'ları dışında sabit renk yok** (`design_tokens_test.dart` zorluyor).
9. **Bellek EKLENEREK güncellenir**, asla üzerine yazılmaz.
10. **Ölçülmeyen şey ölçülmüş gibi yazılmaz.** Uydurma sayı yok.
11. **Yeni `.md`/`.ts` yazdıktan sonra** `npx prettier --write <dosya>` → sonra `pnpm format`.
12. **Gizli değer depoya girmez** — yalnız `.example` şablonları, örnek değer bile yazılmadan.

## 6. DEĞİŞTİRİLMEMESİ GEREKENLER

- ❌ **Evolution E1–E13'ün hiçbir çıktısı** — tamamlandı, geçersiz kılınmaz.
- ❌ **Mevcut `in_app_purchase` yolu SÖKÜLMEZ** — Faz 3'te RevenueCat **yanına** eklenir.
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
| **B1** | Release derlemesi **DEBUG anahtarıyla** imzalanıyor → Play kabul etmez         | 4             |
| **B2** | `android/app/build.gradle.kts` şablon notları                                  | 4             |
| **B4** | RevenueCat yok                                                                 | **3 — AKTİF** |
| **B5** | Üretim veritabanı test artıkları — **kullanıcı onayı bekliyor, izinsiz silme** | 13            |
| **B6** | Play Console kaydı/beyanları (elle)                                            | 4             |

## 8. Test gereksinimleri — mevcut taban

Bir faz bitmeden bu sayıların **altına düşülmemeli**:

```
flutter analyze  → 0
flutter test     → 275
@ea/web          → 516
@ea/db           → 6
@ea/content-schema → 17 · @ea/question-bank → 10 · @ea/srs-engine → 12
pnpm lint (0 hata) · pnpm format (temiz) · pnpm verify (temiz) · pnpm typecheck (0)
```

Komutlar:

```bash
export PATH="$PATH:/home/emre/dev/flutter/bin"
cd apps/mobile && flutter analyze && flutter test
cd <repo>      && pnpm test && pnpm lint && pnpm format && pnpm verify
cd apps/web    && npx playwright test          # içerik/metin değiştiyse ŞART
```

## 9. Faz 3'ün ilk görevi — TAM OLARAK BU

> **Görev:** `REVENUECAT_SETUP.md`'yi oku, sonra **`BillingGateway` soyutlamasını** kur.

Adımlar:

1. `apps/mobile/lib/domain/premium/products.dart` ve `lib/data/premium/iap_service.dart` +
   `entitlements_repository.dart` dosyalarını oku — mevcut ödeme yolunu **anla, değiştirme**.
2. `lib/data/premium/billing_gateway.dart` (**yeni**) — arayüz:
   `products()` · `purchase()` · `restore()` · `entitlements()` · `isConfigured`.
3. Mevcut `IapService`'i bu arayüzün **bir uygulaması** hâline getir (sarmalayıcı; iç mantık
   değişmez).
4. `lib/data/premium/revenuecat_gateway.dart` (**yeni**) — `purchases_flutter` uygulaması.
   `REVENUECAT_PUBLIC_KEY` **yoksa** `isConfigured == false`.
5. `billingGatewayProvider` — anahtar varsa RevenueCat, yoksa mevcut yol. **Çökme yok.**
6. `apps/mobile/.env.example` (**yeni**) — beş RevenueCat değişkeni, **boş şablon**.
7. Testler: anahtarsız derlemede ödeme ekranı **dürüst "mağaza kullanılamıyor"** gösteriyor ·
   geri yükleme düğmesi **her koşulda var** (Play politikası) · sahte ağ geçidiyle satın alma akışı.
8. Cihaz: ödeme ekranı anahtarsız derlemede **çökmüyor** ve dürüst durum gösteriyor.
9. `BETA_PHASE_3_REPORT.md` + `MOBILE_PROJECT_MEMORY.md`'ye **ekleme** + commit + push +
   **CI yeşil bekle**.

**Faz 3'te dikkat:** gerçek satın alma bu Linux ortamında **test edilemez** (Play Billing yalnız
Play'den yüklenmiş imzalı yapıda çalışır). Bunu rapora **dürüstçe** yaz; sahte "test edildi" deme.

## 10. İlk 60 saniyede çalıştırılacak doğrulama

```bash
cd /home/emre/Downloads/OTHER-RESEARCH/other_report/ehliyet-akademi
git log --oneline -3          # 21fac08 görmelisin
git status --short            # boş olmalı
gh run list --limit 3         # son çalışmalar yeşil olmalı
```

Beklenen: son commit **`21fac08`**, çalışma ağacı temiz, CI yeşil.
Farklıysa önce `SESSION_HANDOVER.md` §2 ile karşılaştır.
