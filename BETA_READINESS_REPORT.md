# Ehliyet Akademi — Kapalı Beta Hazırlık Raporu

**Sprint:** Post-Release Stabilization & Beta Readiness · **Tarih:** 31 Temmuz 2026
**Taban:** `cdb9774` → **`c90338c`** · 11 commit · 94 dosya · +9.430 / −256 satır

Destekleyici belgeler: [`BILLING_AUDIT.md`](BILLING_AUDIT.md) (ödeme durum denetimi) ·
[`PLAY_DATA_SAFETY.md`](PLAY_DATA_SAFETY.md) (Play veri güvenliği beyanı)

---

## 1. Karar

**Kapalı beta: ✅ HAZIR.**
**Genel yayın (production): ❌ ÜÇ ENGEL VAR** — hepsi sahibin Play Console/sunucu tarafında
yapacağı işler; kodda kalan bir engel yok (§5).

| Kapı                                 | Sonuç                                      |
| ------------------------------------ | ------------------------------------------ |
| `flutter analyze`                    | **0 sorun**                                |
| Mobil test                           | **888 ✓** (sprint başı 530)                |
| Web test                             | **633 ✓** (sprint başı 603)                |
| `pnpm lint` / `typecheck` / `format` | **✓ / ✓ / ✓** (1 uyarı, sprint öncesinden) |
| `pnpm build`                         | **✓**                                      |
| GitHub Actions                       | **CI ✓ · CodeQL ✓ · Mobile CI ✓**          |
| Gerçek cihaz                         | **8/8 integration ✓** (Huawei ANE-LX1)     |

Her faz ayrı commit edildi, ayrı push edildi ve push'tan önce cihazda koşturuldu.

---

## 2. Bu sprintte bulunan ve düzeltilen GERÇEK hatalar

Sprintin asıl çıktısı eklenen özellikler değil, **bulunanlar**. On dört kusurun ondan fazlası
kullanıcıya görünen, hiçbir teste takılmayan, sessizce kırılan türdendi.

| #   | Kusur                                                     | Neden görünmüyordu                                                           |
| --- | --------------------------------------------------------- | ---------------------------------------------------------------------------- |
| 1   | **Satın alma düğmesi vazgeçmede sonsuza kadar dönüyordu** | Sahte ağ geçidi, gerçeğin kırık olduğu yolu hiç kullanmıyordu (§2.1)         |
| 2   | **Ödenmemiş satın alma onaylanıyordu** (Play ihlali)      | `pendingCompletePurchase` bekleyen satın alma için de doğru                  |
| 3   | **İade edilen satın alma kalıcı premium veriyordu**       | Cihaz defteri ekleme-odaklıydı; `null` ile `[]` ayırt edilmiyordu            |
| 4   | **Giriş ekranı TABLETTE ÇÖKÜYORDU**                       | `clamp(alt > üst)` yalnız ≥1024 dp'de oluşuyor; telefonda hiç görünmüyor     |
| 5   | **Davet derin bağlantısı hiç çalışmıyordu**               | `ehliyetakademi://davet/X` → "davet" host olur, yol boşalır                  |
| 6   | **Çevrimdışı içerik 12 saniye bekletiyordu**              | Depolamada çevrimdışı-öncelik vardı, gecikmede yoktu                         |
| 7   | **`AppVersion.load()` hiç tamamlanmıyordu**               | Cevapsız platform kanalı; hata da fırlatmıyor → tüm analitiği bloke ediyordu |
| 8   | **Negatif `BoxConstraints`** (her açılışta)               | Android 11'de yok, Android 13'te her açılışta — tek cihazda test yetmiyor    |
| 9   | **`ref.read` `dispose()` içinde**                         | Riverpod yasaklıyor; AI Koç her sökülüşünde fırlatacaktı                     |
| 10  | **`Zone mismatch`** açılışta                              | Bu fazda kurulan raportörün kendisi yakaladı                                 |
| 11  | **Soru ekranı taşması** (145–187 px)                      | İki ekranın paylaştığı bileşen; dar ekran + büyük yazı                       |
| 12  | **"8 karakter olmalı (şu an 8)"**                         | `0→O` çevirisi geçersizi başka geçersize dönüştürüyordu                      |
| 13  | **Analitik kuyruğu 404'te olayları düşürüyordu**          | Uygulama sunucudan önce yayınlanırsa tüm ilk veri kaybolurdu                 |
| 14  | **Ham slug kullanıcıya gösteriliyordu**                   | `abc-degerlendirme` — koç kartlarında ham `topic` alanı                      |

