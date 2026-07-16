# PROGRAM 2 ROADMAP — Premium Görsel Deneyim & İçerik Evrimi

_Ehliyet Akademi · Program 2 uygulama yol haritası · 2026-07-16_

> **Konum:** `ROADMAP.md` ana mühendislik yol haritası olmaya devam eder; bu belge Program 2'nin
> uygulama planıdır. Sprint 1–6 + Program 1 tamamlandı; mühendislik ve ürün temeli hazırdır.
> **Mimari yeniden tasarlanmaz, mevcut sistemler değiştirilmez — üzerine inşa edilir.**

## Yönlendirici ilkeler

1. **Premium eğitim deneyimi**: basit el çizimi YOK (bilinçli eğitsel diyagramlar hariç — mevcut
   SVG kütüphanesi diyagram katmanı olarak kalır). Hedef: gerçek fotoğraf kalitesinde görseller.
2. **Görsel kaynak önceliği**: (1) açık lisanslı / uygun lisanslı **gerçek fotoğraf** →
   (2) `OPENAI_API_KEY` ile **profesyonel AI-üretimi fotogerçekçi eğitim görseli**. Her varlık
   lisans + kaynak metaverisiyle kayıt altına alınır; marka/logo/plaka içermez.
3. **Telif ve özgünlük**: telifli eğitim materyali asla kopyalanmaz; tüm sorular/dersler özgün.
4. **Disiplin**: her faz → uygulama + test + erişilebilirlik + performans + CI yeşil +
   production deploy + gerçek tarayıcı doğrulaması + dokümantasyon + faz raporu.
5. **Dürüstlük**: bitmemiş iş "tamamlandı" olarak işaretlenmez; sayılar gerçek tutulur.

## Faz bağımlılık grafiği

```
Faz 1 (Varlık kütüphanesi + pipeline)
 ├─→ Faz 2 (Etkileşimli medya — Faz 1 görsellerini kullanır)
 ├─→ Faz 6 (İşaret genişletme — Faz 1 pipeline'ını kullanır)
 └─→ Faz 7 (Araç bilgisi 70+ — Faz 1 pipeline'ını kullanır)
Faz 3 (Hareket/animasyon) — bağımsız; Faz 2 ile sinerjik
Faz 4 (Video mimarisi) — bağımsız; Faz 5 transkript/özet ile sinerjik
Faz 5 (AI görsel öğrenme) — Faz 1–2 varlıklarına dayanır
Faz 8 (Harita & senaryo) — Faz 3 animasyonlarıyla sinerjik
Faz 9 (Büyük içerik genişletme 1500+) — sürekli; Faz 6–7 içerikleriyle beslenir
```

---

## FAZ 1 — Premium Görsel Varlık Kütüphanesi (EN YÜKSEK ÖNCELİK)

### Hedefler

- Platformun görsel omurgasını "hafif diyagram"dan "premium fotogerçekçi eğitim görseli"ne taşımak.
- Tekrarlanabilir, metaverili, lisans-izli bir **varlık üretim hattı** (pipeline) kurmak.
- Araç/gösterge/kumanda görsellerinin ilk büyük dalgasını üretip derslere ve `/arac`a entegre etmek.

### Kapsam

- **Varlık envanteri araştırması**: trafik işaretleri, gösterge ikaz lambaları, gösterge düğmeleri,
  direksiyon kumandaları, vites (manuel/otomatik), pedallar, ayna ayarı, koltuk kumandaları,
  emniyet kemeri, farlar, sis farları, sinyaller, silecek kumandası, motor bölmesi, akü, yağ
  çubuğu, fren hidroliği, soğutma suyu, sigorta kutusu, kriko, stepne, bagaj, muayene noktaları,
  park referans noktaları, lastikler, bijonlar, acil durum ekipmanı (üçgen/yelek/ilk yardım seti).
