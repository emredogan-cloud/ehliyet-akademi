# Beta Faz 5 Raporu — Giriş Ekranı Yeniden Tasarımı

**Hazırlandı:** 2026-07-26 · cihazda doğrulandı: `AYXSUKIVJVPZ7HPZ` (Redmi M1908C3JGG · Android 11)

## Karar: 🟢 GO

`flutter analyze` **0** · `flutter test` **326** (+15) · web **516** · `@ea/db` **6** ·
`content-schema` **17** · `question-bank` **10** · `srs-engine` **12** ·
`pnpm lint` 0 hata · `format` · `verify` · `typecheck` temiz.

---

## 1. Marka sorunu — rötuş DEĞİL, yeniden çerçeveleme

`ASSET_GENERATION_LIBRARY.md` §4.2 uyarısı: `022-assets.png` içinde **üçüncü taraf araç markası
amblemi okunuyor** (aracın ızgarasında, 1536×1024 içinde ~x 773–829, y 615–692).

**Üç rötuş denemesi yapıldı ve üçü de reddedildi** — her biri kendi ekran görüntüsüyle incelendi:

| Deneme | Yöntem                              | Sonuç                                                  |
| ------ | ----------------------------------- | ------------------------------------------------------ |
| v1     | Izgaradan yama klonlama             | ❌ Dikdörtgen **dikiş izleri** açıkça görünüyor        |
| v2     | Yumuşak maskeli bulanıklaştırma     | ❌ Amblem şekli **hâlâ seçiliyor** (yüksek kontrast)   |
| v3     | Izgara tonuyla doldurma + yumuşatma | ❌ Beyaz kaputa taşan **siyah leke**; sansür görüntüsü |

Bu ortamda içerik-farkındalıklı dolgu (inpainting) aracı **yok**. Kötü bir rötuş sevk etmek,
sorunu çözmek değil yerini değiştirmek olurdu.

**Alınan karar: kompozisyonu değiştir.** Kaynağın **üst %58'i** kırpıldı
(`1536×600+0+0` → `1080×422`). Bu kırpma:

- Amblemi **kareye hiç sokmaz** (ızgara tamamen çerçeve dışında kalır) — rötuş artefaktı yok.
- Kaynağın **bilinçli olarak boş bıraktığı sol bölgesini korur** — marka kimliği oraya yerleşir.
- Gece İstanbul silueti, kule, sürücü kursu aracı, trafik ışığı ve işaretleri **korur**.

> Ölçülen dosya: **21.194 B (20,7 KB)** WebP — varlık bütçesi 150 KB'nin çok altında.
> `-quality` bayrağı ImageMagick tarafından yok sayılıyor (bilinen ortam kısıtı, bellek §P);
> yine de çıktı boyutu ve görsel bütünlük doğrulandı.

## 2. Mockup'lar widget olarak uygulandı

`023` (giriş formu) ve `024` (güven şeridi) **raster sevk EDİLMEDİ** — Faz 1'in gerekçesi
korundu: gömülü metin temaya uymaz, yazı tipi ölçeğiyle büyümez, çevrilemez, alanlar zaten
etkileşimli olmak zorunda.

Uygulanan tasarım dili (hepsi **token** üzerinden — `design_tokens_test.dart` sabit rengi engelliyor):

| Mockup öğesi         | Uygulama                                                         |
| -------------------- | ---------------------------------------------------------------- |
| Işıyan kenarlı kart  | `GlowCard` (mevcut ilkel)                                        |
| Başlık + alt başlık  | `Tekrar hoş geldin` / `Devam etmek için bilgilerini gir.`        |
| Yuvarlak alanlar     | Mevcut `InputDecoration` teması + öncü ikonlar                   |
| Gradyan CTA + ok     | `GradientPillButton(trailingIcon: arrow_forward)` (mevcut ilkel) |
| "veya" ayırıcı       | Korundu (yalnız Google yapılandırılmışsa)                        |
| Güven şeridi (3 öğe) | `_TrustStrip` + `IconBadge` — dar ekranda dikey listeye düşer    |

## 3. Mockup'tan bilinçli SAPMALAR — üçü de testle sabitlendi

### 3.1 "Apple ile giriş" KONMADI

