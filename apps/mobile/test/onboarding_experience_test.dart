import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:ehliyet_akademi/domain/onboarding/onboarding_insights.dart';
import 'package:ehliyet_akademi/features/onboarding/widgets/coach_insight_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Evolution Faz E6 — onboarding koç maskotu + dönen içgörü kartları + kaydırmasız düzen.
void main() {
  group('içgörü seçimi (saf)', () {
    test('her adımın en az 3 içgörüsü var ve hepsi dolu', () {
      for (var step = 0; step < kOnboardingStepCount; step++) {
        final list = insightsForStep(step);
        expect(list.length, greaterThanOrEqualTo(3), reason: 'adım $step');
        for (final i in list) {
          expect(i.text.length, greaterThan(40), reason: 'adım $step · "${i.text}"');
          // Kart KOMPAKT kalmalı: uzun metin kartı büyütür ve kaydırmasız düzeni bozar (ölçüldü).
          expect(i.text.length, lessThan(95), reason: 'adım $step · çok uzun: "${i.text}"');
          expect(i.text.trim().endsWith('.'), isTrue, reason: 'adım $step · "${i.text}"');
        }
      }
    });

    test('seçim deterministiktir', () {
      for (var step = 0; step < kOnboardingStepCount; step++) {
        for (var tick = 0; tick < 12; tick++) {
          expect(insightAt(step, tick).text, insightAt(step, tick).text);
        }
      }
    });

    test('ardışık iki dönüşte aynı içgörü GELMEZ', () {
      for (var step = 0; step < kOnboardingStepCount; step++) {
        for (var tick = 0; tick < 12; tick++) {
          expect(
            insightAt(step, tick).text,
            isNot(insightAt(step, tick + 1).text),
            reason: 'adım $step · tick $tick',
          );
        }
      }
    });

    test('döngü listenin başına döner', () {
      for (var step = 0; step < kOnboardingStepCount; step++) {
        final n = insightsForStep(step).length;
        expect(insightAt(step, 0).text, insightAt(step, n).text);
      }
    });

    test('her adım kendi içgörü kümesini alır (adımlar birbirinden farklı)', () {
      final firstTexts = [
        for (var s = 0; s < kOnboardingStepCount; s++) insightAt(s, 0).text,
      ];
      expect(firstTexts.toSet().length, kOnboardingStepCount);
    });

    test('tanımsız adım boş liste değil, karşılama setini döner', () {
      expect(insightsForStep(99), insightsForStep(0));
      expect(insightsForStep(-1), isNotEmpty);
    });

    test('her içgörü türü en az bir kez kullanılır', () {
      final used = <InsightKind>{};
      for (var s = 0; s < kOnboardingStepCount; s++) {
        used.addAll(insightsForStep(s).map((i) => i.kind));
      }
      expect(used.length, InsightKind.values.length);
    });
  });

  group('koç kartı dönüşü', () {
    testWidgets('hareket açıkken kart süre dolunca değişir, kapanınca sabit kalır', (tester) async {
      // Hareket AÇIK — zamanı elle ilerletiyoruz (pumpAndSettle kullanılmaz: dönen zamanlayıcı var).
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      await tester.pumpWidget(
        const _Host(child: CoachInsightCard(step: 0, rotation: Duration(seconds: 3))),
      );
      expect(find.text(insightAt(0, 0).text), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300)); // geçiş animasyonu
      expect(find.text(insightAt(0, 1).text), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(insightAt(0, 2).text), findsOneWidget);

      // Widget'ı kaldır → zamanlayıcı iptal edilmeli (aksi hâlde test "pending timer" ile patlar).
      await tester.pumpWidget(const _Host(child: SizedBox.shrink()));
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('hareket azaltma açıkken kart DÖNMEZ', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      await tester.pumpWidget(
        const _Host(child: CoachInsightCard(step: 2, rotation: Duration(seconds: 3))),
      );
      expect(find.text(insightAt(2, 0).text), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      expect(find.text(insightAt(2, 0).text), findsOneWidget);
      expect(find.text(insightAt(2, 1).text), findsNothing);
    });
  });

  group('kaydırmasız düzen', () {
    /// Onboarding'in bu adımındaki tüm kaydırma alanlarının kaydırma payı 0 olmalı
    /// (içerik sığıyor → kaydırma gerekmiyor) ve hiçbir taşma hatası oluşmamalı.
    void expectNoScroll(WidgetTester tester, String label) {
      // Yalnız DİKEY gövde kaydırıcıları ölçülür; adımlar arası yatay PageView bu ölçütün konusu
      // değildir (kullanıcı zaten CTA ile ilerler, elle kaydırılamaz).
      var checked = 0;
      for (final element in find.byType(Scrollable).evaluate()) {
        final state = element as StatefulElement;
        final position = (state.state as ScrollableState).position;
        if (!position.hasContentDimensions || position.axis != Axis.vertical) continue;
        checked++;
        expect(
          position.maxScrollExtent,
          0,
          reason:
              '$label: içerik sığmıyor · görünen ${position.viewportDimension.toStringAsFixed(0)} '
              'px, içerik ${(position.viewportDimension + position.maxScrollExtent).toStringAsFixed(0)} px '
              '(fazla ${position.maxScrollExtent.toStringAsFixed(0)})',
        );
      }
      expect(checked, greaterThan(0), reason: '$label: dikey kaydırma alanı bulunamadı');
      expect(tester.takeException(), isNull, reason: '$label: taşma/hata');
    }

    Future<void> runFlow(WidgetTester tester, String label) async {
      await pumpApp(tester, onboardingSeen: false);
      expectNoScroll(tester, '$label · karşılama');

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      for (var step = 1; step <= 4; step++) {
        expectNoScroll(tester, '$label · adım $step');
        await tester.tap(find.text('Devam Et'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Koç ile Başla'), findsOneWidget);
      expectNoScroll(tester, '$label · AI Koç');
    }

    testWidgets('küçük telefon (360×640)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await runFlow(tester, 'küçük telefon');
    });

    testWidgets('büyük yazı tipi (360×640 · 1.3×)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.binding.setSurfaceSize(null);
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await runFlow(tester, 'büyük yazı');
    });

    // Gerçek doğrulama cihazının KULLANILABİLİR alanı (Redmi 1080×2340 @2.75 → 393×851 dp,
    // durum + gezinme çubukları düşünce ≈ 393×780). Bu ölçü testte sabitlenmezse cihazda
    // kaydırma oluşup oluşmadığını yalnız gözle görebilirdik.
    testWidgets('gerçek cihaz ölçüsü (393×780)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await runFlow(tester, 'gerçek cihaz');
    });

    testWidgets('yatay (740×360)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(740, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await runFlow(tester, 'yatay');
    });
  });

  group('koç her adımda görünür', () {
    testWidgets('her onboarding adımında bir içgörü kartı vardır', (tester) async {
      await pumpApp(tester, onboardingSeen: false);
      expect(find.byType(CoachInsightCard), findsOneWidget);
      expect(find.text(insightAt(0, 0).text), findsOneWidget);

      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      for (var step = 1; step <= 4; step++) {
        expect(find.byType(CoachInsightCard), findsOneWidget, reason: 'adım $step');
        expect(find.text(insightAt(step, 0).text), findsOneWidget, reason: 'adım $step');
        await tester.tap(find.text('Devam Et'));
        await tester.pumpAndSettle();
      }
      expect(find.byType(CoachInsightCard), findsOneWidget);
      expect(find.text(insightAt(5, 0).text), findsOneWidget);
    });
  });
}

/// Kartı tek başına barındıran küçük iskele (tam uygulamayı kurmadan).
class _Host extends StatelessWidget {
  const _Host({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(16), child: child))),
    );
  }
}