### 2.1 En öğretici olan: sahte ile gerçeğin ayrışması

Ödeme ekranındaki "vazgeçince düğme sonsuza kadar döner" hatası, testler **yeşilken** vardı.
Sebep basit ve genel:

- Sahte ağ geçidi `purchase()` çağrısından **doğrudan** `BillingCancelled` döndürüyordu.
- Gerçek ağ geçidi `BillingSuccess([])` döndürüp sonucu **akıştan** gönderiyor; vazgeçme oradan
  `canceled` olarak geliyor ve `IapService` onu **sessizce düşürüyordu**.

Yani sahte, gerçeğin kırık olduğu yolu hiç kullanmıyordu. Bir test ikilisi gerçeğin
**sözleşmesinden** ayrıldığında, test yeşil kalır ve ürün kırık olur. Düzeltme yalnız kodu değil,
**ikiliyi** de kapsadı: `StreamBillingGateway` artık gerçek sözleşmeyi taklit ediyor.

### 2.2 İkinci öğretici: tek cihaz yetmiyor

`BoxConstraints has a negative minimum height` hatası **Redmi 8A'da (Android 11) hiç olmuyor,
Redmi Note 11R'de (Android 13) her açılışta oluyordu.** Sistem çubuğu yerleşirken gelen kısa
yükseklik cihaza ve sürüme göre değişiyor. Cihaz değiştirir değiştirmez ortaya çıktı — ve onu
yakalayan, bir faz önce kurulan hata raportörüydü.

---

## 3. Fazların çıktıları

| Faz | Konu             | Somut çıktı                                                                                      |
| --- | ---------------- | ------------------------------------------------------------------------------------------------ |
| 1   | Davet ekosistemi | `/davet/<KOD>` sayfası · App Link + özel şema · atıf tablosu · kod kayıt formunda otomatik dolar |
| 2   | Ödeme denetimi   | 12 durum tek tek denetlendi; 3 kusur düzeltildi ([`BILLING_AUDIT.md`](BILLING_AUDIT.md))         |
| 3   | Ürün analitiği   | 30 olay, merkezî sözlük, kalıcı kuyruk, kullanılmayan-olay bekçisi                               |
| 4   | Hata gözlemi     | 3 kanal + noktasal kancalar, parmak izi gruplama, çökme döngüsü koruması                         |
| 5   | Çevrimdışı       | 13 kalıcı test; önbellek artık BEKLETMİYOR                                                       |
| 6   | Bildirimler      | 8 tür, 3 kanal, tür başına tercih, saf planlama motoru (29 test)                                 |
| 7   | AI Koç           | Zayıf konu · eğilim · 7 günlük plan · sınav tahmini — hepsi çevrimdışı ve deterministik          |
| 8   | Yönetici         | Telemetri panosu + davet yönetimi (toplanan veri artık okunabilir)                               |
| 9   | Play hazırlığı   | Veri güvenliği beyanı · ürün listesi düzeltmesi · boyutun doğru ölçümü                           |
| 10  | Başarım labı     | `tool/perf_lab.sh` — ölç, tabanla karşılaştır, gerilemede hata ver                               |
| 11  | Tam denetim      | 31 rota × 5 koşul = 217 durum; 15 kusur bulundu ve düzeltildi                                    |

---

## 4. Ölçülen sayılar

Huawei ANE-LX1 (Android 9), **release** derlemesi, 3 koşu medyanı — `tool/perf-baseline.json`:

