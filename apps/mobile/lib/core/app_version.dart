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

  /// Platform kanalının cevap vermesi için tanınan süre.
  ///
  /// NEDEN BİR SINIR VAR (Beta Faz 3'te ölçülerek bulundu): `PackageInfo.fromPlatform()` cevap
  /// vermeyen bir kanalda **hiç tamamlanmaz** — hata da fırlatmaz, sonsuza kadar bekler. Bu, tek
  /// başına zararsız görünen bir ayrıntı değildi: analitik bağlamı sürümü beklediği için
  /// `Analytics.log` hiçbir olayı gönderemez hâle geliyordu. Ölçüm, ölçtüğü şeyin en kırılgan
  /// parçasına bağlanmamalı.
  ///
  /// İki saniye, gerçek bir soğuk açılışta bolca yeterlidir; aşılırsa sürüm etiketi "?" olur ve
  /// ürünün geri kalanı çalışmaya devam eder.
  static const Duration loadTimeout = Duration(seconds: 2);

  /// Kurulu paketten okur ve önbelleğe alır.
  ///
  /// Başarısızlık ya da zaman aşımı **önbelleğe alınmaz**: kanal sonradan hazır olabilir ve bir
  /// sonraki çağrı gerçek sürümü yakalayabilir.
  static Future<AppVersion> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final info = await PackageInfo.fromPlatform().timeout(loadTimeout);
      final v = AppVersion(name: info.version, build: info.buildNumber);
      _cached = v;
      return v;
    } catch (_) {
      // Platform kanalı yoksa (widget testi), yavaşsa ya da okuma başarısızsa: çökme/askıda
      // kalma değil, dürüst bir yer tutucu.
      return unknown;
    }
  }

  /// Testlerin gerçek platforma gitmeden değer verebilmesi için.
  @visibleForTesting
  static void setForTest(AppVersion? v) => _cached = v;
}
