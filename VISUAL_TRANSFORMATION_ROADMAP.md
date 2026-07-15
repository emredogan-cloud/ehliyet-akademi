# Ehliyet Akademi — Görsel Dönüşüm Yol Haritası (Visual Transformation Roadmap)

> **Belge türü:** Planlama / strateji (yalnızca yol haritası).
> **Kapsam dışı:** Bu belge hiçbir görsel varlık üretmez, indirmez veya kod yazmaz. Amaç, "Ehliyet Akademi" platformunu premium bir Version 1.0 görsel standardına taşıyacak bir denetim (audit) ve fazlı uygulama planı sunmaktır.
> **Sürüm:** v1.0 · **Tarih:** 2026-07-15 · **Dil:** Türkçe (teknik terimler EN korunur)
> **İlgili dosyalar:** `apps/web/components/LessonFigure.tsx` (12 SVG), `apps/web/components/MasteryRadar.tsx`, `apps/web/app/(marketing)/page.tsx` (vitrin), `apps/web/app/(app)/` (SaaS kabuğu), `apps/web/app/api/media/[id]/` (CMS medya boru hattı).

---

## Yönetici Özeti (Executive Summary)

### Dürüst durum tespiti

Ehliyet Akademi **teknik olarak güçlü, görsel olarak eksik** bir platformdur. Bunu net söylemek gerekir çünkü V1.0 lansmanı için en büyük risk mimaride değil, ilk izlenimde ve öğrenme deneyiminin görsel bütünlüğündedir.

**Bugün güçlü olan taraf (kanıtlanmış):**

- Next.js 15 App Router, framework'süz vanilla CSS, dark-first + light tema, kalıcı sol-sidebar SaaS kabuğu.
- 198 orijinal soru + 19 ders + grounded (halüsinasyon kapılı) AI koç + SRS/mastery motoru + tam ticaret/hukuk/güvenlik altyapısı.
- **12 elle yazılmış inline SVG diyagram** — erişilebilir (`role="img"` + `aria-label`), tema-duyarlı, offline, sıfır bağımlılık. Mevcut figureId'ler: `signs, vehicle, dashboard, junction, following-distance, overtaking, pedestrian, cpr, abc, hill-start, parking, roundabout`.

**Bugün eksik olan taraf (görsel olgunluk):**

- **Fotoğraf yok.** Motor bölmesi, gösterge paneli, lastik, kriko gibi "gerçek araç" konularında öğrenci soyut çizgi resimlere bakıyor; sınavda karşılaşacağı gerçek nesneye değil.
- **İkon seti yok** — emoji dışında tutarlı bir ikonografi yok. Emoji platformlar arası tutarsız render olur ve premium algıyı düşürür.
- **İllüstrasyon sistemi yok** — 12 SVG el işi; ortak bir grid, stroke, renk ve köşe-yuvarlaklığı dili (design tokens) yok. Diyagramlar iyi ama "tek elden çıkmış bir sistem" gibi durmuyor.
- **Animasyon/hareket sistemi yok** — Lottie/Rive/Framer Motion yok; park manevrası, hill-start, şerit değiştirme gibi doğası gereği _hareketli_ konular statik.
- **Vitrin (landing) çoğunlukla metin + CTA.** Hero görseli, sosyal kanıt, başarı hikâyesi anlatımı zayıf; ilk 5 saniyede "premium akademi" algısı oluşmuyor.
- **Trafik işaretleri görsel olarak temsil edilmiyor.** `signs` tek bir jenerik SVG; oysa Türkiye B sınıfı müfredatının belkemiği yüzlerce işarettir.

### Hedefler (V1.0 görsel standardı)

1. **Orijinallik & telif güvenliği birinci ilke.** Hiçbir üçüncü taraf işaret çizimi, MEB/yayınevi görseli veya telifli eğitim materyali kopyalanmaz. Tüm görseller sıfırdan, jenerik geometrik/renk kurallarına dayalı orijinal üretim.
2. **Offline-first korunur.** Ders görsellerinin ana omurgası inline SVG kalır; ağır varlıklar (fotoğraf/Lottie) CMS medya boru hattı (`/api/media/[id]`) üzerinden lazy yüklenir, offline kritik yolu bozmaz.
3. **Tek elden görsel sistem.** Bir illüstrasyon dili (grid, stroke, renk paleti, köşe yarıçapı, tipografi) tanımlanır; 12 mevcut SVG bu sisteme migrate edilir; yeni her görsel bu sisteme uyar.
4. **Erişilebilirlik pazarlık dışı.** Her görselde anlamlı `alt`/`aria-label`, tema-duyarlılık, `prefers-reduced-motion` saygısı, renk-kontrastı AA.
5. **Dürüstlük rozetleri korunur.** Görseller de içerik gibi sınıflandırılır (Resmî Kural / Sınav Uygulaması / Eğitmen Tavsiyesi / En İyi Uygulama / Güvenlik İpucu). Uydurma istatistik, sahte testimonial, uydurma başarı oranı **yok**.

### Bu belgenin çıktısı

7 bölümlük denetim + 5 fazlı (V1–V5) uygulama planı. Her faz için kapsam, karmaşıklık (S/M/L), bağımlılık, öncelik (P0/P1/P2), sıra ve somut teslimatlar. V1.0 öncesi zorunlu (must-ship) ile sonraya bırakılabilir olanlar net ayrılır.

---

## Bölüm 1 — Trafik İşaretleri (Traffic Signs)

Trafik işaretleri, Türkiye B sınıfı hem teori (e-Sınav, Trafik ve Çevre 23 soru) hem de yol farkındalığı için müfredatın **belkemiğidir**. Bugün uygulamada bunları temsil eden tek varlık jenerik `signs` SVG'sidir — bu, en yüksek getirili görsel yatırım alanıdır.

### 1.0 Telif güvenliği ilkesi (bu bölümün en kritik kuralı)

