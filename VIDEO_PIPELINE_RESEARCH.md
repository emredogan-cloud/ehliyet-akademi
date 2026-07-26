# Yeni nesil video hattı araştırması

**Beta Faz 12 · Durum:** ✅ Tamamlandı · **Video ÜRETİLMEDİ** — bu bir karar belgesidir.

---

## 0. Neden bu araştırma

Yol haritası, mevcut animasyon hattının yerine geçebilecek yeni nesil çözümlerin
karşılaştırılmasını istiyor: **Rive · Lottie · Spline · Blender NPR · Three.js · SVG Motion ·
Cavalry · After Effects/Bodymovin**. Ölçütler: kalite · sürdürülebilirlik · maliyet · üretim hızı
· çevrimdışı uyumluluk · Flutter uyumluluğu.

Karşılaştırma soyut değil: **mevcut hat ölçüldü** ve her aday ona göre puanlandı.

---

## 1. Bugün ne var — ölçülmüş gerçek

| Ölçüm              | Değer                                                                            |
| ------------------ | -------------------------------------------------------------------------------- |
| Hat                | Canvas 2D → başsız Chromium (Playwright) → kare yakalama → **ffmpeg**            |
| Kaynak             | `apps/web/scripts/video-scenes.mjs` (429 satır) + `render-video.mjs` (170 satır) |
| Çıktı              | `<id>.mp4` (H.264) · `<id>.webm` (VP9) · `<id>-poster.jpg` · `<id>.tr.vtt`       |
| Çözünürlük / kare  | 1120×640 · 30 fps                                                                |
| Katalog            | 7 animasyon · 28 dosya · **toplam 2,3 MB**                                       |
| Bölüm + transkript | `videos.generated.ts` — **sahneyle aynı nesneden** türetilir                     |
| Mobil oynatma      | `video_player` 2.11 · `VideoPlayerController.networkUrl`                         |
| Yeni bağımlılık    | **Yok** — Playwright zaten E2E için kurulu, ffmpeg sistem aracı                  |

**Kritik mimari özellik:** bölüm/altyazı verisi videoyu çizen sahneden üretilir. Bu yüzden video
ile katalog arasında **sapma yapısal olarak imkânsızdır**. Aday çözümler değerlendirilirken bu
özelliğin korunup korunmadığı belirleyici oldu — kaybedilirse "8. saniyede şu anlatılıyor"
iddiası doğrulanamaz hâle gelir.

**Ölçülen zayıflıklar:**

1. Görsel dil **düz vektör**; ışık, derinlik ve malzeme hissi yok.
2. Kare kare Canvas çizimi el emeği ister — yeni sahne ≈ birkaç yüz satır kod.
3. Etkileşim yok: kullanıcı hızı, açıyı veya adımı değiştiremez.
4. Videolar **ağdan** oynatılıyor; çevrimdışı kullanıcı hiçbir animasyon göremiyor.

---

## 2. Adaylar — ölçüt ölçüt

Puanlar: ⬤⬤⬤ güçlü · ⬤⬤ orta · ⬤ zayıf

### 2.1 Rive

| Ölçüt             | Değerlendirme                                                               |
| ----------------- | --------------------------------------------------------------------------- |
| Kalite            | ⬤⬤⬤ Vektör + **durum makinesi**; canlı, etkileşimli                         |
| Sürdürülebilirlik | ⬤⬤ Tescilli düzenleyici; `.riv` dosyası **metin değil** → anlamlı diff yok  |
| Maliyet           | ⬤⬤ Ücretsiz katman var; takım kullanımı ücretli                             |
| Üretim hızı       | ⬤⬤⬤ Görsel editör — sahne başına saatler, gün değil                         |
| Çevrimdışı        | ⬤⬤⬤ `.riv` **uygulamaya gömülür**, ağ gerekmez                              |
| Flutter           | ⬤⬤⬤ Resmî `rive` paketi, olgun                                              |
| **Sapma riski**   | ⚠️ Bölüm/transkript artık sahneden türetilemez — **elle eşlenmesi gerekir** |

### 2.2 Lottie (ve üreticileri: After Effects/Bodymovin, Cavalry)

