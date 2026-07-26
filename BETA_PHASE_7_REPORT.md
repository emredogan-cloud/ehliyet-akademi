# Beta Faz 7 Raporu — Profil Avatarları

**Hazırlandı:** 2026-07-26 · cihazda doğrulandı: `AYXSUKIVJVPZ7HPZ` (Redmi M1908C3JGG · Android 11)

## Karar: 🟢 GO (gerçek yükleme akışı cihazda denenemedi — §7.1)

`flutter analyze` **0** · `flutter test` **353** (+19) · web **541** (+25) · `@ea/db` **6** ·
`content-schema` **17** · `question-bank` **10** · `srs-engine` **12** ·
`pnpm lint` 0 hata · `format` · `verify` · `typecheck` temiz.

---

## 1. Bu faz bir GİZLİLİK KARARINI değiştiriyor

E8'de "kullanıcı fotoğrafı YÜKLENMEZ" **bilinçli** bir karardı ve şemaya bile yazılmıştı:

> `avatarId`'dir — kullanıcı fotoğrafı YÜKLENMEZ (bu, bütün bir moderasyon/PII sınıfını baştan
> ortadan kaldırır).

Faz 7 o sınıfı geri getiriyor. Yol haritasının şartı gereği **moderasyon ve beyan aynı fazda**
ele alındı; şema yorumu da değişikliği ve gerekçesini taşıyacak biçimde güncellendi.

**Temel ilke:** yükleme **isteğe bağlıdır**. `avatarMediaId` null ise paketlenmiş maskot
(`avatarId`) kullanılır. Maskot kimliği **hiç silinmez** — fotoğraf kaldırıldığında geri
dönülecek yer odur, yani "avatarsız" bir durum oluşamaz.

## 2. Sunucu — savunmalar tek yerde

`POST /api/community/avatar` · `DELETE /api/community/avatar`

| #   | Savunma             | Ayrıntı                                                                |
| --- | ------------------- | ---------------------------------------------------------------------- |
| 1   | Oturum şart         | Anonim yükleme yok. **Yönetici yetkisi gerekmez** (kendi profili)      |
| 2   | Katılım şart        | Topluluk profili olmayan yükleyemez (409) — depolama dışarıdan dolmaz  |
| 3   | **Dar tür listesi** | Yalnız JPEG/PNG/WebP. **SVG YOK**                                      |
| 4   | Sıkı boyut          | **512 KB** — CMS'in genel 2 MB sınırının çok altı                      |
| 5   | Hız sınırı          | 6/dk                                                                   |
| 6   | Tek fotoğraf        | Yeni yükleme eskisini **siler** — kullanıcı başına birikme yok         |
| 7   | Maskota dönüş       | `DELETE` her zaman var; fotoğraf yokken de başarılı (etkisiz-tekrarlı) |

**SVG neden reddedildi:** CMS'in genel `ALLOWED_MIME` listesinde `image/svg+xml` var ve bu editör
içerikleri için makul. Ama SVG gömülü script taşıyabilir; medya servisindeki sandbox CSP iyi bir
savunmadır, **tek hat değildir**. Kullanıcı-üretimi içerikte derinlemesine savunma tercih edildi.

**Depolama sıfırdan kurulmadı:** `media_assets` tablosu ve sertleştirilmiş `GET /api/media/[id]`
(sandbox CSP + `nosniff`) zaten vardı; avatar bunları **yeniden kullanıyor**.

## 3. Moderasyon — aynı fazda

- **`avatar` şikâyet sebebi zaten vardı** (`communityReports.reason`); artık gerçek bir hedefi var.
- **Kaldırma yolu:** kullanıcı kendi fotoğrafını her zaman kaldırabilir; medya kaydı **silinir**.
- **Maskota dönüş yapısal:** `CommunityAvatarView` fotoğraf yoksa **veya ağdan gelmezse** maskot
  çizer → "kırık avatar" durumu oluşamaz.
- **E8 ilkeleri bozulmadı:** opt-in katılım, PII sızmayan yanıtlar (entegrasyon testiyle doğrulandı).

## 4. Mobil

| Katman | Dosya                                                   | Sorumluluk                                     |
| ------ | ------------------------------------------------------- | ---------------------------------------------- |
| Saf    | `domain/community/avatar_image.dart`                    | Kırpma matematiği + bütçe. **Eklenti YOK**     |
| Veri   | `data/community/avatar_service.dart`                    | `AvatarPicker` · `AvatarEncoder` · `AvatarApi` |
| Yüzey  | `features/community/avatar_editor_screen.dart`          | Seç → **etkileşimli kırp** → yükle             |
| Yüzey  | `features/community/widgets/community_avatar_view.dart` | Fotoğraf/maskot gösterimi                      |

**Kırpma gerçekten etkileşimli:** kare pencerede `InteractiveViewer` ile yakınlaştırılıp kaydırılır;
kaydederken pencerede **görünen** alan `cropFromViewport` ile kaynağa geri eşlenir ve yalnız o alan
kodlanır (512×512 JPEG q82). Yani kullanıcı ne gördüyse onu yükler.

## 5. ⚠️ İZİN — ölçüldü, EKLENMEDİ

`PLAY_CONSOLE_SETUP.md` §5.8'in şartı: `READ_MEDIA_IMAGES` **eklenmemeli**. Derlenmiş APK'da
`aapt2 dump permissions` ile doğrulandı ve cihazdaki `dumpsys package` ile bağımsız olarak
teyit edildi:

```
POST_NOTIFICATIONS · RECEIVE_BOOT_COMPLETED · INTERNET · VIBRATE
ACCESS_NETWORK_STATE · WAKE_LOCK · USE_BIOMETRIC · USE_FINGERPRINT · com.android.vending.BILLING
```