- Trafik işaretlerinin **geometrisi ve renk kodları işlevsel bir standarttır** (Karayolları Trafik Yönetmeliği; Viyana Sözleşmesi geleneği). Üçgen = tehlike, kırmızı çember = yasak, mavi daire = mecburiyet gibi kurallar _fikir/işlev_ düzeyindedir ve telif kapsamında değildir.
- **Telifli olan, belirli bir yayınevinin/uygulamanın çizim uygulamasıdır** (pictogram stili, gölge, perspektif, dosya). Bunları **izlemek/trace etmek/kopyalamak yasaktır.**
- **Yaklaşımımız:** Her işareti sıfırdan, kendi pictogram dilimizle çiziyoruz. Standart şekli ve rengi kullanıyoruz (bunlar serbest), içindeki sembolü kendi çizgi/dolgu stilimizle yeniden yorumluyoruz. Sonuç: hukuken güvenli, görsel olarak tutarlı, tek elden bir set.

### 1.1 Parametrik SVG mimarisi (önerilen üretim yaklaşımı)

İşaretleri tek tek elle çizmek yerine, **şekil/renk kabuğu (shell) + sembol (glyph)** ayrımına dayalı parametrik bir SVG bileşen ailesi öneriyoruz:

- **Kabuk bileşenleri (5 adet):** `TriangleShell` (tehlike), `RedRingShell` (yasak), `BlueDiscShell` (mecburiyet), `RectShell` (bilgi — mavi/yeşil varyant), `OctagonShell` (DUR) + özel `InvertedTriangleShell` (yol ver).
- **Glyph katmanı:** Kabuğun içine yerleşen, ortak bir 24×24 çizim grid'ine, tek stroke genişliğine ve tema-duyarlı renklere göre çizilmiş orijinal sembol (araç, yaya, ok, rakam, vb.).
- **Design tokens:** `--sign-red`, `--sign-blue`, `--sign-green`, `--sign-yellow`, stroke genişliği, köşe yarıçapı tema değişkenleri olarak tanımlanır; hem dark hem light modda kontrast korunur.
- **Faydası:** Yüzlerce işaret, birkaç düzine glyph + 6 kabuk kombinasyonundan türer. Bakım kolay, dosya boyutu küçük, %100 offline, tema-duyarlı, tek elden.
- **Yerleşim:** Yeni `components/signs/` klasörü; `<TrafficSign category="warning" glyph="slippery" />` gibi bir API. Mevcut `LessonFigure.tsx` `signs` figürü bu sistemi kullanacak şekilde yeniden yazılır.

### 1.2 Kategori kataloğu

Aşağıdaki tabloda her resmî kategori için tema, öğrenme stratejisi, sınav önemi ve şekil/renk dili verilmiştir.

| Kategori                                      | Resmî anlam teması                                                                                                    | Şekil / Renk dili                                                              | Öğrenme stratejisi                                                         | Sınav önemi                                          |
| --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ | -------------------------------------------------------------------------- | ---------------------------------------------------- |
| **Tehlike Uyarı İşaretleri**                  | Yaklaşan tehlikeyi önceden bildirir (viraj, kavşak, kaygan yol, yaya geçidi yaklaşımı)                                | Eşkenar üçgen (tepe yukarı), kırmızı kenar, beyaz/açık zemin, siyah sembol     | Şekil+renk sabitini önce öğret ("üçgen = dikkat"), sonra sembol ayırt etme | **Çok yüksek** — en kalabalık ve en sık sorulan grup |
| **Trafik Tanzim — Yasaklayıcı / Kısıtlayıcı** | Bir eylemi yasaklar veya sınırlar (girişi yok, hız sınırı, park/duraklama yasağı, sollama yasağı, taşıt cinsi kısıtı) | Daire, kırmızı çember, beyaz zemin, siyah sembol; bazılarında kırmızı çapraz   | "Kırmızı çember = yapma"; yasağın başlangıç/bitiş mantığı                  | **Çok yüksek** — hız/park/sollama soruları klasik    |
| **Trafik Tanzim — Mecburiyet İşaretleri**     | Zorunlu davranış (mecburi yön, mecburi asgari hız, bisiklet yolu)                                                     | Daire, mavi zemin, beyaz sembol                                                | "Mavi daire = yap"; yasak (kırmızı) ile karşıtlığını vurgula               | Yüksek — yasak/mecburiyet karışıklığı sık hata       |
| **Bilgi İşaretleri**                          | Yol kullanıcısını bilgilendirir (hastane, yaya geçidi bilgi, park yeri, çıkmaz yol, tek yön)                          | Dikdörtgen/kare, mavi zemin, beyaz sembol                                      | Yasak/mecburiyetle karıştırılmasını önle (renk+şekil farkı)                | Orta-yüksek                                          |
| **Duraklama & Parketme İşaretleri**           | Durma/park kural ve izinleri                                                                                          | Yasak grubu (kırmızı çember, çapraz/eğik çizgi) + bilgi grubu (mavi kare, "P") | "P mavi = izin, kırmızı çizgili = yasak"; okla yön/mesafe                  | Yüksek — direksiyon+teori kesişimi                   |
| **Otoyol & Bilgilendirme (Yönlendirme)**      | Otoyol/devlet yolu yönlendirme, mesafe, güzergâh                                                                      | Dikdörtgen; **otoyol = yeşil zemin**, devlet yolu = mavi zemin, beyaz yazı     | Renk = yol sınıfı eşlemesi                                                 | Orta                                                 |
| **Geçici / Çalışma İşaretleri**               | Yol çalışması, geçici düzenleme                                                                                       | Sarı/turuncu zemin, siyah sembol (üçgen/dikdörtgen)                            | "Sarı zemin = geçici durum"; kalıcı işaretten ayır                         | Orta                                                 |
| **Yol Çizgileri / Yatay İşaretlemeler**       | Zemine çizilen düzenlemeler (şerit çizgileri, yaya geçidi, DUR çizgisi, oklar, ada)                                   | Beyaz/sarı çizgiler; kesik = geçilebilir, düz = geçilemez                      | Kuş bakışı yol sahnesinde bağlam içinde göster                             | **Çok yüksek** — direksiyon için kritik              |
| **Özel: DUR & Yol Ver**                       | Mutlak durma / geçiş hakkı verme                                                                                      | DUR = kırmızı sekizgen; Yol Ver = ters üçgen, kırmızı kenar                    | Benzersiz şekilleriyle ("sadece bu ikisi") öğret                           | Çok yüksek                                           |
| **Işıklı/Sesli & Trafik Görevlisi**           | Trafik ışıkları ve görevli işaretleri                                                                                 | Işık: dikey kutu (kırmızı/sarı/yeşil); görevli: figür + kol pozisyonu          | Görevli işareti > ışık > levha hiyerarşisi                                 | Yüksek — öncelik soruları                            |

