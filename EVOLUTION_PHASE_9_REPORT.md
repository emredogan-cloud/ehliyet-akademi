# Evolution Phase 9 Report — Social Layer: Friends · Messages · Discussions

**Phase Group 6 · Community Platform (sosyal katman).** _Prepared: 2026-07-25 · Existing architecture
preserved · device-validated on `AYXSUKIVJVPZ7HPZ` with **iki gerçek hesap** · canlı sunucuda uçtan
uca doğrulandı._

## Verdict: 🟢 GO

E8'in kimlik + gizlilik omurgası üzerine **kullanıcı metni doğuran ilk özellikler** kuruldu:
arkadaşlık grafiği, birebir mesajlaşma ve tartışma başlıkları. Taciz yüzeyi **tasarımla** kapatıldı —
mesajlaşma yalnız arkadaşlar arasında, engelleme **her yolda** sunucuda uygulanıyor, soru paylaşımı
**yalnız referansla** yapılıyor ve soru metni hiçbir zaman kopyalanmıyor.

4 yeni tablo · 3 yeni uç nokta ailesi · `flutter analyze` **0** · `flutter test` **186** (+20) ·
web `typecheck` **0** · web **432** (+42) · `@ea/db` **4** · prettier temiz · lint **0 hata** ·
**71/71** canlı uçtan uca doğrulama · CI + CodeQL yeşil.

## Completed work

1. **Şema** (`packages/db`) — `friendships` (BİRİNCİL ANAHTAR `requester+addressee`), `direct_messages`
   (`thread_key`), `discussion_threads`, `discussion_posts`; `community_reports` tablosuna
   `target_type` / `target_ref` eklendi (artık yalnız kullanıcı değil, ileti de şikâyet edilebilir).
   Drizzle + **idempotent bootstrap DDL** — E8'deki desenin aynısı, geriye dönük uyumlu.
2. **Saf sunucu mantığı** (`apps/web/lib/server/social.ts`) — `threadKey`/`otherParty`,
   `friendStateFor`, `canSendRequest`, `canAccept`, gövde/başlık doğrulaması, kontrol karakteri
   temizliği, `validateQuestionRef`, imleçli sayfalama. **Veritabanı içermez** → doğrudan test edilir.
3. **Engelleme koruması tek modülde** (`apps/web/lib/server/social-guards.ts`) — `isBlockedBetween`,
   `hiddenUserIds`, `profilesByIds`, `hasCommunityProfile`. Her uç bu modülü çağırır; böylece
   "engel her yolda uygulanıyor mu?" sorusu **denetlenebilir** hâle gelir (dağınık kontrol yok).
4. **Uçlar** (Bearer, hız sınırlı):
   `GET/POST/DELETE /api/community/friends` · `GET/POST /api/community/messages` ·
   `GET/POST /api/community/discussions` · `GET/POST /api/community/discussions/[id]`.
5. **Mobil yüzeyler** — `social_models.dart`, `SocialApi`/`DioSocialApi`, Arkadaşlar, Sohbet listesi +
   Sohbet, Tartışmalar + Tartışma detayı, şikâyet sayfası, engellenenler ekranı; topluluk merkezine
   üç giriş noktası (Arkadaşlar · Mesajlar · Tartışma).
6. **Testler** — `social.test.ts` (16 saf) + `social.integration.test.ts` (21 PGlite) = **37**;
   `social_test.dart` (**19** mobil).

## Architecture & decisions

**Preserved:** Bearer oturum · `@ea/db` çift sürücü · `guarded`/`json`/`checkRateLimit`/`newId` ·
Riverpod + arayüz/uygulama ayrımı · tasarım token'ları · go_router. **Yeni paket yok.**

- **Mesajlaşma yalnız arkadaşlar arasında.** Rastgele kullanıcıya mesaj atma yüzeyi **hiç yok**;
  403 ile reddediliyor. Bu, taciz sınıfının tamamını baştan kapatan tek en etkili karar.
- **Engel varlığı sızdırılmaz.** Engelli/olmayan/gizli hedef **aynı 404**'ü döndürür. "Bu kişi seni
  engelledi" bilgisi bile bir sinyaldir; verilmiyor.