- **Kaynak stratejisi (varlık başına)**: önce açık lisanslı gerçek fotoğraf (Wikimedia Commons /
  kamu malı vb. — lisans doğrulanır, atıf kaydedilir); bulunamaz/uygunsuzsa `OPENAI_API_KEY` ile
  fotogerçekçi üretim (markasız, plakasız, metin içermeyen, nötr stüdyo/eğitim stili).
- **Pipeline**: `scripts/assets/` — üretim betiği (prompt kataloğu → OpenAI Images API →
  WebP çıktı), optimizasyon (boyut varyantları), manifest üretimi.
- **Manifest + bileşen**: `apps/web/content/asset-manifest.ts` (id/başlık/alt/lisans/kaynak/etiketler/
  boyutlar) + `components/ui/AssetImage.tsx` (next/image, lazy, responsive, erişilebilir figür).
- **Entegrasyon**: `/arac` sayfası foto + diyagram birlikte; dersler ilgili görselleri gösterir.
- CMS medya kütüphanesiyle uyum: manifest kimlikleri CMS `media_assets`e aktarılabilir yapıda.

### Teslimatlar

- `scripts/assets/generate.mjs` + `scripts/assets/catalog.mjs` (prompt/etiket kataloğu)
- `apps/web/public/assets/vehicle/*.webp` (ilk dalga: ≥24 premium görsel)
- `apps/web/content/asset-manifest.ts` + doğrulama testleri
- `components/ui/AssetImage.tsx` + `/arac` ve ders entegrasyonu
- `PROGRAM_2_PHASE_1_REPORT.md`

### Bağımlılıklar

- `OPENAI_API_KEY` (.env — mevcut). Açık lisans kaynakları için ağ erişimi.

### Tahmini karmaşıklık

**Yüksek** (pipeline + üretim + entegrasyon + kalite kontrolü).

### Doğrulama stratejisi

- Birim: manifest şema doğrulaması (id benzersiz, alt/lisans zorunlu, dosya mevcut).
- e2e: `/arac` gerçek foto render; ders sayfasında görsel; lazy-loading çalışır.
- Erişilebilirlik: her görselde anlamlı Türkçe `alt`; figür/caption yapısı.
- Performans: WebP, responsive `sizes`, lazy; sayfa ağırlığı bütçesi (ilk yük < 300KB görsel).
- Görsel kalite denetimi: her üretilen görsel gerçek tarayıcıda insan-kalite kontrolünden geçer;
  bozuk/yanıltıcı üretimler reddedilir ve yeniden üretilir.

### CI gereksinimleri

- Mevcut CI (Lint·Typecheck·Test·Build + E2E + gitleaks + CodeQL) yeşil kalır.
- Manifest testleri CI'da koşar; büyük binariler için depo boyutu izlenir (git LFS gerekmez —
  WebP varlıklar küçük tutulur).

### Production doğrulama listesi

- [ ] `/arac` premium fotoğraflarla render (0 konsol hatası)
- [ ] En az bir ders sayfası premium görsel gösterir
- [ ] Görseller WebP + lazy + responsive servis edilir
- [ ] Lighthouse görsel ağırlık regresyonu yok (manuel kontrol)
- [ ] STATUS/CHANGELOG/MEMORY + faz raporu güncel

---

## FAZ 2 — Etkileşimli Medya

### Hedefler

- Statik görseli aktif öğrenme yüzeyine çevirmek: keşfet, tıkla, karşılaştır, yakınlaş.

### Kapsam

- **Görsel hotspot** bileşeni (foto üzerinde işaretli noktalar → açıklama balonu; klavye erişilebilir).
- **Etkileşimli diyagram** (mevcut SVG diyagramlarla hotspot birleşimi).
- **Yakınlaştırılabilir muayene görselleri** (zoom/pan, dokunmatik destekli).
- **Önce/sonra karşılaştırma** (slider — doğru/yanlış ayna ayarı, doğru/yanlış lastik vb.).
- **Adım adım muayene akışı** (fotoğraflı sıralı rehber; POWDERY/kontrol listesi entegrasyonu).
- 360° görüntüleyici: fizibilite araştırması; pratikse basit sprite-sequence yaklaşımı, değilse ertele
  (raporda gerekçelendir).

