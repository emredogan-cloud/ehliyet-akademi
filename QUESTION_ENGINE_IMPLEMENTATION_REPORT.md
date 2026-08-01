# Ehliyet Akademi — Soru Motoru (QIP v3) · Uygulama Raporu

**Tarih:** 1 Ağustos 2026 · **Taban:** `d8f20e5` → `feature/qip-v3-question-engine`
**Yol haritası:** [`QUESTION_ENGINE_ROADMAP.md`](QUESTION_ENGINE_ROADMAP.md) · **Başka rapor yok.**

---

## 1. Durum

| Kapı              | Sonuç                                               |
| ----------------- | --------------------------------------------------- |
| `flutter analyze` | **0 sorun**                                         |
| Mobil test        | **974 ✓** (sprint başı 943 → **+31**)               |
| Web test          | **633 ✓**                                           |
| Paket testleri    | content-schema 18 ✓ · question-bank 10 ✓ · srs 12 ✓ |
| `pnpm typecheck`  | **✓**                                               |
| Cihaz             | Redmi Note 8 (Android 11) — görsel soru **çizildi** |

---

## 2. Sprintin tezi ve sonucu

> **Platform eksik değildi — bağlı değildi.**

`apps/web/lib/qip/` altında 19 olgun modül (dedup, kalite puanı, aileler, dinamik sınav,
uyarlanabilir seçim, tarihsel sınav, görsel üretim) vardı ve **hiçbiri kullanıcıya ulaşmıyordu.**

Zincir `/api/mobile/question-bank` içindeki `lean()` projeksiyonunda kopuyordu: `image` alanı
düşürülüyor, mobil `Question` modelinde de görsel alanı hiç yoktu.

**Sonuç: 1.562 sorunun %100'ü metindi. Kullanıcı tek bir görsel soru görmüyordu** — uygulamada
81 işaret vektörü + 60 ikaz ışığı + 101 mekanik görseli hazır dururken.

Bugün: **görsel sorular sınavın içinde, cihazda çiziliyor.**

---

## 3. Faz 0 — Denetim

Ölçülen başlangıç (hepsi depodan sayıldı):

| Ne                     | Sayı                                  |
| ---------------------- | ------------------------------------- |
| Toplam soru            | **1.562**                             |
| **Görselli soru**      | **0**                                 |
| Trafik işareti içeriği | 121 (86 resmî vektör + 35 parametrik) |
| İkaz ışığı (gömülü)    | 60                                    |
| Mekanik görsel         | 101                                   |
| Veritabanı tablosu     | 31                                    |

**Faz 6 (Tarihsel sınav) zaten yapılmıştı** — gerçek MEB oturum tarihi (olgu) → o tarihten
tohumlanmış özgün sınav → açık etiket. Yeniden yazılmadı; V2'ye bağlanarak iyileştirildi (§6).

---

## 4. Faz 1 — Soru modeli evrimi

`kind` (8 tür) + `media` (**çoklu görsel**, hotspot alanı ileriye hazır) + `generation` metaverisi.

### Geriye dönük uyumluluk — derleyiciyle doğrulandı

İlk denemede `kind: QuestionKind.default('text')` yazıldı ve `packages/question-bank`
**derlenmedi**: banka dosyaları diziyi `Question[]` (şemanın ÇIKTI tipi) ile bildiriyor ve Zod'da
`.default()` alanı çıktı tipinde **zorunlu** yapıyor → 1.562 sorunun tamamına elle `kind: 'text'`
yazmak gerekirdi.

**Çözüm:** `.optional()` + tek okuma noktası (`kindOf(q) => q.kind ?? 'text'`).
**Sonuç: 1.562 sorunun hiçbiri değişmedi.** "Geriye dönük uyumlu" iddiası burada bir niyet değil,
derleyicinin doğruladığı bir olgu.

### Şemaya konan kural

