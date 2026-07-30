# Play Billing — Üretim Düzeyi Satın Alma Denetimi

**Beta Faz 2** · 30 Temmuz 2026 · Kapsam: `apps/mobile/lib/data/premium/`, `apps/web/app/api/iap/`

Bu belge, ödeme akışının on iki durumunun tek tek nasıl doğrulandığını ve hangi kusurların
bulunduğunu kayda geçer. Ana rapor `BETA_READINESS_REPORT.md`; bu onun destekleyici belgesidir.

---

## 0. Doğrulamanın sınırı — önce bu

**Gerçek bir Play satın alması bu ortamda yapılamaz.** Gerekçesi teknik ve kesindir: Play Billing
yalnız (a) Play Console'da tanımlı ürünler, (b) yükleme anahtarıyla imzalanmış bir yapı ve
(c) Play'den (veya Play test kanalından) yüklenmiş bir uygulama üçlüsü sağlandığında çalışır.
Buradaki yapı yandan yüklenmiş bir hata ayıklama derlemesidir.

Bu yüzden doğrulama iki katmanda yapıldı ve **hangi durumun hangi katmanla doğrulandığı aşağıdaki
tabloda açıkça yazılıdır**:

| Katman             | Ne doğrular                                                                       |
| ------------------ | --------------------------------------------------------------------------------- |
| **Benzetim testi** | Gerçek uygulama kodunun tamamı; yalnız Play'in kendisi sahte (akış taklit edilir) |
| **Cihaz**          | Gerçek Android'de gerçekten çizilen ekran ve gerçekten çalışan yol                |

Benzetim katmanının değeri, **sahtenin gerçeğin sözleşmesine uyması** koşuluna bağlıdır. Bu denetimin
en önemli bulgusu tam olarak buydu (§2.1).

---

## 1. On iki durum

| #   | Durum                      | Sonuç | Nasıl doğrulandı                                                                        |
| --- | -------------------------- | ----- | --------------------------------------------------------------------------------------- |
| 1   | İlk satın alma             | ✅    | Benzetim (`billing_states_test.dart` · "BAŞARILI") + cihazda ödeme ekranı               |
| 2   | İkinci satın alma          | ✅    | Play `ITEM_ALREADY_OWNED` → hata değil, geri yükleme tetiklenir (§2.4)                  |
| 3   | Zaten sahipsin             | ✅    | Benzetim · "ZATEN SAHİPSİN"; `restoreCalls == 1` doğrulanır                             |
| 4   | Geri yükleme               | ✅    | **Cihazda** koşturuldu — dürüst "bulunamadı" mesajı (ekran görüntüsü alındı)            |
| 5   | Çıkış / giriş              | ✅    | `clearForSignOut` sunucu tarafını siler, cihaz defterini KORUR (§3.1)                   |
| 6   | Yeniden kurulum            | ✅    | Defter kaldırma ile silinir; sunucu + geri yükleme erişimi geri getirir (§3.2)          |
| 7   | Çevrimdışı kurtarma        | ✅    | Makbuz kuyruğu; erişim önce açılır, sunucuya sonra bağlanır (`premium_flow_test.dart`)  |
| 8   | **Bekleyen satın alma**    | ⚠→✅  | **İKİ KUSUR BULUNDU VE DÜZELTİLDİ** (§2.2, §2.3)                                        |
| 9   | **Satın almadan vazgeçme** | ❌→✅ | **KUSUR BULUNDU VE DÜZELTİLDİ** — düğme sonsuza kadar dönüyordu (§2.1)                  |
| 10  | **İade**                   | ❌→✅ | **KUSUR BULUNDU VE DÜZELTİLDİ** — iade sonrası erişim kalıcıydı (§2.5). Sunucu tarafı ⚠ |
| 11  | Hesap değiştirme           | ✅    | Durum 5 ile aynı mekanizma; ikinci kullanıcı birincinin sunucu hakkını GÖRMEZ           |
| 12  | Yetki senkronizasyonu      | ⚠     | İstemci tarafı ✅; **sunucu tarafı Play doğrulaması henüz iskele** (§4.1)               |

---

## 2. Bulunan kusurlar

### 2.1 Vazgeçmede satın alma düğmesi sonsuza kadar dönüyordu ❌→✅

