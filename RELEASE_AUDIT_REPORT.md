# Nihai yayın denetimi

**Beta Faz 13 · 2026-07-27** · Denetlenen yapı: `app-release.aab` **64,4 MB** (64.352.068 bayt = 61,4 MiB) · sürüm `1.0.0+1`

Beş şapka takıldı: **Play İnceleyicisi · QA · Güvenlik · Erişilebilirlik · Flutter Başarım.**
Her bulgu ölçüldü; ölçülemeyenler "ölçülmedi" olarak yazıldı.

---

## 🎩 1. Play İnceleyicisi

### 1.1 İzinler — talep edilen her izin gerekçeli

Birleşik manifest'ten (APK üzerinden `aapt2 dump permissions`) **ölçüldü**:

| İzin                                | Kim istiyor              | Gerekçe                                        |
| ----------------------------------- | ------------------------ | ---------------------------------------------- |
| `INTERNET`                          | Flutter                  | Arka uç, içerik, video                         |
| `ACCESS_NETWORK_STATE`              | Flutter                  | Çevrimdışı durumunu dürüstçe göstermek         |
| `POST_NOTIFICATIONS`                | uygulama                 | Çalışma hatırlatıcıları (kullanıcı açarsa)     |
| `RECEIVE_BOOT_COMPLETED`            | uygulama                 | Yeniden başlatmada hatırlatıcıların kurulması  |
| `VIBRATE` · `WAKE_LOCK`             | bildirim/oynatıcı        | Bildirim geri bildirimi, video sırasında ekran |
| `USE_BIOMETRIC` · `USE_FINGERPRINT` | `local_auth` bağımlılığı | _(aşağıda ⚠️)_                                 |
| `com.android.vending.BILLING`       | `in_app_purchase`        | Uygulama-içi satın alma                        |

**⚠️ Bulgu (düşük):** `USE_BIOMETRIC` / `USE_FINGERPRINT` bir bağımlılıktan geliyor; uygulamada
biyometrik bir yüzey **yok**. Play bunu reddetmez ama izin listesi kullanıcıya gösterilir ve
gereksiz izin güven kaybettirir. **Karar:** Kapalı Test'i engellemez; bağımlılık gözden geçirmesi
yayın sonrasına bırakıldı.

**✅ Kritik olumlu:** `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` **yok**. Avatar seçimi
izin gerektirmeyen sistem seçicisiyle yapılıyor (Faz 7 kararı) — Play'in en sık sorduğu
"neden depolama izni?" sorusu hiç doğmuyor.

### 1.2 Politika uyumu

