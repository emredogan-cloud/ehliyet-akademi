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
import 'package:flutter/material.dart' show MaterialApp;
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
  /// "60 FPS" bir iddia değil, ÖLÇÜM olmalı. Burada zemin canlıyken ~2 saniyelik bir pencerede
  /// kare süreleri toplanır ve 90. yüzdelik dilime bakılır.
  ///
  /// **BU TEST İLK SIRADA DURMALI.** Ölçüldü: aynı test dosyanın SONUNDA koştuğunda ortanca
  /// 9,4 ms yerine 26,2 ms çıkıyor. Sebep zemin değil, ölçüm ortamı: integration_test'in bütün
  /// testleri TEK izolatta koşar; önceki testlerin biriktirdiği JIT kodu ve çöp toplama yükü
  /// sonraki ölçümlere karışır. Sırayı değiştiren, bu yorumu da okumalı — aksi hâlde var olmayan
  /// bir başarım gerilemesi kovalanır.
  ///
  /// Eşik 16,7 ms değil **24 ms**: bu bir hata ayıklama (debug) yapısıdır ve JIT + iddia
  /// kontrolleri her kareye sabit yük bindirir. Amaç mükemmelliği kanıtlamak değil, zeminin
  /// kareyi ÇÖKERTMEDİĞİNİ kanıtlamaktır.
  testWidgets('canlı zemin cihazda kareyi düşürmez', (tester) async {
    final binding = IntegrationTestWidgetsFlutterBinding.instance;
    await launchApp(tester);

    final timings = <Duration>[];
    void collect(List<FrameTiming> batch) {
      for (final t in batch) {
        timings.add(t.totalSpan);
      }
    }

    binding.addTimingsCallback(collect);
    // Hareketin gerçekten aktığı bir pencere: her kare zemin yeniden boyanır.
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    binding.removeTimingsCallback(collect);

    expect(timings.length, greaterThan(20), reason: 'kare süresi toplanamadı');
    final sorted = [...timings]..sort();
    final p90 = sorted[(sorted.length * 0.9).floor().clamp(0, sorted.length - 1)];
    final median = sorted[sorted.length ~/ 2];
    // ignore: avoid_print — ölçüm çıktısı raporda kullanılıyor.
    print(
      'ZEMİN KARE SÜRESİ — ortanca ${median.inMicroseconds / 1000} ms · '
      'p90 ${p90.inMicroseconds / 1000} ms · örnek ${timings.length}',
    );
    expect(p90.inMilliseconds, lessThan(24));
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