Görsel gerektiren bir tür (`sign`/`dashboard`/`mechanic`/`diagram`/`intersection`/`image`)
`media` olmadan tanımlanamaz. Soru metni "aşağıdaki levha" deyip ortada levha olmaması,
kullanıcı için **cevaplanamaz** bir sorudur. Kural şemada durur ki üreteç ya da yazar unutamasın
(Faz 11'deki "tam dört şık" kuralının aynı gerekçesi).

`alt` **zorunlu**: görsel çizilemezse soru o metinle yine cevaplanabilir olmalı; ekran okuyucu
kullanan için zaten tek kaynak odur.

---

## 5. Faz 2 + 4 — Görsel soru sistemi (uçtan uca)

### Üretim CİHAZDA, sunucuda değil

Üç katalog da pakete gömülü. Sunucuda üretilseydi:

- banka yükü ~%36 büyürdü (görselleri zaten cihazda),
- sunucu varlığın cihazda olup olmadığını **bilemezdi** → kırık görselli soru gönderebilirdi,
- ilk eşitleme öncesi tek bir görsel soru bile görünmezdi.

Cihazda üretmek üçünü birden çözer ve uygulamanın kurulu deseniyle aynıdır (SRS, `buildExam`,
koleksiyonlar zaten Dart'ta).

### `assetId` = KİMLİK, dosya yolu DEĞİL

Levhaların **35'inin resmî vektörü yok**; parametrik çizici onları kimlikten çiziyor. `assetId`
alanına yol yazılsaydı bu 35 levha için soru üretilemezdi. Çizim yolu türden seçiliyor:
`sign` → `TrafficSignView` · `dashboard`/`mechanic` → `Image.asset` · bulunamazsa `alt` metni.

### Üretilebilen özgün görsel soru

| Katalog        | Adet | Açı           | Soru |
| -------------- | ---- | ------------- | ---- |
| İkaz ışığı     | 60   | anlam + eylem | ~120 |
| Trafik işareti | 121  | anlam         | ~121 |
| Mekanik parça  | 101  | ad + görev    | ~202 |

**~443 özgün görsel soru** — varlık üretimi gerekmeden, hepsi bizim kataloglarımızdan.

> İkaz ışıkları **pakete gömülü** olduğu için içerik indirilmemişken bile üretiliyor. İşaret ve
> parça soruları içerik anlık görüntüsü indikten sonra geliyor — kademeli, hatasız.

### Çeldirici yetmezse soru ÜRETİLMEZ

Üç benzersiz çeldirici bulunamıyorsa üreteç o soruyu atlıyor. Üç şıklı soru üretmek, Faz 11'de
şemaya bağlanan kuralı **üreteç eliyle delmek** olurdu.

---

## 6. Faz 5 — Sınav Üreteci V2

**Önce:** her dersten payı kadar rastgele al, karıştır. Hepsi buydu.

**Şimdi:** `ExamConfig` ile yapılandırılabilir, altı kip:

| Kip          | Adet | Ayırt edici         |
| ------------ | ---- | ------------------- |
| `exam`       | 50   | MEB dağılımı, 45 dk |
| `historical` | 50   | tarihten tohum      |
| `practice`   | 20   | süre baskısı yok    |
| `quick`      | 10   | hızlı tur           |
| `random`     | 20   | dağılım gözetmez    |
| `adaptive`   | 20   | zayıf konu önceliği |

Yetenekler: zorluk dengeleme · ardışık aynı konu kırma · **aynı görseli iki kez kullanmama** ·
şık karıştırma + `answerIndex` yeniden eşleme · zayıf konu önceliği · **görsel soru enjeksiyonu**.

`ExamPlan` üretecin ne yaptığını **raporlar** (`bySubject`, `byDifficulty`, `visualCount`,
`repeatedImages`, `weakTopicCount`). "Zorluk dengeliyorum" iddiası ancak sayılabildiği için test
edilebiliyor.

### Test yazarken bulunan gerçek kusur

Zayıf konu önceliği **yalnız ders döngüsünde** uygulanıyordu. Uyarlanabilir kip `subjects: {}`
ile çağrıldığında (ders ayrımı yapmayan yol) zayıf konular hiç öne alınmıyordu — **kipin tek işi
sessizce çalışmıyordu.** Test yakaladı, düzeltildi.

### Faz 6 — tarihsel sınav V2'ye bağlandı

Deneyim aynı: aynı tarih → aynı sınav, kopyalanan soru yok, açık etiket
_"MEB formatında hazırlanmış özgün deneme sınavı"_. Değişen, sınavın **kalitesi**: zorluk
dengeli, görsel tekrarsız, şıklar karışık, karışımda görsel soru var. Tohum (`seedFromDate`)
değişmedi → "o ayın sınavı" kavramı korundu.

`buildExam` **kaldırılmadı** — koleksiyon yolu ve mevcut testler onu kullanıyor.

---

## 7. Faz 7 — Kalite kapısı

Üretilen her soru şu kapıdan geçiyor (`visual_questions_test.dart` + `exam_v2_test.dart`):

tam dört şık · geçerli `answerIndex` · **benzersiz şıklar** · boş olmayan açıklama ·
`media` + **boş olmayan `alt`** · benzersiz kimlik · dolu öğrenme kazanımı ·
**karıştırma sonrası doğru cevap hâlâ doğru** · biçimi bozuk soru sınava girmiyor ·
aynı görsel tekrarlanmıyor.

> En sinsi kusur ayrı bir testle korunuyor: şıklar karışır ama `answerIndex` eski yerinde kalırsa
> üreteç **sessizce yanlış cevap öğretir**.

---

## 8. Faz 3 — Banka genişlemesi (dürüst kapsam)

Bu sprintte eklenen özgün içerik **~443 görsel sorudur**; kaynağı kendi doğrulanmış
kataloglarımız, ifadesi kendi metinlerimiz. **Hiçbir yerden soru kopyalanmadı.**

**Yapılmayan:** binlerce yeni **metin** sorusunun tek oturumda yazılması. Bir soruyu gerçekten
yazmak (kazanım, dört şık, çeldirici mantığı, açıklama, `whyWrong`) içerik işidir; kalite
kapısından geçmemiş toplu üretim, Faz 11'de kazanılan güvenceyi bir gecede geri alırdı.

---

## 9. Faz 8 + 9 — Hat

**Altyapı zaten var ve yeniden kurulmadı:** `content_items` (durum geçişleri
`draft → in_review → approved → published → retired`, `payload` JSONB Zod-doğrulamalı, `version`) ·
`content_versions` · `media_assets` · `audit_logs` · `analytics_events`. Yönetici akışı
`api.admin.integration.test.ts` içinde koşuyor.

Bu sprintte hattın **çalışan parçaları** birleşti: boşluk tespiti (`gaps.ts`) → varlık arama
(`AssetCatalog`) → üretim (`visual_questions.dart`) → kalite kapısı (testler) → sınav enjeksiyonu.

**Onay insanda kalıyor** — pazarlık edilemez.

---

## 10. Veritabanı göçü — **yapılmadı, gerekmedi**

Yol haritası §3'te gerekçelendirildi ve uygulama bunu doğruladı:

- Yazılmış banka **kodda** duruyor (çevrimdışı sevk için bilinçli) → şema alanı eklemek göç değil,
  **tip değişikliği**.
- `content_items.payload` **JSONB** ve Zod ile doğrulanıyor → yeni alanlar **göçsüz** girdi.
- Yazarlık hattı tabloları zaten mevcuttu.
- Görsel sorular **cihazda üretiliyor**, saklanmıyor.

İzin verilmişti; **gereksiz göç yapılmadı.**

---

## 11. Cihaz doğrulaması

**Cihaz:** Redmi Note 8 (2021), Android 11. Redmi Note 11R ve Huawei bu oturumda `adb devices`
çıktısında **hiç görünmedi**; talimattaki geri düşüş sırası uygulandı.

| Doğrulanan              | Sonuç                                    |
| ----------------------- | ---------------------------------------- |
| Açılış · onboarding     | ✅                                       |
| Akıllı Çalışma          | ✅ 1/20, gerçek soru                     |
| Sınav üretimi           | ✅ 50 soru, 45 dk                        |
| **Görsel soru**         | ✅ **6/50 — ikaz ışığı görseli ÇİZİLDİ** |
| Metin + görsel karışımı | ✅ 17/50 metin sorusu, aynı sınavda      |
| `logcat`                | ✅ istisna yok                           |

Cihazda görülen görsel soru (6/50, "Araç Tekniği · Zor"):

> **"Bu ikaz ışığı yandığında sürücünün yapması gereken nedir?"**
> _(ikaz ışığı görseli çiziliyor)_
> A) Dikkat — kontrol ettir · B) Bilgi — sistem aktif · …

