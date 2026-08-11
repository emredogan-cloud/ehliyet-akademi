import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Yayın öncesi uyum korumaları — kaynak düzeyinde, gerileme önleyici.
///
/// Buradaki üç şeyin ortak özelliği: **kırıldıklarında hiçbir hata vermemeleri.**
/// · `INTERNET` izni düşerse uygulama derlenir, açılır, yalnız hiçbir içerik gelmez.
/// · Yasal bağlantı silinirse hiçbir test kırılmaz, yalnız Play politikası ihlal edilir.
/// · AI bildirim düğmesi kaldırılırsa uygulama sorunsuz çalışır, yalnız üretken yapay zekâ
///   politikası karşılanmaz.
///
/// Sessizce kırılan şeyler için otomatik koruma tek çaredir.
void main() {
  String read(String relative) => File(relative).readAsStringSync();

  group('Android manifesto', () {
    test('INTERNET izni ANA manifestoda açıkça bildirilir', () {
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      expect(
        manifest.contains('android.permission.INTERNET'),
        isTrue,
        reason:
            'INTERNET izni yalnız debug/profile manifestolarındaydı ve sürüm derlemesine '
            'google_sign_in_android eklentisinden birleşerek giriyordu. Eklenti değişirse '
            'sürüm derlemesi ağ erişimini SESSİZCE kaybeder.',
      );
    });

    /// Gizlilik Politikası §1: "hesap açmazsanız ilerlemeniz YALNIZ CİHAZINIZDA kalır."
    ///
    /// `allowBackup` bildirilmezse Android varsayılanı **true**'dur ve sistem misafir
    /// kullanıcının `shared_preferences` verisini Google Drive'a yükler — yani beyan ile
    /// davranış ayrılırdı. Bayrak sessizce düşerse hiçbir test kırılmaz, hiçbir hata çıkmaz;
    /// bu yüzden koruma kaynak düzeyinde durur.
    test('otomatik yedekleme kapalı ve her iki kanal da dışlanmış', () {
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      expect(
        manifest.contains('android:allowBackup="false"'),
        isTrue,
        reason:
            'allowBackup bildirilmezse varsayılan true olur ve misafir ilerlemesi '
            'kullanıcının Google Drive hesabına yüklenir — Gizlilik Politikası §1 ile çelişir.',
      );
      expect(
        manifest.contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
        isTrue,
        reason:
            'Android 12+ için gerekli: allowBackup="false" yalnız bulut yedeğini kapatır, '
            'cihazdan cihaza aktarım ayrı kanaldır ve açık kalır.',
      );

      // Kural dosyaları gerçekten var mı ve İKİ kanalı da dışlıyor mu?
      final rules = read('android/app/src/main/res/xml/data_extraction_rules.xml');
      expect(rules.contains('<cloud-backup>'), isTrue);
      expect(rules.contains('<device-transfer>'), isTrue);
      expect(File('android/app/src/main/res/xml/backup_rules.xml').existsSync(), isTrue);
    });

    test('beklenmedik hassas izin yok', () {
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      for (final banned in [
        'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION',
        'CAMERA',
        'RECORD_AUDIO',
        'READ_CONTACTS',
        'READ_SMS',
        'READ_EXTERNAL_STORAGE',
        'READ_MEDIA_IMAGES',
        'QUERY_ALL_PACKAGES',
        'AD_ID',
      ]) {
        expect(
          manifest.contains(banned),
          isFalse,
          reason: '$banned bildirildi — Veri Güvenliği beyanı bunu kapsamıyor.',
        );
      }
    });
  });

  group('uygulama içi uyum arayüzü', () {
    test('Profil ekranı gizlilik ve KVKK bağlantılarını taşır', () {
      final profile = read('lib/features/profile/profile_screen.dart');
      expect(profile.contains('Gizlilik Politikası'), isTrue);
      expect(profile.contains('KVKK'), isTrue);
      expect(profile.contains('/gizlilik'), isTrue);
      expect(profile.contains('/kvkk'), isTrue);
    });

    test('AI Koç ekranı yanıt bildirme yolu sunar', () {
      final coach = read('lib/features/coach/coach_screen.dart');
      expect(coach.contains('Bu yanıtı bildir'), isTrue);
      expect(coach.contains('aiReportApiProvider'), isTrue);
    });

    test('AI Koç kalıcı uyarısı yerinde duruyor', () {
      final coach = read('lib/features/coach/coach_screen.dart');
      // Bu dize mağaza görsellerinde ve gizlilik politikasında da alıntılanıyor; değişirse
      // üç yer birden tutarsızlaşır.
      expect(
        coach.contains('kesin ve güncel kural için MEB/MTSK esastır'),
        isTrue,
      );
    });
  });
}