### 1.3 Temsili işaretlerin uygulamaya entegrasyonu

Aşağıdaki tablo, her kategoriden temsili işaretlerin **nerede göründüğünü** ve **quiz/mock/ders akışına nasıl bağlandığını** belirtir.

| Temsili işaret                                                     | Kategori         | Nerede görünür                                       | Quiz / Mock / Ders entegrasyonu                                                                       |
| ------------------------------------------------------------------ | ---------------- | ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Kaygan yol, tehlikeli viraj, yaya geçidi yaklaşımı                 | Tehlike uyarı    | Ders (Trafik İşaretleri), soru şıkları, mock e-Sınav | Görsel-tanıma sorusu: "Bu işaret ne anlatır?" 4 metin şık; ders kartında flip (ön=görsel, arka=anlam) |
| Girişi olmayan yol, azami hız (50/70), park yasağı, sollama yasağı | Yasaklayıcı      | Ders, quiz, mock, direksiyon "yol okuma"             | "Hangi işaret sollamayı yasaklar?" 4 görsel şık; hız işaretleri simülatörde senaryo tetikler          |
| Mecburi sağa dön, mecburi asgari hız                               | Mecburiyet       | Ders, quiz                                           | Yasak↔mecburiyet ayırt etme sorusu (renk-şekil çeldiricisi)                                           |
| Hastane, park yeri (P), tek yön                                    | Bilgi            | Ders, quiz                                           | Bağlam sorusu; direksiyon "park yeri bulma" senaryosu                                                 |
| DUR, Yol Ver                                                       | Özel             | Ders, quiz, mock, kavşak simülatörü (`junction`)     | Kavşak önceliği diyagramına gömülü; "kim önce geçer?"                                                 |
| Yaya geçidi çizgisi, kesik/düz şerit çizgisi, oklar                | Yatay işaretleme | Ders, direksiyon dersleri, mock                      | Kuş bakışı sahnede (`overtaking`, `pedestrian` figürleriyle birleşik)                                 |
| Yol çalışması, gevşek malzeme                                      | Geçici/çalışma   | Ders, quiz                                           | "Sarı zemin ne anlama gelir?" kategori-tanıma                                                         |

### 1.4 Öğrenme oyunlaştırması (işaret-özel)

- **İşaret galerisi** (`/dersler/trafik-isaretleri`): kategoriye göre filtrelenebilir, aranabilir grid; her kart tema-duyarlı SVG + anlam + sınıflandırma rozeti.
- **Flip-kart destesi:** ön yüz görsel, arka yüz anlam; mevcut `LessonPractice.tsx` flip mekaniği yeniden kullanılır.
- **"İşaret avı" mini-quiz:** görsel → 4 metin şık ve tersi (metin → 4 görsel şık). Soru bankasına `figureRef` alanı ile bağlanır (yeni, geriye-uyumlu şema alanı).
- **Sınav önemi göre önceliklendirme:** tehlike + yasak + DUR/Yol Ver + yatay işaretlemeler = P0; bilgi/otoyol/geçici = P1.

---

## Bölüm 2 — Araç Görselleri (Vehicle Visuals)

Direksiyon (Mavi/vehicle-introduction) bölümü 14 kalemlik somut, elle-gösterilen bir muayenedir. Öğrenci burada **gerçek nesneyi tanımak** zorunda — soyut çizim yeterli değil. Bu bölüm en yüksek "üretim yöntemi kararı" gerektiren alandır; her görsel için {orijinal fotoğraf, lisanslı varlık, SVG, illüstrasyon, OpenAI görsel üretimi, 3D} arasından gerekçeli seçim yapılır.

### 2.1 Üretim yöntemi seçim ilkeleri

- **Fotoğraf** — nesne tanıma kritik olduğunda (motor bölmesi parçaları, kriko, gösterge paneli lambaları). En yüksek gerçekçilik; ama lisans/gizlilik/tema (dark/light) ve dosya boyutu maliyeti var. **Referans araç: Renault Clio 4/5 manuel** (proje standardı) — tutarlılık için tek araçta çekim önerilir.
- **SVG** — şematik/ilişkisel bilgi (pedal düzeni, vites şeması, ayna açıları, park referans noktaları). Offline, tema-duyarlı, ölçeklenebilir. **Varsayılan tercih.**
- **İllüstrasyon** — yarı-gerçekçi ama stilize (motor bölmesi "harita"sı, koltuk ayarı adımları). SVG'den zengin, fotoğraftan esnek; tema uyumu kolay.
- **OpenAI görsel üretimi** — hızlı taslak/varyant, boşluk doldurma. **Uyarı:** üretilen görsel _ticari kullanım ve doğruluk_ açısından denetlenmeli; teknik parça görsellerinde yanlış/uydurma detay riski var → sınav-kritik parçalarda tek başına kullanılmaz, fotoğraf/illüstrasyonla doğrulanır. `.env` içindeki `OPENAI_API_KEY` yalnızca üretim boru hattında, asla client'ta.
- **3D** — yüksek maliyet; yalnızca park manevrası/kavşak gibi mekânsal-etkileşimli demolar için V3+ değerlendirilir (Bölüm 4). V1.0 için gereksiz.
- **Lisanslı varlık** — yalnızca orijinal üretim maliyeti savunulamazsa; lisans şartı offline/CDN/versiyon ile uyumlu ve ticari kullanıma açık olmalı.

### 2.2 Görsel envanteri ve önerilen yöntem