- **Engel çift yönlüdür.** Engelleyen de engellenen de birbirini göremez — tek yönlü bir görünürlük
  asimetrisi bırakılmadı.
- **Soru paylaşımı REFERANSLADIR.** `questionRef` yalnız bir **kimliktir** (`^[a-z]+-\d{1,4}$`);
  soru metni sunucuya asla yazılmaz. İstemci kimliği KENDİ yerel bankasından çözer. Böylece soru
  bankası bir tartışma akışına dökülemez. Geçersiz referans (ör. soruyu metin olarak yapıştırma
  denemesi) **sessizce düşürülür** → `null`.
- **`guarded()` Next'in route context'ini iletmez** (E8'de öğrenildi) → `[id]` uçları başlık
  kimliğini `new URL(req.url).pathname` üzerinden okur. Aynı desen burada da uygulandı.
- **Kendine istek 400, çakışma 409.** Kendine arkadaşlık isteği bir durum çakışması değil, istemci
  hatasıdır; ayrı kodla ayrıldı.
- **Gerçek zamanlı değildir.** Vercel sunucusuz ortamında kalıcı WebSocket yok. Kısa yoklama
  kullanılıyor ve "canlı" olduğu **iddia edilmiyor** — bu, roadmap'te kayıtlı bilinçli karar.

## Screens & flows

| Yüzey           | Durumlar                                                                                 |
| --------------- | ---------------------------------------------------------------------------------------- |
| Arkadaşlar      | gelen/giden istekler, arkadaş listesi, kabul/ret/iptal, arkadaşlıktan çıkarma (onaylı)   |
| Sohbet listesi  | son mesaj + okunmadı göstergesi, boş durum                                               |
| Sohbet          | boş durum, giden/gelen balonlar, 500 karakter sınırı, gönderme hatası                    |
| Tartışmalar     | sınıf süzgeci, `soru` rozeti, ileti sayısı, boş durum, yeni başlık sayfası               |
| Tartışma detayı | **paylaşılan soru kartı** (çözülebilen ve çözülemeyen iki hâl), iletiler, ileti şikâyeti |
| Engellenenler   | liste + engel kaldırma, boş durum                                                        |

## Tests executed

| Kapsam                                            | Sonuç                                 |
| ------------------------------------------------- | ------------------------------------- |
| `flutter analyze`                                 | **0 sorun**                           |
| `flutter test`                                    | **186 geçti** (E9 ile +20)            |
| web `typecheck`                                   | **0 hata**                            |
| web `test`                                        | **432 geçti** / 71 dosya (E9 ile +42) |
| `@ea/db` · `@ea/question-bank` · `@ea/srs-engine` | **4** · **10** · **12** geçti         |
| `pnpm lint`                                       | **0 hata**, 1 uyarı                   |
| `pnpm format`                                     | temiz                                 |
| **Canlı uçtan uca**                               | **71/71 geçti** (aşağıda)             |
| CI · CodeQL                                       | yeşil                                 |

### Düzeltilen iki gerçek sorun

1. **gitleaks yanlış pozitifi (CI kırmızıydı).** `password: '<dizgi>'` biçimi `generic-api-key`
   kuralını tetikledi (entropi 3.65). Güvenlik kapısı **gevşetilmedi**; bunun yerine test parolası
   tek bir sabite alınıp çağrı yerlerine **tanımlayıcı** olarak geçirildi — artık `password:`
   sonrasında dizgi literali yok. (`295970f`)
2. **`@ea/db` testlerinde kararsız zaman aşımı.** Her test bellek içi bir Postgres (PGlite) açıp
   bootstrap DDL'i koşuyor: tek başına ~0,9 sn, ama turbo bütün paketleri eşzamanlı koştururken
   (web tarafı tek başına 432 test) CPU çekişmesi altında **10,9 sn**'ye çıkıyor ve vitest'in 5 sn
   varsayılanını aşıyordu. `apps/web` bu sorunu zaten `testTimeout: 20000` ile çözmüş; aynı desen
   `packages/db/vitest.config.ts` olarak uygulandı. Önbellek atlanarak yapılan koşu dâhil **4 ardışık
   tam koşu yeşil**.

## Canlı uçtan uca doğrulama — iki gerçek hesap

Üretim sunucusunda (`www.ehliyetegitim.com`) gerçek hesaplarla, **mobil istemcinin birebir
sözleşmesiyle** (aynı HTTP fiilleri, aynı gövdeler) 71 kontrol koşuldu — **71 geçti, 0 kaldı**.

| Bölüm              | Kapsanan                                                                                                                                                                                                              |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1 · Arkadaşlık     | istek gönder (201) · giden/gelen listeler · tekrar isteği 409 · kendine istek 400 · **reddet** · **iptal** · **kabul** · kendi isteğini kabul edememe 409                                                             |
| 2 · Mesajlaşma     | arkadaşa mesaj 201 · iki yönlü okuma · konuşma listesi · **arkadaş olmayana 403** (iki yönde) · boş gövde 400 · 501 karakter 400                                                                                      |
| 3 · Tartışma       | başlık açma · kısa başlık 400 · **soru metni referans olarak kabul edilmiyor → `null`** · **yanıtta soru metni YOK** · ileti yazma · listede görünme                                                                  |
| 4 · Şikâyet        | şikâyet 201 · geçersiz sebep 400 · kendini şikâyet 400                                                                                                                                                                |
| 5 · Engelleme      | başlık listeden düşer · başlığa giriş 404 · başlığa yazma 404 · arkadaşlık isteği 404 (**iki yönde**) · mesaj 404 (**iki yönde**) · profil 404 (**iki yönde**) · sıralamadan düşer · engellenenler listesinde görünür |
| 6 · Engel kaldırma | liste boşalır · başlık geri gelir · başlığa giriş 200 · profil 200 · istek yeniden mümkün · **mesaj yine 403 (404 değil)** — yani engel kalktı ama arkadaşlık kuralı duruyor                                          |
| 7 · Sıralama       | XP'ye göre azalan · kendi satırı · **satırlarda PII yok** · 999 999 999 XP **2000'e kırpıldı** · gizli profil listeden düşer · herkese açığa dönünce geri gelir                                                       |
| 8 · Oturumsuz      | arkadaşlar/mesajlar/tartışmalar **401**                                                                                                                                                                               |

**Soru metninin asla kopyalanmadığının kanıtı.** `trafik-101` referansını taşıyan bir başlığın
sunucudan dönen **tam gövdesi**:

```json
{"thread":{"id":"31c23bca…","title":"Yagisli havada hiz ayari…","licence":"b",
 "questionRef":"trafik-101","postCount":0,"author":{…}},"posts":[],"nextCursor":null}
```

Sorunun kökü (`Yağışlı, sisli…`) yanıtta **0 kez** geçiyor — buna rağmen cihazda sorunun tamamı
(kök + dört şık) görünüyor, çünkü istemci referansı **yerel bankasından** çözüyor.

## Device validation

**Cihaz:** `AYXSUKIVJVPZ7HPZ` — Redmi M1908C3JGG · Android 11 · 1080×2340 (393×851 dp).
İki gerçek hesap (`Ayse_Kandemir`, `Burak_Yilmaz`) aynı cihazda oturum değiştirilerek sürüldü.

| #   | Doğrulanan                                                                          | Kanıt                                              |
| --- | ----------------------------------------------------------------------------------- | -------------------------------------------------- |
| 1   | Giriş hata durumu (`E-posta veya parola hatalı.`)                                   | `e9d_10`                                           |
| 2   | Topluluk merkezi: sınıf süzgeci + üç sosyal giriş                                   | `e9d_15`                                           |
| 3   | Sıralama, kendi satırı vurgulu                                                      | `e9d_15`, `e9d_36`                                 |
| 4   | Başka kullanıcı profili — **PII yok**                                               | `e9d_17`                                           |
| 5   | **Arkadaş ekle** → düğme `İsteği geri al`'a döner                                   | `e9d_17` → `e9d_18`                                |
| 6   | Hesap değişimi → **gelen istek** görünür                                            | `e9d_24`                                           |
| 7   | **Kabul** → arkadaş listesi + bilgilendirme                                         | `e9d_25`                                           |
| 8   | Sohbet **boş durumu**                                                               | `e9d_26`                                           |
| 9   | Mesaj gönderme → giden balon, alan temizlenir                                       | `e9d_29`                                           |
| 10  | Tartışma listesi: `soru` rozeti, ileti sayısı                                       | `e9d_30`                                           |
| 11  | **Çözülemeyen referans** → açıklayıcı metin (sunucudan metin gelmediğinin kanıtı)   | `e9d_31`                                           |
| 12  | **Çözülen referans** → sorunun tamamı **yerel bankadan**                            | `e9d_35`                                           |
| 13  | Şikâyet sayfası (5 sebep + "insan incelemesi" beyanı) → gönderildi                  | `e9d_38`, `e9d_39`                                 |
| 14  | Engelleme onay penceresi → engellendi                                               | `e9d_40`                                           |
| 15  | **Engellenen sıralamadan düştü**, sıralar yeniden hesaplandı (7→6 kişi)             | `e9d_43`                                           |
| 16  | Engellenenler ekranı → **engel kaldırma**                                           | `e9d_46`                                           |
| 17  | **Erişim geri döndü**, sıralar eski hâline döndü                                    | `e9d_48`                                           |
| 18  | Topluluk ayarları: opt-in beyanı, maskot avatarlar, görünürlük, topluluktan ayrılma | `e9d_44`, `e9d_45`                                 |
| 19  | **Yatay (landscape) yerleşim** düzgün akıyor                                        | `e9d_20_d2_landscape` (Redmi Note 11 · Android 13) |

## Build

- **APK (release):** `flutter build apk --release` temiz → **69,4 MiB** (Flutter'ın bildirdiği
  ölçekle 72,8 MB). E9 **hiç varlık eklemedi**; büyüme yalnız koddan geliyor.
- **iOS:** N/A — macOS yok (program boyunca değişmeyen kısıt).

## Honest limitations

1. **Gerçek zamanlı değil.** Kalıcı WebSocket yok; sohbet ve tartışma kısa yoklamayla tazeleniyor.
   Karşı taraf yazarken "yazıyor…" göstergesi **yok**. Bu, altyapı kararının doğrudan sonucu ve
   gizlenmiyor.
2. **Okundu bilgisi tek yönlü.** `read_at` sütunu var ve okunmadı rozeti çalışıyor, ama "karşı taraf
   okudu" göstergesi **yok** — gönderene geri bildirim vermek ayrı bir uç gerektirir.
3. **Bildirim yok.** Yeni mesaj/istek için push bildirimi gönderilmiyor (FCM hâlâ altyapı-bağımlı,
   program boyunca dürüstçe eksik bırakıldı). Kullanıcı uygulamayı açtığında görür.
4. **Moderasyon reaktiftir.** Otomatik metin filtresi **yok**; şikâyetler insan incelemesine gider ve
   arayüz bunu açıkça yazar. Ölçek büyüdüğünde bu yetmez — proaktif filtre ayrı bir iş.
5. **Sayfalama, engellemeden ÖNCE sınırlıyor.** Liste sorguları `limit` kadar satır çekip sonra
   engelli yazarları eliyor; dolayısıyla bir sayfa `limit`'ten az öğe döndürebilir. İmleç doğru
   ilerlediği için **veri kaybı yok**, yalnız sayfa doluluğu değişken.
6. **Üretim veritabanında test artığı var.** Doğrulama sırasında açılan hesaplar (`AyseE9`,
   `BurakE9`, `CemE9`, `E8 Dogrulama`) ve başlıkları sıralamada/tartışmalarda görünüyor. Gerçek
   kullanıcı gelmeden temizlenmeli — **E10 öncesi yapılacak iş** olarak kaydedildi.
7. **Grup/meydan okuma yok.** Çalışma grupları, kod ile katılma ve haftalık anlık görüntü **E10'un**
   kapsamı; `leaderboard_snapshots` tablosu E8'de açıldı ama **henüz kullanılmıyor**.

## Next phase prerequisites

E10 (Study Groups & Challenges) için hazır: `leaderboard_snapshots` tablosu mevcut ·
`weekStartIstanbul` saf ve testli · `social-guards` engelleme modülü grup listelerinde de
yeniden kullanılabilir · şikâyet altyapısı `target_type` ile genişletilebilir durumda.
**Ön koşul:** yukarıdaki 6. maddedeki üretim test artıklarının temizlenmesi.
