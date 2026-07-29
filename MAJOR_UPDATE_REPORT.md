# Ehliyet Akademi — Büyük Ürün Güncellemesi · Tamamlanma Raporu

**Tarih:** 29 Temmuz 2026 · **Kapsam:** 12 faz · **Taban:** `1d5a1da` → **`39791ca`**
**Değişim:** 12 commit · 106 dosya · +10.099 / −520 satır

---

## 1. Durum

| Kapı                                           | Sonuç                             |
| ---------------------------------------------- | --------------------------------- |
| `flutter analyze`                              | **0 sorun**                       |
| `flutter test` (mobil)                         | **530 ✓** (başlangıç: 404)        |
| `pnpm test` (monorepo)                         | **9/9 görev ✓** — web 602 ✓       |
| `pnpm lint` · `typecheck` · `format` · `build` | **✓ ✓ ✓ ✓**                       |
| GitHub Actions                                 | **CI ✓ · Mobile CI ✓ · CodeQL ✓** |
| Gerçek cihaz (Redmi 8A, Android 11)            | **8/8 ✓**                         |

Her faz ayrı ayrı commit edildi, ayrı ayrı push edildi ve push'tan önce cihazda koşturuldu.

---

## 2. Fazlar

Fazlar teknik bağımlılığa göre sıralandı (izin verilmişti): kabuğu değiştiren 3/4/6 önce
yapıldı, çünkü Faz 1'in koç işaretleri **nihai** gezinmeyi tanıtmak zorundaydı.

| #   | Faz            | Sonuç                                                                                  |
| --- | -------------- | -------------------------------------------------------------------------------------- |
| 3   | Çıkış          | Oturum + Google oturumu + sahiplik önbelleği temizlenir, yığın Giriş ekranına çevrilir |
| 4   | Topluluk       | Alt gezinmede birinci sınıf sekme; kendi yığını olan altıncı dal                       |
| 6   | Canlı zemin    | Uygulamanın kökünde tek örnek; ölçülen kare maliyeti **p10 ≈ 5,2–6,4 ms**              |
| 1   | Koç işaretleri | Dokuz yüzeyi tanıtan tur; karartma, ışık halkası, Atla/Geri/İleri, kalıcı işaret       |
| 2   | Premium akışı  | Misafir satın alma, "zaten sahipsin" ve geri yükleme düzeltildi                        |
| 5   | Hesap silme    | Referans tasarım + sunucu tarafı yeniden kimlik doğrulama                              |
| 7   | Puanlama       | Referans tasarım + üç tetik + spam koruması                                            |
| 11  | A/B/C/D        | 1562 sorunun tamamı tam dört şıklı; kural şemaya bağlandı                              |
| 9   | Ödeme ekranı   | Referans tasarım; fiyat mağazadan, sahte aciliyet yok                                  |
| 10  | İlerleme       | Rozet kutlaması, konfeti, tek dokunuşla paylaşım, sosyal kart                          |
| 8   | Davet          | Kod, ödül motoru, sahtecilik koruması, yönetici yüzeyi                                 |
| 12  | Cilalama       | Ölçülen 20 kusur (taşma + erişilebilirlik) düzeltildi                                  |

---

## 3. Kök nedenler — semptom değil, sebep

**Misafir satın alma (Faz 2).** Sahiplik yalnız sunucudan türetiliyordu (oturum şart), oysa
uygulama misafir kullanımına açık. Zincir: misafir → satın al → Play ödemeyi alır →
`POST /api/iap/validate` **401** → istisna → hak verilmez → özellikler kilitli → tekrar denerse
Play "zaten sahipsin" der. **"Zaten sahipsin" bir sebep değil, sonuçtu.** Çözüm: mağazanın
onayladığı satın alma cihaza yazılır, erişim anında açılır, makbuz kuyrukta bekleyip oturum
açılınca sunucuya bağlanır.

**Geri yükleme (Faz 2).** `PlayBillingGateway.restore()` mağazayı beklemeden boş sonuç
dönüyordu; geri yüklenen satın almalar akıştan yüz milisaniye sonra geliyordu. Ekran boş sonuca
bakıp "bulunamadı" diyordu. **Geri yükleme çalışıyordu; ekran onu beklemiyordu.**