### Teslimatlar

- `components/media/{Hotspots,ZoomImage,CompareSlider,StepFlow}.tsx` + CSS
- En az 2 dersin ve `/arac` sayfasının etkileşimli medya ile zenginleştirilmesi
- `PROGRAM_2_PHASE_2_REPORT.md`

### Bağımlılıklar: Faz 1 varlıkları.

### Tahmini karmaşıklık: **Orta-Yüksek** (erişilebilir etkileşim tasarımı).

### Doğrulama stratejisi

- Birim: hotspot verisi doğrulama; e2e: hotspot aç/kapa, slider sürükleme, zoom.
- Erişilebilirlik: klavye ile tüm hotspotlar gezilebilir; ARIA doğru; reduced-motion.

### CI gereksinimleri: mevcut boru hattı + yeni e2e'ler yeşil.

### Production doğrulama listesi

- [ ] Hotspot/zoom/karşılaştırma canlıda çalışır (masaüstü + mobil görünüm)
- [ ] Klavye navigasyonu doğrulandı · [ ] 0 konsol hatası · [ ] dokümanlar güncel

---

## FAZ 3 — Hareket & Animasyon

### Hedefler

- Hareket sistemini "beliriş"ten "anlatan animasyon"a yükseltmek (park, muayene, trafik senaryoları).

### Kapsam

- **Teknoloji değerlendirmesi** (kısa ADR): Lottie vs Rive vs Motion (motion.dev) vs animasyonlu SVG/CSS.
  Karar ölçütleri: bundle boyutu, offline/PWA uyumu, erişilebilirlik, üretim maliyeti, CSP.
- **Animasyonlu park gösterimleri**: paralel park + dik park adım animasyonu (yol üstü görünüm).
- **Animasyonlu araç muayenesi**: sürüş öncesi kontrol sekansı.
- **Animasyonlu trafik senaryoları**: kavşak önceliği, sağdan gelen, ambulansa yol açma (2–3 senaryo).
- Tümü `prefers-reduced-motion` güvenli; oynat/duraklat kontrolü.

### Teslimatlar

- ADR-012 (hareket teknolojisi kararı) · animasyon bileşenleri + en az 4 eğitsel animasyon
- Ders entegrasyonu (park-manevra, kavsak-uygulama, arac-hazirlik) · `PROGRAM_2_PHASE_3_REPORT.md`

### Bağımlılıklar: yok (Faz 2 ile paralel yürüyebilir).

### Tahmini karmaşıklık: **Yüksek** (animasyon içerik üretimi).

### Doğrulama: e2e oynat/duraklat + reduced-motion; bundle boyut bütçesi (+<60KB gz).

### CI: mevcut + animasyon smoke e2e.

### Production listesi

- [ ] Animasyonlar canlı, akıcı, duraklatılabilir · [ ] reduced-motion'da statik alternatif
- [ ] 0 konsol hatası · [ ] bundle bütçesi tutuldu · [ ] dokümanlar güncel

---

## FAZ 4 — Video Öğrenme (mimari + temel)

### Hedefler

- Eksiksiz video öğrenme mimarisini tasarlamak ve altyapıyı kurmak (oynatıcı, bölümler,
  transkript, yer imi, AI özet). Gerçek çekim videolar dış bağımlılıktır; mimari + deneyim hazır olur.

### Kapsam

- ADR-013: video barındırma stratejisi (self-host/mux/YouTube-nocookie vb. — gizlilik + maliyet).
- `VideoPlayer` bileşeni: bölüm işaretleri, hız, transkript paneli (senkron vurgulu), yer imleri
  (localStorage + sync), klavye kısayolları, altyazı (WebVTT).