iOS derlemesi yok (macOS yok). Çalışmayan bir düğme **ölü gezinmedir** (disiplin kural 3).
Test: `expect(find.textContaining('Apple'), findsNothing)`.

### 3.2 "Şifremi unuttum?" SÜS DEĞİL — gerçek uç çağırıyor

Mockup'ta bu bağlantı var. Ölü bırakmak yasak olduğu için **gerçekten uygulandı**. Sunucu
tarafı zaten mevcuttu ve **yeni uç yazılmadı**:

```
POST /api/auth/forgot  {email}  → hız sınırlı (5/dk) · hesap varlığını SIZDIRMAZ
                                 · üretimde token asla yanıtta dönmez
→ e-posta ile /sifirla?token=… bağlantısı (web'de tamamlanır)
```

Mobilde ayrı bir sıfırlama ekranı **yoktur** — olsaydı kullanıcının token'ı elle girmesi
gerekirdi. Sıfırlama web sayfasında tamamlanır; bu bilinçli bir kapsam kararıdır.

**Sunucunun sızdırmama davranışı arayüze taşındı:** yanıt ne olursa olsun aynı mesaj gösterilir —
_"Bu adrese kayıtlı bir hesap varsa sıfırlama bağlantısını gönderdik."_ Arayüz, sunucudan daha
fazlasını **iddia etmez**.

### 3.3 AppBar KALDIRILDI (cihazda görülen kusur)

İlk uygulamada saydam bir `AppBar` vardı. Cihazda görüldü: **ekran kaydırıldıkça geri oku hero'daki
marka işaretinin üstüne biniyordu** (`b5_07`). Üst alan hero'ya devredildi; geri düğmesi hero'nun
içinde, durum çubuğu boşluğuna saygılı duruyor. Testler: `find.byType(AppBar)` **hiçbir şey
bulmamalı**, ve geri düğmesi ekranı gerçekten kapatmalı.

## 4. "MEB müfredatına uygun" — Faz 1 uyarısının çözümü

Faz 1, bunun **doğrulanabilir bir iddia** olduğunu ve kaynak gösterilemiyorsa kullanılmaması
gerektiğini yazmıştı. Depo tarandı:

```
apps/web/app/(app)/giris/page.tsx:15
  'MEB/MTSK müfredatına uygun, güncel ve güvenilir eğitim içerikleri.'
apps/web/app/(marketing)/page.tsx:95
  'Resmî MEB müfredatından, kendi ifademizle. Kopya soru yok.'
```

Bu, ürünün **hâlihazırda üretimde yayında olan** iddiasıdır — üstelik **aynı yüzeyde** (web giriş
sayfası). Dolayısıyla mobilde yeni ve kaynaksız bir iddia üretilmiyor; **var olan ifadeyle
birebir tutarlı** kalınıyor (`MEB/MTSK müfredatına uygun`). Test bunu sabitliyor.

## 5. Testler — +15

| Küme                      | Sayı | Kapsam                                                                                    |
| ------------------------- | ---: | ----------------------------------------------------------------------------------------- |
| Hero + üst alan           |    4 | Varlık gösteriliyor · dekoratif (semantik sızdırmaz) · AppBar yok · geri çalışıyor        |
| Güven şeridi              |    2 | Üç güvence · müfredat ifadesinin ürünle tutarlılığı                                       |
| Bilinçli sapmalar         |    2 | Apple YOK · "Şifremi unuttum?" yalnız giriş kipinde                                       |
| Parola sıfırlama          |    5 | Uca iletiliyor · sızdırmayan mesaj · geçersiz e-posta gitmiyor · vazgeçme · sunucu hatası |
| Mevcut yolların korunması |    2 | Alanlar/düğme/kip geçişi · parola göster-gizle ipucu (E13)                                |

### Düzeltilen bir test ZAYIFLIĞI (yeni hata değil)

`auth_test.dart`'taki giriş akışı testi düğmeyi `find.text('Giriş yap').last` ile arayınca
**AppBar başlığına** dokunuyordu; giriş hiç gerçekleşmiyordu. Test yine de geçebiliyordu, çünkü
`find.text('user@ea.dev')` **giriş formuna yazılan metni** buluyordu — yani yanlış-pozitif.
Artık düğme açıkça hedefleniyor (`find.widgetWithText(GradientPillButton, …)`) ve giriş ekranının
gerçekten kapandığı ayrıca doğrulanıyor.