| #   | Görsel                                 | Uygulamadaki yeri              | Önerilen yöntem                        | Gerekçe                                                       | Lisans / Erişilebilirlik notu                                                           |
| --- | -------------------------------------- | ------------------------------ | -------------------------------------- | ------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| 1   | Motor bölmesi (genel)                  | Direksiyon dersi, Mavi muayene | Fotoğraf + SVG overlay (etiketli)      | Gerçek konumu tanımak şart; SVG etiket katmanı tema-duyarlı   | Kendi çektiğimiz foto → tam telif bizde; `alt`: "Clio motor bölmesi, parçalar etiketli" |
| 2   | Akü (batarya)                          | Direksiyon dersi               | Fotoğraf (yakın çekim)                 | "Aküyü göster" kalemi                                         | Kutup +/− etiketi SVG overlay                                                           |
| 3   | Motor yağ çubuğu (dipstick)            | Ders                           | Fotoğraf + SVG (min/max seviye şeması) | Seviye okuma şematik anlatılmalı                              | `alt` seviye işaretlerini açıklar                                                       |
| 4   | Soğutma suyu (antifriz) haznesi        | Ders                           | Fotoğraf                               | Konum tanıma                                                  | "Motor sıcakken açma" güvenlik rozeti                                                   |
| 5   | Cam suyu haznesi                       | Ders                           | Fotoğraf                               | Akü/antifrizle karışır → net foto                             | Antifrizden ayırt-et vurgusu                                                            |
| 6   | Fren hidroliği haznesi                 | Ders                           | Fotoğraf                               | Konum tanıma                                                  | Güvenlik rozeti                                                                         |
| 7   | Sigorta kutusu                         | Ders                           | Fotoğraf                               | Konum tanıma                                                  | —                                                                                       |
| 8   | Lastik (diş/basınç görsel kontrol)     | Ders, Mavi muayene             | SVG (diş derinliği şeması) + Fotoğraf  | Diş derinliği şematik daha net                                | SVG tema-duyarlı                                                                        |
| 9   | Stepne (yedek lastik)                  | Ders (bagaj)                   | Fotoğraf                               | Bagaj kalemi                                                  | —                                                                                       |
| 10  | Kriko                                  | Ders (bagaj)                   | Fotoğraf + SVG (kaldırma noktası)      | Kaldırma noktası şematik                                      | Güvenlik rozeti                                                                         |
| 11  | Gösterge paneli (genel)                | Ders, Mavi muayene             | Fotoğraf + interaktif SVG overlay      | Mevcut `dashboard` SVG'yi zenginleştir                        | Her gösterge etiketli                                                                   |
| 12  | Vites kutusu / manuel vites şeması     | Ders                           | **SVG**                                | 5 ileri + 1 geri şeması saf şematik                           | Tema-duyarlı; `alt` vites düzenini yazar                                                |
| 13  | Pedallar (debriyaj-fren-gaz)           | Ders                           | **SVG**                                | Konum/sıra şematik (L→R)                                      | `alt`: "soldan sağa debriyaj, fren, gaz"                                                |
| 14  | Direksiyon simidi + kolonu kumandaları | Ders                           | Fotoğraf + SVG (sinyal/silecek/far)    | Kumanda kolları şematik daha net                              | —                                                                                       |
| 15  | Koltuk ayarı                           | Ders                           | İllüstrasyon (adım adım)               | Hareket/adım anlatımı illüstrasyonla akıcı                    | Adımlar numaralı                                                                        |
| 16  | Aynalar (iç/dış + kör nokta)           | Ders                           | **SVG** (kuş bakışı görüş alanı)       | Görüş alanı/kör nokta şematik                                 | Mevcut `Aynalar` figürü geliştirilir                                                    |
| 17  | Farlar/sinyaller (kısa/uzun/dörtlü)    | Ders                           | Fotoğraf + SVG ikon                    | Işık türü ikonu şematik                                       | Gösterge ikonlarıyla eşleşir                                                            |
| 18  | Muayene noktaları (dış tur)            | Ders                           | İllüstrasyon (araç dış hat + işaret)   | Araç etrafında gezinme illüstrasyonla                         | —                                                                                       |
| 19  | Park referans noktaları                | Direksiyon, park simülatörü    | **SVG** (kuş bakışı + ayna görünümü)   | Referans noktaları saf şematik; mevcut `parking` genişletilir | `alt` referansları açıklar                                                              |
| 20  | Araç boyutları / gabari                | Direksiyon dersi               | **SVG** (ölçülü diyagram)              | Ölçü/mesafe şematik                                           | —                                                                                       |

### 2.3 Özet ve karar