**Üç şıklı sorular (Faz 11).** Kök neden şemadaydı: `options: z.array(...).min(2).max(5)`.
Kural serbest bırakıldığı için 39 üç şıklı ve 13 beş şıklı soru sessizce girmişti. Artık
`.length(4)`.

**Çıkış (Faz 3).** Gezinme hiç yapılmıyordu. Ayrıca cihazdaki Google oturumu açık kalıyor ve
`ea:entitlements:v1` silinmiyordu — aynı telefonda oturum açan ikinci kullanıcı birincinin
premium'unu görürdü.

---

## 4. Dürüstlük kararları

Referans tasarımlar iki yerde, arkasında gerçek bir şey olmadığında **karanlık desen** üretiyordu.
Tasarım korundu, veri gerçeğe bağlandı:

- **Üstü çizili eski fiyat ve "SINIRLI SÜRE" sayacı** (Faz 9) `--dart-define` ile gelen gerçek bir
  kampanyaya bağlandı ve **varsayılan olarak kapalı**. Yapılandırma yoksa ekran yalnız mağazanın
  bildirdiği gerçek fiyatı gösterir. Hiç uygulanmamış bir "eski fiyat" yanıltıcı fiyatlandırmadır;
  hiçbir şeyi kapatmayan sayaç sahte aciliyettir.
- **Puanlama yıldızları** (Faz 7) hiçbir yere kaydedilmez ve **puana göre yol ayrılmaz** — Play,
  puanlamayı filtrelemeyi yasaklar. Pencere bunu açıkça yazar: "Puanını Google Play'de vereceksin."
- **Ses** (Faz 10): uygulamada ses varlığı yok. Olmayan bir şeye kanca takmak yerine cihazda
  gerçekten bulunan geri bildirim kullanıldı — `HapticFeedback`.

---

## 5. Cihazda yakalanan, testin kaçırdığı hatalar

Gerçek cihaz doğrulaması için `integration_test` eklendi (CI'daki `flutter test` yalnız `test/`
koşar; etkilenmez). Yakaladıkları:

1. **Koç işareti baloncuğunda sarı alt çizgi.** Bindirme kabuğun `Scaffold`'unun üstünde duruyor;
   `Material` atası olmayınca Flutter metni "eksik stil" işaretiyle çiziyordu. Widget testleri
   sessizdi — metin **bulunuyordu, yalnız yanlış çiziliyordu**.
2. **Altı sekme etiketi 360 dp'de.** Test yazı tipi (Ahem) gerçekten farklı ölçüyor; sığma yalnız
   cihazda doğrulanabilir. Ölçüm kalıcı teste bağlandı.

---

## 6. Başarım ölçümü — üç yanlış yaklaşım ve doğrusu

"60 FPS" iddiası ölçülmeden yazılamazdı. Üç yaklaşım denendi ve **neden bırakıldıkları testin
başına yazıldı**:

1. **Mutlak kare süresi + eşik** → aynı kod, arka arkaya koşularda 9–40 ms ortanca verdi. Sebep
   kod değil, cihazın o anki yüküydü.
2. **`totalSpan` metriği** → vsync'ten raster sonuna kadar geçen duvar saatidir ve kare
   planlanmadığında boşta geçen süreyi de sayar; duragan hâli canlıdan 30 ms **yavaş** gösterdi.
3. **Canlı/duragan farkı** → duragan ağaç yeterli kare üretmediği için tabanı ölçülemedi.

**Bugünkü ölçüm:** canlı zeminde temiz karenin `buildDuration + rasterDuration` değeri, p10.
On iki koşuda **5,2–6,4 ms** bandında (hata ayıklama yapısı, Redmi 8A). Cihaz saturasyondayken
tek okuma 22,6 ms'e çıkabildiği için test gerekirse ikinci tur koşuyor ve iyisini alıyor —
gerçek bir gerileme iki turda da yüksek çıkar.

---

## 7. Cilalama: rastgele değil, ölçülmüş

`test/polish_audit_test.dart` altı ana yüzeyi dört zorlayıcı koşulda tarıyor (320 dp · 1,3×
sistem yazısı · 1024 dp tablet · açık tema) ve **20 gerçek kusur** buldu:

