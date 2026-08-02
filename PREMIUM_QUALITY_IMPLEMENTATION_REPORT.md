# Premium Kalite Programı — Uygulama Raporu

**Tarih:** 1 Ağustos 2026 · **Dal:** `feature/product-evolution-v11-ci` · **Taban:** `fab069e`
**Yol haritası:** [`PREMIUM_QUALITY_ROADMAP.md`](PREMIUM_QUALITY_ROADMAP.md) · **Başka rapor yok.**

---

## 0. Özet

| Faz                       | Durum                                                               |
| ------------------------- | ------------------------------------------------------------------- |
| 1 · Soru kalitesi         | ✅ tamam — %58,1 → **%21,6** (hedef %40'tı; rastgele taban %25)     |
| 2 · Soru genişletme       | ✅ tamam — 43 özgün soru; denetimde SIFIR çıkan 7 konu kapatıldı    |
| 3 · Görsel soru           | ✅ tamam — ~443 → **~665** üretilebilir; **yeni varlık gerekmeden** |
| 4 · Ders zenginleştirme   | ✅ tamam — 18 şema, iki tema, **sıfır bayt**; cihazda çizildi       |
| 5 · Seslendirme altyapısı | ✅ tamam — model + sağlayıcı soyutlaması + dürüst arayüz            |
| 6 · Kod kalitesi          | ✅ tamam — APK **−1,59 MB**, bir bellek sızıntısı giderildi         |
| 7 · Cihaz doğrulaması     | 🟡 **kısmi** — uygulama katmanı doğrulandı, içerik dağıtım bekliyor |

**Kapılar:** `flutter analyze` **0** · mobil **1086 ✓** (1073'ten) · web **633 ✓** ·
content-schema **37 ✓** (31'den) · question-bank **22 ✓** (14'ten) · `pnpm lint` 0 hata ·
`pnpm typecheck` temiz · `prettier` temiz.

**CI:** Lint · Typecheck · Test · Build ✅ · E2E (Playwright) ✅ · gitleaks ✅ · Mobile CI ✅.
Önceki turda kırmızı bırakılan gitleaks bu turda **yeşile alındı** (§7).

---

## 1. Faz 1 — Soru kalitesi

### 1.1 Sonuç

| Ölçüt                          | Başlangıç |     Şimdi | Hedef        |
| ------------------------------ | --------: | --------: | ------------ |
| "en uzun şıkkı seç"            |     %91,1 | **%21,6** | %40 → aşıldı |
| paralel şıklı soru             |     %64,6 | **%86,7** | %60 ✅       |
| doğru/çeldirici uzunluk oranı  |     2,49× | **1,32×** | 1,5× ✅      |
| cevap konumu sapması (B şıkkı) |     +%4,4 | **+%0,1** | ±%8 ✅       |
| içeriksiz şık                  |         3 |     **0** | 0 ✅         |

494 sorunun çeldiricileri yeniden yazıldı. **Motor ve adab derslerinde kalan soru: 0.**

### 1.2 Hedef SIFIR değil, RASTGELE TABAN — bu turun ana bulgusu

Yol haritası "%40 altı, mümkünse %25'e yakın" diyordu. Uygulama sırasında bunun **neden**
böyle olması gerektiği ölçülerek anlaşıldı:

Doğru şıkları kısaltmaya devam edip oranı %0'a indirmek kusuru gidermez, **tersine çevirir.**
Oran düştükçe "en uzunu ELE" stratejisi kazandırmaya başlar:

```
"en uzunu seç" doğruluğu = oran
"en uzunu ele" doğruluğu = (1 − oran) / 3

oran %25 → ele stratejisi %25   (bilgi yok — hedef bu)
oran %10 → ele stratejisi %30   (yeni tellalık, ters yönde)
oran  %0 → ele stratejisi %33
```

Bu yüzden ölçüt artık tek yönlü bir tavan değil, **%25 çevresinde bir bant**:
`maxLongestWinsRate` **ve** `minLongestWinsRate` birlikte kapıda. Bugünkü %21,6'da
"en uzunu ele" %26,1 veriyor — yani şık uzunluğu artık pratikte bilgi taşımıyor.

### 1.3 Kesilmiş doğru şıklar — sevk edilmiş bir kusur

Önceki turun kodmodu, doğru şıkkı bazı sorularda **cümle ortasından** kesip kalan parçayı
`explanation` alanının sonuna eklemişti. Kullanıcı ekranda yarım kalmış bir şık görüyordu:

```
S: Krank milinin görevi aşağıdakilerden hangisidir?
 ✓ Pistonlardan gelen doğrusal (inip kalkan)          ← cümle burada bitiyor
```

**60 soruda** şık tamamlandı ve açıklamada tekrara düşen kuyruk silindi. Bulmayı sağlayan
şey, "kapanmamış görünen şık" düzenlisiydi; onarımı mümkün kılan şey, kodmodun kuyruğu
silmek yerine **taşımış** olmasıydı.

### 1.4 Yazım kuralı — uzatmak değil, alan içinde kalmak

Metrik "doğru şık tek başına en uzun" diyordu; ama örnekler okununca asıl kusur başkaydı:

```
motor-225 · Soğutma sistemindeki termostatın görevi nedir?
  ✗(21) Direksiyonu döndürmek          ← termostat sorusunda DİREKSİYON
  ✗(28) Lastik dişini derinleştirmek   ← ve LASTİK
```

Alan dışı çeldirici iki kez zarar verir: soruyu kolaylaştırır **ve** hiçbir şey öğretmez.
Yeniden yazımın kuralı bu yüzden "uzat" değil, **"aynı alandan, aynı dilbilgisel biçimde,
akla yatkın bir yanılgı yaz"** oldu. Metrik bunun yan ürünü olarak düzeldi.

### 1.5 Kapıya eklenen ölçütler

Tek ölçüt yetmiyor: uzunluk düzelince sıra sınav tekniğine geliyor.

| Yeni ölçüt         | Bugünkü değer | Ne yakalar                                                  |
| ------------------ | ------------: | ----------------------------------------------------------- |
| `shortestWinsRate` |         %11,6 | Ters tellalık — doğru cevap sistematik olarak en kısa       |
| `absoluteOnlyRate` |         %15,5 | "asla/her zaman/kesinlikle" yalnız çeldiricilerde           |
| `lazyOptions`      |             0 | "Hiçbiri", "Fark etmez" — sıfır tolerans                    |
| **`testWiseRate`** |     **%27,5** | **BİRLEŞİK teknik: mutlakları ele, kalanın en uzununu seç** |

Sonuncusu kapının en kapsayıcı ölçütü: tek tek ölçütler temizken **bileşimi** hâlâ %28,3
veriyordu (rastgeleden 3,3 puan yüksek). "Soruyu okumadan kazanılan pay" artık tek bir
sayıda toplanıyor.

### 1.6 Cevap konumu

B şıkkı 459 kez doğruydu (beklenen 391); "emin değilsen B" **%29,4** veriyordu.
`scripts/balance-answers.mjs` 67 sorunun doğru şıkkını **belirlenimci** biçimde eksik temsil
edilen konuma taşıdı → 402/402/402/399. Metin değişmedi, yalnız sıra.

---

## 2. Faz 2 — Soru genişletme

Faz 0'da konu kapsamı **sayıldı**. Kullanıcının saydığı başlıkların çoğu zaten vardı
(kavşak önceliği, park, gösterge paneli, levhalar, ilk yardım, yol çizgileri, acil durum).
Gerçekten boş ya da tek soruluk olanlar kapatıldı:

| Alan                  | Önce | Şimdi |
| --------------------- | ---: | ----: |
| ESP / ASR / çekiş     |    0 |     6 |
| Bagaj / yük yerleşimi |    0 |     5 |
| Römork / karavan      |    1 |     6 |
| Motosiklet            |    3 |    10 |
| Motor bölmesi         |    1 |     6 |
| Araç içi kumandalar   |    — |     6 |
| ABS                   |    4 |     9 |

Banka **1562 → 1605**.

### Mandal işini yaptı

Sorular ilk yazıldığında **43'ün 16'sı** "en uzun şıkkı seç" ile bilinebiliyordu ve kalite
kapısı bunu anında kırdı. Eşik gevşetilmedi; 18 sorunun çeldiricileri yeniden yazıldı.
Sonuç — yeni içerik bankadan **daha temiz** doğdu:

```
en uzun şıkkı seç : %0,0   (banka %21,6)
paralel şıklı     : %100   (banka %86,7)
birleşik teknik   : %2,3   (banka %27,5)
doğru/çeldirici   : 1,01×  (banka 1,32×)
```

`expansion-quality.test.ts` bu sözleşmeyi kalıcı kılıyor: eklenen içerik bankanın
ortalamasını **bozamaz**, ondan daha iyi doğmak zorunda.

---

## 3. Faz 3 — Görsel soru genişletme

Kataloglar `category` ve `system` alanlarını **zaten taşıyordu** ama hiçbir soru bunları
kullanmıyordu. İki yeni üretim açısı eklendi:

- "Bu trafik işareti hangi **gruba** girer?" — 121 levha
- "Bu parça aracın hangi **bölümünde** bulunur?" — 101 parça

Üretilebilir görsel soru **~443 → ~665**. **Tek bir yeni varlık üretilmedi.**

Neden bu açı: anlamı **ezberlemek** ile grubu **okumak** aynı beceri değil. Şekil ve renkten
grubu çıkarabilen aday, hiç görmediği bir levhayı bile sınıflandırabilir — ders içeriğindeki
"önce grubunu tanı" öğüdünün sınav karşılığı budur.

**Yan kazanım:** grup sorusunun çeldiricileri katalogdan değil sabit kategori etiketlerinden
geliyor. Bu yüzden tek levhalık bir katalogda bile geçerli soru çıkıyor; iki test bu yeni
davranışı açıkça yazıyor (eskiden "hiç üretilmez"di).

---

## 4. Faz 4 — Ders zenginleştirme

### Bulgu

Web'de 12 satır içi SVG vardı; mobil `Lesson` modeli `figureId` alanını **taşıyor** ama
hiçbir yerde çizmiyordu. Yani ürünün asıl yüzü olan uygulamada ders görselleri **hiç
görünmüyordu** — QIP v3'teki "platform eksik değil, bağlı değil" bulgusunun ders ikizi.

### Neden raster değil, çizim

Raster görsel dört şeyi birden yapamaz: temaya uymak, yazı tipi ölçeğiyle büyümek,
çevrilebilmek, APK'ya bayt eklememek. 12 şema × 2 tema × 3 yoğunluk = onlarca dosya demekti.
`CustomPainter` + gerçek `Text` widget'ı dördünü birden çözüyor.

**18 şema** (web'deki 12 + 6 yeni: kör nokta, yük yerleşimi, yatay işaretler, görevli kol
işaretleri, koma pozisyonu, durma mesafesi). Şema taşıyan ders **13 → 19**.

Durma mesafesi şemasında çubuk uzunlukları **orantılı**: hız iki katına çıkınca mesafe dörde
katlanıyor ve çizim bunu gösteriyor — rakamı yazmak yerine ilişkiyi çizmek.

---

## 5. Faz 5 — Seslendirme altyapısı

Ses **sentezi** bir dış servis ve bu oturumda bağlanmadı. Bağlanmayan bir şeyin etrafına
yazılabilecek iki tür kod var; burada yalnız **bugün çalışan** kısım var.

### Metin ÜRETİLİYOR, yazılmıyor

Sesli özet için ayrı metin yazmak, aynı bilgiyi ikinci kez ve senkron kalması gereken bir
yerde tutmak demekti: ders güncellenince ses metni bayatlar ve kimse fark etmez. Anlatım
dersin **kendisinden** türetiliyor (özet → hedefler → bölümler → kapanış), markdown süsleri
temizleniyor, süre sözcük sayısından tahmin ediliyor.

### Sağlayıcı soyutlaması

```
NarrationSource
├── SilentNarrationSource     BUGÜN → null
├── AssetNarrationSource      assets/audio/<ders-id>/<parça-id>.m4a
├── RemoteNarrationSource     önbellekte hazır dosya (indirmeyi TETİKLEMEZ)
└── FallbackNarrationSource   önce yerel, sonra önbellek
```

Dosya adı sözleşmesi **şimdiden** sabit; ses üretilip klasöre konduğunda sağlayıcı değişir,
**ekran kodu değişmez**. Düello'daki `DuelOpponent` ile aynı desen.

### GÖRÜNMEME kuralı

Oynatıcı, kaynak ses veremiyorsa **hiçbir şey çizmiyor**. "Yakında" rozeti, devre dışı düğme
ya da boş ilerleme çubuğu yok. Gerekçe Faz 0 denetiminden: ürün turu gerçekleşmeyen bir vaat
veriyordu ve bu kullanıcıya yalan söylemekti; "sesli anlatım (yakında)" düğmesi aynı hatanın
ses tarafındaki biçimi olurdu.

**2× hız bilinçli olarak yok** — eğitim içeriğinde anlamayı bozuyor. Bir test bunu yazıyor.

---

## 6. Faz 6 — Kod kalitesi

### Ölü bağımlılık — önce ölçüldü, sonra kaldırıldı

RevenueCat ağ geçidi yalnız `--dart-define=REVENUECAT_PUBLIC_KEY` verilmişse seçiliyordu;
o bayrak **hiçbir derlemede verilmedi**. Kod hiç çalışmadı. Buna karşılık bedeli ölçüldü:

```
yayınlanan APK'nın classes.dex dosyasında  3114 RevenueCat sembolü
arm64 APK   31,9 MB → 30,3 MB   (−1,59 MB, %5,0)
RevenueCat sembolü   3114 → 0
```

Bu ölçüm aradaki **tüm** değişiklikleri kapsıyor ve bu turda kod **eklendi** (43 soru,
18 ders şeması, seslendirme katmanı). Dolayısıyla SDK'nın gerçek payı 1,59 MB'den büyük.

Kaldırma davranışı değiştirmiyor ve bu **kanıtlanabilir**: seçim koşulu `isConfigured` idi,
anahtar boş olduğu için daima `false` dönüyordu — sevk edilen her derleme zaten Play Billing
yolunu kullanıyordu.

`BillingServerBridge.revenueCatWebhook` → `externalWebhook` olarak yeniden adlandırılıp
**bilerek bırakıldı**: ayrım, ödeme altyapısı değiştiğinde gerçekten değişen şeyi (yetkiye
ulaşan yol) tek satırda anlatıyor.

### Bellek sızıntısı

`showNewThreadSheet` üst düzey bir **fonksiyon** olduğu için `dispose()` kancası yoktu;
`TextEditingController` alt sayfa her açıldığında yeniden yaratılıp hiç bırakılmıyordu.
Kullanıcı "yeni başlık"ı on kez açtıysa on denetleyici yaşıyordu.
`whenComplete(controller.dispose)` — düğmeyle, geri hareketiyle ya da dışına dokunularak
kapatılsın, her yolda çalışır. Kalan 40+ denetleyici/zamanlayıcı tarandı; hepsi doğru
bırakılıyor.

---

## 7. CI — önceki turun kırmızısı yeşile alındı

Önceki rapor gitleaks'i kırmızı bırakmış ve "bu programın kapsamı dışında" demişti. Bu turda
çözüldü ve **üç kez aynı ders alındı**:

1. Kaynak bulgusu (`social.integration.test.ts`, geçmişte) → parmak izi istisnası
2. Yeni bulgu: **önceki turun RAPORU** dizgeyi alıntılıyordu → alıntı kaldırıldı
3. Yeni bulgu: **benim `.gitleaksignore` gerekçem** dizgeyi alıntılıyordu → kaldırıldı

> **Bir sızıntıyı belgelemek, onu bir kez daha depoya yazmaktır.**

Blanket devre dışı bırakma yapılmadı: üç bulgu, her birinin gerekçesi dosyada yazılı. Geçmiş
yeniden yazılmadı — paylaşılan bir dalda tek bir test demirbaşı için göze alınacak bir işlem
değil.

---

## 8. Faz 7 — Cihaz doğrulaması

**Cihaz:** Redmi Note 8 (`M1908C3JGG`), Android 11, arm64-v8a.

### Tercih edilen cihaz neden yine kullanılmadı — bu kez KANITLA

Redmi Note 11R (`22095RA98C`) **bağlıydı** ve kurulum denendi:

```
adb -s jfzxugsgnnvsrsg6 install -r app-arm64-v8a-release.apk
→ INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package signatures do not match
```

Üzerinde Play'den kurulmuş kapalı beta var (`installerPackageName=com.android.vending`).
Kurmak için Play sürümünü **kaldırmak** gerekiyor; bu, sahibinin telefonundaki kurulumu ve
verisini silmek demek — geri alınamaz ve istenmedi. **Yapılmadı.** Huawei bu oturumda
`adb devices` çıktısında hiç görünmedi.

### Cihazda KANITLANAN

| Ne                          | Sonuç                                                                     |
| --------------------------- | ------------------------------------------------------------------------- |
| Açılış                      | ✅ temiz; 2316 satır `logcat`'te **tek istisna yok**                      |
| **Faz 4 · ders şeması**     | ✅ Kavşak şeması **çizildi** — yollar, iki araç, oklar, açıklama          |
| **Faz 5 · oynatıcı**        | ✅ **Görünmüyor** — ses yok, dolayısıyla oynatıcı da yok (tasarım gereği) |
| **Faz 6 · RevenueCat**      | ✅ SDK'sız derleme çalışıyor, ödeme yolu bozulmadı                        |
| Öğren / Pratik / Koleksiyon | ✅ 19 ders · 121 işaret · 70 parça · 60 ikaz                              |

### Cihazda KANITLANAMAYAN — ve nedeni

**Faz 1, 2 ve 3'ün içerik çıktısı cihazda görünmedi.** Sebep tahmin değil, ölçüm:

```
GET https://www.ehliyetegitim.com/api/mobile/question-bank
→ 1562 soru (yeni 43'ü YOK), ilkyardim-547 şıkları ESKİ hâlinde

GET https://www.ehliyetegitim.com/api/mobile/content-snapshot
→ 13 figureId (yeni 6'sı YOK)
```

Mobil uygulama soruları ve dersleri **APK'dan değil, dağıtılmış Next.js API'sinden** alıyor.
APK uygulama **kodunu** taşıyor (şema çizici, seslendirme katmanı, SDK kaldırma — üçü de
doğrulandı); **içerik** ise sunucudan geliyor.

Yani Faz 1/2/3, dal `main`'e birleşip web dağıtımı yapıldığında kullanıcıya ulaşır. Bu
normal akıştır ve üretim dağıtımı **sahibin kararıdır** — otonom olarak yapılmadı.

---

## 9. Yeni araçlar

| Araç                          | Ne işe yarar                                                         |
| ----------------------------- | -------------------------------------------------------------------- |
| `scripts/dump-bank.mjs`       | Bankayı tek JSON'a döker — her ölçümde vitest ayağa kaldırmamak için |
| `scripts/wl.mjs`              | Döküm üzerinde saniyeler içinde süzme ve ölçüm                       |
| `scripts/pad-patch.mjs`       | Kısa kalan çeldiriciyi ve gereken uzunluğu bildirir                  |
| `scripts/balance-answers.mjs` | Cevap konumunu belirlenimci biçimde dengeler                         |
| `apply-option-patches.mjs`    | `dropTail` bayrağı — şık tamamlanınca açıklamadaki artığı siler      |

---

## 10. Dürüstçe: yapılmayanlar

1. **Ses sentezi bağlanmadı.** Altyapı, model, sağlayıcı soyutlaması ve arayüz kuralı var;
   ses dosyası yok. Oynatıcı bu yüzden görünmüyor ve bu bilinçli.
2. **Yeni görsel VARLIK üretilmedi.** Faz 3'ün kazancı, var olan kataloglardan yeni soru
   açıları çıkarmaktan geldi. Fotogerçekçi görsel isteyen konular (motor bölmesi fotoğrafı,
   kokpit, çeki demiri yakın çekimi) için istem yazılmadı — bu turda üretilecek görsel
   olmadığı için istem yazmak, kullanılmayacak bir belge üretmek olurdu.
3. **Kalan 347 soru** hâlâ "en uzun şık" ölçütünde işaretli (trafik 200 · pratik 89 ·
   ilkyardım 58). Metrik rastgele tabanın **altında** olduğu için bunlar artık bir tellalık
   oluşturmuyor; yine de şıkları elden geçmemiş sorulardır.
4. **Web `LessonFigure` bileşenine 6 yeni şema eklenmedi.** Mobil ürün olduğu için şemalar
   orada çizildi; web bilinmeyen `figureId` için `null` döndürüyor, yani kırılmıyor.
5. **Üretim dağıtımı yapılmadı.** İçerik değişikliklerinin kullanıcıya ulaşması için gereken
   tek adım budur ve sahibin kararıdır.
