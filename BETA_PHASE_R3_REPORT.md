# Beta Faz R3 — Giriş ekranı yeniden tasarımı

**Durum:** ✅ Tamamlandı · **Kapsam:** `apps/mobile` (giriş/kayıt ekranı)
**Yerine geçtiği:** Faz 5'in giriş ekranı tasarımı

---

## A. Geri bildirim ve teşhis

> "Mevcut giriş tasarımı verilen referansı yakalamıyor. Esnetilmiş, düz, sönük duruyor ve verilen
> görseli yanlış kullanıyor. Tamamen yeniden tasarla. Hedef doğruluk: %99."

Teşhis tek bir satırda toplanıyordu:

```dart
SizedBox(height: 232 + topPad)  →  Image.asset(authHero, fit: BoxFit.cover)
```

Varlığın en-boy oranı **2,56:1**; kutu ise 393×232 ≈ **1,69:1**. `BoxFit.cover` bu farkı **yatay
kırparak** kapatır: görsel önce kutu yüksekliğine ölçeklenir (genişlik 594 px olur), sonra 393
px'e kırpılır. Kaybolanlar:

| Kaybolan                                   | Neden önemli                                |
| ------------------------------------------ | ------------------------------------------- |
| Trafik lambası · yaya geçidi · 50 tabelası | Referansın sağ kolonunun tamamı             |
| Solda **bilinçli bırakılmış boş bölge**    | Referansta marka kimliği tam oraya oturuyor |
| Tavan tabelası ("SÜRÜCÜ ADAYI KURS ARACI") | Sahnenin ne olduğunu anlatan tek öge        |

Geriye ortada kalan gökyüzü şeridi kalıyordu — "sönük" görünmesinin sebebi buydu. Marka kimliği de
referanstaki **logo kilidi** değil, jenerik bir ikon + düz metindi.

---

## B. Yapılanlar — kırpmak değil, kompozisyonu yeniden kurmak

### 1. Marka kilidi varlık olarak üretildi

Referans, `apps/assets/app_icon.png` içindeki logo kilidini kullanıyor. Varlık **opak** koyu
lacivert zeminli; olduğu gibi bindirilince hero'nun üstünde belirgin bir **dikdörtgen kenar**
oluşuyor. Zemin rengine uzaklığa göre **yumuşak alfa rampasıyla** (12→46) anahtarlandı:

- düz zemin şeffaflaşır,
- amblemin **koyu yol/araç bölgeleri korunur** (sert eşik onları da silerdi),
- içerik kutusuna kırpılıp 760 px'e indirildi → `brand_lockup.webp`.

### 2. Görsel artık **esnetilmiyor ve kırpılmıyor**

```dart
static const _heroAspect = 1080 / 422;   // varlığın ÖLÇÜLEN oranı
final art = w / _heroAspect;             // çizilecek yükseklik genişlikten türer
Positioned(left: 0, right: 0, bottom: 0, height: art,
  child: Image.asset(AppImages.authHero, fit: BoxFit.fitWidth, ...))
```

Görsel **tam genişlikte, alta yaslı** çizilir. Hiçbir öge kırpılmaz. Üstte kalan alan, görselin
kendi gece göğüyle **aynı renktedir**; üstüne inen dikey degrade dikişi tamamen yok eder →
referanstaki "tek parça hero" hissi.

### 3. Marka bloğu referanstaki yerine oturdu

Kilit + slogan, kaynağın **solda bıraktığı boşluğa** yerleşir. Kilidin ölçüsü **genişliğe**
bağlanır (`w * 0.383`), yüksekliğe değil: referans sayfa 2:3, telefon ~9:19,5 — dikey oran birebir
eşlenemez, genişlik eşlenebilir.

### 4. Form kartı ve güven şeridi referansa hizalandı

| Öge             | Değişiklik                                                                  |
| --------------- | --------------------------------------------------------------------------- |
| Başlık          | "Tekrar Hoş Geldin! 👋" · sıkı harf aralığı                                 |
| Alan ikonları   | Gri → **teal** (yalnız bu ekranda; genel tema değişmedi)                    |
| Alan etiketleri | "E-posta adresiniz" · "Şifreniz"                                            |
| CTA             | "Giriş Yap" / "Kayıt Ol"                                                    |
| Kip geçişi      | Soru **gri**, eylem **teal** (`Text.rich`) — tek renkken eylem görünmüyordu |
| Güven şeridi    | Dolgulu rozet → **parlayan teal anahat ikon**, teal kenar + dış parıltı     |

---