| Metrik                  | Değer      | Not                                                   |
| ----------------------- | ---------- | ----------------------------------------------------- |
| Soğuk açılış            | 759 ms     |                                                       |
| Sıcak açılış            | 154 ms     |                                                       |
| Bellek (PSS)            | 64,9 MB    |                                                       |
| **Kullanıcı indirmesi** | **~32 MB** | arm64 APK; arm32 30 MB                                |
| AAB dosyası             | 62 MB      | Yarısı hata ayıklama sembolü — **kullanıcı indirmez** |
| Kare maliyeti p10       | 11,87 ms   | Bütçe 12 ms · in-app `FrameTiming`                    |

> **"Uygulama 65 MB" demek yanlış olurdu.** AAB'nin neredeyse yarısı `BUNDLE-METADATA`
> (sembol dosyaları + ProGuard haritası); Play onları kullanıcıya göndermez. Doğru cümle:
> **kullanıcı ~32 MB indiriyor.**

---

## 5. ❌ YAYIN ENGELLERİ — üçü de sahibin işi

Kodda kalan engel **yok**. Bu üçü Play Console ve sunucu yapılandırmasında yapılır.

### E1 · Sunucu tarafı Play makbuz doğrulaması yapılandırılmamış

`GOOGLE_PLAY_SA_JSON` yok. Kod **fail-closed**: üretimde uç **503** döner ve sahte hak vermez —
yani güvenlik açığı değil, **eksik yetenek**. Sonucu şu:

> Kullanıcı satın alır, erişimi **o cihazda** açılır (cihaz defteri sayesinde), **ikinci cihazında
> açılmaz.**

**Yapılacak:** Play Console → API erişimi → servis hesabı → `GOOGLE_PLAY_SA_JSON`.
Ayrıntı: [`BILLING_AUDIT.md`](BILLING_AUDIT.md) §4.1

### E2 · Veri güvenliği formu doldurulmamış (ve beyan DEĞİŞTİ)

Uygulama artık analitik olayları ve çökme raporları topluyor (Faz 3–4). Eski beyanla yayına
çıkmak **yanlış beyandır** ve politika ihlalidir. Formun her satırının cevabı ve koddaki karşılığı
[`PLAY_DATA_SAFETY.md`](PLAY_DATA_SAFETY.md) içinde hazır.

**Yapılacak:** formu doldur · **hesap silme talebi URL'si** sağla · gizlilik politikasına
analitik/çökme bölümü ekle (form ile tutarlı olmak zorunda).

### E3 · Play Console ürünü tanımlanmamış

Tek yönetilen ürün: **`komple_ehliyet`** (399 TL, tek seferlik).
`STORE_LISTING.md` bu sprintte düzeltildi — eskiden var olmayan **beş** ürün sayıyordu ve o
listeyle kurulum yapılsaydı uygulamanın sorduğu tek ürün tanımsız kalırdı ("ürün bulunamadı",
satın alma hiç açılmaz).

---

## 6. ⚠ İYİLEŞTİRİLMESİ GEREKENLER — engel değil

| #   | Konu                              | Durum ve gerekçe                                                                                                                                     |
| --- | --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| İ1  | **İade bildirimi (Play RTDN)**    | Sunucu iadeyi kendiliğinden ÖĞRENMİYOR. Uzlaşma mekanizması hazır ve testli; eksik olan Pub/Sub akışı. O zamana kadar iade elle işlenir.             |
| İ2  | **Tablet ekran görüntüleri**      | Tablet DÜZENİ cihazda doğrulandı (taşma yok). Eksik olan yalnız mağaza görselleri — gerçek çözünürlükte bir tablet/öykünücü gerekiyor.               |
| İ3  | **Kare bütçesi dar**              | ANE-LX1'de p10 11,87 ms, bütçe 12 ms. 2018 orta segmentte 60 fps için yeterli ama **pay yok**; yeni bir animasyon eklenirse önce burası kırılır.     |
| İ4  | **`REFERRAL_IP_SALT`**            | Üretimde ayarlanmazsa geliştirme tuzu kullanılır ve IP hash'i tahmin edilebilir olur.                                                                |
| İ5  | **Sunucudan push (FCM)**          | Bildirimler tamamen YEREL. Sunucudan tetiklenen bildirim yok; Firebase yapılandırması ayrı bir iş.                                                   |
| İ6  | **Kampanya/ödül/bayrak yönetimi** | Arkalarında çalışan bir mekanizma yok. **Bilinçli olarak boş ekran EKLENMEDİ** — olmayan bir yeteneği varmış gibi göstermek yanıltıcı olurdu.        |
| İ7  | **"7 gün iade" ifadesi**          | Ödeme ekranındaki güven şeridinde duruyor. Play'in kendi penceresi 48 saat; 7 gün geliştiricinin **gönüllü taahhüdü** olur. Ürün kararı.             |
| İ8  | **Gerçek Play satın alması**      | İmzalı + Play'den yüklenmiş yapı gerektirir; bu ortamda yapılamaz. Mantık benzetimle uçtan uca test edildi ([`BILLING_AUDIT.md`](BILLING_AUDIT.md)). |

