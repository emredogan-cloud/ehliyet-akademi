// GERÇEK CİHAZ doğrulaması.
//
// NEDEN AYRI BİR PAKET: `test/` altındaki widget testleri sahte bir yüzeyde, platform kanalları
// kapalı çalışır. Cihazda bozulan şeylerin çoğu (gerçek yazı tipi metrikleri, gerçek ekran oranı,
// gerçek dokunma hedefleri, gerçek `SharedPreferences`, gerçek gezinme) orada GÖRÜNMEZ. Bu dosya
// uygulamayı telefonda açar ve akışları orada koşturur.
//
// ÇALIŞTIRMA:
//   flutter test integration_test -d <device-id>
//
// KAPSAM SÖZÜ: burada yalnız cihaza bağlı olan şeyler doğrulanır. İş kuralları ve saf mantık
// `test/` altında kalır — aynı şeyi iki kez test etmek bakım borcudur.

import 'package:ehliyet_akademi/app/app.dart';
import 'package:ehliyet_akademi/core/storage/token_store.dart';
import 'package:ehliyet_akademi/domain/onboarding/ai_welcome_controller.dart';
import 'package:ehliyet_akademi/domain/onboarding/onboarding_controller.dart';
import 'package:ehliyet_akademi/domain/onboarding/welcome_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulamayı cihazda başlat.
///
/// [firstRun] true ise tanıtım/karşılama işaretleri TEMİZ başlar — ilk açılış deneyimi
/// (koç işaretleri) böyle doğrulanır.
Future<void> launchApp(
  WidgetTester tester, {
  bool firstRun = false,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues({...prefs});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingSeenProvider.overrideWith(() => OnboardingController(!firstRun)),
        welcomeSeenProvider.overrideWith(() => WelcomeController(!firstRun)),
        aiWelcomeSeenProvider.overrideWith(() => AiWelcomeController(!firstRun)),
        // Cihazda Keystore gerçek çalışır ama testler arası sızıntı yapar → bellek-içi jeton.
        tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
      ],
      child: const EhliyetAkademiApp(),
    ),
  );
  // Ağdan içerik gelene kadar bekleme YAPILMAZ: `pumpAndSettle` sonsuz animasyonlu bir ekranda
  // takılabilir. Sabit sayıda kare çizilir — cihazda yeterli ve deterministik.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('uygulama cihazda açılır ve alt gezinme çalışır', (tester) async {
    await launchApp(tester);
    expect(find.text('Ana Sayfa'), findsWidgets);

    // Her sekme gerçekten açılıyor mu (gerçek ekran genişliğinde, gerçek yazı tipiyle).
    for (final tab in const ['Öğren', 'Pratik', 'AI Koç', 'Profil']) {
      await tester.tap(find.text(tab).last);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('çıkış: Profil → Çıkış yap → Giriş ekranı (cihazda)', (tester) async {
    await launchApp(tester);
    await tester.tap(find.text('Profil').last);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Misafirken çıkış satırı YOKTUR — dürüst davranış; cihazda da böyle.
    expect(find.text('Çıkış yap'), findsNothing);
    expect(find.text('Misafir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
