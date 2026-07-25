# Evolution Phase 8 Report — Community Foundation: Profiles · XP · Leaderboards

**Phase Group 6 · Community Platform (temel).** _Prepared: 2026-07-25 · Existing architecture
preserved · device-validated on `AYXSUKIVJVPZ7HPZ`._

## Verdict: 🟢 GO

Topluluk platformunun **omurgası** kuruldu: kimlik, sunucunun sahip olduğu istatistikler, sıralama ve
**daha ilk satırdan** gizlilik + moderasyon. Katılım **varsayılan olarak KAPALI**, fotoğraf yükleme
**yok**, engelleme/şikâyet **kullanıcı metni doğuran hiçbir özellik gelmeden** devrede.
6 yeni tablo · 6 yeni uç nokta · `flutter analyze` 0 · `flutter test` **166** (+12) ·
web `typecheck` 0 · web **390** (+46) · prettier/verify temiz · lint 0 hata.

## Completed work

1. **Şema** (`packages/db`) — `community_profiles`, `community_stats`, `community_achievements`,
   `leaderboard_snapshots`, `community_reports`, `community_blocks`; Drizzle + **idempotent
   bootstrap DDL** (mevcut desenin aynısı, geriye dönük uyumlu).
2. **Saf sunucu mantığı** (`apps/web/lib/server/community.ts`) — anti-hile sınırlama, hafta sınırı
   (Europe/Istanbul), sıralama, görünen ad/avatar/sebep doğrulaması. **Veritabanı içermez** → doğrudan
   test edilir.
3. **Uçlar** (Bearer, hız sınırlı, eklemeli):
   `GET/PUT/DELETE /api/community/profile` · `POST /api/community/stats` ·
   `GET /api/community/leaderboard` · `GET /api/community/user/[id]` ·
   `POST /api/community/report` · `GET/POST/DELETE /api/community/block`.
4. **Mobil** — modeller, `CommunityApi` + `CommunityController`, **katılım (opt-in) ekranı**,
   sıralama ekranı (sınıf süzgeci + kendi sıran), başka kullanıcı profili (rozetler + **engelle/bildir**),
   Profil'e topluluk satırı.
5. **Testler** — `community.test.ts` (23 saf), `community.integration.test.ts` (23 PGlite),
   `community_test.dart` (12 mobil).

## Architecture & decisions

**Preserved:** Bearer oturum · `@ea/db` çift sürücü (PGlite/Postgres) · `guarded`/`json`/`checkRateLimit`
· Riverpod + arayüz/uygulama ayrımı · tasarım token'ları. **Yeni paket yok.**

- **Gizlilik varsayılanı KAPALI ve bu yapısal.** `visibility` sütunu `private` başlar; istemci
  görünürlüğü AÇIKÇA göndermezse gizli kalır. Profil satırının varlığı "katıldı" demek değildir.
  Sıralama sorgusu yalnız `public` satırları seçer — yani katılmayan biri, hata durumunda bile
  listelenemez.
- **PII yapısal olarak yok.** Topluluk uçları e-posta/gerçek ad/konum **döndürmez**; mobil modelde
  bu alanlar **hiç tanımlı değildir**. İki entegrasyon testi yanıt gövdesinde `@ea.dev` ve kayıt
  adının geçmediğini doğrudan doğrular.
- **Fotoğraf yükleme YOK.** Avatar, uygulamayla gelen 6 maskottan biridir. Bu bir eksiklik değil
  bilinçli kapsam: kullanıcı fotoğrafı, bütün bir moderasyon + PII + depolama sınıfını beraberinde
  getirirdi.
- **Anti-hile sunucuda, üç kural** (`clampStats`, saf ve ayrı test edilmiş):
  (1) **geri gitme yok** — küçük sayaç mevcut değeri silmez; (2) **pencere başına tavan** — tek
  bildirimde XP ≤ 2000, cevap ≤ 300, ders ≤ 30, sınav ≤ 20; (3) **çok sık bildirim** — son yazmadan
  60 sn geçmeden artış uygulanmaz (döngüyle şişirme engeli). Bildirilen ham XP `submitted_xp`
  sütununda ayrıca saklanır → kabul edilen ile bildirilen arasındaki fark **denetlenebilir iz**
  bırakır. Yanıt `clamped`/`regressed` bayraklarını döndürür: sessizce farklı veri saklamayız.
- **Engelleme SUNUCUDA ve ÇİFT YÖNLÜ.** Sıralama ve profil uçları hem "engellediklerimi" hem
  "beni engelleyenleri" düşürür. İstemci filtresine güvenilmez.