Bu, sprint öncesi **imkânsızdı**: modelde alan, projeksiyonda geçiş, arayüzde çizim yoktu.

---

## 12. Bilinen sınırlar (dürüstçe)

1. **Tek cihaz.** Yalnız Android 11 / Redmi Note 8. Android 13 ve 360 dp genişlik doğrulanmadı.
2. **İşaret ve parça soruları içerik eşitlemesine bağlı.** İkaz ışığı soruları pakete gömülü
   olduğu için hemen; diğer ikisi içerik anlık görüntüsü indikten sonra. Cihazda doğrulanan
   görsel soru bu yüzden ikaz ışığı sorusuydu.
3. **Hotspot alanı çizilmiyor.** Şemada yer tutuyor; "araca dokun" tipi sorular geldiğinde göç
   gerekmesin diye bugünden kondu.
4. **Kavşak/ilk yardım/senaryo görselleri yok.** Üretim planı
   `CONTENT_EXPANSION_MASTERPLAN.md` §8'de duruyor; bu sprintte varlık **üretilmedi**.
5. **`lean()` hâlâ `image` alanını taşımıyor.** Gerek kalmadı: görsel sorular cihazda üretiliyor.
   Sunucu tarafı görsel soru göndermek istenirse projeksiyon genişletilmeli.
6. **Kipler kod düzeyinde hazır ama arayüzde tek giriş var.** `quick`/`random`/`adaptive`
   kipleri `ExamConfig` ile çağrılabilir durumda; Pratik ekranına ayrı düğme eklenmedi.

---

## 13. Sonuç

Motor sprint öncesine göre **ölçülebilir biçimde** daha güçlü:

|                       | Önce      | Sonra                                    |
| --------------------- | --------- | ---------------------------------------- |
| Görsel soru           | **0**     | **~443 üretilebilir**, sınavda çiziliyor |
| Soru türü             | 1 (metin) | **8**                                    |
| Çoklu görsel          | ✗         | ✅                                       |
| Üreteç yapılandırması | ✗         | **6 kip + 8 anahtar**                    |
| Zorluk dengesi        | ✗         | ✅                                       |
| Görsel tekrar engeli  | ✗         | ✅                                       |
| Şık karıştırma        | ✗         | ✅                                       |
| Zayıf konu önceliği   | ✗         | ✅                                       |
| Üretim raporu         | ✗         | `ExamPlan`                               |
| Mobil test            | 943       | **974**                                  |