- **Taşmalar:** `GradientPillButton` (uygulamanın her yerindeki birincil düğme), Ana Sayfa ve
  Profil istatistik satırları, `StatTile` bileşeninin kendisi, AI Koç kart başlığı, alt gezinme
  etiketi. Kırpmak yerine küçültme seçildi — bir eylemin adı yarım okunmamalı.
- **Erişilebilirlik:** plan satırları 30 dp, öneri çipleri 35 dp (Android alt sınırı 48 dp);
  koyu tema anahtarının semantik etiketi yoktu.

**Kendi ölçüm hatam:** dokunma hedefleri başta `InkWell`'in render kutusuyla ölçüldü ve yanlış
alarm verdi — `IconButton`'ın mürekkep dalgası 42 dp olsa da hedefi `MaterialTapTargetSize.padded`
ile 48 dp'ye tamamlanıyor. Elle ölçüm bırakıldı, `meetsGuideline(androidTapTargetGuideline)`
kullanılıyor.

---

## 8. Kalan işler — sahibin kararı gereken

1. **Davet ödülü ortam değişkeni.** `REFERRAL_IP_SALT` üretimde ayarlanmalı; ayarlanmazsa
   geliştirme tuzu kullanılır ve IP hash'i tahmin edilebilir olur.
2. **Kampanya yapılandırması.** Ödeme ekranındaki üstü çizili fiyat ve sayaç kapalı. Gerçek bir
   kampanya başlatılacaksa `PAYWALL_LIST_PRICE` ve `PAYWALL_OFFER_ENDS_AT` verilmeli.
3. **"7 gün iade" ifadesi.** Ödeme ekranındaki güven şeridinde duruyor (bu güncellemeden önce de
   vardı). Google Play'in kendi iade penceresi 48 saat; 7 gün **geliştiricinin gönüllü taahhüdü**
   olur. Taahhüt sürdürülecekse kalmalı, sürdürülmeyecekse metin değişmeli — bu bir ürün kararı.
4. **Davet bağlantısı için web sayfası.** `/davet/<KOD>` bağlantısı paylaşılıyor; web tarafında bu
   rota henüz yok. Kod elle de girilebildiği için akış çalışır, ama bağlantıya tıklayan kullanıcı
   şu an 404 görür.
5. **Play'de gerçek satın alma denemesi.** İmzalı, Play'den yüklenmiş yapı gerektirir; bu ortamda
   yapılamaz. Satın alma/geri yükleme mantığı sahte ağ geçidiyle uçtan uca test ediliyor.

---

## 9. Bilinen sınırlar (dürüstçe)

- **Görüntü alma widget testinde doğrulanamaz.** `toImage` motorun rasterleştirmesine bağlıdır ve
  testin sahte-zaman bölgesinde tamamlanmaz. Widget testi metin yedeğini, **cihaz testi** gerçek
  PNG üretimini doğruluyor (imza + boyut).
- **Faz 2 commit mesajında test sayısı yanlış** yazıldı (447 yerine 438 olmalıydı). Dal
  force-push'a kapalı olduğu için mesaj düzeltilemedi; doğru sayı burada.
- **Ödül geri alma yok.** Yönetici sahte daveti iptal edebilir ama verilmiş premium erişimi geri
  alınmaz — iyi niyetli kullanıcıyı da vurabilecek bir işlem, elle karar gerektirir.

---

## 10. Mimari notlar

- **Kural katmanı ekrandan ayrı.** Davet, puanlama, kampanya, rozet kutlaması ve A/B/C/D biçimi
  saf fonksiyonlar olarak yazıldı ve doğrudan test edildi; ekranlar yalnız uyguluyor.
- **Platforma bağlı her şey arayüz + uygulama.** Paylaşım, mağaza puanlama ve davet uçları
  soyutlandı; testler platform kanalı açmadan koşuyor.
- **Sanat raster, mockup widget.** Ödeme ekranının dört referans parçasından yalnız biri (taç
  madalyonu + araç) raster olarak sevk edildi; diğer üçü widget — raster olsalardı fiyat ülkeye
  göre değişemez, sayaç işlemez, tema değişemez, ekran okuyucu okuyamazdı.
- **Süreli erişim `purchases` tablosuna yazılmaz.** Orada süre kavramı yok; davet ödülü
  `GET /api/purchases` içinde türetiliyor ve süresi dolduğu an kendiliğinden kapanıyor. Mobil
  taraf tek satır değişmeden premium görüyor.
