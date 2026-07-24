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

  // Illustration heroes
  static const illTarget = '$_base/ill_target.webp'; // session results success
  static const illFolder = '$_base/ill_folder.webp'; // collections
  static const illPapers = '$_base/ill_papers.webp'; // past exams
  static const illDashboard = '$_base/ill_dashboard.webp'; // turn-signal (exam illustration)
  static const illWheelCheck = '$_base/ill_wheel_check.webp'; // premium success
  static const illLockGold = '$_base/ill_lock_gold.webp'; // premium incentive
}
