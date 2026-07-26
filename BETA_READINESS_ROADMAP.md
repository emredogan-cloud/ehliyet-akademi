# Beta Readiness Roadmap — Google Play Kapalı Test (12 test kullanıcısı)

**Program başlangıcı:** 2026-07-26 · **Önceki program:** Evolution (E1–E13) — TAMAMLANDI, dokunulmaz.
**Hedef:** Üretimdeki uygulamayı **Google Play Kapalı Test**'e hazır bir sürüm adayına dönüştürmek.

Bu yol haritası Evolution programının mühendislik disiplinini **aynen** sürdürür:
`MOBILE_ENGINEERING_DISCIPLINE.md` her fazdan önce okunur, bellek yalnız **eklenerek** güncellenir,
mimari sökülmez, çalışan sistem değiştirilmez.

---

## 0. Başlangıç durumu — ölçülmüş gerçekler

Bu yol haritası varsayımla değil, depodan okunan değerlerle yazıldı.

| Ölçüt                  | Değer                                                           |
| ---------------------- | --------------------------------------------------------------- |
| Uygulama kimliği       | `com.ehliyetegitim.ehliyet_akademi`                             |
| Sürüm                  | `1.0.0+1` (versionName 1.0.0 · versionCode 1)                   |
| Flutter                | 3.41.9 stable                                                   |
| compileSdk / targetSdk | **36** (Android 16) — Play'in asgarisinin üstünde               |
| Java / Kotlin JVM      | 17 · core library desugaring **açık**                           |
| İzinler                | `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` (yalnız ikisi)   |
| Release imzalama       | **DEBUG ANAHTARI** ⛔ — Play kabul etmez (bkz. Faz 4)           |
| Ödeme (mobil)          | `in_app_purchase ^3.3.0` — RevenueCat yok                       |
| Kimlik doğrulama       | E-posta + parola (Bearer oturum) — Google Sign-In yok           |
| Firebase               | **Yok**                                                         |
| Profil fotoğrafı       | Yok (avatar = uygulama maskotu)                                 |
| Test sayıları          | `flutter test` 267 · web 484 · `@ea/db` 6 · `flutter analyze` 0 |
| Release artefaktı      | AAB 57,3 MB · arm64 APK 27,9 MB · evrensel APK 69,9 MB          |

### Bilinen yayın engelleri (bu programda çözülecek)

| #   | Engel                                                   | Çözüldüğü faz |
| --- | ------------------------------------------------------- | ------------- |
| B1  | Release derlemesi **debug anahtarıyla** imzalanıyor     | Faz 4         |
| B2  | `android/app/build.gradle.kts` içinde şablon `TODO`ları | Faz 4         |
| B3  | Google Sign-In yok                                      | Faz 2         |
| B4  | RevenueCat yok (Play ürün/abonelik yaşam döngüsü eksik) | Faz 3         |
| B5  | Üretim veritabanında Evolution doğrulama artıkları      | Faz 13        |
| B6  | Play Console kaydı/beyanları yok                        | Faz 4         |

---

## 1. Faz planı

Her faz **Temel DoD**'u sağlamak zorundadır (aşağıda). Fazlar sırayla yürütülür; bir faz
bitmeden sonraki başlamaz.

### Temel DoD (her faz için geçerli)

1. `flutter analyze` → **0 sorun**
2. `flutter test` → tamamı geçer (yeni yüzey varsa yeni test **eklenir**)
3. Backend etkilendiyse: `pnpm test` + entegrasyon testleri geçer
4. `pnpm lint` 0 hata · `pnpm format` temiz
5. CI + Mobile CI + CodeQL **yeşil**
6. **Gerçek cihazda doğrulama** (`AYXSUKIVJVPZ7HPZ`) + ekran görüntüsü kanıtı
7. `EVOLUTION`-tarzı faz raporu: `BETA_PHASE_<N>_REPORT.md`
8. `MOBILE_PROJECT_MEMORY.md`'ye **ekleme** (asla üzerine yazma)
9. Commit + push + bütün akışlar yeşil olana kadar bekle

