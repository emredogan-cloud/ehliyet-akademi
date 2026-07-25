# Evolution Phase 10 Report — Study Groups & Challenges

**Phase Group 6 · Community Platform (grup katmanı).** _Prepared: 2026-07-25 · Existing architecture
preserved · device-validated on `AYXSUKIVJVPZ7HPZ` · canlı sunucuda iki gerçek hesapla doğrulandı._

## Verdict: 🟢 GO — bir ÜRETİM OLAYIYLA birlikte (aşağıda tam anlatım)

E8'in kimliği ve E9'un sosyal grafiği üzerine grup çalışması ve meydan okumalar kuruldu.
İki tasarım ilkesi belirleyici oldu: **sınırsız büyüme yolu yok** (tavanlar sunucuda) ve
**meydan okuma ilerlemesi türetilir, bildirilmez** (E8'in kırpma katmanından okunur → yeni bir
hile yüzeyi açılmaz).

4 yeni tablo · 3 yeni uç ailesi · `flutter analyze` **0** · `flutter test` **204** (+18) ·
web **479** (+47) · `@ea/db` **6** (+2) · lint **0 hata** · format temiz · APK **69,5 MiB**.

## Completed work

1. **Şema** (`packages/db`) — `study_groups` (benzersiz `join_code`), `study_group_members`
   (PK: grup+kullanıcı), `challenges` (sunucu tanımlı), `challenge_progress` (PK: meydan+kullanıcı,
   `baseline` sütunuyla). İdempotent bootstrap DDL + **ilk meydan okuma kümesi** (3 adet).
2. **Saf mantık** (`apps/web/lib/server/groups.ts`) — tavanlar, katılım kodu üretimi/normalleştirme,
   meydan okuma etkinlik penceresi, ilerleme hesabı, **belirlenimci anlık görüntü sıralaması**.
   Veritabanı içermez → doğrudan test edilir (**20 test**).
3. **Uçlar** — `GET/POST/DELETE /api/community/groups` · `POST/DELETE /api/community/groups/join` ·
   `GET /api/community/groups/[id]` · `GET/POST /api/community/challenges`.
4. **Mobil** — `group_models.dart`, `GroupsApi`/`DioGroupsApi`, Gruplar ekranı (kur + kodla katıl),
   Grup ayrıntısı (kod, toplu istatistik, üye sıralaması, ayrıl/sil), Meydan okumalar ekranı.
5. **Testler** — `groups.test.ts` (25 saf) + `groups.integration.test.ts` (22 PGlite) = **47**;
   `groups_test.dart` (**18** mobil).

## Architecture & decisions

**Preserved:** Bearer oturum · `@ea/db` çift sürücü · `guarded`/`json`/`checkRateLimit`/`newId` ·
Riverpod + arayüz/uygulama ayrımı · tasarım token'ları · `social-guards` engelleme modülü.
**Yeni paket yok.**

- **Sınırsız büyüme yolu yok.** 3 grup kurma · 10 gruba katılma · 50 üye tavanı **sunucuda**
  uygulanır; istemci kuralı ikinci kez uygulamaya çalışmaz, yalnız sunucunun hatasını gösterir.
- **Meydan okuma ilerlemesi TÜRETİLİR.** İstemcide ilerlemeye dokunan hiçbir denetim yoktur
  (widget testi bunu düğme/alan düzeyinde doğrular). İlerleme `community_stats`'tan okunur, yani
  E8'in kırpma ve **60 sn pencere** kuralları meydan okumalara olduğu gibi yayılır — entegrasyon
  testi arka arkaya bildirimle ilerlemenin **sıfır kaldığını** kanıtlıyor.
- **`baseline` (taban).** Katılım anındaki sayaç saklanır; ilerleme `güncel − taban`. Böylece
  geçmişte kazanılmış ilerleme meydan okumayı **anında bitiremez**. Canlıda kanıtlandı: 220 çözülmüş
  soruyla katılan hesap için 200 soruluk meydan okuma `%0` başladı.
- **Katılım kodunda karışan karakter YOK** (`0/O`, `1/I/L` alfabede değil). Bu yüzden yazım hatası
  **sessizce eşlenmez**; geçersiz karakter açık hata verir. Sessiz eşleme kullanıcıyı **başka bir
  gruba** sokabilirdi — ilk taslakta bu hata vardı, kod incelemesinde düzeltildi.
- **Sahipsiz grup kalmaz.** Sahibi ayrılırsa sahiplik **en eski üyeye** devredilir; son üye
  ayrılırsa grup silinir.
