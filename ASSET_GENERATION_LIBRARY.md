# Varlık Üretim Kütüphanesi

**Durum:** Faz 0'da **iskelet** oluşturuldu · **Faz 1'de doldurulacak.**

Bu belge, projede kalan **her yer tutucu görselin** kaydını ve onu üretmek için kullanılacak
**üretime hazır GPT Image promptunu** tutar. Amaç: görsel üretecek kişinin bu dosyadan başka
hiçbir şeye ihtiyaç duymaması.

---

## 1. Kayıt şeması — her giriş bunları taşımak ZORUNDA

Faz 1'de bulunan her yer tutucu aşağıdaki on bir alanla kaydedilir. Eksik alanlı kayıt kabul
edilmez.

| Alan                     | Açıklama                                                                                 |
| ------------------------ | ---------------------------------------------------------------------------------------- |
| **Ekran**                | Kullanıcının gördüğü ekran adı (ör. "Onboarding 1. adım")                                |
| **Widget**               | `dosya.dart:satır` — görselin çizildiği yer                                              |
| **Mevcut varlık**        | Şu an ne kullanılıyor (dosya yolu veya "yordamsal çizim / yok")                          |
| **Değiştirme gerekçesi** | Neden yetersiz — somut olarak (düşük çözünürlük, marka dışı, jenerik…)                   |
| **GPT Image promptu**    | Kopyala-yapıştır çalışacak, tam prompt (§3 standardına uygun)                            |
| **Görsel stil**          | Hangi stil ailesine ait (§2)                                                             |
| **Dosya adı**            | `snake_case`, uzantısız                                                                  |
| **Uzantı**               | `.webp` (varsayılan) · `.svg` (vektör gerekiyorsa) · `.png` (şeffaflık + WebP olmuyorsa) |
| **Hedef çözünürlük**     | Piksel (3× cihaz için hesaplanmış)                                                       |
| **Kayıt dizini**         | Tam yol (`apps/mobile/assets/...` veya `apps/web/public/assets/...`)                     |
| **Kullanım yeri**        | Nerede, hangi boyutta gösterilecek                                                       |

### Çözünürlük kuralı

Mobil hedef cihaz 1080×2340 (3× yoğunluk). Gösterim genişliği `W` dp ise üretim genişliği
**`W × 3`** olmalıdır; üstüne çıkmak boşuna bayt, altına inmek bulanıklıktır.

| Kullanım                       | Gösterim (dp) | Üretim (px)   |
| ------------------------------ | ------------- | ------------- |
| Tam genişlik hero/illüstrasyon | 360           | **1080**      |
| Yarım genişlik kart görseli    | 170           | 512           |
| Liste öğesi küçük görsel       | 80            | 240           |
| Simge/rozet                    | 40            | 120           |
| Onboarding ana illüstrasyon    | 360 × ~600    | **1080×1800** |

## 2. Stil aileleri — proje zaten bunları kullanıyor

Yeni bir görsel dil **getirilmez**. Üretilen her varlık aşağıdaki ailelerden birine ait olmalıdır.

| Aile                       | Nerede kullanılır                | Nitelikler                                                     |
| -------------------------- | -------------------------------- | -------------------------------------------------------------- |
| **Maskot (baykuş)**        | Onboarding, boş durumlar, AI Koç | 3B render, teal/turkuaz tüy, gözlük, sıcak ve öğretici         |
| **Şematik animasyon**      | Manevra videoları, diyagramlar   | Kuş bakışı, düz renk, tasarım token renkleri, etiketli adımlar |
| **Gerçek fotoğraf**        | Araç tekniği, kabin kumandaları  | Gerçek parça fotoğrafı, nötr arka plan, markasız               |
| **Resmî vektör**           | Trafik işaretleri, ikaz ışıkları | Mevzuata birebir uygun; **stil serbestisi YOK**                |
| **Editoryal illüstrasyon** | Ders hero'ları, premium yüzeyler | Düz/yarı-düz, marka paleti, insan figürü soyut                 |

### Marka paleti (promptlarda kullanılacak)

```
primary  #14b8a6 (teal)      primary-700 #0b7268
accent   #F59E0B (amber)     danger #ef4444    success #22c55e
koyu zemin #050b16 / #0b1523        açık zemin #f4f6fb / #ffffff
```

## 3. Prompt yazım standardı

Bir prompt "üretime hazır" sayılabilmesi için şunları **açıkça** içermelidir:

1. **Konu** — ne çizilecek, tek cümle
2. **Stil ailesi** (§2) ve somut stil sözcükleri
3. **Kompozisyon** — çerçeveleme, bakış açısı, öğelerin yerleşimi
4. **Renk** — marka paletinden **hex** değerlerle
5. **Arka plan** — şeffaf mı, düz mü, hangi renk
6. **En-boy oranı ve çözünürlük**
7. **Negatifler** — istenmeyenler (metin, filigran, marka, insan yüzü ayrıntısı …)