## C. Ölçüm sırasında yakalanan üç gerçek kusur

Bunlar tahmin değil; ikisi testte, biri cihazda yakalandı.

1. **`RenderImage` dokunuşu YUTUYOR.** Marka kilidi geri düğmesinin üstüne geldiğinde düğme
   tıklanamaz oldu; `tap()` "would not hit test on the specified widget" ile düştü. `RenderImage`
   kendini hit-test eder. Blok tamamen dekoratif olduğu için `IgnorePointer` ile sarıldı ve marka
   bloğu geri düğmesinin **altında** başlayacak şekilde konumlandırıldı.

   > Not: bu kusur ancak testteki iddia **gerçek metne** güncellenince görünür oldu. Eski iddia
   > (`find.text('Tekrar hoş geldin'), findsNothing`) yeni başlıkla artık hiçbir şeyle eşleşmediği
   > için **boş yere geçiyordu**. Yanlış bir "yeşil", kusuru saklıyordu.

2. **Açık temada hero çöküyordu.** Zemin `p.bg` (beyaza yakın) alınınca üç şey birden bozuldu:
   marka kilidinin beyaz yazısı beyaz zeminde kayboldu, koyu görselin üst kenarı beyazın içinde
   **sert bir dikdörtgen** oluşturdu, beyaz slogan okunmadı. Çözüm: hero her iki temada da
   **koyu kalır** — bu bir tema yüzeyi değil, bir **gece medyası bloğudur**. Değerler yine
   token paletinden gelir (`AppPalette.dark`), sabit renk yoktur.

3. **Durum çubuğu simgeleri.** (2)'nin doğrudan sonucu: açık temada sistem koyu simge çiziyor ve
   saat/pil, gece görselinin üstünde okunmuyordu. `AnnotatedRegion<SystemUiOverlayStyle>` ile
   açık simgeye geçildi.

---

## D. Referanstan bilinçli sapmalar

| Sapma                                          | Gerekçe                                                                                                                      |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **"Apple ile giriş" yok**                      | iOS derlemesi yok; çalışmayan düğme ölü gezinmedir (Faz 5 kararı korundu)                                                    |
| **Google düğmesi metni "Google ile devam et"** | Düğme hem girişe hem kayda hizmet ediyor; "giriş yap" kayıt kipinde yanlış olurdu                                            |
| **Aracın alt gövdesi yok**                     | Varlık, üçüncü taraf marka amblemini kareden çıkarmak için üstten kırpıldı (Faz 5 kararı). Alt kenar degradesi kesiği gizler |
| **Hero'da geri düğmesi var**                   | Referans tam sayfa bir giriş ekranı; bizimki sekme kabuğunun üstünde açılıyor, kapatma yolu şart                             |

**Aracın alt gövdesi** referansla aramızdaki tek görsel farktır ve ürün kararı değil, **hukuki
tercih** sonucudur: amblemi rötuşlamak yerine kadraj dışında bırakmak seçildi.

---

## E. Alt kenar degradesi — ölçülmüş denge

| Oran                              | Sonuç                                               |
| --------------------------------- | --------------------------------------------------- |
| 0,34                              | Aracın yarısı yıkanıyor                             |
| 0,20                              | Varlığın kesiği **sert bir çizgi** olarak görünüyor |
| **0,30 · duraklar [0,18 – 0,95]** | Kesik gizli, araç görünür ✅                        |

---

## F. Kapılar

```
flutter analyze            → 0 sorun
flutter test               → 366 test (auth: 27)
flutter build apk --release→ 79,7 MB
cihaz (AYXSUKIVJVPZ7HPZ, Android 11):
  koyu tema  ✅  açık tema ✅  durum çubuğu ✅  güven şeridi ✅
  RenderFlex overflowed / EXCEPTION CAUGHT → 0
kanıt: r3_05 (koyu) · r3_09 (açık) · r3_06 (güven şeridi)
```

---

## G. Değişen dosyalar

| Dosya                                                                                 | Değişiklik                                                                                |
| ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `assets/img/brand_lockup.webp`                                                        | **yeni** — anahtarlanmış marka kilidi                                                     |
| `lib/core/assets.dart`                                                                | `brandLockup` + üretim gerekçesi                                                          |
| `lib/features/auth/auth_screen.dart`                                                  | hero yeniden kuruldu · form ve güven şeridi hizalandı · tema bağımsız hero · durum çubuğu |
| `test/auth_test.dart` · `test/auth_redesign_test.dart` · `test/google_auth_test.dart` | referans metinlerine ve marka kilidine göre güncellendi                                   |
