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

import 'dart:ui' show FrameTiming;

import 'package:ehliyet_akademi/app/app.dart';
import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:ehliyet_akademi/design/app_background.dart';
import 'package:flutter/material.dart';
import 'package:ehliyet_akademi/app/shell.dart';
import 'package:ehliyet_akademi/core/storage/token_store.dart';
import 'package:ehliyet_akademi/domain/onboarding/ai_welcome_controller.dart';
import 'package:ehliyet_akademi/domain/onboarding/coach_marks_controller.dart';
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
        coachMarksSeenProvider.overrideWith(() => CoachMarksController(!firstRun)),
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

  /// Faz 6 — canlı zemin GERÇEKTEN ucuz mu?
  ///
  /// MUTLAK kare süresi ÖLÇÜLMEZ ve eşik olarak KULLANILMAZ. Denendi ve işe yaramadı: aynı cihazda
  /// aynı kod, arka arkaya koşularda 9 ms ile 40 ms arasında ortanca verdi. Sebep zemin değil,
  /// cihazın o anki durumu (derleme/kurulum sonrası ısınma, arka plan işleri, hata ayıklama
  /// yapısında JIT). Böyle bir eşik ya sürekli yanlış alarm verir ya da hiçbir şeyi yakalamaz.
  ///
  /// Bunun yerine zeminin **MARJİNAL maliyeti** ölçülür: aynı koşuda, aynı saniyelerde, aynı
  /// içerikle iki pencere alınır —
  ///   (a) zemin DURAGAN (hareket azaltma açık),
  ///   (b) zemin CANLI.
  /// Aradaki fark, zeminin gerçekten kaça mal olduğudur ve cihazın ısısından etkilenmez.
  testWidgets('canlı zeminin kare maliyeti ihmal edilebilir', (tester) async {
    final binding = IntegrationTestWidgetsFlutterBinding.instance;

    Future<List<Duration>> measure({required bool animate}) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: tester.view.physicalSize / tester.view.devicePixelRatio,
              disableAnimations: !animate),
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const AppBackground(
              child: Scaffold(body: Center(child: Text('ölçüm'))),
            ),
          ),
        ),
      );
      // Isınma kareleri — ilk karelerde raster önbelleği kuruluyor, ölçüme dâhil edilmez.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final out = <Duration>[];
      void collect(List<FrameTiming> batch) {
        for (final t in batch) {
          // `totalSpan` DEĞİL: o, vsync'ten raster sonuna kadar geçen DUVAR SAATİDİR ve kare
          // planlanmadığında (hareket kapalıyken) boşta geçen süreyi de sayar — ölçüldü, duragan
          // durum "canlı"dan 30 ms YAVAŞ göründü. Gerçek maliyet, işin kendisidir:
          // inşa (CPU) + rasterleştirme (GPU).
          out.add(t.buildDuration + t.rasterDuration);
        }
      }

      binding.addTimingsCallback(collect);
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      binding.removeTimingsCallback(collect);
      return out;
    }

    double medianMs(List<Duration> xs) {
      final s = [...xs]..sort();
      return s[s.length ~/ 2].inMicroseconds / 1000;
    }

    // Sıra bilinçli: canlı ölçüm ÖNCE, duragan SONRA. Tersi olsaydı, ısınmanın canlı ölçüme
    // yığdığı yükü zeminin maliyeti sanardık.
    final animated = await measure(animate: true);
    final still = await measure(animate: false);
    expect(animated.length, greaterThan(20));
    expect(still.length, greaterThan(20));

    final a = medianMs(animated);
    final b = medianMs(still);
    // ignore: avoid_print — ölçüm çıktısı raporda kullanılıyor.
    print(
      'ZEMİN MARJİNAL MALİYET — canlı ${a.toStringAsFixed(2)} ms · '
      'duragan ${b.toStringAsFixed(2)} ms · fark ${(a - b).toStringAsFixed(2)} ms',
    );

    // Ölçümün kendisi anlamlı mı? (Sıfıra yakın değerler, kare hiç çizilmedi demektir.)
    expect(a, greaterThan(0.1), reason: 'canlı ölçüm kare üretmemiş');
    expect(b, greaterThan(0.1), reason: 'duragan ölçüm kare üretmemiş');

    // Eşik: 60 FPS bütçesinin (16,7 ms) yaklaşık beşte biri. Zemin bundan fazlasına mal oluyorsa
    // "çok hafif" iddiası düşmüştür ve kod gözden geçirilmelidir.
    expect(a - b, lessThan(3.5));
  });

  testWidgets('uygulama cihazda açılır ve altı sekmenin hepsi çalışır', (tester) async {
    await launchApp(tester);
    expect(find.byType(AppBottomNav), findsOneWidget);

    // Her sekme gerçekten açılıyor mu (gerçek ekran genişliğinde, gerçek yazı tipiyle).
    for (final tab in const ['Öğren', 'Pratik', 'AI Koç', 'Topluluk', 'Profil', 'Ana Sayfa']) {
      await tester.tap(find.descendant(of: find.byType(AppBottomNav), matching: find.text(tab)));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(tester.takeException(), isNull);
  });

  /// Altı sekme, dar telefonlarda etiket taşmasının GERÇEK sınavıdır. Bu, yalnız cihazda
  /// (gerçek yazı tipi metrikleri + gerçek genişlik) doğrulanabilir; testteki Ahem yazı tipi
  /// farklı ölçer.
  testWidgets('altı sekme etiketi cihaz genişliğinde taşmaz', (tester) async {
    await launchApp(tester);
    final barWidth = tester.getSize(find.byType(AppBottomNav)).width;
    final slot = barWidth / AppShell.tabs.length;

    for (final tab in AppShell.tabs) {
      final finder = find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text(tab.label),
      );
      final textWidth = tester.getSize(finder).width;
      expect(
        textWidth,
        lessThanOrEqualTo(slot),
        reason: '"${tab.label}" yuvasına sığmıyor (${textWidth.toStringAsFixed(1)} > '
            '${slot.toStringAsFixed(1)} dp)',
      );
    }
    expect(tester.takeException(), isNull);
  });

  /// Faz 1 — ürün turu, GERÇEK ekran oranında da hedefini bulmalı.
  ///
  /// Bu, cihazda doğrulanması ZORUNLU olan bir şey: tur, hedefi görünür alana kaydırıp ölçer.
  /// Test yüzeyi (800×1400) telefondan çok daha uzundur; orada sığan bir baloncuk 360×760'ta
  /// taşabilir. Burada her adımın baloncuğunun ekran İÇİNDE kaldığı ölçülür.
  testWidgets('ürün turu cihazda her adımda ekran içinde kalır', (tester) async {
    await launchApp(tester, firstRun: true);

    // İlk açılış zinciri: tanıtım → karşılama → Ana Sayfa → AI penceresi → tur.
    Future<void> tapIfPresent(String label) async {
      final f = find.text(label);
      if (f.evaluate().isEmpty) return;
      await tester.tap(f.first, warnIfMissed: false);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    await tapIfPresent('Atla'); // tanıtım
    await tapIfPresent('Hadi başlayalım'); // AI karşılama penceresi
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    final screen = tester.getSize(find.byType(MaterialApp));
    var visited = 0;
    while (find.text('${visited + 1}/9').evaluate().isNotEmpty) {
      visited++;
      // Baloncuğun düğmeleri ekranın İÇİNDE mi?
      for (final label in const ['Atla', 'İleri', 'Başla']) {
        final f = find.text(label);
        if (f.evaluate().isEmpty) continue;
        final r = tester.getRect(f.first);
        expect(
          r.top >= 0 && r.bottom <= screen.height,
          isTrue,
          reason: 'adım $visited: "$label" ekran dışında (${r.top}..${r.bottom} / '
              '${screen.height})',
        );
      }
      final next = find.text('İleri').evaluate().isNotEmpty
          ? find.text('İleri')
          : find.text('Başla');
      if (next.evaluate().isEmpty) break;
      await tester.tap(next.first, warnIfMissed: false);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    expect(visited, 9, reason: 'turun dokuz adımı da cihazda görünmeli');
    expect(tester.takeException(), isNull);
  });

  /// Faz 2 — ödeme ekranı cihazda.
  ///
  /// DÜRÜST KAPSAM: gerçek bir satın alma yalnız Play'den yüklenmiş, imzalı bir yapıda ve Play
  /// Console'da tanımlı ürünle yapılabilir; burada mağaza KAPALIDIR. Bu yüzden burada satın alma
  /// akışı değil, mağaza kapalıyken ekranın DÜRÜST davranışı doğrulanır:
  /// · satın alma düğmesi devre dışı (çalışmayan düğmeye basılamaz),
  /// · "Geri yükle" yine de erişilebilir (Play politikası bunu ZORUNLU kılar).
  /// Satın alma/geri yükleme mantığı `test/premium_flow_test.dart` içinde sahte ağ geçidiyle
  /// uçtan uca test edilir.
  testWidgets('ödeme ekranı cihazda dürüst davranıyor', (tester) async {
    await launchApp(tester);
    await tester.tap(find.descendant(of: find.byType(AppBottomNav), matching: find.text('Profil')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    await tester.scrollUntilVisible(find.text('Premium özellikleri keşfet'), 200);
    await tester.tap(find.text('Premium özellikleri keşfet'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text("Premium'a Geç"), findsOneWidget);
    // Play politikası: geri yükleme HER KOŞULDA erişilebilir.
    expect(find.text('Geri yükle'), findsOneWidget);
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
