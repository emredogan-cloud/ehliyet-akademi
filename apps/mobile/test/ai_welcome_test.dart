import 'package:ehliyet_akademi/features/home/widgets/ai_welcome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Beta R1 — Ana Sayfa'da açılan AI karşılama popup'ı.
///
/// Ürün sahibi geri bildirimi: tanıtım onboarding'e **sayfa eklemez**. Kullanıcı önce Ana
/// Sayfa'yı görür; popup ondan **sonra** açılır ve kapandıktan sonra **bir daha görünmez**.
void main() {
  group('açılma anı', () {
    testWidgets('Ana Sayfa GÖRÜNDÜKTEN SONRA açılır', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, aiWelcomeSeen: false);

      // Ana Sayfa gerçekten arkada duruyor — popup onun ÜSTÜNE geliyor.
      expect(find.text('Bugün de çalışalım'), findsOneWidget);
      expect(find.byType(AiWelcomeDialog), findsOneWidget);
      // "Hoş geldin!" Ana Sayfa'daki koç kartında da geçiyor → arama DİYALOĞA daraltılır.
      expect(
        find.descendant(of: find.byType(AiWelcomeDialog), matching: find.text('Hoş geldin!')),
        findsOneWidget,
      );
    });

    testWidgets('görülmüşse HİÇ açılmaz', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester); // varsayılan: görülmüş
      expect(find.byType(AiWelcomeDialog), findsNothing);
      expect(find.text('Bugün de çalışalım'), findsOneWidget);
    });

    testWidgets('onboarding’e SAYFA EKLENMEDİ — tanıtım akışı bozulmadı', (tester) async {
      // Geri bildirimin özü: karşılama, onboarding'i uzatmamalı.
      await useTallSurface(tester);
      await pumpApp(tester, onboardingSeen: false, aiWelcomeSeen: false);
      expect(find.byType(AiWelcomeDialog), findsNothing, reason: 'tanıtımda popup olmaz');
      expect(find.text('Devam'), findsOneWidget); // onboarding ilk sayfası
    });
  });

  group('içerik — beş tanıtım', () {
    testWidgets('AI Koç · öğrenme · öneriler · topluluk · premium', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, aiWelcomeSeen: false);

      expect(find.text('AI Koç yanında'), findsOneWidget);
      expect(find.text('Öğrenme sistemi'), findsOneWidget);
      expect(find.text('Sana özel öneriler'), findsOneWidget);
      expect(find.text('Topluluk'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
    });
  });

  group('doğal kapanış — ve BİR DAHA açılmaz', () {
    testWidgets('CTA ile kapanır', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, aiWelcomeSeen: false);

      await tester.tap(find.text('Hadi başlayalım'));
      await tester.pumpAndSettle();

      expect(find.byType(AiWelcomeDialog), findsNothing);
      expect(find.text('Bugün de çalışalım'), findsOneWidget);
    });

    testWidgets('ZEMİNE dokununca da kapanır — kullanıcı hapsedilmez', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, aiWelcomeSeen: false);

      // Diyaloğun dışına dokun (sol üst köşe).
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(find.byType(AiWelcomeDialog), findsNothing);
    });

    testWidgets('GERİ TUŞU ile kapanır', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, aiWelcomeSeen: false);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(AiWelcomeDialog), findsNothing);
    });
  });

  group('düzen', () {
    // NOT: genişlik 800'de bırakılır. 360 px'te ARKADAKİ Ana Sayfa, testlerin Ahem yazı tipi
    // gerçeğinden geniş olduğu için taşıyor (Faz 6'da ölçüldü; cihazda 393 dp'de taşma YOK).
    // Buradaki risk diyaloğun DİKEY bütçesidir — onu ölçüyoruz.
    testWidgets('kısa ekranda taşmaz (640 dp yükseklik)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester, aiWelcomeSeen: false);

      expect(find.byType(AiWelcomeDialog), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'taşma/hata olmamalı');
      // CTA her koşulda erişilebilir olmalı.
      expect(find.text('Hadi başlayalım'), findsOneWidget);
    });

    testWidgets('büyük yazı tipinde de taşmaz (640 dp · 1.3×)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 640));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.binding.setSurfaceSize(null);
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await pumpApp(tester, aiWelcomeSeen: false);

      expect(find.byType(AiWelcomeDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