| Ölçüt             | Değerlendirme                                                                       |
| ----------------- | ----------------------------------------------------------------------------------- |
| Kalite            | ⬤⬤ Vektör animasyon; AE'nin bazı efektleri (maskeleme, expression) **desteklenmez** |
| Sürdürülebilirlik | ⬤⬤ JSON — okunabilir ama elle düzenlenemez; kaynak AE/Cavalry projesidir            |
| Maliyet           | AE ⬤ (abonelik) · Cavalry ⬤⬤ (tek seferlik) · Bodymovin ⬤⬤⬤ (ücretsiz)              |
| Üretim hızı       | ⬤⬤⬤ Tasarımcı aracı; animasyon üretimi hızlı                                        |
| Çevrimdışı        | ⬤⬤⬤ JSON gömülür                                                                    |
| Flutter           | ⬤⬤ `lottie` paketi olgun ama resmî değil                                            |
| **Sapma riski**   | ⚠️ Aynı sorun: zaman damgaları elle eşlenir                                         |

> **Not:** Faz 7'de Lottie, **avatar yüklemede** bilinçli olarak yasaklanmıştı (kullanıcı yüklediği
> JSON'un çizim motorunda çalıştırılması saldırı yüzeyidir). Burada durum farklıdır: dosya
> **bizim** ürettiğimiz, depoya giren, incelenmiş bir varlıktır. İki karar çelişmez.

### 2.3 Spline

| Ölçüt             | Değerlendirme                                                     |
| ----------------- | ----------------------------------------------------------------- |
| Kalite            | ⬤⬤⬤ Gerçek 3B, ışık ve malzeme                                    |
| Sürdürülebilirlik | ⬤ **Bulut bağımlı**; sahne dosyası tescilli, dışa aktarım sınırlı |
| Maliyet           | ⬤⬤ Ücretsiz katman + ücretli plan                                 |
| Üretim hızı       | ⬤⬤⬤ Çok hızlı                                                     |
| Çevrimdışı        | ⬤ Web çalışma zamanı; gömülü kullanım zayıf                       |
| Flutter           | ⬤ **WebView zorunlu** — başarım ve bellek maliyeti                |

### 2.4 Three.js

| Ölçüt             | Değerlendirme                                                       |
| ----------------- | ------------------------------------------------------------------- |
| Kalite            | ⬤⬤⬤ Sınırsız; tamamen bize bağlı                                    |
| Sürdürülebilirlik | ⬤⬤⬤ Açık kaynak, kod = metin, diff'lenebilir                        |
| Maliyet           | ⬤⬤⬤ Ücretsiz                                                        |
| Üretim hızı       | ⬤ **Her sahne mühendislik işi** — bugünkü Canvas hattından da yavaş |
| Çevrimdışı        | ⬤⬤ Web'de iyi; mobilde WebView                                      |
| Flutter           | ⬤ WebView zorunlu                                                   |

### 2.5 Blender (NPR / toon render)

| Ölçüt             | Değerlendirme                                                                              |
| ----------------- | ------------------------------------------------------------------------------------------ |
| Kalite            | ⬤⬤⬤ En yüksek; sinematik ışık, gölge, kamera                                               |
| Sürdürülebilirlik | ⬤⬤ `.blend` ikili dosya; ama tamamen açık kaynak ve **komut satırından render edilebilir** |
| Maliyet           | ⬤⬤⬤ Ücretsiz                                                                               |
| Üretim hızı       | ⬤ Sahne başına gün(ler); render süresi ayrıca                                              |
| Çevrimdışı        | ⬤⬤ Çıktı **video** → bugünküyle aynı; indirilirse çevrimdışı olur                          |
| Flutter           | ⬤⬤⬤ Sonuç videodur; `video_player` yeterli, **yeni bağımlılık yok**                        |
| **Sapma riski**   | ✅ Yok — bölüm verisi yine sahne betiğinden üretilebilir                                   |

### 2.6 SVG Motion (SMIL / CSS)

| Ölçüt             | Değerlendirme                                                        |
| ----------------- | -------------------------------------------------------------------- |
| Kalite            | ⬤ Basit geçişler; anlatı animasyonu için yetersiz                    |
| Sürdürülebilirlik | ⬤⬤⬤ Metin, diff'lenebilir                                            |
| Maliyet           | ⬤⬤⬤ Ücretsiz                                                         |
| Üretim hızı       | ⬤⬤ Basit sahnelerde hızlı                                            |
| Çevrimdışı        | ⬤⬤⬤ Gömülür                                                          |
| Flutter           | ⬤ `flutter_svg` **animasyonu desteklemez** → tek başına kullanılamaz |

---

## 3. Karşılaştırma tablosu