**Belirti.** Kullanıcı "PAKETİ SATIN AL"a basar, Play ödeme sayfası açılır, kullanıcı geri tuşuyla
kapatır. Düğme dönen göstergede KALIR ve bir daha çıkmaz. Ekrandan çıkıp girmeden satın alma
tekrar denenemez.

**Kök neden.** `in_app_purchase` sözleşmesi asenkrondur: `purchase()` yalnız akışın
**başlatıldığını** bildirir ve `BillingSuccess([])` döner. Ödeme ekranı bunu "sonuç akıştan
gelecek" diye okur ve beklemeye geçer. Vazgeçme akıştan `PurchaseStatus.canceled` olarak gelir —
ama `IapService.listen` yalnız `purchased`, `restored` ve `error` durumlarını işliyor, `canceled`'ı
**sessizce düşürüyordu**. Bekleyen ekranı uyandıracak olay hiç gelmiyordu.

**Testler bunu neden kaçırdı.** `FakeBillingGateway.purchase()` vazgeçmeyi `BillingCancelled`
olarak **doğrudan döndürüyor**; ödeme ekranı o dalı işliyor ve meşguliyeti temizliyor. Yani sahte
ağ geçidi, gerçek ağ geçidinin kırık olduğu yolu **hiç kullanmıyordu**. Sahtenin sözleşmesi
gerçeğinkinden ayrıldığında test yeşil kalır ve ürün kırık olur.

**Düzeltme.** `IapService.listen` artık `canceled` ve `pending` durumlarını da bildiriyor;
`BillingGateway.listen` sözleşmesine `onCancelled`/`onPending` eklendi; ödeme ekranı vazgeçmede
meşguliyeti temizliyor (mesaj göstermeden — vazgeçme hata değildir).

**Kalıcı test.** `test/billing_states_test.dart` içindeki `StreamBillingGateway`, gerçek ağ geçidinin
sözleşmesini taklit eder: `purchase()` boş başarı döner, sonuç `emit*` ile akıştan gelir.

### 2.2 Bekleyen (ödenmemiş) satın alma ONAYLANIYORDU ❌→✅

Play Billing kuralı: **bekleyen bir satın alma onaylanmaz**; onay (`acknowledge`) yalnız durum
`PURCHASED` olduktan sonra verilir. Bekleyen satın alma nakit ödeme ve operatör faturasında olur.

Kod, akıştan gelen her öğe için koşulsuz `completePurchase` çağırıyordu:

```dart
if (pd.pendingCompletePurchase) await _iap.completePurchase(pd);
```

`pendingCompletePurchase` eklentide `!billingClientPurchase.isAcknowledged` olarak hesaplanır — yani
**bekleyen bir satın alma için de doğrudur**. `completePurchase` ise doğrudan `acknowledgePurchase`
çağırır. Sonuç: parası henüz alınmamış bir satın alma onaylanıyordu.

Onay artık yalnız `purchased`/`restored` durumunda veriliyor.

### 2.3 Bekleyen satın almada kullanıcıya hiçbir şey söylenmiyordu ⚠→✅

Aynı kök (akıştaki `pending` yutuluyordu): kullanıcı nakit ödeme talimatını verir, uygulamaya döner,
**hiçbir şey değişmemiştir** ve düğme döner durur. "Param gitti mi?" sorusu doğar.

Artık durum açıkça söyleniyor ve **erişim AÇILMIYOR** (ödeme tamamlanmadı):

> Ödemen onay bekliyor. Onaylandığında premium kendiliğinden açılır — uygulamayı tekrar açman yeterli.

### 2.4 "Zaten sahipsin" — önceki fazda düzeltilmişti ✅

Doğrulandı ve kalıcı teste bağlandı: hata gösterilmez, geri yükleme kendiliğinden tetiklenir.

### 2.5 İade edilen satın alma o cihazda SONSUZA KADAR premium veriyordu ❌→✅

**Kök neden.** Cihaz defteri (`StorePurchaseStore`) yalnız BÜYÜYORDU ve sahiplik
`birleşim(sunucu, defter)` olarak yayımlanıyordu. Sunucu iadeden sonra hakkı geri alsa bile
defterdeki satır erişimi açık tutuyordu. Yani para geri gidiyor, erişim gitmiyordu.

**Neden dikkatli düzeltildi.** Ters yönde hata çok daha pahalı: ödenmiş bir paketi silmek. Bu yüzden
bir kayıt ancak **üç koşul birlikte** sağlanınca düşer:

