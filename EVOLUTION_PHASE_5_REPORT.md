# Evolution Phase 5 Report — A & D Category Content & Exam Flows

**Phase Group 3 · Multi Licence Support (content).** _Prepared: 2026-07-25 · Existing architecture
preserved · device-validated on `AYXSUKIVJVPZ7HPZ`._

## Verdict: 🟢 GO

A ve D sınıfları artık **gerçek, eksiksiz bir öğrenme yolculuğuna** sahip: 10 yeni sınıfa özgü ders,
sınıfa göre kapsamlanan ders listesi, **işaret ağırlıklandırma** (31 işaret gerekçesiyle öne çıkarıldı)
ve **bankadaki gerçek sorulardan** kurulan sınıf odak setleri (A 19 · D 52). Teori sınavının tüm
sınıflarda ortak olduğu uygulamanın içinde açıkça yazılıdır — uydurma bir sınav yoktur.
`flutter analyze` 0 · `flutter test` **131** (+18) · web `typecheck` 0 · web **344** (+8) ·
`@ea/content-schema` **17** (+3) · prettier temiz.

## Completed work

1. **`Lesson.licences`** — `packages/content-schema` (Zod, varsayılan `[]`), web `content/lessons.ts`
   ve mobil freezed modeli (codegen commit'li). **Etiketsiz = her sınıfta geçerli.**
2. **`apps/web/content/lessons-licence.ts`** — **10 yeni ders**: 5 A (motosiklet) + 5 D (otobüs).
3. **`ALL_LESSONS`** — `/api/mobile/content-snapshot` bu listeyi servis eder; web `LESSONS`'ı
   kullanmaya devam eder → **web davranışı birebir korunur** (E4'ün `ALL_VEHICLE_PARTS` deseni).
4. **`licence_scope.dart`** — derslere kapsamlama (`forLicence` / `specificFor` / `shared`) ve
   **`SignFocus`** ağırlıklandırma tablosu (A 14 · D 17 işaret, her biri gerekçeli).
5. **`content_queries.dart`** — `lessonsBySubject(licence:)`, `licenceLessons()`, `lessonCountFor()`,
   `focusSignsFor()`.
6. **`collections.dart`** — `licenceFocusQuestions()` + sınıf odak koleksiyonu listenin başında.
7. **Ekranlar** — Dersler ("Sınıfına özel" bölümü + sınıf rozeti), Öğren hub (sınıfa göre ders sayısı),
   İşaretler (öne çıkanlar bölümü), İşaret detayı (sınıfa özel gerekçe), Pratik hub (ortak-sınav
   bilgilendirmesi + sınıf odak seti).
8. **Testler** — `apps/mobile/test/licence_content_test.dart` (18 yeni),
   `apps/web/content/lessons-licence.test.ts` (8 yeni), content-schema (+3), anlık görüntü entegrasyon
   testi genişletildi.

## Architecture & decisions

**Preserved:** Riverpod · go_router · dio · drift · freezed · offline-first anlık görüntü · tasarım
token'ları. **Yeni paket yok, yeni uç nokta yok, yeni tablo yok.**

- **Ek dersler ayrı modülde, yalnız mobil anlık görüntüsüne katılır.** `LESSONS` web'in ders
  kütüphanesidir; ondan sayfa, site haritası ve QIP grafiği türer. A/D dersleri oraya karışsaydı web
  davranışı ve 336 testi değişirdi. `ALL_LESSONS` ayrımı bunu kökten engeller ve bir testle sabitlenir
  (`LESSONS` içinde etiketli ders bulunursa test kırılır).
- **İşaretlerde FİLTRE değil AĞIRLIKLANDIRMA.** Dersleri sınıfa göre kapsamlamak doğrudur (motosiklet
  zinciri D öğrencisini ilgilendirmez), ama **işaretler öyle değildir**: e-Sınavda her sınıfa aynı
  işaret sorulabilir. Bu yüzden 121 işaretlik galeri hiçbir sınıfta kısılmaz; yalnız o sınıfın sürüş
  gerçekliğinde kritik olanlar **gerekçesiyle** en üste bir bölümde toplanır ve gerekçe işaret
  detayında gösterilir. Ayrım kodda ve testte açıkça adlandırılmıştır.
- **B için yapay bir "öne çıkanlar" kümesi üretilmedi.** Mevcut işaret kütüphanesi zaten B odaklıdır;
  keyfî bir alt küme öne çıkarmak öğretici değil yanıltıcı olurdu. B'de bölüm hiç görünmez.
- **Odak setleri bankadan seçilir, soru UYDURULMAZ.** Sınıfa özgü soru bankası yoktur ve olduğunu iddia
  etmek yanlış olurdu. Bunun yerine 1562 soruluk ortak banka, sınıfın aracını/mesleğini doğrudan konu
  alan kavramlarla taranır ve **gerçek sorular** bir sete toplanır (A 19 · D 52 — kartta görünen sayı
  ölçülen gerçek sayıdır, kırpma yoktur). `kask(?!o)` gibi bir negatif ileri-bakış, "kasko" sorusunun
  A setine sızmasını engeller ve bu bir testle sabitlenmiştir.
- **Ortak sınav gerçeği uygulamada yazılı.** Pratik hub'ında kalıcı bir bilgilendirme: _"e-Sınav B, A ve
  D için aynıdır: 50 soru · 45 dakika · aynı konu dağılımı."_ Roadmap'in "nothing is faked as a separate
  exam where none exists" şartı böyle karşılanır — sınav akışı sınıfa göre çatallanmaz.
- **İlerleme hâlâ sınıfa göre bölünmez** (E4 kararı korunur): teori ortak olduğu için SRS/cevap geçmişi
  sınıf değiştirince kaybolmaz.

## Kaynak doğrulaması (bu fazın en önemli mühendislik notu)

E4 hafızası, "yasal sürüş/dinlenme süresi gibi sayısal iddialar kaynaksız yazılmayacak" diye
işaretlemişti. D dersleri için mevzuat **birincil kaynaktan** okundu ve şu bulundu:

1. **Karayolu Taşıma Yönetmeliği madde 35 sayı İÇERMEZ** — süreleri AETR ile Karayolları Trafik Kanunu
   ve Yönetmeliğine havale eder. Yaygın "KTY madde 43/35'te yazar" varsayımı yanlıştır.
2. **2918 sayılı Kanun'un 49. maddesi 12/2/2026 tarihli 7574 sayılı Kanunla DEĞİŞTİRİLDİ** ve yeni
   metin sayısal sınırları artık **kanunda saymıyor**; yönetmeliğe bırakıyor ve ihlalleri _günlük
   sürekli · günlük toplam · haftalık/birleşik iki haftalık kullanma · günlük dinlenme · haftalık
   dinlenme_ olarak ayrı ayrı cezalandırıyor. Ezberden yazılsaydı **güncelliğini yitirmiş bir kaynak**
   gösterilmiş olacaktı.
3. Sayıların yürürlükteki kaynağı **Karayolları Trafik Yönetmeliği madde 98/A**'dır. Derste kullanılan
   her değer oradan alınmıştır: kapsam (ticari yolcu taşımacılığında **şoför dahil 9 kişiyi geçen**
   araçlar), **24 saatte toplam 9 saat**, **devamlı 4,5 saat**, **en az 45 dakika mola** (4,5 saat
   içinde **en az 15 dakikalık** bölümler hâlinde de kullanılabilir), **molalar günlük dinlenmeden
   sayılmaz**, **her 24 saatte 11 saat kesintisiz dinlenme** (bölünürse biri en az 8 saat, toplam 12
   saate çıkar; haftada 3 defadan fazla olmamak üzere en az 9 saate indirilebilir), **en fazla 6 günlük
   kullanmadan sonra en az 24 saatlik hafta tatili**, **birleşik 2 haftada en çok 90 saat**, çift
   şoförde **her 30 saatte her şoföre en az 8 saat**.
4. Yolcu güvenliği dersindeki iki iddia da birincil metinden: **KTK madde 78** (koruma başlığı/gözlüğü
   zorunluluğu; _"koruyucu sistemleri usulüne uygun kullanmayanlar kullanmamış sayılır"_; yolcuların
   kemer konusunda **hareketten önce ve seyahat sırasında** uyarılması zorunluluğu) ve KTY'nin araçlarda
   bulundurulacak teçhizat tablosu (**otobüslerde toplam en az 6 kg kuru toz**; **26 kişiye kadar olan
   otobüslerde 2 kg'lık en az iki adet**; cihazlardan **en az biri sürücünün hemen yanında**).

Kaynağı doğrulanamayan hiçbir sayı yazılmadı (bkz. Honest limitations).

## Content added (measured)

| Item                          | Count                                                                                       |
| ----------------------------- | ------------------------------------------------------------------------------------------- |
| A (motosiklet) dersleri       | **5** — koruyucu donanım · kumandalar/kalkış · fren-viraj · bakım · trafikte konum          |
| D (otobüs) dersleri           | **5** — havalı fren · retarder/motor freni · takograf & süreler · yolcu güvenliği · manevra |
| Toplam yeni ders bölümü       | **31** bölüm · **10** karşılaştırma tablosu · **14** vurgu kutusu · **21** tekrar kartı     |
| Anlık görüntü ders sayısı     | 19 → **29**                                                                                 |
| Web ders sayısı               | **19 (değişmedi)**                                                                          |
| Öne çıkarılan işaret          | A **14** · D **17** (her biri tek cümlelik gerekçeyle)                                      |
| Sınıf odak seti (gerçek soru) | A **19** · D **52** (1562 soruluk ortak bankadan)                                           |
| Yeni varlık (asset)           | **0** — bu faz tamamen içerik + mantık                                                      |

## Screens & flows

- **Öğren > Dersler · A/B/D** — en üstte "Sınıfına özel · A Motosiklet" bölümü (sınıf rozetli kartlar +
  teorinin ortak olduğunu söyleyen kutu), altında ortak teori konuya göre gruplu. B'de bölüm hiç yok.
- **Öğren hub** — ders sayacı sınıfa göre (B 19 · A 24 · D 24), alt yazı sınıfa özel içeriği duyurur.
- **Öğren > Trafik İşaretleri** — "A/D sınıfı için öne çıkanlar · N" bölümü; galeri kısılmaz.
- **İşaret detayı** — o sınıf için öne çıkarılmışsa "🎯 A sınıfı için neden kritik?" gerekçesi.
- **Pratik hub** — kalıcı "Teori sınavı tüm sınıflarda ortaktır" bilgilendirmesi + "A/D Sınıfı Odak
  Seti" satırı (gerçek soru sayısıyla), koleksiyon olarak çalıştırılabilir.
- **Koleksiyonlar** — sınıf odak seti listenin başında.

## Tests executed

- `flutter analyze` — **0 issues**.
- `flutter test` — **131 passed** (113 önce, **+18**): ders kapsamlama (etiketsiz her sınıfta, etiketli
  yalnız kendi sınıfında, `specificFor`/`shared`, hiçbir sınıf derssiz kalamaz, anlık görüntü sayaçları),
  işaret ağırlıklandırma (A/D dolu-B boş, benzersizlik + gerekçe uzunluğu, **her öne çıkan işaretin
  gerçek katalogda bulunması**, anlık görüntüde olmayanın elenmesi), odak setleri ("kasko" yanlış
  eşleşmiyor, B için set üretilmiyor, geriye dönük uyumluluk) ve 5 ekran testi (A'da bölüm var, B'de
  yok, galeri kısılmıyor, detay gerekçesi, pratik bilgilendirmesi).
- Web — `typecheck` **0**, **344 passed** (336 önce, **+8**): şema geçerliliği, tek sınıf etiketi,
  id/slug/no benzersizliği, **web `LESSONS`'ın etiketli ders taşımadığı**, her dersin öğrenme değeri
  (hedef/bölüm/özet/tekrar kartı/gövde uzunluğu), mevzuat dersinin kaynak göstermesi.
- `@ea/content-schema` — **17 passed** (14 önce, **+3**): `licences` varsayılanı, geçerli kod kabulü,
  tanımsız kodun reddi.
- Anlık görüntü entegrasyon testi genişletildi: anlık görüntü A ve D derslerini taşır, `ALL_LESSONS >
LESSONS`, ve **etiketsiz ders sayısı tam olarak web listesi kadardır**.
- `pnpm format` temiz · `pnpm verify` temiz · `pnpm lint` **0 hata** (packages/db'de 1 önceden var olan
  uyarı, bu fazla ilgisiz).

## Build

`flutter build apk --debug` → **215 MB** debug APK (hata yok). Bu faz **hiç varlık eklemedi**; içerik
sunucudan gelir, uygulama boyutu pratikte değişmez. iOS — **N/A (Linux'ta macOS yok)**; `ios/` yapılandırması
değişmedi.

## Device validation (`AYXSUKIVJVPZ7HPZ` · Redmi M1908C3JGG · Android 11)

Yeniden derlenmiş APK kuruldu, koyu temada doğrulandı (kanıt: `e5_01`–`e5_12` ekran görüntüleri):

**A sınıfında:**

- Trafik İşaretleri → **"A sınıfı için öne çıkanlar · 14"**; 14 resmî vektör doğru çiziliyor (Motosiklet
  Giremez, Kaygan Yol, Gizli Buzlanma, Gevşek Malzeme, Tramvay Hattı, Hemzemin Geçit, Yandan Rüzgâr,
  viraj üçlüsü, Tehlikeli Eğim, Tümsek…). Galeri altında kategoriler tam hâlde duruyor.
- Kaygan Yol detayı → **"🎯 A sınıfı için neden kritik?"** gerekçesi görünüyor.
- Pratik → **"Teori sınavı tüm sınıflarda ortaktır"** bilgilendirmesi + **"A Sınıfı Odak Seti · 19"**.
- Odak seti açıldı: **1/19**, ilk soru gerçek banka sorusu ("Kırmızı çember içinde bir motosiklet
  sembolü bulunan işaret neyi ifade eder?"), sayaç ve süre çalışıyor.

**D sınıfına geçiş (Profil > Ehliyet sınıfı > D · Otobüs):**

- Pratik → **"D Sınıfı Odak Seti · 52"** (otobüs ikonu), sayı anında yeniden kapsamlandı.
- Trafik İşaretleri → **"D sınıfı için öne çıkanlar · 17"** (Otobüs Giremez, Yükseklik 3,5 m, Ağırlık
  7 t, Dingil 6 t, Genişlik 2,30 m, Uzunluk 10 m, Tehlikeli Eğim iniş/çıkış, daralmalar…).
- **Negatif doğrulama:** D sınıfındayken Kaygan Yol detayında A'ya özel gerekçe kutusu **görünmüyor** —
  ağırlıklandırma sınıfa gerçekten bağlı.

Taşma, boş kutu, takılma veya ölü navigasyon gözlenmedi.

**Dağıtım sonrası doğrulama (dersler):** ders içeriği CANLI `/api/mobile/content-snapshot`'tan gelir;
bu yüzden 10 yeni ders cihazda ancak Vercel dağıtımından sonra görünür (Faz 2'de konan sıralama kuralı,
E4'te de aynen uygulanmıştı). Bu bölüm CI yeşile döndükten ve dağıtım tamamlandıktan sonra bu rapora
eklenmiştir — aşağıya bakınız.

## Honest limitations

- **Kaynağı olmayan sayı yazılmadı.** Havalı fren dersinde **bar cinsinden basınç değeri**, motosiklet
  bakım dersinde **zincir sarkma milimetresi** ve **motosiklet için asgari diş derinliği** bilinçli
  olarak YAZILMADI: ilki araca göre değişir, ikincisi kullanım kılavuzuna aittir, üçüncüsü için
  doğrulanmış bir birincil kaynak elde edilemedi. Dersler bunun yerine ölçütü öğretir ("kendi
  kılavuzundaki değeri esas al").
- **İdari para cezası tutarları yazılmadı** — KTK m.49'daki tutarlar her yıl güncellenir; tutar yazmak
  içeriği hızla yanlışlar. Ceza **kalemleri** yazıldı, tutarlar yazılmadı.
- **A/D için ayrı soru bankası YOKTUR ve olduğu iddia edilmez.** Odak setleri ortak bankadaki gerçek
  soruların seçkisidir. Sınıfa özgü yeni soru üretmek, MEB sorusu uydurmak anlamına gelirdi.
- **Odak seti eşleşmesi anahtar kavram tabanlıdır**, anlamsal değil: bir soru sınıfın aracını
  adlandırmadan ilgili olabilir (kaçırılır) ya da yalnız şıkta geçtiği için girebilir. Ölçülen sayılar
  (19 / 52) bu yöntemin gerçek çıktısıdır, hedeflenmiş bir sayı değildir.
- **B sınıfı için öne çıkan işaret listesi yoktur** (yukarıda gerekçelendirildi) — B'de galeri
  değişmeden kalır.
- **Videolar hâlâ sınıfa göre etiketli değil.** Mevcut 6 video ortak manevra/teori konularıdır ve her
  sınıf için geçerlidir; yapay etiket eklemek kapsamı daraltırdı. A/D'ye özgü video E12'nin konusudur.
- **E3'ten devreden ikaz ışığı ders bağlantısı** bu fazda da kurulmadı: yeni A/D dersleri ikaz ışığı
  değil sistem düzeyinde anlatım içeriyor; tek bir ışığa çapa olacak granülerlik hâlâ yok. Süslemek
  yerine açıkça bırakıldı.
- Ehliyet sınıfı yalnız yerel `StudyProfile`'da saklanır; sunucuya senkronlanmaz (E4'ten devam).

## Next phase prerequisites

**E6 — Onboarding Experience (Coach + Insight Cards).** Bağımlılığı olan E4 tamam, içerik tarafı da
artık tamam. Onboarding zaten `StudyProfile`'ı topluyor ve bu fazdan sonra seçim uygulamanın her
katmanında (ders kapsamı, işaret vurgusu, pratik seti) karşılık buluyor — yani E6'nın "adım-ilgili
içgörü kartları" için gerçek, sınıfa bağlı bir içerik havuzu var. E6 yeni backend istemez; dikkat
edilecek nokta roadmap'te yazılı: dönen kartların zamanlayıcısı enjekte edilip dispose'da iptal
edilmeli (sınav zamanlayıcısı deseni) ve 320 dp + 1,3× metin ölçeğinde kaydırmasız/taşmasız düzen
widget testiyle sabitlenmeli.