| Faz    | Konu                               | Kod?  | Ana çıktı                                               |
| ------ | ---------------------------------- | ----- | ------------------------------------------------------- |
| **0**  | Yayın hazırlığı — dokümantasyon    | Hayır | 9 belge (bu dosya dâhil)                                |
| **1**  | Tam varlık denetimi                | Hayır | `ASSET_GENERATION_LIBRARY.md` — üretime hazır promptlar |
| **2**  | Google Sign-In                     | Evet  | Üretim düzeyinde Google kimlik doğrulama                |
| **3**  | RevenueCat                         | Evet  | Abonelik altyapısı (gizli anahtarlar hariç)             |
| **4**  | Play yayın hazırlığı               | Evet  | Upload key, imzalama, Play Console belgeleri            |
| **5**  | Giriş ekranı yeniden tasarımı      | Evet  | Referans varlıklarla premium giriş                      |
| **6**  | Onboarding cilası                  | Evet  | Görsel %85–95 güvenli alan, kaydırmasız                 |
| **7**  | Profil avatarları                  | Evet  | Galeri/kamera + kırpma + sıkıştırma + depolama          |
| **8**  | Karşılama deneyimi                 | Evet  | Onboarding sonrası AI tanıtım diyaloğu                  |
| **9**  | Akan (streaming) AI                | Evet  | Aşamalı metin, SSE'ye hazır mimari                      |
| **10** | Kabin kumandaları detay sayfaları  | Evet  | Mekanik kalitesinde detay + zoom                        |
| **11** | Ders sayfası yeniden tasarımı      | Evet  | Editoryal düzen, hedefler, ilerleme                     |
| **12** | Yeni nesil video hattı araştırması | Hayır | `VIDEO_PIPELINE_RESEARCH.md` (üretim YOK)               |
| **13** | Nihai yayın denetimi               | Evet  | `RELEASE_AUDIT_REPORT.md` + engellerin kapatılması      |
| **—**  | Kapanış                            | —     | `BETA_READINESS_FINAL_REPORT.md`                        |

---

## 2. Faz ayrıntıları

### Faz 0 — Yayın hazırlığı (kod YOK)

Üretilecek dokuz belge, **yeni bir geliştiricinin dışarıdan hiçbir belgeye bakmadan** uygulamayı
yayınlayabileceği ayrıntıda olmalı:

