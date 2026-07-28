import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Uygulamanın **gerçek** sürüm kimliği — sabit yazılmış değil, kurulu paketten okunur.
///
/// NEDEN GEREKLİ (GOOGLE_PLAY_SIGNIN_ROOT_CAUSE.md):
/// Profil ekranı `'v1.0 (geliştirme)'` dizesini SABİT gösteriyordu. Sonuç: bir test kullanıcısı
/// "Google girişi çalışmıyor" dediğinde, cihazındaki yapının hangi sürüm olduğu **öğrenilemiyordu**.
/// Bu, "Play eski bir yapı mı sunuyor?" sorusunu yanıtsız bırakıyor ve USB ile Play arasındaki
/// farkı teşhis etmeyi imkânsız kılıyordu.
///
/// `versionCode` (derleme numarası) burada kritik olandır: Play'e yüklenen her AAB'nin numarası
/// artar, dolayısıyla cihazdaki numara **hangi AAB'nin çalıştığını kesin olarak söyler**.
class AppVersion {
  const AppVersion({required this.name, required this.build});

  /// `1.0.0` — kullanıcıya anlamlı sürüm.
  final String name;

  /// `3` — Play'e yüklenen AAB'nin sürüm kodu. Teşhisin can alıcı parçası.
  final String build;

  /// Profil ekranında ve "Hakkında" penceresinde gösterilen tek biçim.
  String get label => 'v$name ($build)';

  /// Okunamazsa uygulama ÇÖKMEZ; dürüst bir yer tutucu döner.
  static const AppVersion unknown = AppVersion(name: '?', build: '?');

  static AppVersion? _cached;

  /// Kurulu paketten okur ve önbelleğe alır.
  static Future<AppVersion> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final info = await PackageInfo.fromPlatform();
      final v = AppVersion(name: info.version, build: info.buildNumber);
      _cached = v;
      return v;
    } catch (_) {
      // Platform kanalı yoksa (widget testi) veya okuma başarısızsa: çökme değil, yer tutucu.
      return unknown;
    }
  }

  /// Testlerin gerçek platforma gitmeden değer verebilmesi için.
  @visibleForTesting
  static void setForTest(AppVersion? v) => _cached = v;
}
