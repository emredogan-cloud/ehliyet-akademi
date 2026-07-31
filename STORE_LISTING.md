# Google Play Store Listing — Ehliyet Akademi (Mobile Phase 8)

Draft store metadata for the Android app. Language: **Türkçe (tr-TR)** primary. App id
`com.ehliyetegitim.ehliyet_akademi`. Category: **Education**. Content rating: **Everyone / 3+**
(educational; no user-to-user content, no ads, one-time in-app purchases).

> **Beta Faz 9 — DÜZELTİLDİ.** Bu not eskiden **beş** yönetilen ürün sayıyordu
> (`premium_teori`, `premium_direksiyon`, `simulator_paketi`, `premium_soru_bankasi`, `komple_b`).
> Katalog o günden beri **tek ürüne** indi (`apps/mobile/lib/domain/premium/products.dart`).
> Eski liste kaldırılmasaydı, Play Console'da var olmayan dört ürün tanımlanır ve uygulamanın
> sorduğu tek ürün (`komple_ehliyet`) unutulabilirdi — mağaza "ürün bulunamadı" der, satın alma
> hiç açılmaz ve sebebi uygulamada aranırdı.
>
> **Play Console'da tanımlanacak TEK yönetilen ürün:**
>
> | Ürün kimliği     | Tür                      | Fiyat  |
> | ---------------- | ------------------------ | ------ |
> | `komple_ehliyet` | Yönetilen (tek seferlik) | 399 TL |
>
> Ayrıca yayın öncesi: backend'e `GOOGLE_PLAY_SA_JSON` (sunucu tarafı makbuz doğrulaması —
> `BILLING_AUDIT.md` §4.1) ve imzalı `flutter build appbundle` (üretim keystore'u gerekir).

## App name

**Ehliyet Akademi — B Sınıfı Sınav**

## Short description (≤ 80 chars)

**Akıllı, çevrimdışı ehliyet sınavı hazırlığı: dersler, denemeler ve AI Koç.**

## Full description

Ehliyet Akademi, B sınıfı sürücü belgesi sınavına hazırlanmanın en akıllı yolu — üstelik internet
olmadan da çalışır.

**📚 Kapsamlı içerik**

- 19 detaylı ders: trafik, ilk yardım, araç tekniği ve trafik adabı
- 121 trafik işareti — kategorilere ayrılmış, aranabilir görsel galeri
- Araç tekniği: motor, gösterge paneli ve bileşenler
- Kısa, öz anlatım videoları

**🎯 Gerçek MEB formatında pratik**

- 50 soru · 45 dakika · resmi dağılım (23/12/9/6) deneme sınavları
- Akıllı çalışma (aralıklı tekrar / SRS) — zayıf konularına odaklanır
- Her gün yenilenen koleksiyonlar + MEB formatında geçmiş denemeler

**🤖 AI Koç**

- İlerlemeni izleyen, sana özel öneren proaktif bir koç
- Ehliyet ve trafik sorularını platform içeriğine dayalı yanıtlar

**📊 İlerleme & motivasyon**

- Hazırlık skoru, ders bazında radar, çalışma ısı haritası
- Seviye/XP, seri takibi ve rozetler
- Günlük çalışma hatırlatmaları (yerel bildirim)

**⭐ Premium (tek seferlik, ömür boyu — abonelik yok)**

- Premium dersler, sınırsız deneme, tam soru bankası, sınırsız AI Koç

Çevrimdışı-öncelik: içerik ve sorular bir kez indirilir, sonra internetsiz çalışır.

_AI yanıtları yardımcıdır; kesin ve güncel kural için MEB/MTSK esastır._

## Keywords / tags

ehliyet, ehliyet sınavı, B sınıfı, sürücü kursu, MEB, trafik işaretleri, deneme sınavı, ilk yardım,
motor, trafik adabı, e-sınav, ehliyet soruları

## What's new (release notes — v1.0)

Ehliyet Akademi'nin ilk sürümü: dersler, 121 trafik işareti, MEB formatında denemeler, akıllı çalışma
(SRS), AI Koç, ilerleme takibi ve çevrimdışı çalışma.

## Assets checklist

- App icon: `android/app/src/main/res/mipmap-*/ic_launcher` (mevcut). Play için 512×512 yüksek çözünürlük
  ikonu gerekir.
- Feature graphic (1024×500): oluşturulacak.
- Screenshots (min 2, phone): mevcut cihaz görüntüleri kullanılabilir — Ana Sayfa (hazırlık halkası),
  İşaret galerisi, Deneme sınavı, AI Koç, İlerleme (radar/rozetler), Premium.
- Privacy policy URL: gerekli (hesap + satın alma verisi işlendiğinden).

## Build & release

- Debug-signed **release APK builds** (`flutter build apk --release` → ~66 MB universal). iOS N/A (macOS
  yok).
- Play için **App Bundle** önerilir (`flutter build appbundle`) → Play cihaz-başına küçük APK üretir
  (~20–25 MB). **Üretim imzalama için bir keystore gerekir** (`android/key.properties` + `.jks`); bu
  ortamda keystore yok → yükleme adımı belgeli-eksiktir (IAP/iOS gibi).
