# Yayın Denetim Planı (Faz 13'te uygulanacak)

Faz 13'te beş ayrı şapka takılarak denetim yapılır. Bu belge **denetimin nasıl yürütüleceğini**
önceden tanımlar ki denetim, "her şey iyi görünüyor" demenin kibar bir yolu olmasın.

**Çıktı:** `RELEASE_AUDIT_REPORT.md` — her bulgu **kanıtlı** (komut çıktısı, ekran görüntüsü veya
dosya:satır), her sonuç **GO / NO-GO**.

---

## Denetim ilkeleri

1. **Kanıtsız iddia yok.** "Çalışıyor" demek yetmez; hangi komutun ne döndürdüğü yazılır.
2. **Ölçülemeyen ölçülmüş gibi yazılmaz.** (E13'te kare düzeyinde jank ölçülemedi ve öyle
   yazıldı — aynı dürüstlük sürer.)
3. **Bulgu şiddeti:** `BLOCKER` (yayın durur) · `MAJOR` (yayından önce düzeltilir) ·
   `MINOR` (kaydedilir, sonraya kalabilir).
4. Her `BLOCKER` ve `MAJOR` **aynı fazda düzeltilir**; düzeltme de kanıtlanır.

---

## 1. Google Play İnceleyicisi şapkası

Soru: _"Bu uygulamayı reddeder miyim?"_

| #   | Kontrol                                                        | Yöntem                                                 | Şiddet  |
| --- | -------------------------------------------------------------- | ------------------------------------------------------ | ------- |
| 1   | Test hesabıyla uygulamaya **girilebiliyor** mu                 | Hesapla giriş denenir                                  | BLOCKER |
| 2   | Gizlilik politikası URL'si açılıyor mu                         | `curl -I` → 200                                        | BLOCKER |
| 3   | Veri Güvenliği formu **koddaki davranışla** aynı mı            | Kodda toplanan alanlar taranır, formla karşılaştırılır | BLOCKER |
| 4   | İzinler beyanla uyumlu mu, gereksiz izin var mı                | `aapt2 dump permissions`                               | MAJOR   |
| 5   | Kullanıcı üretimi içerik beyanı yapıldı mı, moderasyon var mı  | Şikâyet + engelleme akışları denenir                   | BLOCKER |
| 6   | **Üretken AI beyanı** ve uygunsuz çıktı bildirme yolu          | AI Koç yüzeyi denetlenir                               | MAJOR   |
| 7   | targetSdk Play'in asgarisini karşılıyor mu                     | `aapt2 dump badging` → 36                              | BLOCKER |
| 8   | AAB **upload key** ile imzalı mı                               | `apksigner verify --print-certs`                       | BLOCKER |
| 9   | Mağaza varlıkları eksiksiz mi (simge, Öne Çıkan Grafik, 2+ SS) | Play Console kontrolü                                  | BLOCKER |
| 10  | Çökme/ANR oranı eşiğin altında mı                              | Android vitals                                         | MAJOR   |

## 2. QA şapkası

Soru: _"Gerçek bir kullanıcı bunu bozabilir mi?"_

| Alan          | Senaryolar                                                                                         |
| ------------- | -------------------------------------------------------------------------------------------------- |
| Kimlik        | Google giriş · e-posta giriş · misafir · çıkış → giriş · yanlış parola · aynı e-posta iki yöntemle |
| Satın alma    | Satın al · **geri yükle** · iptal · anahtarsız derleme · mağaza yok                                |
| Çevrimdışı    | Uçak modunda her sekme · yarıda kesilen istek · yeniden bağlanma                                   |
| Topluluk      | Katıl · ayrıl · arkadaşlık döngüsü · engelle/kaldır · şikâyet · **avatar**                         |
| AI            | Uzun soru · boş soru · ağ kesintisi · akış sırasında ekrandan çıkma                                |
| Video         | Oynat · sar · bölüm · altyazı · tam ekran · arka plan → dönüş · premium kilidi                     |
| Yaşam döngüsü | Arka plan/ön plan · döndürme · düşük bellek · süreç öldürme sonrası durum                          |
| Veri          | Uygulama verisini temizle → ilk açılış · sunucu 500 döndüğünde                                     |

**Yöntem:** her senaryo gerçek cihazda yürütülür; kırılan her şey `BLOCKER`/`MAJOR` olarak
kaydedilir ve düzeltilir.

## 3. Güvenlik Mühendisi şapkası

