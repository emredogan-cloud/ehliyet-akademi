import 'package:ehliyet_akademi/core/assets.dart';
import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:ehliyet_akademi/design/living_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ürün Evrimi v1.1 · Faz 6 — yaşayan koç.
///
/// Animasyonun "güzel" olduğu test edilemez; ÖLÇÜLEBİLİR olan üç şey test edilir:
/// 1. Hareket gerçekten var (dönüşüm kareler arasında değişiyor).
/// 2. Hareket azaltıldığında HİÇ yok (dönüşüm sarmalayıcısı bile kurulmuyor).
/// 3. Döngü mekanik değil — periyotlar birbirine bölünmüyor.

Widget _host(Widget child, {bool reduceMotion = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduceMotion),
  child: MaterialApp(theme: AppTheme.light(), home: Scaffold(body: Center(child: child))),
);

/// Maskotun KENDİ ürettiği dönüşüm — uygulama kabuğundakiler sayılmaz.
Finder _ownTransforms() =>
    find.descendant(of: find.byType(LivingMascot), matching: find.byType(Transform));

Matrix4? _transform(WidgetTester tester) {
  final t = tester.widgetList<Transform>(_ownTransforms());
  return t.isEmpty ? null : t.first.transform;
}

void main() {
  testWidgets('hareket var — dönüşüm kareler arasında değişiyor', (tester) async {
    await tester.pumpWidget(_host(const LivingMascot(AppImages.owlWave, height: 120)));
    await tester.pump(const Duration(milliseconds: 100));
    final a = _transform(tester);
    await tester.pump(const Duration(milliseconds: 500));
    final b = _transform(tester);

    expect(a, isNotNull, reason: 'hareket açıkken dönüşüm sarmalayıcısı olmalı');
    expect(b, isNot(equals(a)), reason: 'maskot donmuş görünüyor');

    // Sonsuz döngüyü tester'a bırakma.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hareket azaltıldığında hiçbir dönüşüm kurulmaz', (tester) async {
    await tester.pumpWidget(
      _host(const LivingMascot(AppImages.owlWave, height: 120), reduceMotion: true),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      _ownTransforms(),
      findsNothing,
      reason: 'hareket azaltıldığında dönüşüm katmanı hiç oluşturulmamalı',
    );
    expect(
      find.descendant(of: find.byType(LivingMascot), matching: find.byType(Image)),
      findsOneWidget,
      reason: 'maskot yine de görünmeli',
    );
  });

  testWidgets('dikkat durumu ölçeği değiştirir', (tester) async {
    await tester.pumpWidget(
      _host(const LivingMascot(AppImages.owlWave, height: 120, attentive: false)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final sakin = tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

    await tester.pumpWidget(
      _host(const LivingMascot(AppImages.owlWave, height: 120, attentive: true)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final dikkatli = tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

    expect(dikkatli, greaterThan(sakin));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  /// Üç döngü aynı ya da birbirine bölünen periyotlara sahip olsaydı hareket birkaç saniyede
  /// bir aynı kareye döner ve göz bunu "döngü" olarak yakalardı.
  test('periyotlar birbirine bölünmüyor — hareket mekanik görünmez', () {
    final ms = [
      LivingMascot.breathPeriod.inMilliseconds,
      LivingMascot.floatPeriod.inMilliseconds,
      LivingMascot.tiltPeriod.inMilliseconds,
    ];
    expect(ms.toSet(), hasLength(3), reason: 'periyotlar farklı olmalı');
    for (var i = 0; i < ms.length; i++) {
      for (var j = 0; j < ms.length; j++) {
        if (i == j) continue;
        expect(
          ms[i] % ms[j],
          isNot(0),
          reason: '${ms[i]} ms, ${ms[j]} ms\'nin tam katı — döngüler hizalanır',
        );
      }
    }
  });

  /// Abartısız kalsın: "premium eğitim" tonu isteniyordu, çizgi film değil.
  test('genlikler ölçülü', () {
    expect(LivingMascot.breathScale, lessThanOrEqualTo(0.03));
    expect(LivingMascot.floatAmplitude, lessThanOrEqualTo(6));
    expect(LivingMascot.tiltAmplitude, lessThanOrEqualTo(0.05));
  });
}