---

## 7. ✅ HAZIR olanlar

- **Çevrimdışı** — dersler, işaretler, sınav, ilerleme, rozetler, istatistikler internetsiz çalışıyor;
  13 kalıcı test koruyor. İnternet isteyen yüzeyler (AI sohbeti, topluluk, mağaza) **sessiz kalmıyor**.
- **Ödeme akışı (istemci)** — 12 durumun tamamı denetlendi; vazgeçme, beklemede ve iade düzeltildi.
- **Davet** — bağlantıdan kayda kadar zincir çalışıyor; huninin üç basamağı da ölçülüyor.
- **Gözlemlenebilirlik** — çökme, ağ, mağaza ve Google girişi hataları raporlanıyor; yönetici panosu var.
- **Bildirimler** — 8 tür, tür başına tercih, sessiz saat koruması.
- **Erişilebilirlik** — dokunma hedefi ve etiket yönergeleri altı ana yüzeyde testli; 217 durumluk
  tarama 320 dp, 1,3× yazı, açık tema, tablet ve yatay yönü kapsıyor.
- **Gizlilik** — ham IP saklanmıyor, analitik boyutlarında kişisel veri yok (testle korunuyor),
  istemcinin gönderdiği kimlik yok sayılıyor.

---

## 8. Önerilen sıradaki adımlar

1. **E1–E3'ü kapat** (sahip) — bunlar olmadan genel yayın yapılamaz.
2. **Kapalı betayı başlat.** Telemetri panosu (`/admin/telemetri`) ilk günden okunabilir durumda;
   huni ve hata grupları oradan izlenir.
3. **İlk hafta sonunda panoya bak.** Beklenen ilk sorular: kaç kişi ilk sınavı çözüyor, ödeme
   ekranından satın almaya dönüşüm ne, hangi hata kaç kişiyi etkiliyor.
4. **RTDN'yi bağla** (İ1) — iade otomasyonu için tek eksik parça.
5. **Her sürümden önce** `tool/perf_lab.sh` ve `flutter test integration_test -d <cihaz>`.

---

## 9. Dürüstlük notları

- **Gerçek Play satın alması denenmedi** ve denenemez (§6 İ8). "Satın alma çalışıyor" cümlesi
  benzetim + kod denetimi düzeyinde doğrudur; mağaza katmanının kendisi kapalı beta ile sınanacak.
- **Başarım sayıları tek cihaza aittir** (ANE-LX1, Android 9, 2018). Daha yeni cihazlarda daha
  iyi olması beklenir; taban çizgisi o cihaz için geçerlidir.
- **Kare metriği `gfxinfo`'dan ALINMADI.** İlk denemede alınmıştı ve "kare p90 = 4950 ms" gibi
  uydurma bir sayı üretiyordu: `gfxinfo` Android'in kendi çizim sistemini ölçer, Flutter onu
  kullanmaz. Sayı rapordan çıkarıldı ve ölçüm uygulama içindeki `FrameTiming`'e bırakıldı.
- **Tablet ekran görüntüsü üretilmedi.** Telefondan alınan görüntü fiziksel çözünürlükte kalıyor;
  mağazaya "tablet görüntüsü" diye ölçeklenmiş bir telefon karesi koymak yanıltıcı olurdu.
