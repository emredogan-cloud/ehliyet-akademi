/// App configuration. The API base URL is overridable at build time:
/// `flutter build apk --dart-define=API_BASE_URL=https://staging.example.com`.
class AppConfig {
  const AppConfig._();

  /// Production API (the live Next.js backend). Bearer-token auth for mobile.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://www.ehliyetegitim.com',
  );

  /// Android application id — sent to `/api/iap/validate` for Play purchase verification.
  static const String androidPackage = 'com.ehliyetegitim.ehliyet_akademi';

  /// Beta Faz 3 — uygulamanın sorduğu TEK RevenueCat yetkisi (entitlement).
  ///
  /// Ömür boyu paket de, aylık/yıllık abonelik de **aynı** yetkiyi açar; böylece ürün modeli
  /// değişse bile uygulama kodu değişmez (`REVENUECAT_SETUP.md` §0 ve §3.1). RevenueCat
  /// yapılandırılmamışsa bu değer hiç kullanılmaz.
  static const String revenueCatEntitlement = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT',
    defaultValue: 'premium',
  );
}