- **Üye olmayan grubu göremez** — grup adı bile sızmaz (aynı 404). Engel E9 ilkesiyle sürüyor:
  engellediğin kişinin grubuna katılamazsın, engellenen üye listede görünmez; ancak `memberCount`
  **gerçeği söyler** (yoksa engelleyen kişi grubu eksik sanardı).
- **Haftalık devir BELİRLENİMCİDİR ve tektir.** İki katman: (1) `orderSnapshotRows` XP azalan,
  eşitlikte `userId` artan sıralar → veritabanı dönüş sırasına bağlı değildir; (2) kimlik
  `hafta:sınıf` + benzersiz dizin + `onConflictDoNothing` → aynı hafta için ikinci görüntü **asla**
  yazılmaz, eşzamanlı iki istek yarışsa bile sonuç tektir. İçinde bulunulan hafta **hiç
  dondurulmaz**; boş hafta da dondurulmaz. Devir başarısız olursa sıralama okuması **engellenmez**
  (bir sonraki okumada yeniden denenir). Geçmiş haftalar `GET /api/community/leaderboard/history`
  ile okunur.
- **Topluluk merkezi tek satır, yatay kaydırma.** İki satıra yaymak küçük ekranlarda ölçülen
  **31 px taşma** yaptı ve dikey alanı kalıcı olarak yiyordu; yatay kaydırma yüksekliği sabit tutar
  ve sonraki fazlar yeni yüzey eklediğinde ölçeklenir.

## ⚠️ Üretim olayı — bootstrap DDL yorumundaki noktalı virgül

**Ne oldu.** E10'u yayınladıktan sonra **bütün** veritabanı uçları (yalnız E10 değil; E8 ve E9 de)
500 dönmeye başladı. Süre: yaklaşık **1 saat 5 dakika** (yayın ≈ 18:45 → düzeltme ≈ 19:50 UTC+3).

**Kök neden.** Bootstrap DDL, Postgres yolunda `split(';')` ile tek tek ifadelere bölünüyordu.
E10 ile eklediğim iki **SQL yorum satırında noktalı virgül** vardı
(`-- … arayüzü yoktur; bu yüzden …`). Bölme yorumun ortasından kesti ve geriye sözdizimi hatası
veren bir parça kaldı → `getDb()` her soğuk açılışta patladı → veritabanına dokunan her uç 500.

**Neden testler yakalamadı.** Testler PGlite kullanır ve PGlite bütün metni **tek seferde**
çalıştırır (`exec`) — bölme mantığı hiç devreye girmez. Hata yalnız Postgres yolunda vardı;
`flutter analyze`, 204 mobil test, 471 web testi, lint, format, CI ve CodeQL **hepsi yeşildi**.

**Düzeltme (iki katman).**

