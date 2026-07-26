# Yayın Kontrol Listesi

**Her kapalı test yüklemesinden önce** baştan sona işaretlenir. Bir madde bile atlanmışsa
yükleme yapılmaz.

> Kaynak belgeler: `PLAY_CONSOLE_SETUP.md` · `GOOGLE_AUTH_SETUP.md` · `REVENUECAT_SETUP.md` ·
> `ENV_TEMPLATE.md` · `CLOSED_TEST_GUIDE.md`

---

## A. Kod kapıları (otomatik)

- [ ] `cd apps/mobile && flutter analyze` → **0 sorun**
- [ ] `flutter test` → tamamı geçer
- [ ] `pnpm test` → web + `@ea/db` + paketler geçer
- [ ] `pnpm lint` → **0 hata**
- [ ] `pnpm format` → temiz
- [ ] `pnpm typecheck` → 0 hata
- [ ] Playwright E2E → yeşil (**içerik değiştiyse yerelde de koş**)
- [ ] CI · Mobile CI · CodeQL → **hepsi yeşil**
- [ ] `gitleaks` → sızıntı yok

## B. Sürüm numarası

- [ ] `pubspec.yaml` içindeki `version:` **artırıldı** (`1.0.0+N` → `1.0.0+N+1`)
- [ ] versionCode bir önceki **yüklenmiş** sürümden büyük
- [ ] Sürüm notları Türkçe ve somut yazıldı
- [ ] `git tag v1.0.0+N` atıldı (hızlı düzeltme sürümü üretebilmek için)

## C. İmzalama (yayın engeli B1)

- [ ] `android/key.properties` mevcut ve **Git'te değil**
- [ ] Anahtar deposu Git dışında (`~/keys/…`), yedeklenmiş
- [ ] `build.gradle.kts` release bloğunda **debug anahtarı YOK**
- [ ] `flutter build appbundle --release` başarılı
- [ ] `apksigner verify --print-certs` çıktısında **`androiddebugkey` GEÇMİYOR**
- [ ] Sertifika SHA-1'i `keytool -list` çıktısıyla **aynı**

## D. Ortam değişkenleri

- [ ] Vercel üretim ortamında `DATABASE_URL` tanımlı
- [ ] `GOOGLE_SERVER_CLIENT_ID` tanımlı (Faz 2 sonrası)
- [ ] `ANTHROPIC_API_KEY` tanımlı (AI Koç çalışsın)
- [ ] `IAP_DEV_ACCEPT` üretimde **TANIMLI DEĞİL**
- [ ] `RATE_LIMIT_DISABLED` üretimde **TANIMLI DEĞİL**
- [ ] `.env.example` dosyalarında **gerçek değer yok**
- [ ] Mobil derleme `--dart-define` değerleri doğru

## E. Firebase / Google Sign-In

- [ ] `google-services.json` doğru konumda ve **doğru projeye ait**
- [ ] **Üç** SHA parmak izi Firebase'de: debug · upload · **Play App Signing**
- [ ] Uygulamada `serverClientId` = **Web** istemci kimliği (Android değil)
- [ ] Sunucu `idToken`'ı doğruluyor (imza · `aud` · `iss` · `exp` · `email_verified`)
- [ ] OAuth onay ekranındaki test kullanıcıları listesi güncel
- [ ] **Play'den kurulan yapıda** Google girişi denendi

## F. Ödeme

- [ ] Play'de ürün(ler) **etkin** ve kimlikleri koddakiyle birebir
- [ ] Lisans test hesapları tanımlı
- [ ] Satın alma akışı Play'den kurulan yapıda çalıştı
- [ ] **"Satın Alımı Geri Yükle"** çalışıyor (sil → kur → geri yükle)
- [ ] Anahtarsız derlemede uygulama **çökmüyor**, dürüst durum gösteriyor
- [ ] RevenueCat webhook/Pub/Sub bağlı (abonelik kullanılıyorsa)

## G. Play Console beyanları

- [ ] Gizlilik politikası URL'si **erişilebilir**
- [ ] Uygulama erişimi: **çalışan** incelemeci hesabı verildi ve sınandı
- [ ] Reklam beyanı: Hayır
- [ ] İçerik derecelendirme anketi dolduruldu — **kullanıcı üretimi içerik: Evet**
- [ ] Hedef kitle: 18+ · çocuklara yönelik değil
- [ ] **Veri Güvenliği formu koddaki gerçek davranışla birebir**
      (Faz 7 avatar eklendiyse **fotoğraf satırı güncellendi**)
- [ ] Yapay zekâ beyanı yapıldı; uygunsuz çıktı bildirme yolu var
- [ ] İzin listesi yalnız `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED`
      (yeni izin eklendiyse **gerekçesi yazıldı**)

## H. Mağaza listesi

- [ ] Uygulama simgesi 512×512 PNG
- [ ] **Öne Çıkan Grafik 1024×500** yüklendi
- [ ] En az 2 telefon ekran görüntüsü (güncel arayüzden)
- [ ] Kısa açıklama ≤ 80 karakter · tam açıklama ≤ 4000
- [ ] Kategori: Eğitim · iletişim e-postası girildi

## I. Cihaz doğrulaması (gerçek donanım)

- [ ] Soğuk açılış çalışıyor, ilk ekran anlamlı
- [ ] Tanıtım → karşılama → ana sayfa zinciri **kaydırmasız**
- [ ] Giriş (Google + e-posta) çalışıyor
- [ ] Ders · işaret · araç · kabin · video yüzeyleri açılıyor
- [ ] Video oynuyor; altyazı/bölüm/tam ekran çalışıyor
- [ ] AI Koç yanıtı **akarak** geliyor
- [ ] Topluluk: katılma, sıralama, mesaj, engelleme, şikâyet
- [ ] Profil avatarı yükleme (Faz 7)
- [ ] **Uçak modunda çökme yok**, dürüst hata durumu
- [ ] Açık **ve** koyu temada tarama yapıldı
- [ ] Ekran döndürme bozulma yapmıyor

## J. Üretim hijyeni

- [ ] Üretim veritabanında **test artığı yok**
      (`AyseE9`, `BurakE9`, `CemE9`, `E8 Dogrulama`, `Cihaz Dogrulama Ekibi` …)
- [ ] Üretim uçları sağlıklı: `/api/community/leaderboard` → 401,
      `/api/mobile/content-snapshot` → 200
- [ ] **Şemaya dokunan bir yayın yapıldıysa canlı uç gerçekten çağrıldı**
      (E10 dersi: CI yeşil olması üretimin ayakta olduğu anlamına gelmez)

## K. Belgeler

- [ ] Faz raporu yazıldı (`BETA_PHASE_<N>_REPORT.md`)
- [ ] `MOBILE_PROJECT_MEMORY.md`'ye **eklendi** (üzerine yazılmadı)
- [ ] Bilinen sınırlar dürüstçe yazıldı — hiçbiri sahte "tamamlandı" ile kapatılmadı

---

## Son kontrol — yükleme öncesi üç soru

1. **İncelemeci uygulamaya girebiliyor mu?** (test hesabı gerçekten çalışıyor mu?)
2. **Veri Güvenliği formu kodun yaptığıyla aynı şeyi mi söylüyor?**
3. **AAB debug anahtarıyla mı imzalı?** (`apksigner` çıktısına bak — tahmin etme.)

Bu üçü, kapalı test retlerinin büyük çoğunluğunun sebebidir.