- **Sızıntısız 404.** Profil yoksa, gizliyse veya taraflardan biri diğerini engellemişse yanıt
  **aynıdır** (404). Böylece "gizli mi, engellenmiş mi" bilgisi çıkarılamaz.
- **Şikâyet ve engelleme E9'dan ÖNCE.** Mağaza politikaları kullanıcı içeriği barındıran uygulamalarda
  bunları zorunlu kılar; mesajlaşma (E9) gelmeden altyapı hazır olsun diye bu fazda kuruldu.
- **Gerçek zamanlılık iddia EDİLMEZ.** Vercel sunucusuz ortamında kalıcı WebSocket yoktur; sıralama
  açılışta ve elle yenilemede tazelenir. Kod ve arayüz bunu açıkça yazar (roadmap'teki karar).
- **`apps/web/lib/community.ts` DEĞİŞMEDİ.** Web'in tek-oyunculu XP kademeleri/günlük meydan okuma
  modülüdür; yeni sunucu mantığı ayrı dosyaya (`lib/server/community.ts`) yazıldı → web davranışı
  ve testleri birebir korundu.
- **6. sekme EKLENMEDİ (bilinçli sapma).** Roadmap "community tab entry" diyor; alt gezinme çubuğunda
  zaten 5 sekme var ve dar ekranlarda sınırda. Topluluk, kimliğin doğal evi olan **Profil** dalının
  altına (`/profile/community`) yerleştirildi — giriş noktası korunur, düzen bozulmaz.

## Data model (measured)

| Tablo                    | Amaç                                         | Not                                      |
| ------------------------ | -------------------------------------------- | ---------------------------------------- |
| `community_profiles`     | görünen ad · avatar · sınıf · **görünürlük** | `visibility` varsayılan **`private`**    |
| `community_stats`        | XP · seri · ders · sınav · cevap · doğruluk  | + `submitted_xp` (denetim izi)           |
| `community_achievements` | kazanılan rozetler                           | PK(user, achievement) → idempotent       |
| `leaderboard_snapshots`  | haftalık sıralama dondurma (sınıf başına)    | hafta anahtarı Europe/Istanbul pazartesi |
| `community_reports`      | şikâyet kuyruğu (insan incelemesi)           | `status: open/reviewed/dismissed`        |
| `community_blocks`       | engelleme (çift yönlü uygulanır)             | PK(blocker, blocked)                     |

## Tests executed

- `flutter analyze` **0** · `flutter test` **166** (154 önce, **+12**): görünen ad kuralları (sunucuyla
  aynı), avatar kimliğinin güvenli varsayılana düşmesi, JSON çözümlemesinde **gizli varsayılan**,
  sıralama sayfası + kendi sıran, rozet kimliğinin yerel katalogdan çözülmesi; ekranlar: **opt-in
  daveti** (katılmamışa sıralama YOK), katılana sıralama, **gizli profilde "listede görünmezsin"
  uyarısı**, ağ hatasında dürüst hata + tekrar dene, katılma ekranının geçersiz adı reddedip geçerliyi
  kaydetmesi, başka profilde **engelle/bildir** ve engellemenin API'ye gitmesi, erişilemeyen profilde
  **ayrım sızdırmayan** tek mesaj.
- Web `typecheck` **0** · web **390** (344 önce, **+46**):
  - **Saf (23):** ad doğrulama (e-posta reddi dahil), sayaç ayrıştırma, anti-hile'nin dört kuralı,
    hafta sınırı (UTC pazar 22:00 → İstanbul pazartesi dahil), sıralama (eşit XP aynı sıra: 1,2,2,4),
    sayfalama sınırları, sabit alan kümeleri.
  - **Entegrasyon (23, PGlite):** oturumsuz 401 · katılmamışta profil null · **görünürlük
    gönderilmezse gizli** · geçersiz ad/avatar 400 · ayrılınca veri silinir · **yanıtta e-posta/gerçek
    ad yok** · katılmadan istatistik 409 · ilk bildirimde bile tavan · **pencere dolmadan artış yok**
    · geri gitme yok sayılır · rozet idempotent · **yalnız public listelenir** · sınıf süzgeci + kendi
    sıran · sayfa boyutu sınırı · sıralamada e-posta yok · **engelleme çift yönlü düşürür** · engelli
    profil 404 · engel kaldırılınca geri gelir · engel listesi · kendini engelleme/bildirme reddi ·
    gizli profil başkasına 404 kendine 200 · şikâyet kuyruğu + geçersiz sebep/kullanıcı reddi ·
    şikâyet/engel/profil oturum ister.
- `pnpm verify` temiz · `pnpm format` temiz · `pnpm lint` **0 hata** (packages/db'de 1 önceden var
  olan uyarı). Web suite iki ardışık koşuda **390/390** — kararlı.

## Build

`flutter build apk --debug` temiz. Yeni varlık yok. iOS — **N/A (Linux'ta macOS yok)**.

## Device validation (`AYXSUKIVJVPZ7HPZ` · Redmi · Android 11)

**Dağıtım öncesi (yerel olarak doğrulanabilen):** Profil ekranında **Topluluk** satırı göründü;
açıldığında **opt-in daveti** dört gizlilik güvencesiyle çizildi — "Varsayılan olarak KAPALI",
"Gerçek adın görünmez", "Fotoğraf yüklenmez", "Engelle ve bildir", "İstediğin an ayrıl" — ve
"Katılmak için hesabınla giriş yapmış olman gerekir" notu. Katılmamış kullanıcıya **sıralama
gösterilmedi ve hiçbir istek yapılmadı** (tasarım gereği).

**Dağıtım sonrası doğrulama:** topluluk uçları CANLI backend'e bağlıdır; katılma → sıralama →
engelle/bildir akışı ancak Vercel dağıtımından sonra cihazda çalışır (Faz 2'de konan sıralama kuralı,
E4/E5'te de uygulanmıştı). CI yeşile döndükten ve dağıtım tamamlandıktan sonra bu bölüme eklenmiştir.

## Honest limitations

- **Gerçek zamanlı değildir.** Kalıcı WebSocket için ayrı bir servis gerekir ve bu ortamda
  sağlanmamıştır. Sıralama açılışta ve elle yenilemede tazelenir; "canlı" olduğu hiçbir yerde
  iddia edilmez.
- **Moderasyon reaktiftir ve insana bağlıdır.** Şikâyetler kuyruğa yazılır; otomatik sınıflandırma
  veya ML **yoktur** ve olduğu söylenmez. Kuyruğu işleyecek **yönetici arayüzü bu fazda yok** —
  kayıtlar veritabanındadır; yönetim yüzeyi E9'un moderasyon kapsamına aittir.
- **Haftalık anlık görüntü tablosu KURULDU ama henüz doldurulmuyor.** Sıralama şu an canlı XP'den
  hesaplanır. Haftalık dondurma/devir (rollover) E10'un konusudur; tablo şimdiden eklendi ki E10 şema
  göçü gerektirmesin. Boş bir tablonun varlığı özellik sayılmaz — burada açıkça yazılıdır.
- **İstatistik bildirimi otomatik zamanlanmıyor.** `pushStats` hazırdır ancak arka planda periyodik
  gönderim kurulmadı; XP sunucuya kullanıcı topluluk ekranını kullandıkça yansır. Otomatik senkron,
  pil/veri maliyeti taşıdığı için bilinçli olarak ertelendi.
- **Anti-hile sınırlar sunucuda uygulanır ama istemci verisi yine de beyandır.** Uygulama çevrimdışı
  çalıştığı için sunucunun bağımsız doğrulayabileceği bir kaynak yoktur; yapılabilecek en iyi şey
  artışları sınırlamak, geri gitmeyi reddetmek ve **ham beyanı denetim için saklamaktır** — hepsi
  yapıldı. "Hile imkânsız" DENMEZ.
- **Katılım için hesap gerekir.** Misafir kullanıcı topluluğa katılamaz (kimlik olmadan sıralama
  anlamsız olurdu); ekran bunu açıkça yazar.
- Ehliyet sınıfı topluluk profiline **kopyalanır** (sıralama süzgeci için); kullanıcı sınıfını
  değiştirince topluluk profilini yeniden kaydedene kadar eski sınıfta listelenir. Küçük ve
  görünür bir tutarsızlık; otomatik eşitleme E9'a bırakıldı.

## Next phase prerequisites

**E9 — Social Graph & Messaging.** E8 tamam olduğu için bağımlılık karşılandı. Hazır olanlar:
`community_profiles` kimliği, **engelleme tablosu ve çift yönlü uygulama deseni**, şikâyet kuyruğu,
hız sınırlama kapısı, PGlite entegrasyon test iskeleti. E9'un dikkat etmesi gerekenler (roadmap):
arkadaşlık yaşam döngüsü, **her okuma/yazma yolunda engel kontrolü**, mesaj uzunluğu + sıklık
sınırları, sayfalama + saklama politikası, soru paylaşımının **referansla** yapılması (banka kopyası
değil) ve moderasyon kuyruğunun yönetici yüzeyi. Bu fazda kurulan "sızıntısız 404" kuralı mesaj ve
arkadaşlık uçlarında da korunmalıdır.