- **Şematik/ilişkisel (12, 13, 16, 19, 20 ve işaret glyph'leri): SVG** — offline, tema-duyarlı, orijinal, sıfır lisans riski. **Varsayılan.**
- **Nesne-tanıma kritik (1–7, 9–11, 14, 17): kendi çektiğimiz orijinal fotoğraf** — tam telif kontrolü, referans araç Clio 4/5. Tek çekim seansı → tutarlı ışık/açı.
- **Adım/hareket anlatan (15, 18): illüstrasyon** — SVG-tabanlı, tema-duyarlı, tek elden stil.
- **OpenAI:** yalnızca taslak/varyant ve non-kritik dekoratif alanlarda; sınav-kritik teknik görselde doğrulama olmadan yayınlanmaz.
- **3D:** V1.0 kapsamı dışı.
- **Erişilebilirlik disiplini:** her fotoğraf/illüstrasyon anlamlı `alt`; dekoratifse `alt=""`. Fotoğrafların dark modda okunabilirliği için hafif overlay veya SVG etiket katmanı fotoğrafın üstünde (fotoğrafın kendisi tema değiştirmez, etiketler değişir).

---

## Bölüm 3 — Vitrin (Landing Page) Deneyimi

Vitrin bugün çoğunlukla metin + CTA. Modern eğitim SaaS'larında (Duolingo, Brilliant, Coursera, Khan Academy) vitrin, ürünün _öğrenme vaadini 5 saniyede_ göstererek dönüşüm sağlar. Hedef: dürüst ama premium bir anlatım.

### 3.0 Dürüstlük kısıtı (pazarlık dışı)

- **Testimonial'lar gerçek olacak.** Toplanmadan hiçbir kullanıcı yorumu gösterilmez. V1.0'da gerçek yorum yoksa bölüm ya boş bırakılır ya "İlk mezunlarımız yakında" gibi dürüst bir placeholder ile konur — sahte isim/foto/yorum **asla**.
- **Başarı metrikleri dürüst.** "%98 geçme oranı", "50.000 öğrenci" gibi doğrulanamayan sayılar uydurulmaz. Bunun yerine _doğrulanabilir_ metrikler: "198 orijinal soru", "19 ders", "grounded AI koç", "offline çalışır", "50 soru / 45 dk gerçek format deneme". Metrik yoksa özellik anlatılır.
- **Honesty badge** vitrine de taşınır: "Uydurmayan AI — sadece kendi içeriğimizden yanıt verir."

### 3.1 Bölüm-bölüm vitrin planı

| Sıra | Bölüm                        | İçerik & görsel strateji                                                                                                                                                                                                                                                | Not                                                 |
| ---- | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| 1    | **Hero**                     | Tek cümlelik net vaat ("B sınıfı direksiyon+teori sınavını ilk seferde geç"), birincil CTA ("Ücretsiz başla"), ikincil CTA ("Nasıl çalışır?"). Sağda: ürünün _gerçek_ bir ekranını gösteren hafif animasyonlu illüstrasyon (mock deneme ekranı veya işaret flip-kartı). | Gerçek UI göster; stok görsel değil                 |
| 2    | **Sosyal kanıt şeridi**      | Dürüst güven göstergeleri: "Resmî MEB formatı", "Offline çalışır", "KVKK uyumlu", "Reklamsız". Sayı uydurma yok.                                                                                                                                                        | Rozet stili, tema-duyarlı                           |
| 3    | **Özellik vitrinleri (3–4)** | Her biri: kısa başlık + tek cümle + küçük animasyonlu diyagram. (1) Gerçek-format deneme, (2) Grounded AI koç, (3) SRS/mastery ilerleme, (4) Direksiyon simülatörü.                                                                                                     | Bölüm 4 illüstrasyon/animasyonları yeniden kullanır |
| 4    | **"Nasıl çalışır" — 3 adım** | Öğren → Dene → Ölç. Her adım orijinal illüstrasyon.                                                                                                                                                                                                                     | Anlatı akışı                                        |
| 5    | **İçerik derinliği**         | "198 orijinal soru, 19 ders, 4 e-Sınav konusu" — doğrulanabilir, gerçek sayılar.                                                                                                                                                                                        | Metrik = özellik                                    |
| 6    | **Dürüstlük & güven**        | Sınıflandırma rozeti sistemi anlatılır (Resmî Kural / Sınav Uygulaması / …); "AI uydurmaz" vurgusu.                                                                                                                                                                     | Farklılaştırıcı                                     |
| 7    | **Testimonial (koşullu)**    | Gerçek yorum toplandıysa göster; yoksa dürüst placeholder.                                                                                                                                                                                                              | Sahte yok                                           |
| 8    | **Fiyatlandırma önizleme**   | Tek-seferlik paketler (abonelik yok) — mevcut `Pricing.tsx`. Şeffaf fiyat.                                                                                                                                                                                              | İlk yardım/güvenlik içeriği asla premium            |
| 9    | **Yol haritası / şeffaflık** | "Sırada ne var" — dürüst gelişim planı (mobil app, daha çok soru).                                                                                                                                                                                                      | Güven inşası                                        |
| 10   | **Son CTA + footer**         | Tekrar birincil CTA; hukuki linkler (gizlilik/KVKK/çerez).                                                                                                                                                                                                              | —                                                   |

### 3.2 Premium hareket & etkileşim (vitrin)

- **Hero mikro-animasyon:** flip-kart veya gösterge lambası yanıp sönme — hafif, `prefers-reduced-motion` ile durur.
- **Scroll-reveal:** bölümler görünüre girince yumuşak fade+rise (200–400ms, ease-out). Abartısız.
- **İnteraktif demo bölümü:** ziyaretçi tek bir örnek soruyu vitrinde çözebilir (kayıt gerektirmeden) — Brilliant/Duolingo "hemen dene" mantığı, ama içerik bizim.
- **Performans:** hero görseli hariç her şey lazy; LCP < 2.5s hedefi korunur (mevcut SSG + CSP mimarisiyle uyumlu).

---

## Bölüm 4 — Uygulama İçi Deneyim (In-App)

SaaS kabuğu (`app/(app)/`) sağlam; eksik olan, öğrenmeyi _görselleştiren_ ve _ödüllendiren_ hareket ve etkileşim katmanı. Aşağıdaki plan mevcut bileşenleri (`Dashboard.tsx`, `MasteryRadar.tsx`, `LessonFigure.tsx`, `ExamSimulator.tsx`, `LessonPractice.tsx`) zenginleştirir.

### 4.1 İllüstrasyon & interaktif diyagramlar

- **12 mevcut SVG'yi sisteme migrate et:** ortak grid, stroke, renk token'ları, tema-duyarlılık standardı. "El işi 12 diyagram" → "tek elden 12 diyagram".
- **İnteraktif hale getir:** `junction`, `overtaking`, `pedestrian`, `roundabout` gibi ilişkisel diyagramlar tıklanabilir/adımlanabilir olur (hover/tap → açıklama katmanı).
- **İnteraktif gösterge paneli:** `dashboard` figürü → her lamba tıklanınca anlam + aciliyet (kırmızı=dur/servis, sarı=dikkat). Renk-aciliyet eşlemesi.

### 4.2 Animasyonlu öğrenme demoları

- **Park manevrası (`parking`):** adım-adım animasyon (paralel park referans noktaları) — Lottie veya SVG-SMIL/CSS keyframe. Kullanıcı adımları ileri/geri sarabilir. Offline için CSS-tabanlı tercih; ağır Lottie CMS'ten lazy.
- **Hill-start (`hill-start`):** debriyaj-gaz-el freni koordinasyonu zaman çizelgesi animasyonu.
- **Şerit değiştirme / sollama (`overtaking`):** araç hareketi + ayna kontrol sırası vurgusu.
- **Kavşak önceliği (`junction`):** araçların sıralı geçişi animasyonla.

### 4.3 Grafik & ilerleme görselleştirmeleri

- **Mastery radar** (`MasteryRadar.tsx`) korunur/geliştirilir; 4 eksenli konu hâkimiyeti. _(Not: grafik/veri-görselleştirme yapılırken `dataviz` skill'i referans alınır — tutarlı, erişilebilir, light/dark palet.)_
- **İlerleme çubukları & streak:** panelde animasyonlu doluş (reduced-motion'da anında).
- **Deneme sonucu görselleştirme:** Kırmızı/Sarı/Mavi hata dağılımı, geçme eşiği (70/100) göstergesi — dürüst, gerçek veriden.
- **Zaman içinde gelişim:** çözülen soru/doğruluk trendi (kullanıcının kendi verisi).

### 4.4 Mikro-etkileşimler & durum ekranları

- **Animasyonlu öğrenme kartları:** flip (mevcut), doğru/yanlış geri bildirim mikro-animasyonu (yeşil onay / nazik düzeltme).
- **Boş durumlar (empty states):** "Henüz deneme yok" → cesaretlendiren illüstrasyon + tek CTA. Jenerik boş kutu değil.
- **Yükleme durumları (loading):** mevcut streaming skeleton (`app/(app)/loading.tsx`) korunur; premium shimmer.
- **Başarı kutlamaları (`basarilar`):** rozet açılınca hafif konfeti/parlama — reduced-motion'da statik rozet.

### 4.5 Hareket sistemi (motion system)

Tutarlı, ölçülü, erişilebilir bir hareket dili — design tokens olarak tanımlanır:

| Token              | Değer                                             | Kullanım                                                              |
| ------------------ | ------------------------------------------------- | --------------------------------------------------------------------- |
| `--motion-fast`    | 120–150ms                                         | Hover, buton basış, toggle                                            |
| `--motion-base`    | 200–250ms                                         | Kart flip, scroll-reveal, tab geçiş                                   |
| `--motion-slow`    | 350–450ms                                         | Sayfa/panel geçişi, demo adımı                                        |
| Easing (giriş)     | `ease-out` / `cubic-bezier(0.16,1,0.3,1)`         | Görünüre girme                                                        |
| Easing (çıkış)     | `ease-in`                                         | Kaybolma                                                              |
| **Reduced-motion** | Tüm süreler → ~0ms, animasyon yerine anında durum | `@media (prefers-reduced-motion: reduce)` her animasyonda **zorunlu** |

- **İlke:** hareket bilgi taşır (dikkat yönlendirir, durum değişimini açıklar), dekoratif değil.
- **Offline/performans:** kritik yol animasyonları CSS/SVG; ağır Lottie yalnızca CMS medya üzerinden lazy, offline'da statik fallback.

---

## Bölüm 5 — Görsel Üretim Stratejisi (Image Production)

Her görsel sınıfı için kaynak, lisans, üretim, sıkıştırma, optimizasyon, erişilebilirlik, responsive, CDN ve versiyonlama tanımlanır. Üstteki ilke tüm süreci yönetir.

### 5.0 Politika (değişmez ilkeler)

1. **Orijinal-önce (original-first):** her görsel önce kendi üretimimiz olarak denenir. Üçüncü taraf varlık ancak orijinal üretim savunulamazsa ve ticari+offline+CDN uyumlu lisansla.
2. **Telif-güvenli (copyright-safe):** hiçbir işaret çizimi, MEB/yayınevi/rakip uygulama görseli izlenmez, kopyalanmaz. Standart şekil/renk (işlevsel) serbest; belirli çizim ifadesi değil.
3. **Offline-dostu (offline-friendly):** ders görsellerinin omurgası inline SVG; ağır varlık CMS'ten lazy, kritik yolu bozmaz. SW cache stratejisiyle uyumlu.

### 5.1 Görsel sınıfı × strateji matrisi

| Görsel sınıfı                 | Kaynak                                        | Lisans                                                    | Üretim                             | Sıkıştırma / Optimizasyon            | Responsive             | CDN / Dağıtım                                     | Versiyonlama             |
| ----------------------------- | --------------------------------------------- | --------------------------------------------------------- | ---------------------------------- | ------------------------------------ | ---------------------- | ------------------------------------------------- | ------------------------ |
| **İşaret SVG'leri**           | Orijinal (parametrik)                         | Bizim (tam)                                               | Kod-içi React/SVG bileşen          | SVGO benzeri; inline, tema token     | `viewBox` + %100 ölçek | Bundle içinde (offline)                           | Git; `components/signs/` |
| **Ders diyagramları (12+)**   | Orijinal                                      | Bizim                                                     | Inline SVG (`LessonFigure.tsx`)    | Path sadeleştirme                    | `viewBox`              | Bundle içinde                                     | Git + `figureId`         |
| **Araç fotoğrafları**         | Kendi çekimimiz (Clio 4/5)                    | Bizim                                                     | Fotoğraf + SVG etiket katmanı      | WebP/AVIF, çoklu boyut, `next/image` | `srcset`/`sizes`       | CMS `/api/media/[id]` (immutable cache) veya Blob | Medya asset id + hash    |
| **İllüstrasyonlar**           | Orijinal                                      | Bizim                                                     | SVG-tabanlı illüstrasyon           | SVGO / inline                        | `viewBox`              | Bundle veya CMS                                   | Git                      |
| **Animasyonlar (Lottie/CSS)** | Orijinal                                      | Bizim                                                     | CSS/SVG (kritik) · Lottie (zengin) | Lottie JSON min; CSS bundled         | Konteyner-akışkan      | Kritik=bundle, zengin=CMS lazy                    | Git / medya id           |
| **OpenAI görselleri**         | Üretilmiş                                     | **Doğrulama şart** — ticari kullanım ve doğruluk denetimi | Boru hattında üretim, insan onayı  | WebP                                 | `srcset`               | CMS medya                                         | Prompt + versiyon kaydı  |
| **İkon seti**                 | Orijinal veya açık-lisans (ör. MIT ikon seti) | Ticari + atıf uyumlu                                      | SVG ikon bileşenleri               | Inline/sprite                        | `em` ölçek             | Bundle                                            | Git                      |

### 5.2 Erişilebilirlik disiplini (alt-text kuralı)

- Bilgilendirici görsel → anlamlı `alt`/`aria-label` (SVG'de `role="img"`), _ne gösterdiğini ve neden_ açıklar. Mevcut 12 SVG bu standartta — genişletilir.
- Dekoratif görsel → `alt=""` / `aria-hidden`.
- İşaretlerde `alt` = işaretin resmî anlamı (görünümü değil): "Sollama yasağı" (doğru) > "kırmızı çemberli iki araç" (yetersiz).
- Renkle iletilen bilgi (kırmızı/sarı/mavi hata; gösterge lambası) her zaman metin/şekil ile de kodlanır (renk-körü güvenliği).

### 5.3 CDN & versiyonlama stratejisi

- **Kritik ders görselleri:** bundle içinde, offline. SW cache-first.
- **Ağır varlıklar:** mevcut CMS boru hattı (`content_items`/`media_assets`, base64-in-DB, `/api/media/[id]` immutable cache) veya ihtiyaç halinde Blob/S3 adaptörü (zaten mimaride gate'li). CDN cache immutable + içerik-hash isim.
- **Versiyonlama:** SVG/illüstrasyon Git'te; medya asset'leri id + hash ile; görsel değişince yeni hash → cache-bust otomatik.

---

## Bölüm 6 — UI/UX Evrimi (Benchmark Karşılaştırması)

Her referans üründen _alınabilir fikir_, _kopyalanmaması gereken_ ve _Ehliyet Akademi'nin nasıl farklılaştığı_ ayrı ayrı verilir. Farklılaştırıcı çekirdek her satırda sabittir: **Türkiye MEB sınav odağı, grounded (uydurmayan) AI, dürüstlük rozetleri, offline-first.** _(Distinctive görsel yön kararları için `frontend-design` skill'i uygulanır.)_

| Ürün             | Alınabilir fikir                                                                                | Kopyalanmaması gereken                                                                            | Ehliyet Akademi farkı                                                                           |
| ---------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| **Duolingo**     | Streak, günlük hedef, mikro-ödül, hafif oyunlaştırma, "hemen dene"                              | Aşırı gamification, dark-pattern bildirimler, karakter maskotuna aşırı bağımlılık, yapay aciliyet | Oyunlaştırma sınav-hazırlığa hizmet eder, dopamin döngüsüne değil; içerik MEB-gerçek            |
| **Brilliant**    | İnteraktif/manipüle edilebilir diyagram, "yaparak öğren", kavram görselleştirme                 | STEM-ağır soyutlama, abonelik zorlaması                                                           | İnteraktif diyagramlar somut sınav senaryoları (kavşak, park) üzerine; tek-seferlik satın alma  |
| **Notion**       | Temiz tipografi, boşluk (whitespace) disiplini, esnek içerik blokları                           | Aşırı minimalizm/özelliksizlik hissi, boş-tuval öğrenme yükü                                      | Yapılandırılmış, rehberli öğrenme yolu — boş tuval değil                                        |
| **Linear**       | Keskin, hızlı, klavye-dostu, tutarlı design tokens, premium dark tema                           | B2B/mühendis estetiğinin soğukluğu, jargon                                                        | Aynı teknik keskinlik + sınav adayına sıcak, teşvik edici ton                                   |
| **Stripe**       | Güven veren netlik, mükemmel dokümantasyon estetiği, kademeli açıklama (progressive disclosure) | Kurumsal/finansal ciddiyetin mesafesi                                                             | Netlik + öğrenci-dostu; "dürüstlük rozeti" Stripe'ın güven diline benzer ama eğitim-etik odaklı |
| **Khan Academy** | Ücretsiz-erişim etiği, mastery-tabanlı ilerleme, ilerleme görselleştirme                        | Tarihlenmiş görsel dil, yoğun/kalabalık arayüz                                                    | Modern görsel sistem + mastery; ilk yardım/güvenlik içeriği asla premium (etik)                 |
| **Coursera**     | Yapılandırılmış müfredat, sertifika/tamamlanma hissi, güven göstergeleri                        | Uydurma "kurumsal ortak" logoları, şişirilmiş pazarlama                                           | Dürüst metrikler; sahte kurum/rozet yok; MEB formatına sadık                                    |

**Sentez:** Duolingo'nun alışkanlık döngüsü + Brilliant'ın interaktivitesi + Linear/Stripe'ın premium netliği + Khan'ın etiği — hepsi **MEB sınav gerçekliği, grounded AI ve offline-first** çekirdeği etrafında. Kopyalanan hiçbir görsel/varlık yok; alınan yalnızca _ilke_.

---

## Bölüm 7 — Uygulama Planı (Phased Implementation)

Fazlar bağımlılık ve değer sırasına göre. Karmaşıklık: **S** (küçük), **M** (orta), **L** (büyük). Öncelik: **P0** (V1.0 için zorunlu), **P1** (V1.0'a değer katar, kısmen ertelenebilir), **P2** (V1.0 sonrası).

### Faz V1 — Görsel Sistem Temeli (Design System Foundation)

- **Kapsam:** İllüstrasyon dili (grid, stroke, renk, köşe token'ları); hareket sistemi token'ları (Bölüm 4.5); mevcut 12 SVG'nin sisteme migrate edilmesi; alt-text/erişilebilirlik disiplini standardı; ikon seti kararı.
- **Karmaşıklık:** M · **Öncelik:** P0 · **Bağımlılık:** yok (tüm diğer fazların temeli).
- **Teslimatlar:** design tokens (CSS değişkenleri), `components/LessonFigure.tsx` refactor, hareket token'ları, erişilebilirlik kontrol listesi, ikon seti seçimi.

### Faz V2 — Trafik İşaretleri Sistemi (Traffic Signs)

- **Kapsam:** Parametrik SVG kabuk + glyph mimarisi (`components/signs/`); P0 kategoriler (tehlike, yasak, DUR/Yol Ver, yatay işaretlemeler); işaret galerisi + flip-kart + "işaret avı" quiz entegrasyonu; soru bankasına `figureRef` alanı (geriye-uyumlu).
- **Karmaşıklık:** L · **Öncelik:** P0 · **Bağımlılık:** V1.
- **Teslimatlar:** 5 kabuk bileşeni, P0 glyph seti, `/dersler/trafik-isaretleri` galeri, işaret-quiz akışı, şema alanı.

### Faz V3 — Araç Görselleri (Vehicle Visuals)

- **Kapsam:** Şematik SVG'ler (pedal, vites, ayna, park referans, gabari — Bölüm 2.2 #12,13,16,19,20); orijinal fotoğraf çekim seansı (Clio 4/5) + SVG etiket katmanları; adım illüstrasyonları (koltuk/dış tur); `next/image` + CMS medya boru hattı entegrasyonu.
- **Karmaşıklık:** L · **Öncelik:** P0 (şematikler) / P1 (fotoğraflar) · **Bağımlılık:** V1; fotoğraflar bir çekim seansına bağlı (dış bağımlılık).
- **Teslimatlar:** vehicle-intro şematik SVG seti, etiketli fotoğraf varlıkları, illüstrasyon adım kartları.

### Faz V4 — Uygulama İçi Hareket & Etkileşim (In-App Motion)

- **Kapsam:** İnteraktif diyagramlar (junction/overtaking/pedestrian/roundabout tıklanabilir); animasyonlu park/hill-start demoları (CSS/SVG öncelikli); interaktif gösterge paneli; ilerleme/deneme-sonucu görselleştirmeleri; mikro-etkileşimler; premium empty/loading durumları; reduced-motion uyumu.
- **Karmaşıklık:** L · **Öncelik:** P1 · **Bağımlılık:** V1 (hareket token), V2/V3 (görseller).
- **Teslimatlar:** interaktif diyagram bileşenleri, park/hill-start demo, dashboard etkileşimi, sonuç/ilerleme grafikleri (`dataviz` uyumlu), empty/loading state kütüphanesi.

### Faz V5 — Premium Vitrin & İkincil İçerik (Landing + Polish)

- **Kapsam:** Bölüm 3 vitrin yeniden tasarımı (hero animasyon, özellik vitrinleri, dürüst metrikler, koşullu testimonial, interaktif demo); P1 işaret kategorileri (bilgi/otoyol/geçici); başarı kutlamaları; son cila.
- **Karmaşıklık:** M · **Öncelik:** P1 (vitrin) / P2 (ikincil kategoriler) · **Bağımlılık:** V1–V4 (vitrin gerçek UI'yi sergiler).
- **Teslimatlar:** yeni `(marketing)/page.tsx` bölümleri, hero illüstrasyon/animasyon, vitrin interaktif demo, kalan işaret kategorileri.

### 7.1 Öncelik matrisi

| Faz                     | Kapsam özeti                     | Karmaşıklık | Öncelik | Bağımlılık | V1.0 zorunlu mu?                                    |
| ----------------------- | -------------------------------- | ----------- | ------- | ---------- | --------------------------------------------------- |
| V1 Görsel sistem temeli | Token, hareket, 12 SVG migrasyon | M           | **P0**  | —          | **Evet**                                            |
| V2 Trafik işaretleri    | Parametrik SVG, galeri, quiz     | L           | **P0**  | V1         | **Evet** (P0 kategoriler)                           |
| V3 Araç görselleri      | Şematik SVG + fotoğraf           | L           | P0/P1   | V1, çekim  | **Evet** (şematikler); fotoğraf P1                  |
| V4 Uygulama içi hareket | İnteraktif diyagram + animasyon  | L           | P1      | V1–V3      | Kısmen (temel etkileşim evet, ağır animasyon sonra) |
| V5 Vitrin & cila        | Premium landing                  | M           | P1/P2   | V1–V4      | Vitrin evet; ikincil kategoriler hayır              |

### 7.2 Yürütme sırası (execution order)

`V1 → V2 → V3 (şematik) → V4 (temel etkileşim) → V5 (vitrin)`; V3 fotoğrafları ve V5 ikincil kategoriler paralel/sonraya kayabilir (dış bağımlılık: çekim seansı).

### 7.3 V1.0 için MUTLAKA gerekenler (must-ship) vs. sonraya

**V1.0 öncesi zorunlu (must-ship):**

- V1 görsel sistem temeli (tüm görsellerin tek elden olması için ön koşul).
- V2 P0 işaret kategorileri (tehlike, yasak, DUR/Yol Ver, yatay işaretleme) + galeri + quiz.
- V3 şematik araç SVG'leri (pedal, vites, ayna, park referans, gabari).
- V4'ten: reduced-motion uyumlu temel mikro-etkileşimler + premium empty/loading.
- V5'ten: yeniden tasarlanmış hero + dürüst metrik/güven bölümleri.
- Tüm zorunlu görsellerde erişilebilirlik (alt-text, tema, kontrast).

**V1.0 sonrasına bırakılabilir:**

- V3 orijinal fotoğraf seti (çekim seansına bağlı — arada illüstrasyon/şematik köprüler).
- V4 ağır Lottie/animasyonlu park & hill-start demoları (CSS fallback ile V1.0'da yeterli).
- V2 P1/P2 işaret kategorileri (bilgi/otoyol/geçici).
- V5 interaktif vitrin demo, testimonial (gerçek yorum toplanınca), başarı kutlama animasyonları.
- 3D görselleştirme (kapsam dışı, uzun vade).

---

## Kapanış İlkeleri (her fazda geçerli)

1. **Orijinal-önce, telif-güvenli, offline-dostu** — istisnasız.
2. **Erişilebilirlik pazarlık dışı** — alt-text, tema, kontrast, reduced-motion.
3. **Dürüstlük** — uydurma metrik/testimonial/başarı oranı yok; sınıflandırma rozetleri görsellere de uygulanır.
4. **Tek elden sistem** — her yeni görsel V1 tasarım diline uyar; el işi tutarsızlık birikmez.
5. **Performans korunur** — kritik yol bundle+offline; ağır varlık lazy; LCP/CSS bütçesi bozulmaz.
