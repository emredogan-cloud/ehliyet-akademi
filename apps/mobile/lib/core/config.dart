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
}