### Test yüzeyi

Uzun ekranlar için paylaşılan `useTallSurface()` yardımcısı eklendi (800×**1400**). Varsayılan
800×600'de gönder düğmesi görünüm alanının dışında kalıyor ve `tap()` ıskalıyordu. **Genişlik
800'de bırakıldı**: testlerin Ahem yazı tipi gerçeğinden geniştir ve daha dar bir yüzeyde cihazda
**bulunmayan** taşmalar üretiyor (Faz 3'te ölçüldü). Ödeme ekranı testleri de bu yardımcıya taşındı.

## 6. Cihaz doğrulaması

**Cihaz yine değişti** — bu oturumda iki telefon dönüşümlü takıldı. Faz 5, belgelerin **özgün**
cihazında doğrulandı:

| Faz   | Cihaz              | Android |
| ----- | ------------------ | ------- |
| 3, 4  | `jfzxugsgnnvsrsg6` | 13      |
| **5** | `AYXSUKIVJVPZ7HPZ` | **11**  |

İkisi birlikte Android 11 **ve** 13 kapsamı veriyor. Yardımcı betik artık cihazı **otomatik
algılıyor** (sabit kimlik yok).

| #   | Doğrulanan                                                               | Kanıt           |
| --- | ------------------------------------------------------------------------ | --------------- |
| 1   | Hero + marka kimliği + kart + güven şeridi — **koyu tema**               | `b5_09`         |
| 2   | Aynı ekran — **açık tema** (gradyan gece görselini açık zemine eritiyor) | `b5_15`         |
| 3   | AppBar çakışması düzeldi (öncesi `b5_07`, sonrası `b5_09`)               | `b5_07`/`b5_09` |
| 4   | Parola sıfırlama diyaloğu açılıyor, e-posta odaklanıyor                  | `b5_10`         |
| 5   | **GERÇEK ÜRETİM UCU çağrıldı** → dürüst, sızdırmayan mesaj               | `b5_13`         |
| 6   | `logcat -b crash` **boş** · `RenderFlex overflowed` **yok**              | —               |

> **§5 hakkında:** var olmayan bir adresle üretim `/api/auth/forgot` ucuna gerçek bir istek
> gönderildi. Sunucu hesabı bulamadığı için **e-posta göndermez**; yan etkisi yoktur ve bu,
> mobil→sunucu sözleşmesinin uçtan uca çalıştığını kanıtlar.

## 7. Dürüst sınırlar

1. **Marka amblemi silinmedi, çerçeve dışında bırakıldı.** Kaynak PNG değişmedi; sevk edilen
   varlıkta amblem yoktur. Aracın gövdesindeki jenerik "SÜRÜCÜ ADAYI KURS ARACI" tabelası ve
   plakası görselde kalır — bunlar üretici markası değildir.
2. **Google düğmesi cihazda görünmedi** çünkü `GOOGLE_SERVER_CLIENT_ID` verilmeden derlendi
   (doğru davranış — Faz 2'de testle sabit). Google yolunun görünür hâli Faz 2'de doğrulanmıştı.
3. **Gerçek bir hesapla giriş denenmedi** bu fazda; giriş akışının kendisi Faz 2'de ve widget
   testleriyle kapsanıyor.
4. **Parola sıfırlamanın e-posta teslimi doğrulanmadı** — var olmayan bir adres kullanıldığı için
   sunucu zaten göndermez. Gerçek teslim `RESEND_API_KEY` yapılandırmasına bağlıdır.
5. **Dar ekran (<420 dp) yatay güven şeridi görülmedi** — cihaz 393 dp olduğu için dikey düzen
   çalıştı. Yatay dal yalnız geniş ekranlarda devreye girer ve cihazda **doğrulanmadı**.

## 8. Sonraki faz

Faz 6 — **Onboarding cilası**. Girdiler `ASSET_GENERATION_LIBRARY.md` §4.3'te hazır: beş
onboarding görseli **695–820 px**, 3× cihazda tam genişlik için **1080 px** gerekiyor → yalnız
yerleşim değil, **varlık çözünürlüğü** işi de. `OnboardingDensity` mimarisi (E6) **korunur**.