| Konu                 | Durum                                                                                      |
| -------------------- | ------------------------------------------------------------------------------------------ |
| Hedef SDK            | **36** (Play'in güncel şartının üstünde) · minSdk 24                                       |
| Uygulama kimliği     | `com.ehliyetegitim.ehliyet_akademi` — yayından sonra değişmez                              |
| İçerik iddiaları     | "MEB/MTSK müfredatına uygun" — ürünün mevcut ve yayındaki iddiasıyla tutarlı               |
| AI çıktısı           | Her yanıtın sonuna **kalıcı uyarı** eklenir: resmî kural için MEB/MTSK esastır             |
| Sahte içerik         | Video kataloğu `available`/`planned` ayrımı yapar; **sahte video yayınlanmaz**             |
| Üçüncü taraf markası | Giriş hero'sundaki araç görseli, marka amblemini kadraj dışında bırakacak biçimde kırpıldı |

### 1.3 İmza

```
jar verified.
Owner: CN=Emre Dogan, OU=Mobile, O=Ehliyet Akademi - Sınav 2026, L=adana, ST=TR, C=TR
Valid: 2026-07-26 → 2053-12-11
SHA256: 46:B2:DF:CE:…:07:D3
```

> `jarsigner`'ın PKIX uyarısı **beklenen** durumdur: yükleme anahtarı kendinden imzalıdır.
> `apksigner` bir AAB'yi doğrulayamaz — bu, Faz 4'te ölçülerek düzeltilmiş bir yanlış adımdı.

---

## 🎩 2. QA — akış akış

| Akış                           | Durum         | Kanıt                                                                                                             |
| ------------------------------ | ------------- | ----------------------------------------------------------------------------------------------------------------- |
| Onboarding (5 sayfa)           | ✅            | Cihaz: 4 adım da güvenli alanın %94–96'sını kaplıyor (R2)                                                         |
| AI karşılama popup'ı           | ✅            | Cihaz: Ana Sayfa'dan sonra açıldı, kapandı, **bir daha açılmadı** (R1)                                            |
| Giriş / kayıt                  | ✅            | 27 test · cihazda koyu + açık tema (R3)                                                                           |
| Google ile giriş               | ⚠️ koşullu    | Kod uçtan uca hazır ve sunucu doğrulamalı; **düğme yalnız derlemeye kimlik verilirse görünür**. Bu AAB'de verildi |
| Parola sıfırlama               | ✅            | Gerçek uç çağrılıyor; sunucu hesap varlığını sızdırmıyor                                                          |
| Satın alma (`in_app_purchase`) | ⚠️ ölçülemedi | Play imzalı yapı + Play Console gerektirir; **bu ortamda uçtan uca sınanamaz**                                    |
| RevenueCat                     | ✅ kod hazır  | Webhook ucu yazıldı (11 test, fail-closed); pano değerleri bekliyor                                               |
| Geri yükleme                   | ⚠️ ölçülemedi | Aynı sebep                                                                                                        |
| Çevrimdışı                     | ⚠️ kısmi      | Uygulama açılıyor ve yerel içerik çalışıyor; **videolar yalnız ağdan** oynuyor (Faz 12'de ölçüldü)                |
| Topluluk                       | ✅            | Sunucu testleri + cihaz gezintisi                                                                                 |
| AI Koç (akan)                  | ✅            | Gerçek HTTP + gerçek model: 22 parça, ilk parça 0,64 s                                                            |
| Videolar                       | ✅            | 7 animasyon, 2,3 MB, bölüm/altyazı sapması **yapısal olarak imkânsız**                                            |
| Öğren → kabin detayları        | ✅            | 39 kumanda, zoom'lu detay (Faz 10)                                                                                |
| Ders sayfası                   | ✅            | Hero + okuma ilerlemesi + türetilmiş zorluk (Faz 11)                                                              |

---

## 🎩 3. Güvenlik

| Kontrol                | Sonuç                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| Depoda gizli değer     | **Yok** — `gitleaks` CI'da yeşil; `pnpm verify` 566 dosya tarıyor                                      |
| `.env` depoda mı       | Hayır; yalnız `.env.example` **şablonları**                                                            |
| CodeQL                 | ✅ yeşil (son üç commit)                                                                               |
| Oturum modeli          | Bearer + sunucu tarafı oturum; çok cihaz destekli                                                      |
| Parola sıfırlama       | Hesap varlığını **sızdırmaz** (aynı yanıt)                                                             |
| Hız sınırı             | AI uçlarında 20/dk; **akan uç aynı kovayı kullanır** (atlatma yolu yok)                                |
| Avatar yükleme         | Dar MIME listesi (JPEG/PNG/WebP), 512 KB, 6/dk, üyelik şartı — SVG ve Lottie **bilinçli olarak yasak** |
| IAP grant              | **Fail-closed**: doğrulama yapılandırılmamışsa üretimde grant reddedilir                               |
| RevenueCat webhook     | **Fail-closed**: sır yoksa 503, hiçbir şey yazmaz; sabit zamanlı karşılaştırma; idempotent             |
| AI halüsinasyon kapısı | Akıştan **önce** çalışır; eşleşme yoksa model kapsam-dışını nazikçe reddeder                           |

**⚠️ Bulgu (orta):** `.env` ve `apps/web/.env.local` içinde iki anahtar `AD =değer` biçiminde
(eşittirden önce boşluk). `dotenv` tolere eder, kabuk (`source .env`) **etmez**. Sızıntı değil ama
sessiz bir "değişken tanımsız" hatası üretebilir. `FINAL_ENVIRONMENT_GUIDE.md` §10'da yazılı.

---

## 🎩 4. Erişilebilirlik

| Kontrol           | Sonuç                                                                                                          |
| ----------------- | -------------------------------------------------------------------------------------------------------------- |
| Hareket azaltma   | ✅ Sistem "animasyonları azalt" derse maskot animasyonu ve ders hero hareketi **hiç kurulmaz** (testle ölçülü) |
| Büyük yazı tipi   | ✅ Onboarding 1,3× ölçekte kaydırmasız (kapı testi)                                                            |
| Küçük ekran       | ✅ 360×640 ve 393×780/851 ölçülerinde taşma yok                                                                |
| Ekran okuyucu     | ✅ Parola göster/gizle ipucu, marka kilidi etiketi, dekoratif görseller `excludeFromSemantics`                 |
| Dokunma hedefleri | ✅ CTA'lar tam genişlik; kart hedefleri ≥48 dp                                                                 |
| Renk kaynağı      | ✅ Sabit renk yasak — `design_tokens_test.dart` zorluyor                                                       |

**⚠️ Açık kalan (düşük, Faz 8'den):** 360×640 @1,3× ölçüsünde **24 px yatay taşma** — kaynağı
izole edilemedi; ilgili test kaydırmasızlığı doğruluyor ve taşmanın kapsam dışı olduğunu satır
içinde yazıyor. Cihazda 393 dp'de görülmüyor.

---

## 🎩 5. Flutter başarım

| Ölçüm                 | Değer                                                                                                 |
| --------------------- | ----------------------------------------------------------------------------------------------------- |
| AAB                   | **64,4 MB** (Play, cihaz başına indirmeyi bölerek küçültür)                                           |
| APK (evrensel)        | 76,1 MB                                                                                               |
| Flutter / Dart        | 3.41.9 · stable                                                                                       |
| Simge ağaç budama     | ✅ MaterialIcons 1,65 MB → 21,8 KB (%98,7)                                                            |
| Cihazda taşma/istisna | **0** (`RenderFlex overflowed` / `EXCEPTION CAUGHT`) — R2, R3, F9, F10, F11 doğrulamalarının hepsinde |
| Görsel bellek         | Hero'lar `cacheWidth` ile gösterim genişliğine indiriliyor                                            |
| Akan AI               | İlk metin **0,64 s** (öncesi: 4,94 s boş ekran)                                                       |

**⚠️ Bulgu (düşük):** 64,4 MB (61,4 MiB), bir sınav uygulaması için büyük. Kaynağı **varlıklar** (video +
illüstrasyon + maskot). Kapalı Test'i engellemez; yayın sonrası varlık optimizasyonu adayıdır.

---

## 6. Bulgu özeti

| #   | Şiddet | Bulgu                                             | Karar                                    |
| --- | ------ | ------------------------------------------------- | ---------------------------------------- |
| 1   | Orta   | `.env` anahtarlarında eşittirden önce boşluk      | Belgelendi; düzeltilmesi önerilir        |
| 2   | Düşük  | Kullanılmayan biyometrik izinler (bağımlılıktan)  | Yayın sonrası                            |
| 3   | Düşük  | 24 px yatay taşma (360×640 @1,3×)                 | Açıkça belgeli, kapsam dışı              |
| 4   | Düşük  | 64,4 MB paket boyutu                              | Yayın sonrası optimizasyon               |
| 5   | Bilgi  | Videolar yalnız ağdan                             | Faz 12'de sıradaki iş olarak işaretlendi |
| 6   | Bilgi  | Satın alma/geri yükleme bu ortamda **ölçülemedi** | Kapalı Test'in ilk işi                   |

**Yayın engelleyici bulgu: YOK.**

---

## 7. Yayın kararı

**Kapalı Test için ONAYLANDI.**

Kalan elle işler (ikisi de kod değil):

1. `REVENUECAT_WEBHOOK_SECRET` + RevenueCat panosu — _isteğe bağlı_, yayın engellemez.
2. Üretim veritabanı temizliği — `DATABASE_CLEANUP_REPORT.md` §7, **onay bekliyor**, yayın
   engellemez.
3. AAB'nin Play Console'a yüklenmesi.