| Çözüm                       | Kalite | Sürdürülebilirlik | Maliyet | Hız | Çevrimdışı | Flutter | Sapma riski |
| --------------------------- | :----: | :---------------: | :-----: | :-: | :--------: | :-----: | :---------: |
| **Bugünkü (Canvas+ffmpeg)** |   ⬤⬤   |        ⬤⬤⬤        |   ⬤⬤⬤   | ⬤⬤  |     ⬤      |   ⬤⬤⬤   |   ✅ yok    |
| Rive                        |  ⬤⬤⬤   |        ⬤⬤         |   ⬤⬤    | ⬤⬤⬤ |    ⬤⬤⬤     |   ⬤⬤⬤   |   ⚠️ var    |
| Lottie (AE/Cavalry)         |   ⬤⬤   |        ⬤⬤         |   ⬤⬤    | ⬤⬤⬤ |    ⬤⬤⬤     |   ⬤⬤    |   ⚠️ var    |
| Spline                      |  ⬤⬤⬤   |         ⬤         |   ⬤⬤    | ⬤⬤⬤ |     ⬤      |    ⬤    |   ⚠️ var    |
| Three.js                    |  ⬤⬤⬤   |        ⬤⬤⬤        |   ⬤⬤⬤   |  ⬤  |     ⬤⬤     |    ⬤    |   ⚠️ var    |
| Blender NPR                 |  ⬤⬤⬤   |        ⬤⬤         |   ⬤⬤⬤   |  ⬤  |     ⬤⬤     |   ⬤⬤⬤   |   ✅ yok    |
| SVG Motion                  |   ⬤    |        ⬤⬤⬤        |   ⬤⬤⬤   | ⬤⬤  |    ⬤⬤⬤     |    ⬤    |      —      |

---

## 4. Öneri

### Kapalı Test için: **hattı DEĞİŞTİRME**

Gerekçe tek cümlede: **kapalı testin darboğazı video kalitesi değil.** 12 test kullanıcısının
göreceği eksikler dağıtım, giriş, satın alma ve içerik doğruluğudur. Hat değişikliği yeni bir
tescilli araç, yeni bir bağımlılık ve **sapma riski** getirir; karşılığında ölçülebilir bir kapalı
test kazancı yoktur.

### Kısa vade (Kapalı Test sonrası ilk iş): **çevrimdışı indirme**

En büyük ölçülmüş eksik, hattın kalitesi değil, **erişimi**: videolar yalnız ağdan oynatılıyor.
Adayların hiçbiri bunu çözmez; çözüm indirme + yerel oynatmadır ve **mevcut hatla** yapılabilir.
Kazanç/çaba oranı bütün aday çözümlerden yüksektir.

### Orta vade: **Rive — ama yalnız MİKRO etkileşimlerde**

Rive'ın gerçek üstünlüğü sinematik kalite değil, **durum makinesi**: "şimdi debriyajı bırak"
adımını kullanıcı kendi hızında ilerletebilir. Bu, videonun yapamadığı bir şeydir.

Şart: bölüm/transkript üretimi elle eşlenecekse, **eşlemeyi doğrulayan bir test** yazılmadan
girilmemelidir — bugünkü hattın en değerli özelliği (sapmanın imkânsızlığı) sessizce kaybedilir.

### Uzun vade: **Blender NPR — yalnız "amiral gemisi" sahneler için**

Tüm kataloğu Blender'a taşımak sürdürülemez (sahne başına gün). Ama 3–5 tanıtım/kilit sahne için
kalite sıçraması gerçektir ve **hattı değiştirmez**: çıktı yine videodur, `video_player` yeterli,
yeni Flutter bağımlılığı yoktur.

### Reddedilenler ve gerekçesi

| Çözüm             | Ret gerekçesi                                                                             |
| ----------------- | ----------------------------------------------------------------------------------------- |
| **Spline**        | Bulut bağımlılığı + Flutter'da WebView zorunluluğu; çevrimdışı hedefiyle doğrudan çelişir |
| **Three.js**      | Kalite tavanı yüksek ama üretim hızı bugünkü hattan **daha yavaş**; mobilde WebView       |
| **SVG Motion**    | `flutter_svg` animasyon desteklemiyor — mobil tarafta tek başına kullanılamaz             |
| **After Effects** | Abonelik maliyeti + Bodymovin'in desteklemediği efektler sessiz bozulma üretir            |

---

## 5. Karar özeti

1. **Şimdi:** hat değişmiyor. Kapalı Test mevcut hatla çıkar.
2. **Sonraki iş:** çevrimdışı video indirme (mevcut hatla, yeni bağımlılık yok).
3. **Sonra:** Rive — yalnız etkileşimli mikro adımlarda, **sapma testi** şartıyla.
4. **Uzun vade:** Blender NPR — yalnız birkaç amiral gemisi sahne.

**Bu fazda video üretilmedi**; yol haritasının şartı buydu.