### Şablon

```
[KONU]. [STİL AİLESİ] tarzında: [stil sözcükleri].
Kompozisyon: [çerçeveleme ve yerleşim].
Renk paleti: [hex değerler].
Arka plan: [şeffaf / düz #hex].
En-boy: [oran] · Çözünürlük: [WxH].
Negatif: metin yok, filigran yok, marka/logo yok, [duruma özel].
```

### Örnek — dolu bir prompt nasıl görünür

> **Boş durum: henüz arkadaş yok**
>
> Teal renkli bilge bir baykuş maskotu, elinde boş bir arkadaş listesi tutuyor ve izleyiciye
> cesaret verici biçimde bakıyor. Maskot ailesi tarzında: yumuşak 3B render, hafif alt aydınlatma,
> yuvarlak hatlar, gözlüklü, sıcak ve öğretici ifade.
> Kompozisyon: ortalanmış, tam gövde, alt tarafta hafif gölge, çevresinde nefes alacak boşluk.
> Renk paleti: tüyler #14b8a6 ve #0b7268, gaga/ayak #F59E0B, vurgu #22c55e.
> Arka plan: şeffaf.
> En-boy: 1:1 · Çözünürlük: 512×512.
> Negatif: metin yok, filigran yok, marka/logo yok, gerçekçi kuş anatomisi yok, karanlık/kasvetli
> ton yok.

## 4. Faz 1'de taranacak alanlar (kontrol listesi)

Faz 1, projenin **tamamını** tarar. En az şu kategoriler tek tek gözden geçirilir:

- [ ] Yordamsal/geçici SVG çizimler
- [ ] Üretilmiş (procedural) illüstrasyonlar
- [ ] Yer tutucu fotoğraflar
- [ ] Eksik illüstrasyonlar (olması gereken ama olmayan)
- [ ] **Boş durum** görselleri
- [ ] Geçici ikonlar
- [ ] Geçici diyagramlar
- [ ] Düz (flat) vektörler — marka dışı kalmışlar
- [ ] Sahte/mock varlıklar
- [ ] Eski onboarding görselleri
- [ ] Eski giriş ekranı görselleri
- [ ] Topluluk yer tutucuları
- [ ] Mekanik yer tutucuları
- [ ] Araç yer tutucuları
- [ ] İkaz ışığı yer tutucuları
- [ ] Gösterge paneli yer tutucuları
- [ ] Ders yer tutucuları
- [ ] Sosyal yer tutucuları
- [ ] Video yer tutucuları

### Tarama yöntemi (Faz 1'de uygulanacak)

1. `apps/mobile/assets` ve `apps/web/public/assets` **tam envanteri** çıkarılır.
2. Her varlık **kodda nerede kullanılıyor** eşlenir; kullanılmayanlar işaretlenir.
3. Kodda **varlık beklenip bulunmayan** yerler taranır (yordamsal çizim, `Icon` ile idare edilen
   yerler, boş `Container` ile geçilen görsel alanlar).
4. Her ekran cihazda açılıp **gözle** kontrol edilir — envanterin göremediği "jenerik duruyor"
   durumları ancak böyle çıkar.
5. Bulunan her şey §1 şemasıyla bu dosyaya yazılır.

## 5. Envanter — Faz 1'de doldurulacak

> Aşağıdaki bölümler Faz 1'de gerçek bulgularla doldurulacaktır. **Uydurma kayıt yazılmaz**;
> her giriş gerçek bir dosyaya ve gerçek bir ekrana bağlıdır.

### 5.1 Onboarding

_(Faz 1)_

### 5.2 Giriş / kimlik

_(Faz 1)_

### 5.3 Boş durumlar

_(Faz 1)_

### 5.4 Topluluk

_(Faz 1)_

### 5.5 Ders ve öğrenme

_(Faz 1)_

### 5.6 Araç tekniği / kabin kumandaları

_(Faz 1)_

### 5.7 İkaz ışıkları / gösterge paneli

_(Faz 1)_

### 5.8 Video

_(Faz 1)_

### 5.9 Diğer

_(Faz 1)_

## 6. Üretim sonrası akış

Görsel üretildikten sonra:

1. Hedef çözünürlüğe getir, **WebP**'ye çevir (şeffaflık korunacaksa `-lossless` veya yüksek
   kalite; fotoğrafta kayıplı yeterli).
2. `ASSET_GENERATION_LIBRARY.md`'deki **kayıt dizini ve dosya adına** birebir kaydet.
3. `apps/mobile/pubspec.yaml` varlık listesine ekle (mobil tarafıysa).
4. Kodda yer tutucuyu değiştir.
5. **Cihazda** doğrula — ekran görüntüsü al.
6. Boyut bütçesini kontrol et (mobil varlıklarda tekil dosya için makul üst sınır ~150 KB).