| #   | Kontrol                                                         | Yöntem                                    |
| --- | --------------------------------------------------------------- | ----------------------------------------- |
| 1   | Depoda gizli değer var mı                                       | `gitleaks detect` (CI'da zaten açık)      |
| 2   | Google `idToken` **sunucuda** doğrulanıyor mu                   | Sahte/expired token ile entegrasyon testi |
| 3   | Satın alma **sunucuda** doğrulanıyor mu                         | Sahte `purchaseToken` reddediliyor mu     |
| 4   | Yetkilendirme istemciden **zorlanabiliyor** mu                  | İstemci yanıtı taklit edilerek denenir    |
| 5   | Engelleme **her yolda** uygulanıyor mu                          | E9 entegrasyon testleri + canlı uçlar     |
| 6   | Sızıntısız 404 korunuyor mu (engelli/yok/gizli ayırt edilmiyor) | Canlı uç karşılaştırması                  |
| 7   | Hız sınırlama etkin mi (`RATE_LIMIT_DISABLED` üretimde yok)     | Ortam değişkenleri denetimi               |
| 8   | `IAP_DEV_ACCEPT` üretimde kapalı mı                             | Ortam değişkenleri denetimi               |
| 9   | PII sızıntısı: yanıtlarda e-posta/gerçek ad var mı              | Topluluk uçlarının tam gövdeleri taranır  |
| 10  | Ağ trafiği HTTPS mi, sertifika doğrulaması açık mı              | İstemci yapılandırması                    |
| 11  | CodeQL bulguları                                                | CodeQL akışı                              |

## 4. Erişilebilirlik Mühendisi şapkası

| #   | Kontrol                                                       | Ölçüt                                            |
| --- | ------------------------------------------------------------- | ------------------------------------------------ |
| 1   | Her etkileşimli öğenin erişilebilir adı var mı                | `IconButton` tooltip taraması (E13'te 26/26 idi) |
| 2   | Dokunma hedefleri **en az 48×48 dp** mi                       | Kaynak + cihaz incelemesi                        |
| 3   | Metin kontrastı WCAG AA (4.5:1) karşılıyor mu                 | Token çiftleri hesaplanır                        |
| 4   | Ekran okuyucu ile temel akış tamamlanabiliyor mu              | TalkBack ile giriş → ders → soru                 |
| 5   | Büyük yazı tipinde (1.3×) yerleşim taşmıyor mu                | Cihazda font ölçeği artırılır                    |
| 6   | Hareket azaltma (reduce motion) saygı görüyor mu              | E6'daki `disableAnimationsOf` yolu doğrulanır    |
| 7   | Renk **tek başına** anlam taşıyor mu (ikon/metin destekli mi) | Durum göstergeleri incelenir                     |

## 5. Flutter Başarım Mühendisi şapkası

| #   | Kontrol                   | Yöntem                                                                                                                                  |
| --- | ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Soğuk açılış süresi       | `adb shell am start -W` (E13 taban değeri: **451 ms**)                                                                                  |
| 2   | Kare süreleri / jank      | **`--profile` derlemesi + DevTools timeline** — E13'te `gfxinfo` ve `SurfaceFlinger` veri vermedi; bu kez profil derlemesi kullanılacak |
| 3   | Bellek (galeri ekranları) | `adb shell dumpsys meminfo <pkg>` — işaret/mekanik galerilerinde                                                                        |
| 4   | APK/AAB boyutu            | `unzip -l` ile bileşen dökümü (E13: yerel kütüphaneler %90)                                                                             |
| 5   | Gereksiz yeniden çizim    | Kod incelemesi: `setState` kapsamı, `const` kullanımı                                                                                   |
| 6   | Görsel bellek             | Büyük görsellerde `cacheWidth`/`cacheHeight` kullanımı                                                                                  |
| 7   | Ağ                        | Gereksiz tekrar istek, önbellek başlıkları                                                                                              |

> **E13 dersi:** `dumpsys gfxinfo` Flutter için 0 kare döndürüyor (Flutter HWUI hattını atlar).
> Faz 13'te kare ölçümü **profil derlemesiyle** yapılacak; yine alınamazsa **alınamadı** diye
> yazılacak, uydurma sayı üretilmeyecek.

---

## Denetim çıktısının biçimi

`RELEASE_AUDIT_REPORT.md` şu bölümlerle yazılır:

```
## Özet — GO / NO-GO
## Bulgular tablosu (şiddet · alan · kanıt · durum)
## 1. Play İnceleyicisi
## 2. QA
## 3. Güvenlik
## 4. Erişilebilirlik
## 5. Başarım
## Düzeltilenler (kanıtıyla)
## Ölçülemeyenler (nedeniyle)
## Kalan riskler ve elle yapılacaklar
```

**Kapanış kuralı:** rapor, açık bir `BLOCKER` varken **GO** diyemez.