1. Sunucu gerçekten cevap verdi (**yalnız HTTP 200**),
2. kayıt daha önce sunucuya **bağlanmıştı** (`bound`) — yani sunucu onu biliyordu,
3. sunucu artık o ürünü vermiyor.

Bunun için `EntitlementsApi.fetchOwned()` sözleşmesi değişti: **`null` ile boş liste artık aynı şey
değil.** `[]` = "sunucu cevap verdi, hiçbir şeyin yok" (yetkili), `null` = "sorulamadı" (401, ağ yok,
5xx). Eskiden ikisi de `[]`'ye indirgeniyordu; bu yüzden "iade edildi" ile "misafirim" ayırt
edilemiyordu.

Dört kalıcı test bu ayrımı korur — biri düşmeyi, üçü **düşmemeyi** doğrular (misafir satın alması,
oturumsuzluk, sunucunun hâlâ hak vermesi).

---

## 3. Doğrulanan tasarım kararları

### 3.1 Çıkışta cihaz defteri neden SİLİNMİYOR

`ea:entitlements:v1` (sunucu tarafı sahiplik) kullanıcıya aittir ve çıkışta silinir — aynı telefonda
oturum açan ikinci kullanıcı birincinin premium'unu görmemeli. Cihaz defteri ise cihazdaki **Play
hesabına** aittir; lisansın gerçek sahibi odur. Silinseydi, çıkış yapan kullanıcı kendi satın aldığı
paketi kaybederdi. Play'in kendi davranışı da budur.

### 3.2 Yeniden kurulumda ne olur

Kaldırma `SharedPreferences`'ı siler → cihaz defteri gider. Erişim iki yoldan geri gelir: oturum
açılırsa sunucudan (`GET /api/purchases`), açılmazsa "Geri yükle" ile Play'den. İkinci yol Play
politikasının zorunlu kıldığı yüzeydir ve **cihazda koşturularak doğrulandı**.

---

## 4. Kalan riskler — sahibin işi

### 4.1 Sunucu tarafı Play doğrulaması İSKELE ⚠ (yayın engeli)

`app/api/iap/validate/route.ts` içindeki `verifyPlayPurchase`, token'ın uzunluğuna bakar; gerçek
`androidpublisher purchases.products.get` çağrısı **yapılmaz**. Kod fail-closed'dır: üretimde
`GOOGLE_PLAY_SA_JSON` yoksa uç **503** döner ve sahte bir hak verilmez. Ama sonuç şudur:

> Servis hesabı yapılandırılmadan, çapraz cihaz senkronu üretimde ÇALIŞMAZ.

Kullanıcı satın alır, erişimi **o cihazda** açılır (defter sayesinde), ama ikinci cihazında açılmaz.
Yapılacak: Play Console → API erişimi → servis hesabı → `GOOGLE_PLAY_SA_JSON` ortam değişkeni.

### 4.2 İade bildirimi (RTDN) bağlı değil ⚠

Sunucu bir iadeyi kendiliğinden ÖĞRENMEZ. §2.5'teki uzlaşma, sunucunun iadeyi öğrendiği an devreye
girer; öğrenme yolu Play'in Real-time Developer Notifications (Pub/Sub) akışıdır ve henüz kurulmadı.
Kurulana kadar iade yalnız elle işlenebilir.

### 4.3 Tek ürünlü iade, cihazda anında yakalanamaz ⚠

Play'in `queryPurchases` cevabı, iade edilmiş satın almayı artık döndürmez. Ama "Play boş liste
döndürdü" ile "geri yükleme penceresi sessiz geçti" ayırt edilemediği için, defterin yalnız Play'e
bakarak temizlenmesi tehlikeli olurdu (ödenmiş paketi silme riski). Bu yüzden iade tespiti §2.5'teki
**sunucu otoritesine** dayandırıldı. Sunucu tarafı (4.1/4.2) tamamlandığında bu boşluk kapanır.

---

## 5. Kapılar

| Kapı                          | Sonuç                                                           |
| ----------------------------- | --------------------------------------------------------------- |
| `flutter analyze`             | 0 sorun                                                         |
| `flutter test`                | 577 ✓ (denetim öncesi 567)                                      |
| Yeni kalıcı test              | `test/billing_states_test.dart` — 10 test                       |
| Cihaz (Redmi 8A · Android 11) | Ödeme ekranı, koşulsuz "Geri yükle", dürüst geri yükleme sonucu |