**`READ_MEDIA_IMAGES` YOK · `CAMERA` YOK.** `image_picker` izin gerektirmeyen sistem seçicisini
kullanıyor.

### Yan bulgu — belgede önceden var olan hata

`PLAY_CONSOLE_SETUP.md` §5.8 "yalnız ikisi bildirilir" diyordu. Bu **bizim yazdığımız** izinler
için doğruydu ama **derlenmiş APK'yı tarif etmiyordu** (9 izin var). Hiçbiri "tehlikeli" sınıfta
değil ve yalnız `POST_NOTIFICATIONS` çalışma zamanında soruluyor; yine de belge ölçülen tam
listeyle düzeltildi. **Bu, Faz 7'nin yol açtığı bir sorun değil, önceden var olan bir belge
hatasıydı.**

## 6. Veri Güvenliği beyanı — GÜNCELLENDİ

`PLAY_CONSOLE_SETUP.md` §5.6'daki "Fotoğraflar" satırı **Hayır → EVET** yapıldı ve beyan
ayrıntılandırıldı: toplanıyor (isteğe bağlı) · paylaşılmıyor · zorunlu değil · amaç yalnız profil
avatarı · kullanıcı silebilir. **Yanlış beyan mağazadan kaldırılma sebebidir**; bu yüzden kod ve
beyan aynı commit'te hizalandı.

## 7. Cihazda bulunan ve düzeltilen DÜRÜSTLÜK HATASI

Topluluk tanıtım ekranı hâlâ şunu vaat ediyordu:

> **Fotoğraf yüklenmez** — Avatarını uygulamanın maskotlarından seçersin.

Bu, Faz 7'den sonra **yanlış bir vaat**. Cihazda görüldü (`b7_02`) ve düzeltildi:

> **Fotoğraf isteğe bağlı** — İstersen fotoğraf yükle, istersen maskotla devam et.

Testi de güncellendi ve eski metnin **bir daha geri gelmemesi** sabitlendi
(`findsNothing`). Düzeltme cihazda doğrulandı (`b7_03`).

## 8. Testler — +44

| Küme                           | Sayı | Kapsam                                                                                     |
| ------------------------------ | ---: | ------------------------------------------------------------------------------------------ |
| Sunucu, saf (`avatar.test.ts`) |   12 | Tür/boyut/biçim kuralları · SVG ve Lottie reddi · maskota dönüş                            |
| Sunucu, entegrasyon            |   13 | Yetki · katılım şartı · redler · tek fotoğraf · PII sızmazlığı · sertleştirilmiş başlıklar |
| Mobil (`avatar_test.dart`)     |   19 | Kırpma matematiği · bütçe · **gerçek görselle** kodlama · maskot yedeği · şikâyet sebebi   |

Kodlayıcı testi gerçek bir görsel üretip kırpıyor ve **doğru bölgenin** alındığını piksel
okuyarak doğruluyor — "kırpma uygulandı" iddiası ölçülüyor.

## 9. Dürüst sınırlar

### 9.1 Gerçek yükleme akışı CİHAZDA DENENMEDİ

Avatar düzenleyiciye ulaşmak **topluluğa katılmış bir hesap** gerektiriyor; topluluk ekranı
"Katılmak için hesabınla giriş yapmış olman gerekir" diyor. Bu ortamda gerçek bir hesapla giriş
yapılamadı (Google girişi Firebase eksikliği yüzünden çalışmıyor — Faz 4 §6.3).

**Cihazda doğrulanan:** izin listesi (kritik) · düzeltilen metin · uygulamanın yeni bağımlılıklarla
çökmeden çalışması. **Doğrulanmayan:** galeri/kamera seçimi, kırpma jesti ve gerçek yükleme.
Bunlar 44 testle kapsanıyor ama **gerçek cihazda görülmedi** — sahte "denendi" denmiyor.

### 9.2 Mobil liste yüzeyleri henüz maskot gösteriyor

Sunucu **bütün** topluluk yüzeylerinde `avatarUrl` döndürüyor (sıralama, profil, kullanıcı, engel,
mesaj, tartışma, grup, arkadaş). Mobil tarafta model alanı da her yerde var, ama **gösterim**
şimdilik profil düzenleyicide bağlandı. Liste ekranlarına `CommunityAvatarView` bağlamak
mekanik bir iştir ve kalıyor.

### 9.3 Görsel moderasyon otomatik DEĞİL

Yüklenen fotoğraflar otomatik taranmıyor (içerik sınıflandırma yok). Moderasyon **reaktiftir**:
şikâyet → inceleme → kaldırma. Bu, E8'den devreden bilinçli duruşun devamıdır ve
`RELEASE_AUDIT_PLAN.md` Faz 13 denetiminde tekrar değerlendirilmelidir.

### 9.4 Depolama Postgres'te base64

Mevcut `media_assets` deseni yeniden kullanıldı. 512 KB tavanı ve tek-fotoğraf kuralı büyümeyi
sınırlıyor; yine de nesne deposu (Blob) uzun vadede daha uygundur. Kapalı test ölçeğinde sorun
değildir.

## 10. Sonraki faz

Faz 8 — **Karşılama deneyimi**: onboarding'den hemen sonra, Ana Sayfa'dan önce premium bir AI
karşılama diyaloğu. E7'deki tek-seferlik karşılama zinciri **korunur**, üstüne inşa edilir; zincirin
(tanıtım → karşılama → ana sayfa) tek seferlik olduğu testle sabitlenmelidir.