`BETA_READINESS_ROADMAP.md` (bu) · `RELEASE_CHECKLIST.md` · `GOOGLE_AUTH_SETUP.md` ·
`PLAY_CONSOLE_SETUP.md` · `REVENUECAT_SETUP.md` · `CLOSED_TEST_GUIDE.md` · `ENV_TEMPLATE.md` ·
`ASSET_GENERATION_LIBRARY.md` (iskelet; Faz 1'de doldurulur) · `RELEASE_AUDIT_PLAN.md`.

**DoD:** dokuz dosya mevcut · prettier temiz · commit + push + CI yeşil.

### Faz 1 — Tam varlık denetimi (kod YOK)

Projenin **tamamı** taranır; kalan her yer tutucu bulunur: yordamsal/geçici SVG, üretilmiş
illüstrasyon, sahte fotoğraf, eksik boş-durum görseli, geçici ikon/diyagram, düz vektör, eski
onboarding/giriş görselleri, topluluk/mekanik/araç/ikaz-ışığı/gösterge/ders/sosyal/video yer
tutucuları.

Her kayıt: **ekran · widget · mevcut varlık · değiştirme gerekçesi · tam GPT Image promptu ·
görsel stil · dosya adı · uzantı · hedef çözünürlük · kayıt dizini · kullanım yeri**.

**DoD:** `ASSET_GENERATION_LIBRARY.md` üretime hazır promptlarla dolu · her kayıt gerçek bir
dosya/ekrana bağlı (uydurma kayıt yok).

### Faz 2 — Google Sign-In

Android + Firebase + mevcut Bearer oturumla bütünleşik, **sunucu tarafı doğrulamalı** Google
girişi. Misafir kullanım bozulmaz. Play Integrity ile uyumlu. `.env.example`'a
`GOOGLE_WEB_CLIENT_ID`, `GOOGLE_ANDROID_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID`,
`GOOGLE_IOS_CLIENT_ID` **şablon olarak** eklenir — **gizli değer yazılmaz**.

**Riskler:** SHA-1/SHA-256 parmak izi yanlışsa giriş sessizce başarısız olur (mitigasyon: hem
upload hem Play App Signing parmak izleri belgelenir) · sunucu doğrulaması atlanırsa istemci
sahtelenebilir (mitigasyon: `idToken` sunucuda Google'ın JWKS'iyle doğrulanır, entegrasyon testi).

**DoD:** Temel DoD + gerçek cihazda gerçek Google hesabıyla giriş + sunucu doğrulama testi.

### Faz 3 — RevenueCat

Üretim RevenueCat entegrasyonu; **gizli anahtarlar hariç her şey**. `.env.example`'a
`REVENUECAT_PUBLIC_KEY`, `REVENUECAT_PROJECT_ID`, `REVENUECAT_ENTITLEMENT`,
`REVENUECAT_MONTHLY_PRODUCT`, `REVENUECAT_YEARLY_PRODUCT`.

Belgelenecek: RevenueCat panosu · Play Console ürünleri · Offerings · Entitlements · test ·
**Satın Alımı Geri Yükle** · Ödemesiz dönem (grace period) · Hesap beklemesi (account hold) · iptal.

**Kritik kısıt:** mevcut `in_app_purchase` tabanlı yetkilendirme **sökülmez**; RevenueCat onun
yanına, arayüz+uygulama deseniyle eklenir ve anahtar yoksa mevcut yola düşer.

**DoD:** Temel DoD + anahtarsız ortamda uygulama **çökmez** ve dürüst bir "mağaza yapılandırılmadı"
durumu gösterir.

### Faz 4 — Google Play yayın hazırlığı

`release-keystore.properties.example` üretilir; **upload key oluşturulur**; parolalar Git dışında
tutulur. `build.gradle.kts` release imzalaması gerçek anahtara bağlanır ve şablon `TODO`ları
temizlenir (**B1, B2**).

Belgelenecek (sıfırdan): Play Console · uygulama oluşturma · iç test · kapalı test · 12 test
kullanıcısı akışı · zorunlu beyanlar (Veri Güvenliği, Gizlilik, Hedef SDK, İçerik Derecelendirme,
Uygulama Erişimi, **AI beyanları**, izinler) · ekran görüntüleri · Öne Çıkan Grafik · mağaza
listesi · imzalama · AAB yükleme · inceleme · geri alma.

**DoD:** Temel DoD + **gerçek upload key ile imzalanmış AAB** üretilir ve imza doğrulanır
(`apksigner verify --print-certs`).

### Faz 5 — Giriş ekranı yeniden tasarımı

Referanslar: `apps/assets/login-page.png` ve `apps/assets/interface-assets/{022,023,024}-assets.png`
(mevcut; ölçüldü: 1536×1024 · 1024×1536 · 1994×789). Varlıklar **birebir** uygulanır, yaklaşık
geçilmez. Mevcut tasarım sistemi korunur; **yeni görsel dil getirilmez**. Görüntü alanı dolar,
garip boşluk kalmaz.

**DoD:** Temel DoD + cihazda açık ve koyu temada doğrulama.

### Faz 6 — Onboarding cilası

Mevcut illüstrasyonlar küçük. Görsel **güvenli alanın ~%85–95'ini** kaplamalı; kaydırma yok;
aşırı boşluk yok; illüstrasyon düzene hâkim; referans kompozisyon izlenir; duyarlılık korunur
(E6'daki `OnboardingDensity` mimarisi **korunur**, değiştirilmez).

**DoD:** Temel DoD + en az iki ekran ölçüsünde (393×851 dp ve dar bir ölçü) kaydırmasız doğrulama.

### Faz 7 — Profil avatarları

Galeri + kamera + kırpma + sıkıştırma + **depolama soyutlaması**. Topluluk, sıralama ve profilde
görünür. Gelecekteki moderasyonla uyumlu.

**Kritik gizlilik notu:** E8'de "fotoğraf yükleme YOK" bilinçli bir moderasyon kararıydı. Bu faz
o kararı **değiştiriyor**; dolayısıyla moderasyon yüzeyi (şikâyet hedefi olarak avatar, engelleme,
varsayılan maskota dönüş) aynı fazda ele alınmak zorundadır.

**DoD:** Temel DoD + yükleme/kırpma/sıkıştırma cihazda doğrulanır + avatar şikâyet edilebilir.

### Faz 8 — Karşılama deneyimi

Onboarding'den **hemen sonra**, Ana Sayfa'dan **önce** premium bir AI karşılama diyaloğu:
uygulama, öğrenme sistemi, topluluk, AI Koç, Premium tanıtılır. E7'deki tek-seferlik karşılama
zinciri **korunur**, üstüne inşa edilir.

**DoD:** Temel DoD + zincirin (tanıtım → karşılama → ana sayfa) tek seferlik olduğu testle korunur.

### Faz 9 — Akan (streaming) AI

Anlık yanıt çizimi kaldırılır. Backend akış destekliyorsa **gerçek akış**; yoksa **aşamalı parça
çizimi** ve SSE'ye geçişe uygun mimari. **Anlık yanıt asla sahte akış gibi gösterilmez.**

**DoD:** Temel DoD + backend'in akış destekleyip desteklemediği **ölçülerek** rapora yazılır.

### Faz 10 — Kabin kumandaları detay sayfaları

Şu an detay sayfası açılmıyor. Mekanik kütüphanesiyle **aynı kalitede** detay sayfası: büyük
görsel, zoom, açıklama, ipuçları, öğrenme kartları.

### Faz 11 — Ders sayfası yeniden tasarımı

Editoryal düzen: hero, illüstrasyon, ilerleme, tahmini süre, zorluk, öğrenme hedefleri, gelişmiş
hiyerarşi, modern kartlar, hareket. Tasarım token'ları korunur (E13'teki token testi bunu zorlar).

### Faz 12 — Yeni nesil video hattı araştırması (üretim YOK)

Rive · Lottie · Spline · Blender NPR · Three.js · SVG Motion · Cavalry · After Effects/Bodymovin
ve uygun diğer çözümler karşılaştırılır: kalite · sürdürülebilirlik · maliyet · üretim hızı ·
çevrimdışı uyumluluk · Flutter uyumluluğu. **Video üretilmez.**

**Çıktı:** `VIDEO_PIPELINE_RESEARCH.md` + uzun vadeli öneri.

### Faz 13 — Nihai yayın denetimi

Beş şapka takılarak denetim: Play İnceleyicisi · QA · Güvenlik · Erişilebilirlik · Flutter Başarım.
Kapsam: kimlik doğrulama, Google girişi, RevenueCat, satın alma, geri yükleme, çevrimdışı,
topluluk, AI, videolar, başarım, bellek, erişilebilirlik, politika uyumu, gizlilik, Veri Güvenliği,
izinler, hedef SDK, mağaza hazırlığı, yayın hazırlığı. **B5** (üretim veri temizliği) burada kapanır.

**Çıktı:** `RELEASE_AUDIT_REPORT.md`.

---

## 3. Program genelinde riskler

| Risk                                                           | Etki   | Azaltma                                                                         |
| -------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------- |
| Gizli anahtarlar yanlışlıkla depoya girer                      | Kritik | Yalnız `.example` şablonları · CI'da **gitleaks** zaten açık                    |
| Firebase/Play/RevenueCat panoları **dışarıdan** yapılandırılır | Yüksek | Her adım belgelenir; kod **anahtar yokken de çalışır** ve dürüst durum gösterir |
| Avatar yükleme yeni moderasyon yükü doğurur                    | Yüksek | Faz 7 moderasyonu **aynı fazda** ele alır (E8 ilkesi bozulmaz)                  |
| Yeni ekranlar tasarım sisteminden sapar                        | Orta   | E13'teki `design_tokens_test.dart` sapmayı testle engelliyor                    |
| Play incelemesi AI beyanı/veri güvenliği nedeniyle reddeder    | Orta   | Faz 4'te beyanlar tek tek belgelenir; Faz 13'te denetlenir                      |
| Debug imzalı AAB yüklenmeye çalışılır                          | Kritik | Faz 4 imzalamayı düzeltir; Faz 13 `apksigner` ile doğrular                      |

## 4. Program tamamlandığında

`BETA_READINESS_FINAL_REPORT.md`: uygulanan her şey · mimari · güvenlik · başarım · yayın
hazırlığı · Play Console hazırlığı · Google Sign-In hazırlığı · RevenueCat hazırlığı · bilinen
sınırlar · kalan **elle** yapılacak adımlar · risk değerlendirmesi · **Go / No-Go**.