- Video içerik şeması (content-schema genişletmesi, geriye dönük uyumlu): id/başlık/bölümler/
  transkript/ilgili ders/quiz bağları.
- AI-destekli özet: transkriptten grounded özet + "videodan sorular" (mevcut AI hattıyla).
- Placeholder içerik stratejisi: gerçek çekim yoksa animasyonlu demo (Faz 3) videoya eşdeğer akışla sunulur;
  sahte "çekilmiş gibi" video YAYINLANMAZ (dürüstlük).

### Teslimatlar

- ADR-013 + `components/video/VideoPlayer.tsx` + şema + örnek 1–2 video sayfası (lisanslı/animasyon tabanlı)
- `PROGRAM_2_PHASE_4_REPORT.md`

### Bağımlılıklar: gerçek video çekimi (dış bağımlılık — kullanıcı kararı); Faz 3 animasyonları alternatif kaynak.

### Karmaşıklık: **Orta** (mimari) + dış bağımlılık (içerik).

### Doğrulama: birim (şema/bölüm mantığı) + e2e (oynatıcı, transkript senkronu, yer imi kalıcılığı).

### CI: mevcut + video e2e.

### Production listesi

- [ ] Oynatıcı canlı ve erişilebilir (klavye + altyazı) · [ ] transkript/bölüm/yer imi çalışır
- [ ] AI özet grounded · [ ] 0 konsol hatası · [ ] dokümanlar güncel

---

## FAZ 5 — AI Görsel Öğrenme

### Hedefler

- AI koçu görsel-farkında hale getirmek: görselle açıklama, görsel-tabanlı kişisel tekrar.

### Kapsam

- **Görsel açıklamalar**: AI yanıtlarına ilgili varlık/işaret/diyagram kartı iliştirme
  (grounded: yalnız kendi manifest/işaret kataloğumuzdan).
- **Görsel-tabanlı sorular**: "bu işaret/gösterge ne?" modunda quiz (Faz 1 + işaret sistemi).
- **Kişiselleştirilmiş görsel tekrar**: yanlış yapılan işaret/bileşen görselleriyle SRS destesi.
- **Bağlam-farkında öğrenme**: ders bağlamına göre AI önerilen görseller.
- **Gelecek vizyon-model mimarisi** (tasarım): kamera-destekli öğrenme (ör. kullanıcı gösterge
  fotoğrafı yükler → AI tanır) — **yalnız mimari/ADR**, gizlilik-öncelikli (görüntü cihazda kalır
  varsayılanı, açık rıza, saklama yok); uygulama kullanıcı onayına bırakılır.

### Teslimatlar

- Görsel quiz modu + AI yanıt-görsel iliştirme + görsel SRS · ADR-014 (vizyon mimarisi, gizlilik)
- `PROGRAM_2_PHASE_5_REPORT.md`

### Bağımlılıklar: Faz 1 manifest; mevcut grounded AI hattı.

### Karmaşıklık: **Orta-Yüksek**.

### Doğrulama: birim (görsel eşleme grounded — halüsinasyon kapısı görsel kimliklerini de kapsar);

e2e (görsel quiz akışı, AI yanıtında görsel kart).

### CI: mevcut + yeni testler.

### Production listesi

- [ ] Görsel quiz canlı · [ ] AI görsel kartları yalnız kendi kataloğundan · [ ] gizlilik metinleri güncel
- [ ] 0 konsol hatası · [ ] dokümanlar güncel

---

## FAZ 6 — Trafik İşareti Genişletmesi

### Hedefler

- İşaret sistemini eksiksiz Türk B-ehliyet ekosistemine genişletmek (~120+ işaret).

### Kapsam

- Envanter: tehlike uyarı (T grubu), tanzim/yasak (TT), bilgi (B), duraklama-park, otoyol,
  geçici/yapım, yatay işaretleme (yol çizgileri) — resmî sınıflandırmayla hizalı, özgün sunum.