1. Yorumlardaki noktalı virgüller kaldırıldı — üretimi ayağa kaldıran asıl düzeltme.
2. `splitDdlStatements()` çıkarıldı: bölmeden **önce** satır yorumlarını atıyor, böylece iki sürücü
   de aynı ifade kümesini görüyor. **+2 regresyon testi** (yorumdaki noktalı virgül ifadeyi bölmemeli;
   gerçek DDL'in her parçası bir SQL anahtar sözcüğüyle başlamalı).

**Kalıcı ders.** Çift sürücülü bir kurulumda **yalnız bir sürücüyle test etmek yetmez**. PGlite ile
Postgres arasındaki davranış farkı (çok-ifadeli metin) bütün test paketini yalancı-yeşil yaptı.
Bundan sonra: sürücüye özgü her kod yolu **doğrudan** test edilir — burada bölme fonksiyonu artık
saf ve test edilebilir olduğu için bu mümkün.

## Tests executed

| Kapsam                      | Sonuç                       |
| --------------------------- | --------------------------- |
| `flutter analyze`           | **0 sorun**                 |
| `flutter test`              | **204 geçti** (E10 ile +18) |
| web `typecheck`             | **0 hata**                  |
| web `test`                  | **479 geçti** (E10 ile +47) |
| `@ea/db`                    | **6 geçti** (+2 regresyon)  |
| `pnpm lint` · `pnpm format` | 0 hata · temiz              |
| CI · Mobile CI · CodeQL     | yeşil                       |

## Canlı doğrulama (üretim, iki gerçek hesap)

| Kontrol                                                  | Sonuç                                  |
| -------------------------------------------------------- | -------------------------------------- |
| Bootstrap tohumu 3 meydan okumayı oluşturdu              | ✅ (`200 soru`, `10 ders`, `5 deneme`) |
| Grup kurma + kod üretimi                                 | ✅ `TPKKH8`                            |
| **Küçük harfle** kodla katılma                           | ✅ 201                                 |
| Grup ayrıntısı: 2 üye, toplam 3300 XP, XP'ye göre sıralı | ✅                                     |
| Üye olmayan grup ayrıntısı                               | ✅ 404 (ad sızmıyor)                   |
| Bilinmeyen kod / geçersiz karakter / kısa ad             | ✅ 404 / 400 / 400                     |
| Meydan okumaya katılma, **taban** kaydı                  | ✅ `baseline: 220` → ilerleme `%0`     |
| Aynı meydan okumaya tekrar katılma                       | ✅ 409                                 |
| **Sahiplik devri**: sahibi ayrıldı → en eski üye sahip   | ✅ `isOwner: true`, mevcut 1           |

## Device validation

**Cihaz:** `AYXSUKIVJVPZ7HPZ` — Redmi M1908C3JGG · Android 11 · 1080×2340.

| #   | Doğrulanan                                                            | Kanıt              |
| --- | --------------------------------------------------------------------- | ------------------ |
| 1   | Topluluk merkezi tek satır yatay kaydırma, **taşma yok**              | `e10_03`, `e10_04` |
| 2   | Gruplar ekranı: kodla katıl kartı, grup listesi, **kurucu** rozeti    | `e10_05`           |
| 3   | Sunucudaki **sahiplik devri** cihazda görünüyor (Burak artık kurucu)  | `e10_05`           |
| 4   | Grup ayrıntısı: katılım kodu + kopyala, toplu istatistik, üye listesi | `e10_06`           |
| 5   | Sahip için "Gruptan ayrıl (sahiplik devredilir)" ve "Grubu sil"       | `e10_06`           |
| 6   | Meydan okumalar: üç kart, ilerleme çubuğu, dürüst açıklama            | `e10_07`           |
| 7   | Katılma → teal vurgu + `%0` + **Katıl düğmesi kayboldu**              | `e10_08`           |

## Build

- **APK (release):** `flutter build apk --release` temiz → **69,5 MiB**. E10 varlık eklemedi.
- **iOS:** N/A — macOS yok.

## Honest limitations

1. **Meydan okumalar otomatik dönmez.** Zamanlayıcı (cron) sağlanmadığı için tohumlanan üç meydan
   okumanın penceresi uzundur (90 gün) ve **kendiliğinden yenilenmez**; yeni dönem yeni satır
   eklemeyi gerektirir. Yönetici arayüzü yoktur.
2. **Haftalık devir TEMBELDİR (zamanlayıcı yok).** Devir bağlandı ve çalışıyor, ama Vercel'de bu
   proje için cron sağlanmadığı üzere tetikleyici bir zamanlayıcı yoktur: anlık görüntü, hafta
   döndükten **sonraki ilk sıralama okumasında** alınır. Sonucu şudur — görüntü "hafta bittiği an"
   değil, **ilk okuma anındaki** duruma karşılık gelir; kimse okumazsa görüntü de alınmaz.
   Belirlenimcilik ve tekillik ayrıca güvence altındadır (aşağıya bakınız).
3. **Sınıfa özel topluluk açılış sayfaları yapılmadı.** Roadmap'te E10 kapsamında sayılıyordu;
   mevcut sınıf süzgeci (Tümü/B/A/D) işlevi karşılıyor, ayrı açılış sayfası eklenmedi.
4. **Grup içi sohbet/akış yok.** Grup şu an ortak istatistik ve sıralama yüzeyidir; grup mesajlaşması
   E9'un birebir mesajlaşmasından ayrı bir moderasyon yüzeyi açacağı için kapsam dışı bırakıldı.
5. **Üretim veritabanında test artığı var** (E9'dan devam): `AyseE9`, `BurakE9`, `CemE9`,
   `E8 Dogrulama` hesapları ve `Cihaz Dogrulama Ekibi` grubu sıralamada/listelerde görünüyor.
   **Gerçek kullanıcı gelmeden temizlenmeli.**

## Next phase prerequisites

E11 (Premium Video Player) E1–E10'dan bağımsızdır; ön koşulu yoktur. E10'dan devreden iki iş:
haftalık anlık görüntü devrinin bağlanması ve üretim test artıklarının temizlenmesi.
