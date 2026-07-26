/// Bundled illustration + mascot catalog. All are background-keyed transparent WebP (optimized
/// from the supplied `apps/assets/interface-assets/` PNGs) so they composite seamlessly on the
/// app's dark surfaces. See MOBILE_UI_REDESIGN_REPORT.md for the source→asset mapping.
class AppImages {
  const AppImages._();

  static const _base = 'assets/img';

  // Onboarding heroes
  static const onbWelcome = '$_base/onb_welcome.webp'; // cap + book + orbiting icons
  static const onbThink = '$_base/onb_think.webp'; // student thinking (exam-before step)
  static const onbWheel = '$_base/onb_wheel.webp'; // steering wheel (Direksiyon card)
  static const onbTablet = '$_base/onb_tablet.webp'; // tablet quiz (e-Sınav card)
  static const onbCalendar = '$_base/onb_calendar.webp'; // calendar + clock (time step)

  // Vehicle photos (licence category cards)
  static const vehicleCar = '$_base/vehicle_car.webp'; // B
  static const vehicleMoto = '$_base/vehicle_moto.webp'; // A
  static const vehicleBus = '$_base/vehicle_bus.webp'; // D

  // Owl mascot poses
  static const owlBookBadge = '$_base/owl_book_badge.webp';
  static const owlWheel = '$_base/owl_wheel.webp'; // home / practice hero
  static const owlReading = '$_base/owl_reading.webp'; // learn hero
  static const owlClipboard = '$_base/owl_clipboard.webp';
  static const owlShield = '$_base/owl_shield.webp'; // profile
  static const owlWave = '$_base/owl_wave.webp'; // coach / AI intro
  static const owlTeacher = '$_base/owl_teacher.webp'; // practice runner

  // Auth hero (Beta Faz 5)
  //
  // Kaynak: `apps/assets/interface-assets/022-assets.png` (1536×1024) — gece İstanbul silueti,
  // sürücü kursu aracı, koniler, trafik işaretleri. **Üst %58'i kırpıldı** (1536×600 → 1080×422):
  // kırpma, aracın ızgarasındaki üçüncü taraf marka amblemini kareden tamamen çıkarır ve
  // kaynağın bilinçli olarak boş bıraktığı sol bölgeyi korur. Gerekçe: BETA_PHASE_5_REPORT.md.
  static const authHero = '$_base/auth_hero.webp';

  // Marka kilidi (Beta R3)
  //
  // Kaynak: `apps/assets/app_icon.png` (1254², **opak** koyu lacivert zeminli). Referans giriş
  // sayfası bu kilidi hero'nun sol üstünde kullanıyor; opak hâliyle bindirilirse görselin
  // üstünde belirgin bir DİKDÖRTGEN kenar oluşuyor. Bu yüzden zemin rengine olan uzaklığa göre
  // yumuşak bir alfa rampasıyla (12→46) anahtarlandı: amblemin koyu yol/araç bölgeleri korunur,
  // düz zemin şeffaflaşır. İçerik kutusuna kırpılıp 760 px'e indirildi.
  static const brandLockup = '$_base/brand_lockup.webp';

  // Illustration heroes
  static const illTarget = '$_base/ill_target.webp'; // session results success
  static const illFolder = '$_base/ill_folder.webp'; // collections
  static const illPapers = '$_base/ill_papers.webp'; // past exams
  static const illDashboard = '$_base/ill_dashboard.webp'; // turn-signal (exam illustration)
  static const illWheelCheck = '$_base/ill_wheel_check.webp'; // premium success
  static const illLockGold = '$_base/ill_lock_gold.webp'; // premium incentive
}
