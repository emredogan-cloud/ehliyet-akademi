# Varlık Üretim Kütüphanesi

**Durum:** Faz 1 tamamlandı — envanter **gerçek taramadan** çıkarıldı, uydurma kayıt yoktur.

Bu belge, projede kalan **her yer tutucu görselin** kaydını ve onu üretmek için kullanılacak
**üretime hazır GPT Image promptunu** tutar. Amaç: görsel üretecek kişinin bu dosyadan başka
hiçbir şeye ihtiyaç duymaması.

---

## 0. Faz 1 denetim özeti — ölçülmüş

| Bulgu                                            | Sonuç                                                               |
| ------------------------------------------------ | ------------------------------------------------------------------- |
| Mobil varlık envanteri                           | 263 dosya · 4,7 MB · `dash` 60 · `img` 21 · `mech` 101 · `signs` 81 |
| **Yetim (kodda referanssız) varlık**             | **0** — hepsi kullanılıyor                                          |
| **Emoji ile idare edilen boş/hata durumu**       | **38 çağrı yeri**                                                   |
| Bunların kapsandığı **ayrı illüstrasyon** sayısı | **14** (emoji'ler tekrar ediyor)                                    |
| Giriş ekranında görsel                           | **HİÇ YOK** — Faz 5'in gerekçesi                                    |
| Onboarding görselleri                            | 695–820 px → 3× cihaz için **1080 px gerekiyor**                    |
| Yordamsal çizim (`CustomPainter`)                | 4 adet — **yer tutucu DEĞİL**, veri görselleştirme                  |

### Yer tutucu olmayanlar (bilerek dışarıda bırakıldı)

- **`CustomPainter` × 4** (`readiness_radar`, `result_view` halkası, `brand` direksiyon,
  `readiness_ring`): bunlar veriyi çizen bileşenler; raster görselle değiştirilemez, değiştirilmemeli.
- **Trafik işaretleri (81) ve ikaz ışıkları (60):** E1/E3'te resmî vektörlerle değiştirildi.
  **Mevzuata bağlı**, üretilmez.
- **Mekanik fotoğraflar (101):** E2'de gerçek fotoğraflarla dolduruldu.

---

## 1. Kayıt şeması

Her giriş on bir alan taşır: **Ekran · Widget · Mevcut varlık · Değiştirme gerekçesi ·
GPT Image promptu · Görsel stil · Dosya adı · Uzantı · Hedef çözünürlük · Kayıt dizini ·
Kullanım yeri.**

### Çözünürlük kuralı

Hedef cihaz 1080×2340 (3×). Gösterim genişliği `W` dp ise üretim genişliği **`W × 3`** olmalıdır.

| Kullanım                    | Gösterim (dp) | Üretim (px)   |
| --------------------------- | ------------- | ------------- |
| Tam genişlik hero           | 360           | **1080**      |
| Boş durum illüstrasyonu     | 160           | **480×480**   |
| Onboarding ana illüstrasyon | 300–340       | **1080×1080** |
| Liste öğesi küçük görsel    | 80            | 240           |

## 2. Stil aileleri

Yeni görsel dil **getirilmez**. Marka paleti:

```
primary  #14b8a6   primary-700 #0b7268   accent #F59E0B
danger   #ef4444   success #22c55e
koyu zemin #050b16 / #0b1523      açık zemin #f4f6fb / #ffffff
```

| Aile                  | Nerede                        | Nitelik                                      |
| --------------------- | ----------------------------- | -------------------------------------------- |
| **Maskot (baykuş)**   | Onboarding, boş durum, AI Koç | Yumuşak 3B, teal tüy, gözlük, sıcak/öğretici |
| **Şematik animasyon** | Manevra videoları             | Kuş bakışı, düz renk, token renkleri         |
| **Gerçek fotoğraf**   | Araç tekniği, kabin           | Gerçek parça, nötr zemin, **markasız**       |
| **Resmî vektör**      | İşaretler, ikaz ışıkları      | Mevzuata birebir — **stil serbestisi yok**   |
| **Editoryal**         | Ders hero, premium            | Düz/yarı-düz, marka paleti                   |

## 3. Prompt standardı

Şablon:

```
[KONU]. [STİL AİLESİ] tarzında: [stil sözcükleri].
Kompozisyon: [çerçeveleme ve yerleşim].
Renk paleti: [hex].
Arka plan: [şeffaf / düz #hex].
En-boy: [oran] · Çözünürlük: [WxH].
Negatif: metin yok, filigran yok, marka/logo yok, [duruma özel].
```

**Kural:** üretilecek hiçbir görselde **metin bulunmaz.** Metin widget'la çizilir — yoksa
temaya uymaz, yazı tipi ölçeğiyle büyümez ve çevrilemez.

---

## 4. ENVANTER

### 4.1 Boş ve hata durumları — 14 illüstrasyon, 38 çağrı yerini kapatır

Şu an hepsi `AppEmptyState(emoji: …)` ile emoji gösteriyor. Emoji bir illüstrasyon değildir:
cihaz yazı tipine göre değişir, marka dili taşımaz, ölçeklenince bulanıklaşmaz ama kaba durur.

`AppEmptyState` widget'ı Faz 1 kapsamında **değiştirilmez**; `illustration` parametresi eklemek
ve emoji'yi geriye dönük uyumlu bırakmak ilgili fazın işidir.

---

#### EM-01 · Bağlantı yok / veri alınamadı ← **9 çağrı yeri**

| Alan              | Değer                                                                                                                                                                                                                                                                                    |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Ekran**         | Topluluk · Arkadaşlar · Sohbet · Tartışma · Gruplar · Meydan okuma · Engellenenler · İçerik kapsamı · Soru bankası                                                                                                                                                                       |
| **Widget**        | `community_screen.dart:228` · `friends_screen.dart:96` · `chat_screen.dart:67` · `discussions_screen.dart:108` · `groups_screen.dart:101` · `challenges_screen.dart:95` · `blocked_users_screen.dart:81` · `learn/widgets/content_scope.dart:36` · `practice/widgets/bank_scope.dart:36` |
| **Mevcut varlık** | Emoji `📡`                                                                                                                                                                                                                                                                               |
| **Gerekçe**       | Dokuz ayrı ekranda tekrarlanan en görünür hata durumu; emoji marka dili taşımıyor ve "sorun geçici, tekrar dene" duygusunu vermiyor                                                                                                                                                      |
| **Görsel stil**   | Maskot                                                                                                                                                                                                                                                                                   |
| **Dosya adı**     | `empty_offline`                                                                                                                                                                                                                                                                          |
| **Uzantı**        | `.webp`                                                                                                                                                                                                                                                                                  |
| **Çözünürlük**    | 480×480                                                                                                                                                                                                                                                                                  |
| **Dizin**         | `apps/mobile/assets/img/`                                                                                                                                                                                                                                                                |
| **Kullanım**      | `AppEmptyState` üstünde ~160 dp                                                                                                                                                                                                                                                          |

**Prompt:**

> Teal renkli bilge bir baykuş maskotu, kopmuş bir bağlantı kablosunun iki ucunu tutmuş,
> sakin ve güven verici biçimde izleyiciye bakıyor; panik yok, "birazdan düzelir" hissi.
> Maskot ailesi tarzında: yumuşak 3B render, yuvarlak hatlar, gözlüklü, hafif alt aydınlatma.
> Kompozisyon: ortalanmış, tam gövde, altta yumuşak gölge, çevresinde nefes payı.
> Renk paleti: tüyler #14b8a6 ve #0b7268, gaga/ayak #F59E0B, kablo ucunda #ef4444 kıvılcım.
> Arka plan: şeffaf.
> En-boy: 1:1 · Çözünürlük: 480×480.
> Negatif: metin yok, filigran yok, marka/logo yok, gerçekçi kuş anatomisi yok, kasvetli ton yok,
> hata/ünlem simgesi yok.

---

#### EM-02 · Arama sonucu yok ← **7 çağrı yeri**

| Alan              | Değer                                                                                                                                                                                          |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Ekran**         | İşaretler · İşaret detayı · İkaz ışıkları (×2) · Kabin kumandaları · Araç bileşeni · Ders detayı                                                                                               |
| **Widget**        | `signs_screen.dart:119` · `sign_detail_screen.dart:30` · `dash_lights_screen.dart:78,193` · `cabin_controls_screen.dart:57` · `vehicle_detail_screen.dart:28` · `lesson_detail_screen.dart:31` |
| **Mevcut varlık** | Emoji `🔍`                                                                                                                                                                                     |
| **Gerekçe**       | Öğrenme bölümünün her galerisinde çıkıyor; arama deneyiminin parçası                                                                                                                           |
| **Görsel stil**   | Maskot                                                                                                                                                                                         |
| **Dosya adı**     | `empty_search`                                                                                                                                                                                 |
| **Uzantı**        | `.webp` · **Çözünürlük** 480×480 · **Dizin** `apps/mobile/assets/img/`                                                                                                                         |

**Prompt:**

> Teal renkli bilge bir baykuş maskotu, büyüteçle boş bir rafa bakıyor; meraklı ve yardımsever
> ifade, hayal kırıklığı değil. Maskot ailesi tarzında: yumuşak 3B render, yuvarlak hatlar,
> gözlüklü.
> Kompozisyon: ortalanmış, tam gövde, büyüteç hafif öne çıkmış, altta yumuşak gölge.
> Renk paleti: tüyler #14b8a6 ve #0b7268, büyüteç çerçevesi #F59E0B, raf #0b1523.
> Arka plan: şeffaf.
> En-boy: 1:1 · Çözünürlük: 480×480.
> Negatif: metin yok, filigran yok, marka/logo yok, üzgün/ağlayan ifade yok.

---

#### EM-03 · Erişim yok / kilitli ← **4 çağrı yeri**

| Alan              | Değer                                                                                                                                    |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **Ekran**         | Sohbet (engelli) · Tartışma başlığı · Grup ayrıntısı · Kullanıcı profili                                                                 |
| **Widget**        | `chat_screen.dart:253` · `discussion_thread_screen.dart:122` · `group_detail_screen.dart:73` · `user_profile_screen.dart:118`            |
| **Mevcut varlık** | Emoji `🔒`                                                                                                                               |
| **Gerekçe**       | Engelleme/gizlilik sonucunda görülen durum; **suçlayıcı olmamalı** — E8/E9'un sızıntısız 404 ilkesiyle uyumlu, nötr bir görsel gerekiyor |
| **Görsel stil**   | Maskot                                                                                                                                   |
| **Dosya adı**     | `empty_locked`                                                                                                                           |
| **Uzantı**        | `.webp` · **Çözünürlük** 480×480 · **Dizin** `apps/mobile/assets/img/`                                                                   |

**Prompt:**

> Teal renkli baykuş maskotu, kapalı ama sade bir kapının önünde nazikçe duruyor; elinde kalkan
> benzeri yuvarlak bir levha. İfade nötr ve saygılı — kimseyi suçlamıyor.
> Maskot ailesi tarzında: yumuşak 3B render, yuvarlak hatlar, gözlüklü.
> Kompozisyon: ortalanmış, tam gövde, kapı arkada hafif bulanık.
> Renk paleti: tüyler #14b8a6 ve #0b7268, kalkan #0b7268, kapı #14243a.
> Arka plan: şeffaf.
> En-boy: 1:1 · Çözünürlük: 480×480.
> Negatif: metin yok, filigran yok, marka/logo yok, asma kilit simgesi yok, tehdit edici/karanlık
> ton yok, kırmızı yasak işareti yok.

---

#### EM-04 · Henüz mesaj/ileti yok ← **3 çağrı yeri**

| Alan              | Değer                                                                               |
| ----------------- | ----------------------------------------------------------------------------------- |
| **Ekran**         | Sohbet listesi · Sohbet · Tartışma başlığı                                          |
| **Widget**        | `chat_screen.dart:83,270` · `discussion_thread_screen.dart:156`                     |
| **Mevcut varlık** | Emoji `💬`                                                                          |
| **Gerekçe**       | "İlk mesajı sen yaz" davetini görselle desteklemek                                  |
| **Görsel stil**   | Maskot · **Dosya adı** `empty_chat` · `.webp` · 480×480 · `apps/mobile/assets/img/` |

**Prompt:**

> Teal renkli baykuş maskotu, boş bir konuşma balonunu kanadıyla tutmuş, izleyiciyi konuşmaya
> davet eder gibi hafifçe öne eğilmiş; sıcak ve cesaretlendirici.
> Maskot ailesi tarzında: yumuşak 3B render, yuvarlak hatlar, gözlüklü.
> Kompozisyon: ortalanmış, tam gövde, balon sağ üstte.
> Renk paleti: tüyler #14b8a6 ve #0b7268, balon #0f1c2e kenarlık #14b8a6.
> Arka plan: şeffaf.
> En-boy: 1:1 · Çözünürlük: 480×480.
> Negatif: metin yok, balon içinde yazı yok, filigran yok, marka/logo yok.

---

#### EM-05 … EM-14 · Tekil durumlar

| Kod       | Emoji          | Ekran / Widget                                                                                                                                  | Dosya adı           | Prompt konusu (aynı maskot şablonu, 480×480, şeffaf)                       |
| --------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | -------------------------------------------------------------------------- |
| **EM-05** | `👋`           | Arkadaşlar boş · `friends_screen.dart:112`                                                                                                      | `empty_friends`     | Baykuş el sallıyor, yanında iki boş avatar halkası — "ilk arkadaşını ekle" |
| **EM-06** | `👥`           | Grup yok · `groups_screen.dart:125`                                                                                                             | `empty_groups`      | Üç baykuş silueti bir masa etrafında, ortadaki yer boş — "gruba katıl"     |
| **EM-07** | `🎯`           | Meydan okuma yok · `challenges_screen.dart:111`                                                                                                 | `empty_challenge`   | Baykuş hedef tahtasına bakıyor, ok henüz atılmamış                         |
| **EM-08** | `🏁`           | Sıralama boş · `community_screen.dart:247`                                                                                                      | `empty_leaderboard` | Boş podyum, baykuş ilk basamağa çıkmaya hazırlanıyor                       |
| **EM-09** | `🛡️`           | Engellenen yok · `blocked_users_screen.dart:97`                                                                                                 | `empty_blocked`     | Baykuş kalkanı indirmiş, rahat duruyor — "kimseyi engellemedin"            |
| **EM-10** | `💡`           | İpucu/öneri · `discussions_screen.dart:124` · `lesson_detail_screen.dart:172`                                                                   | `hint_bulb`         | Baykuş, üstünde yumuşak ışık halesi olan bir ampule bakıyor                |
| **EM-11** | `📊`           | İlerleme yok · `progress_screen.dart:42`                                                                                                        | `empty_progress`    | Baykuş boş bir çubuk grafiğin önünde, ilk çubuğu koymaya hazırlanıyor      |
| **EM-12** | `🎉`           | Oturum bitti · `practice_runner_screen.dart:113`                                                                                                | `state_celebrate`   | Baykuş konfeti arasında, başarı kutlaması — abartısız                      |
| **EM-13** | `⚠️`           | İlerleme yüklenemedi · `progress_screen.dart:37` · `practice_runner_screen.dart:107`                                                            | `state_warning`     | Baykuş elinde eğik bir tabela, özür diler gibi; **kırmızı ünlem yok**      |
| **EM-14** | `🗂️`/`🎬`/`🧠` | Set boş · Video yok · Ders zihin haritası · `exam_runner_screen.dart:180` · `video_detail_screen.dart:37` · `lesson_detail_screen.dart:145,154` | `empty_content`     | Baykuş boş bir dosya/film şeridi tutuyor — genel "içerik yok" durumu       |

> **Not:** EM-14 üç emoji'yi tek görselle kapatır; üçü de "beklenen içerik yok" anlamına geliyor
> ve ayrı görsel üretmek gereksiz bakım yükü olurdu.

---

### 4.2 Giriş ekranı — Faz 5

#### LG-01 · Giriş hero görseli

| Alan              | Değer                                                                                                                                                                       |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Ekran**         | Giriş / Kayıt (`auth_screen.dart`)                                                                                                                                          |
| **Widget**        | Ekranda **hiç görsel yok** — form doğrudan boş zeminde                                                                                                                      |
| **Mevcut varlık** | **YOK**                                                                                                                                                                     |
| **Gerekçe**       | Uygulamanın en çok görülen ikinci ekranı tamamen çıplak; premium hissi yok                                                                                                  |
| **Kaynak**        | **`apps/assets/interface-assets/022-assets.png` MEVCUT** (1536×1024) — gece Istanbul silueti, sürücü kursu aracı, koniler, trafik ışığı; sol taraf içerik için bilinçli boş |
| **Yapılacak**     | Üretilmesine **gerek yok**; mevcut referans 1080×720'ye ölçeklenip WebP'ye çevrilir                                                                                         |
| **Dosya adı**     | `auth_hero` · `.webp` · 1080×720 · `apps/mobile/assets/img/`                                                                                                                |

> ⚠️ **Marka uyarısı:** 022 görselinde **Renault logosu** okunabiliyor. Evolution roadmap'inde
> "üçüncü taraf markalar → markasız varyant tercih edilir, seçim belgelenir" kuralı var.
> **Faz 5'te logo rötuşlanmalı** veya markasız bir varyant üretilmelidir. Aksi hâlde mağaza
> listesinde ve uygulamada üçüncü taraf marka izinsiz kullanılmış olur.

#### LG-02 / LG-03 · **Varlık DEĞİL — tasarım şartnamesi**

`023-assets.png` (giriş formu) ve `024-assets.png` (güven şeridi) **birer arayüz mockup'ıdır**,
içlerinde **gömülü Türkçe metin** vardır.

**Bunlar raster olarak sevk EDİLMEZ.** Nedeni mühendislik:

1. Gömülü metin **temaya uymaz** (ikisi de yalnız koyu tema).
2. Kullanıcının **yazı tipi ölçeğiyle büyümez** — erişilebilirlik ihlali.
3. **Çevrilemez**.
4. Form alanları zaten **etkileşimli** olmak zorunda.

→ Faz 5'te **widget olarak** birebir uygulanır: aynı yerleşim, aynı tipografi hiyerarşisi, aynı
teal vurgu; ama metin `Text`, alanlar `TextField`, renkler `context.palette`.

**Faz 5 için iki uyarı daha:**

- Mockup'ta **"Apple ile giriş yap"** düğmesi var. iOS derlemesi **yok** (macOS yok) ve Android'de
  Apple girişi standart değil. Çalışmayan bir düğme koymak **ölü gezinme** olur (disiplin kural 3)
  → **konmayacak**, gerekçesi rapora yazılacak.
- **"MEB müfredatına uygun"** ifadesi (024) **doğrulanabilir bir iddiadır**. Kaynak gösterilemiyorsa
  bu metin kullanılmamalı — dürüstlük disiplini.

---

### 4.3 Onboarding — Faz 6

#### OB-01 … OB-05 · Mevcut görsellerin yüksek çözünürlüklü sürümleri

| Dosya               | Mevcut  | Gereken   | Durum              |
| ------------------- | ------- | --------- | ------------------ |
| `onb_welcome.webp`  | 820×721 | 1080×1080 | Yeniden üretilecek |
| `onb_wheel.webp`    | 760×722 | 1080×1080 | Yeniden üretilecek |
| `onb_think.webp`    | 695×820 | 1080×1080 | Yeniden üretilecek |
| `onb_tablet.webp`   | 820×641 | 1080×1080 | Yeniden üretilecek |
| `onb_calendar.webp` | 820×623 | 1080×1080 | Yeniden üretilecek |

**Gerekçe:** Faz 6, görselin güvenli alanın **%85–95'ini** kaplamasını istiyor. 360 dp genişlikte
3× cihazda bu **1080 px** demek. Mevcut 695–820 px kaynaklar büyütüldüğünde **yumuşama/bulanıklık**
oluşur. Yani Faz 6 yalnız bir yerleşim işi değil; **varlık çözünürlüğü de yetersiz**.

**Prompt şablonu (her biri için konu değişir):**

> [KONU — aşağıdaki tabloya bakınız]. Maskot ailesi tarzında: yumuşak 3B render, teal tüyler,
> gözlüklü bilge baykuş, sıcak ve öğretici ifade, hafif alt aydınlatma, yuvarlak hatlar.
> Kompozisyon: **kare çerçeve içinde ortalanmış, tam gövde**, çevrede %8 nefes payı; görsel
> çerçeveyi dolduracak biçimde büyük.
> Renk paleti: tüyler #14b8a6 ve #0b7268, vurgu #F59E0B.
> Arka plan: **şeffaf**.
> En-boy: 1:1 · Çözünürlük: **1080×1080**.
> Negatif: metin yok, filigran yok, marka/logo yok, gerçekçi kuş anatomisi yok, kalabalık sahne yok.

| Dosya          | Konu                                                                                          |
| -------------- | --------------------------------------------------------------------------------------------- |
| `onb_welcome`  | Baykuş el sallayarak karşılıyor, arkasında yumuşak teal hale                                  |
| `onb_wheel`    | Baykuş direksiyon başında, kendinden emin                                                     |
| `onb_think`    | Baykuş çenesine kanadını dayamış düşünüyor, üstünde soru işareti silueti (metin değil, şekil) |
| `onb_tablet`   | Baykuş tablet tutuyor, ekranda soyut grafik şekilleri                                         |
| `onb_calendar` | Baykuş takvim yanında, bir günü işaretlemiş                                                   |

---

### 4.4 Profil avatarı — Faz 7

#### AV-01 · Varsayılan avatar (fotoğraf yüklenmediğinde)

| Alan              | Değer                                                                                                  |
| ----------------- | ------------------------------------------------------------------------------------------------------ |
| **Ekran**         | Profil · Topluluk · Sıralama                                                                           |
| **Mevcut varlık** | 6 maskot avatarı (`owl_wave` vb.) — **yeterli, üretim gerekmiyor**                                     |
| **Gerekçe**       | Faz 7 fotoğraf yüklemeyi getiriyor; yüklemeyen kullanıcı için mevcut maskotlar varsayılan kalır        |
| **Yapılacak**     | **Yeni varlık YOK.** Faz 7 yalnız yükleme/kırpma akışını ekler ve maskotu geri dönüş yolu olarak korur |

---

### 4.5 Üretim GEREKMEYENLER — kayıt için

| Kapsam                    | Neden üretilmiyor                                       |
| ------------------------- | ------------------------------------------------------- |
| Trafik işaretleri (81)    | Resmî vektör (E1) — mevzuata bağlı, stil serbestisi yok |
| İkaz ışıkları (60)        | Resmî vektör (E3)                                       |
| Mekanik fotoğraflar (101) | Gerçek fotoğraf (E2)                                    |
| Araç görselleri (3)       | E4/E5'te eklendi, çözünürlük yeterli                    |
| Video posterleri (7)      | E12 hattı üretiyor — elle üretilmez                     |
| `CustomPainter` × 4       | Veri görselleştirme; raster olamaz                      |
| Uygulama ikonu            | `design-sources/new_icon.png` (1254²) mevcut            |

---

## 5. Üretim özeti

| Kategori                       |         Üretilecek görsel |
| ------------------------------ | ------------------------: |
| Boş/hata durumları (EM-01…14)  |                    **14** |
| Onboarding yeniden üretim (OB) |                     **5** |
| Giriş hero (LG-01)             | 0 (mevcut, rötuş gerekli) |
| **TOPLAM**                     |                    **19** |

**Tahmini bütçe:** 19 × ~60 KB (WebP, 480–1080 px) ≈ **1,1 MB** → mobil varlıklar 4,7 MB → ~5,8 MB.
APK'ya etkisi ihmal edilebilir (E13: varlıklar APK'nın yalnız %6'sı).

## 6. Üretim sonrası akış

1. Hedef çözünürlüğe getir, **WebP**'ye çevir (şeffaflık korunacak → `-lossless` veya yüksek kalite).
2. Tablodaki **dizin ve dosya adına** birebir kaydet.
3. `apps/mobile/pubspec.yaml` varlık listesine ekle (dizin zaten kayıtlıysa gerekmez).
4. `lib/core/assets.dart` içine sabit ekle.
5. Kodda emoji yerine illüstrasyonu bağla.
6. **Cihazda** doğrula, ekran görüntüsü al.
7. Tekil dosya bütçesi: **≤ 150 KB**.

---

## 7. Trafik işaretleri — prosedürel çizim denetimi (Ürün Evrimi v1.1 · Faz 3)

### 7.1 Ölçüm

|                                                  |         |
| ------------------------------------------------ | ------: |
| Katalogdaki işaret (`apps/web/content/signs.ts`) | **121** |
| `official_signs.dart` ile SVG'ye eşlenen         |  **86** |
| **Resmî SVG'si olmayan → prosedürel çiziliyor**  |  **35** |

Prosedürel çizim `TrafficSignView` içinde yapılır: şekil + renk + (varsa) rakam parametreden
gelir. Yani bu 35 işaret **bozuk değil, çiziliyor** — soru da sorulabiliyor. Denetim, hangilerinin
gerçekten bir piktogram istediğini ayırmak için yapıldı.

### 7.2 Üretilmeyecekler — 17 işaret, gerekçesiyle

Bunlar **rakam taşıyan hız levhaları**. İçindeki sayı bir _veridir_, çizim değil: aynı kırmızı
(ya da mavi) halkanın içine yazılır. `TrafficSignView` bunu zaten parametreyle yapıyor ve sonuç
mevzuata birebir uyuyor.

17 ayrı görsel üretmek, tek farkı iki rakam olan 17 dosya demek olurdu — kullanıcının
"**Do NOT generate duplicate prompts**" kuralının tam ihlali. Ayrıca her yeni hız sınırı
(ör. 130) yeni bir görsel gerektirirdi; parametrik çizimde ise hiçbir şey gerekmez.

```
azami-hiz-20/30/40/50/60/70/80/90/100/110/120   (11)
asgari-hiz-30/40/50                              (3)
hiz-siniri-sonu · tum-yasaklarin-sonu            (2)  → halka + eğik çizgi, rakamsız
yukseklik-siniri                                 (1)  → halka + "3,5 m" metni (veri)
```

**Karar: prosedürel kalır. Görsel üretilmez.**

### 7.3 Üretilecekler — 18 işaret

Bunların hepsi bir **piktogram** (silüet/şekil) içeriyor; prosedürel çizim bunları gerçekten
üretemiyor, yerine yalnız boş çerçeve + kategori rengi çiziliyor.

> **STİL AİLESİ: "Resmî vektör" — §2 uyarınca stil serbestisi YOKTUR.**
> Bu, üretimin sınırını da belirler: GPT Image mevzuata _birebir_ bir levha üretmez, yaklaşık
> üretir. Bu yüzden **birincil kaynak resmî vektördür**; aşağıdaki istemler, resmî vektör temin
> edilene kadar geçerli olan **eğitim amaçlı gösterim** içindir. Dosya adları şimdiden koda
> bağlıdır, dolayısıyla ister üretilmiş görsel ister resmî vektör konsun, uygulama onu kullanır.

**Ortak alanlar (18 kalemin hepsi için aynı):**

| Alan                  | Değer                                                                                                                                                                                                                                   |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Kayıt dizini          | `apps/mobile/assets/signs/`                                                                                                                                                                                                             |
| Uzantı                | `.svg` (vektör; ölçekten bağımsız keskin)                                                                                                                                                                                               |
| **Dosya adı kuralı**  | `assets/signs/<işaret-id>.svg` — üretilmiş levhalar KGM kodu kullanıyor ama hangi kodun boş olduğu buradan bilinemiyor: ilk denemede `t-9.svg` seçildi ve zaten kullanımdaydı (test yakaladı). İşaret kimliği hem benzersiz hem okunur. |
| Çözünürlük            | vektör — `viewBox="0 0 100 100"`                                                                                                                                                                                                        |
| Arka plan             | **şeffaf**                                                                                                                                                                                                                              |
| Kullanım yeri         | `TrafficSignView` → Öğren ▸ İşaretler, işaret detayı, **görsel sorular**                                                                                                                                                                |
| Negatif (her istemde) | `metin yok, filigran yok, marka/logo yok, gölge yok, 3B yok, perspektif yok`                                                                                                                                                            |

**İstem şablonu** (§3 standardına uygun, konu alanı değişir):

```
[KONU]. Resmî trafik levhası vektörü tarzında: düz renk, keskin kenar, tek düzlem.
Kompozisyon: levha kareye ortalanmış, kenar boşluğu %6.
Renk paleti: [kategori renkleri].
Arka plan: şeffaf.
En-boy: 1:1 · Çözünürlük: vektör (viewBox 0 0 100 100).
Negatif: metin yok, filigran yok, marka/logo yok, gölge yok, 3B yok, perspektif yok.
```

Kategori renkleri: **tehlike** `#ed1c24` üçgen + beyaz zemin + siyah simge ·
**yasak** `#ed1c24` halka + beyaz zemin + siyah simge · **mecburiyet** `#0d47a1` mavi disk +
beyaz simge · **bilgi/park** `#0d47a1` mavi dikdörtgen + beyaz simge ·
**otoyol** `#1b7a3e` yeşil dikdörtgen + beyaz simge.

#### Tehlike (kırmızı kenarlı üçgen, tepe yukarı) — 4

| Dosya adı                 | İşaret                    | KONU (isteme yazılacak)                                                                    |
| ------------------------- | ------------------------- | ------------------------------------------------------------------------------------------ |
| `kaygan-yol.svg`          | Kaygan Yol                | Kırmızı kenarlı üçgen; içinde siyah otomobil silüeti ve altında iki adet dalgalı kayma izi |
| `tehlikeli-viraj-sag.svg` | Sağa Tehlikeli Viraj      | Kırmızı kenarlı üçgen; içinde sağa kıvrılan kalın siyah yol oku                            |
| `dik-cikis.svg`           | Tehlikeli Eğim (çıkış)    | Kırmızı kenarlı üçgen; içinde yukarı doğru yükselen siyah eğim çizgisi                     |
| `vahsi-hayvan.svg`        | Vahşi Hayvanlar Geçebilir | Kırmızı kenarlı üçgen; içinde yandan görünen siyah geyik silüeti                           |

#### Yasak / Park (kırmızı halka ya da mavi disk) — 4

| Dosya adı               | İşaret                 | KONU                                                                    |
| ----------------------- | ---------------------- | ----------------------------------------------------------------------- |
| `park-yasak.svg`        | Parketmek Yasaktır     | Mavi disk, kırmızı halka ve sol üstten sağ alta tek kırmızı eğik çizgi  |
| `park-yasagi-sonu.svg`  | Park Yasağı Sonu       | Aynı levhanın üzerinde ince gri eğik iptal çizgileri                    |
| `park-saat-sinirli.svg` | Süre Sınırlı Park Yeri | Mavi kare, ortasında beyaz büyük "P" ve altında beyaz kum saati simgesi |
| `engelli-parki.svg`     | Engelli Park Yeri      | Mavi kare, ortasında beyaz tekerlekli sandalye simgesi                  |

#### Mecburiyet (mavi disk, beyaz simge) — 2

| Dosya adı                | İşaret                   | KONU                                                        |
| ------------------------ | ------------------------ | ----------------------------------------------------------- |
| `saga-donus-mecburi.svg` | İleride Sağa Mecburi Yön | Mavi disk; içinde yukarı çıkıp sağa kıvrılan kalın beyaz ok |
| `sola-donus-mecburi.svg` | İleride Sola Mecburi Yön | Mavi disk; içinde yukarı çıkıp sola kıvrılan kalın beyaz ok |

#### Bilgi (mavi dikdörtgen, beyaz simge) — 5

| Dosya adı                | İşaret             | KONU                                                                      |
| ------------------------ | ------------------ | ------------------------------------------------------------------------- |
| `lokanta.svg`            | Lokanta            | Mavi kare; içinde beyaz çatal ve bıçak yan yana                           |
| `taksi-duragi.svg`       | Taksi Durağı       | Mavi kare; içinde beyaz otomobil silüeti ve tavanında küçük taksi levhası |
| `tunel.svg`              | Tünel              | Mavi kare; içinde beyaz kemerli tünel ağzı ve içine giren yol             |
| `havalimani.svg`         | Havalimanı         | Mavi kare; içinde eğik duran beyaz uçak silüeti                           |
| `motorlu-tasit-yolu.svg` | Motorlu Taşıt Yolu | Mavi kare; içinde önden görünen beyaz otomobil silüeti                    |

#### Otoyol / Yönlendirme (yeşil dikdörtgen) — 3

| Dosya adı                | İşaret                  | KONU                                                                            |
| ------------------------ | ----------------------- | ------------------------------------------------------------------------------- |
| `otoyol-cikisi.svg`      | Otoyol Çıkışı           | Yeşil dikdörtgen; içinde ana yoldan sağa ayrılan beyaz çıkış oku                |
| `otoyol-cikisi-300m.svg` | Otoyol Çıkışı Yaklaşımı | Yeşil dikdörtgen; içinde sağa ayrılan beyaz ok ve yanında üç eğik mesafe çubuğu |
| `devlet-yolu.svg`        | Devlet Yolu Yönlendirme | Beyaz kenarlı mavi dikdörtgen; içinde yukarı yönelen beyaz yön oku              |

### 7.4 Yerleştirme — kod ŞİMDİDEN hazır

Yukarıdaki dosya adları `apps/mobile/lib/core/official_signs.dart` içine **bu değişiklikle
eklendi**. Görsel klasöre konduğu an uygulama onu kullanır; kod değişikliği gerekmez.

Doğrulama: `flutter test test/official_signs_test.dart` — eşlemesi olup dosyası olmayan işaret
varsa test bunu söyler ve prosedürel çizime düşüldüğünü belgeler.

---

## 8. Maskot KATMANLARI — göz kırpma ve bakış takibi için (Ürün Evrimi v1.1 · Faz 6)

### 8.1 Neden bu katmanlar gerekiyor

Faz 6'da koç canlandırıldı: nefes, süzülme, mikro eğim ve konuşurken öne yaklaşma —
hepsi yerel Flutter dönüşümleriyle, sıfır bağımlılıkla (`design/living_mascot.dart`).

**Göz kırpma ve bakış takibi YAPILMADI.** İkisi de gözün nerede olduğunu bilmeyi gerektirir;
elimizdeki maskot tek parça bir raster. Göz konumunu tahmin edip üstüne kapak çizmek, gözün
yanına siyah bir çubuk koymak olurdu. Olmayan bir şey taklit edilmedi.

Aşağıdaki katmanlar üretildiğinde ikisi de eklenebilir — `LivingMascot` tek değiştirme noktası.

### 8.2 Rive / Lottie neden seçilmedi

| Seçenek                       | Durum                                                                                                       |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Rive**                      | En güçlüsü (durum makinesi, etkileşim). `.riv` dosyası ister — elimizde yok, durağan `.webp`den üretilemez. |
| **Lottie**                    | Yaygın, After Effects çıktısı. `.json` ister — aynı sorun.                                                  |
| **Yerel Flutter dönüşümleri** | **Seçilen.** Bağımlılık yok, dış varlık yok, bugün çalışıyor.                                               |

Bağımlılık eklemek, dosya gelene kadar hiçbir şey çalıştırmazdı: bugün sıfır kazanç, kalıcı
bakım yükü. Katmanlı varlıklar geldiğinde Rive'a geçmek hâlâ mümkün.

### 8.3 İstenen katmanlar — `owl_teacher` için 5 dosya

Hepsi **aynı tuval**, **aynı hizada**, **şeffaf** — üst üste bindirildiğinde tam maskotu vermeli.
Kayma olursa göz gövdenin dışında kalır.

| Alan               | Değer                                                                  |
| ------------------ | ---------------------------------------------------------------------- |
| Kayıt dizini       | `apps/mobile/assets/img/`                                              |
| Uzantı             | `.webp` (şeffaflık korunmalı → kayıpsız ya da yüksek kalite)           |
| Çözünürlük         | **1080×1080**, hepsi birebir aynı                                      |
| Arka plan          | şeffaf                                                                 |
| Stil ailesi        | **Maskot (baykuş)** — §2: yumuşak 3B, teal tüy, gözlük, sıcak/öğretici |
| Negatif (hepsinde) | `metin yok, filigran yok, marka/logo yok, arka plan yok, gölge yok`    |

| Dosya adı                  | Katman     | İçerik                                                                    |
| -------------------------- | ---------- | ------------------------------------------------------------------------- |
| `owl_layer_body.webp`      | Gövde      | Baş ve gözler HARİÇ her şey: gövde, kanatlar, ayaklar, gözlük çerçevesi   |
| `owl_layer_head.webp`      | Baş        | Yalnız baş (gözler hariç); gövdeden ayrı döndürülebilsin diye             |
| `owl_layer_eyes_open.webp` | Göz akı    | Yalnız iki göz akı, göz bebeği YOK                                        |
| `owl_layer_pupils.webp`    | Göz bebeği | Yalnız iki göz bebeği, ortalanmış — kaydırılarak bakış yönü verilir       |
| `owl_layer_eyelids.webp`   | Göz kapağı | Kapalı göz kapakları; opaklığı 0↔1 arasında değiştirilerek kırpma yapılır |

**İstem şablonu** (§3 standardına uygun):

```
[KATMAN İÇERİĞİ]. Maskot (baykuş) ailesi tarzında: yumuşak 3B, teal tüy, yuvarlak gözlük,
sıcak ve öğretici ifade.
Kompozisyon: kareye ortalanmış, diğer katmanlarla BİREBİR hizalı, kenar boşluğu %8.
Renk paleti: #14b8a6, #0b7268, #F59E0B.
Arka plan: şeffaf.
En-boy: 1:1 · Çözünürlük: 1080×1080.
Negatif: metin yok, filigran yok, marka/logo yok, arka plan yok, gölge yok, diğer katmanların
parçaları yok.
```

### 8.4 Katmanlar geldiğinde yapılacak

1. `LivingMascot`'a `layers` seçeneği: verilirse `Stack` ile beş katman çizilir.
2. **Göz kırpma** — `owl_layer_eyelids` opaklığı; 90 ms kapanma, 4–7 sn arası rastgele aralık.
   Aralık SABİT OLMAMALI: sabit aralıklı kırpma robot gibi görünür.
3. **Bakış takibi** — `owl_layer_pupils` en fazla ±%4 kaydırılır; daha fazlası şaşı görünür.
4. Testler: kırpma aralığının sabit olmadığı ve hareket azaltıldığında hiç kırpılmadığı.