- **Gerçek görsel**: işaret başına otantik görünüm — mevcut parametrik SVG motoru genişletilir
  (yeni glyph'ler); gerekçeli durumlarda açık lisanslı resmî çizimler (lisans kaydıyla).
- Her işaret: eğitsel açıklama + hafıza tekniği + sınav önemi + ilgili ders + ilgili quiz +
  deneme sınavı bağlantısı + etkileşimli tekrar modu (flip + görsel quiz [Faz 5] + SRS).
- Galeri UX: alt-kategori süzme, "karıştırılanlar" karşılaştırmaları, işaret detay sayfası.

### Teslimatlar

- `content/signs.ts` ≥120 işaret + yeni glyph'ler + detay/karşılaştırma UX + işaret-quiz soruları
- `PROGRAM_2_PHASE_6_REPORT.md`

### Bağımlılıklar: Faz 1 pipeline (varlık disiplini), Faz 5 görsel quiz (tekrar modu için).

### Karmaşıklık: **Yüksek** (içerik hacmi + doğruluk).

### Doğrulama: birim (katalog bütünlüğü, kategori kapsamı, quiz bağları çözülür);

e2e (galeri süzme/arama/detay); içerik doğruluk denetimi (resmî sınıflandırmayla çapraz kontrol).

### CI: mevcut + genişletilmiş katalog testleri.

### Production listesi

- [ ] ≥120 işaret canlı · [ ] detay sayfaları + quiz bağları çalışır · [ ] 0 konsol hatası · [ ] dokümanlar güncel

---

## FAZ 7 — Araç Bilgisi Genişletmesi

### Hedefler

- Araç kütüphanesini **70+ bileşene** çıkarmak; her bileşen premium görsel + muayene adımlarıyla.

### Kapsam

- Envanter genişletmesi: mevcut 21 → 70+ (ör. far türleri ayrı ayrı, silecek/su, kemer/gergi,
  airbag, ISOFIX, klima/kalorifer, buğu çözme, cam/ayna kumandaları, yakıt kapağı, katalitik,
  egzoz, süspansiyon, amortisör, rot-balans, fren balatası/diski, debriyaj seti, triger,
  alternatör, marş motoru, radyatör fanı, polen filtresi, hava/yağ/yakıt filtreleri, buji,
  silecek lastiği, anahtar/immobilizer, OBD portu, reflektör, çekme halatı, takoz, zincir...).
- Her bileşen: **gerçek görsel** (Faz 1 pipeline) + açıklama + muayene adımları + sık hatalar +
  sınav önemi + ilgili ders + ilgili quiz soruları.
- `/arac` UX: alt-sistem navigasyonu, bileşen detay görünümü, arama.

### Teslimatlar

- `content/vehicle.ts` ≥70 bileşen + görseller + detay UX + bileşen-quiz soruları
- `PROGRAM_2_PHASE_7_REPORT.md`

### Bağımlılıklar: Faz 1 pipeline.

### Karmaşıklık: **Yüksek** (görsel hacim + teknik doğruluk).

### Doğrulama: birim (envanter bütünlüğü, görsel-manifest eşleşmesi, quiz bağları);

e2e (detay + arama); teknik doğruluk denetimi.

### CI: mevcut + genişletilmiş testler.

### Production listesi

- [ ] ≥70 bileşen premium görselle canlı · [ ] muayene adımları + quiz bağları çalışır
- [ ] 0 konsol hatası · [ ] dokümanlar güncel

---

## FAZ 8 — Harita & Senaryo Öğrenme

### Hedefler

- Konum-tabanlı/mekânsal öğrenmeyi araştırıp pratik bir senaryo katmanı kurmak.

### Kapsam

- **Araştırma** (kısa rapor): eğitsel harita seçenekleri (statik özgün SVG yol düzenleri vs
  MapLibre/OSM vs Street View — maliyet/lisans/gizlilik; Street View = gelecek entegrasyon ADR'ü).
- **Sürüş senaryoları**: kavşak düzenleri, dönel kavşak, şerit seçimi, park alanı düzenleri —
  özgün kuş-bakışı SVG sahneler + adım adım karar noktaları (Faz 3 animasyonlarıyla).
- **Senaryo motoru**: karar → sonuç → açıklama akışı (quiz benzeri, puanlı).
- Sınav güzergâhı kavramı: genel eğitsel senaryolar (gerçek kişisel veri/rota YOK).

### Teslimatlar

- Senaryo motoru + ≥6 etkileşimli senaryo + araştırma raporu/ADR-015 (Street View gelecek yolu)
- `PROGRAM_2_PHASE_8_REPORT.md`

### Bağımlılıklar: Faz 3 (animasyon) sinerjisi; bağımsız başlayabilir.

### Karmaşıklık: **Orta-Yüksek**.

### Doğrulama: birim (senaryo grafı tutarlı, çıkmaz yok); e2e (senaryo tamamlama akışı).

### CI: mevcut + senaryo testleri.

### Production listesi

- [ ] Senaryolar canlı ve tamamlanabilir · [ ] açıklamalar grounded · [ ] 0 konsol hatası · [ ] dokümanlar güncel

---

## FAZ 9 — Büyük İçerik Genişletmesi (1500+ soru)

### Hedefler

- **1500+ ÖZGÜN soru** (mevcut 534 → 1500+); tüm dersleri derinleştirmek; pratik senaryoları artırmak;
  AI açıklamalarını iyileştirmek.

### Kapsam

- Soru üretim dalgaları (konu başına dengeli; her soru tam metaverili, `review:'draft'`,
  answerIndex dengeli, kimlik çakışmasız). Dalga başına kalite denetimi (örneklem insan/AI çapraz kontrol +
  otomatik tekrar/benzerlik taraması).
- Ders derinleştirme: her derse yeni bölümler/görseller/etkileşimli bloklar (Faz 1–3 varlıklarıyla).
- Pratik senaryo artışı (Faz 8 motoruna içerik).
- AI açıklama iyileştirme: whyWrong kalite geçişi, zayıf-konu odaklı açıklama zenginleştirme.
- Performans: soru bankası büyüyünce yükleme stratejisi (konu-bazlı bölme/lazy import) — mimariyi
  değiştirmeden modül bölümleme.

### Teslimatlar

- ≥1500 soru + genişletilmiş dersler + senaryo içerikleri + `PROGRAM_2_PHASE_9_REPORT.md`

### Bağımlılıklar: Faz 6–7 (işaret/araç soruları oradan beslenir); sürekli yürür.

### Karmaşıklık: **Çok Yüksek** (hacim × kalite).

### Doğrulama: banka kapı testleri kademeli yükseltilir (≥800 → ≥1200 → ≥1500);

benzerlik/tekrar taraması; e-Sınav dağılım oranları korunur; performans bütçesi (bank yükleme).

### CI: mevcut + yükseltilmiş kapılar; build süresi izlenir.

### Production listesi

- [ ] 1500+ soru canlı · [ ] deneme/çalışma akışları hızlı (performans bütçesi) · [ ] 0 konsol hatası
- [ ] içerik `review` yönetişimi işliyor · [ ] dokümanlar güncel

---

## Program geneli çalışma disiplini

- Her faz sonunda: testler → Playwright → deploy → **gerçek tarayıcı doğrulaması** → commit/push →
  CI yeşil → `STATUS.md` + `MEMORY.md` + `CHANGELOG.md` + `PROGRAM_2_PHASE_<n>_REPORT.md`.
- Sıralama: 1 → 2 → 3 → 5 → 6 → 7 → 8 → 9; Faz 4 mimarisi 3'ten sonra (video içerik dış bağımlılık).
  Dış bağımlılıkla tıkanan faz atlanıp not düşülür, akış devam eder.
- Sırlar (.env) asla commit edilmez; üretilen varlıklar marka/plaka/kişi içermez; lisans kaydı zorunlu.
