import 'package:ehliyet_akademi/features/onboarding/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Evolution Faz E7 — karşılama anı: tanıtım → karşılama → ana sayfa zinciri, tek seferlik olması
/// ve ekranda yazan değerlerin kaydedilmiş profille birebir aynı olması.
void main() {
  /// Kişiselleştirmeyi baştan sona tamamlar (varsayılan seçimlerle) ve karşılamada bırakır.
  Future<void> completeOnboarding(WidgetTester tester) async {
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Koç ile Başla'));
    await tester.pumpAndSettle();
  }

  group('yönlendirme zinciri', () {
    testWidgets('tanıtım tamamlanınca ANA SAYFA değil KARŞILAMA gelir', (tester) async {
      await pumpApp(tester, onboardingSeen: false, welcomeSeen: false);
      expect(find.text('Devam'), findsOneWidget); // tanıtım

      await completeOnboarding(tester);

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Her şey hazır!'), findsOneWidget);
      expect(find.text('Bugün de çalışalım'), findsNothing); // henüz ana sayfa değil
    });

    testWidgets('karşılamadan devam edilince ana sayfaya geçilir', (tester) async {
      await pumpApp(tester, onboardingSeen: false, welcomeSeen: false);
      await completeOnboarding(tester);

      await tester.tap(find.text('Çalışmaya başla'));
      await tester.pumpAndSettle();

      expect(find.text('Bugün de çalışalım'), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('"Atla" karşılamayı da atlar — seçilmemiş değerler özetlenmez', (tester) async {
      await pumpApp(tester, onboardingSeen: false, welcomeSeen: false);
      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.text('Bugün de çalışalım'), findsOneWidget);
    });

    testWidgets('tanıtımı görmüş ama karşılamayı görmemiş kullanıcı karşılamaya iner', (
      tester,
    ) async {
      await pumpApp(tester, welcomeSeen: false);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Bugün de çalışalım'), findsNothing);
    });

    testWidgets('ikinci açılışta karşılama GÖSTERİLMEZ (tek seferlik)', (tester) async {
      await pumpApp(tester); // her iki işaret de görülmüş
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.text('Bugün de çalışalım'), findsOneWidget);
    });

    testWidgets('karşılamada "Atla" da ana sayfaya götürür', (tester) async {
      await pumpApp(tester, welcomeSeen: false);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();
      expect(find.text('Bugün de çalışalım'), findsOneWidget);
    });
  });

  group('özet değerleri kaydedilen profille birebir aynı', () {
    testWidgets('kullanıcının seçtiği sınıf, sınav, tempo ve günlük hedef görünür', (tester) async {
      await pumpApp(tester, onboardingSeen: false, welcomeSeen: false);
      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();

      // Adım 1: A sınıfı
      await tester.tap(find.text('Motosiklet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      // Adım 2 → 3
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      // Adım 3: yalnız e-Sınav kalsın (Direksiyon seçimini kaldır)
      await tester.tap(find.text('Direksiyon\nSınavı'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      // Adım 4: 1 haftadan az → yoğun tempo, günlük 30 → oturum 25 (clamp)
      await tester.tap(find.text('1 Haftadan Az'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Koç ile Başla'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('A · Motosiklet'), findsOneWidget);
      expect(find.text('e-Sınav (Trafik)'), findsOneWidget);
      expect(find.text('Yoğun tempo'), findsOneWidget);
      expect(find.text('25 soru'), findsOneWidget);
    });

    testWidgets('varsayılan seçimlerle özet varsayılan profili yansıtır', (tester) async {
      await pumpApp(tester, onboardingSeen: false, welcomeSeen: false);
      await completeOnboarding(tester);

      expect(find.text('B · Otomobil'), findsOneWidget);
      expect(find.text('e-Sınav + Direksiyon'), findsOneWidget);
      expect(find.text('Düzenli tempo'), findsOneWidget);
      expect(find.text('20 soru'), findsOneWidget);
    });
  });

  group('düzen', () {
    testWidgets('karşılama küçük telefonda da kaydırmasız sığar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester, welcomeSeen: false);

      expect(find.byType(WelcomeScreen), findsOneWidget);
      var checked = 0;
      for (final element in find.byType(Scrollable).evaluate()) {
        final position = ((element as StatefulElement).state as ScrollableState).position;
        if (!position.hasContentDimensions || position.axis != Axis.vertical) continue;
        checked++;
        expect(position.maxScrollExtent, 0, reason: 'karşılama içeriği sığmıyor');
      }
      expect(checked, greaterThan(0));
      expect(tester.takeException(), isNull);
      // İlerleme düğmesi her zaman görünür.
      expect(find.text('Çalışmaya başla'), findsOneWidget);
    });
  });
}
