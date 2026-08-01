import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:ehliyet_akademi/design/coach_marks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ürün Evrimi v1.1 · Faz 5 — koç turu başarım kapısı.
///
/// Turun takılmasının kök nedeni: karartma (tam ekran `Path.combine`) ile nefes alan halka AYNI
/// boyacıdaydı. Nabız 1600 ms'lik sonsuz döngüde koştuğu için `shouldRepaint` her karede true
/// dönüyor, saniyede ~60 kez tam ekran boyutunda Skia boolean yol işlemi yapılıyordu.
///
/// Bu test kusurun geri gelmesini engeller: **nabız ilerlerken karartmanın yeniden çizilmemesi**
/// ölçülebilir bir olgudur; boyacıların `shouldRepaint` sözleşmesiyle doğrulanır.
///
/// Boyacılar özel (private) olduğu için doğrudan kurulamaz; ağaçtan bulunup karşılaştırılır.

/// Ağaçtaki tüm `CustomPaint` boyacılarını, çalışma zamanı tür adına göre toplar.
List<CustomPainter> _paintersNamed(WidgetTester tester, String typeName) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<CustomPainter>()
    .where((p) => p.runtimeType.toString() == typeName)
    .toList();

Widget _host(GlobalKey<CoachMarkHostState> key) => MaterialApp(
  // Gerçek tema ŞART: boyacılar `context.palette` okuyor, o da tema uzantısından geliyor.
  theme: AppTheme.light(),
  home: CoachMarkHost(
    key: key,
    child: Scaffold(
      body: Center(
        child: CoachAnchor(
          id: 'hedef',
          child: Container(width: 120, height: 48, color: Colors.blue),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('nabız ilerlerken KARARTMA yeniden çizilmez', (tester) async {
    final key = GlobalKey<CoachMarkHostState>();
    await tester.pumpWidget(_host(key));

    unawaited(
      key.currentState!.start(const [
        CoachMarkStep(anchorId: 'hedef', title: 'Başlık', body: 'Gövde', icon: Icons.home),
      ]),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final scrimBefore = _paintersNamed(tester, '_ScrimPainter');
    expect(scrimBefore, isNotEmpty, reason: 'karartma boyacısı ağaçta olmalı');

    // Nabzı ilerlet — hedef değişmedi, yalnız nabız değişti.
    await tester.pump(const Duration(milliseconds: 200));
    final scrimAfter = _paintersNamed(tester, '_ScrimPainter');

    expect(
      scrimAfter.first.shouldRepaint(scrimBefore.first),
      isFalse,
      reason:
          'Hedef değişmediği hâlde karartma yeniden çizilmek istiyor — pahalı Path.combine '
          'yine kare hızında koşuyor demektir.',
    );

    key.currentState!.finish();
    await tester.pumpAndSettle();
  });

  testWidgets('nabız halkası ise HER KARE yeniden çizilir (canlılık korunuyor)', (tester) async {
    final key = GlobalKey<CoachMarkHostState>();
    await tester.pumpWidget(_host(key));

    unawaited(
      key.currentState!.start(const [
        CoachMarkStep(anchorId: 'hedef', title: 'Başlık', body: 'Gövde', icon: Icons.home),
      ]),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final ringBefore = _paintersNamed(tester, '_PulseRingPainter');
    expect(ringBefore, isNotEmpty, reason: 'nabız halkası ağaçta olmalı');

    await tester.pump(const Duration(milliseconds: 200));
    final ringAfter = _paintersNamed(tester, '_PulseRingPainter');

    expect(
      ringAfter.first.shouldRepaint(ringBefore.first),
      isTrue,
      reason: 'halka nefes almayı bıraktıysa tur ölü görünür',
    );

    key.currentState!.finish();
    await tester.pumpAndSettle();
  });

  testWidgets('hedef değişince karartma yeniden çizilir', (tester) async {
    final key = GlobalKey<CoachMarkHostState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: CoachMarkHost(
          key: key,
          child: Scaffold(
            body: Column(
              children: [
                const SizedBox(height: 40),
                CoachAnchor(
                  id: 'bir',
                  child: Container(width: 100, height: 40, color: Colors.red),
                ),
                const SizedBox(height: 200),
                CoachAnchor(
                  id: 'iki',
                  child: Container(width: 100, height: 40, color: Colors.green),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    unawaited(
      key.currentState!.start(const [
        CoachMarkStep(anchorId: 'bir', title: 'Bir', body: 'Gövde', icon: Icons.home),
        CoachMarkStep(anchorId: 'iki', title: 'İki', body: 'Gövde', icon: Icons.star),
      ]),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final first = _paintersNamed(tester, '_ScrimPainter').first;

    key.currentState!.next();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final second = _paintersNamed(tester, '_ScrimPainter').first;

    expect(
      second.shouldRepaint(first),
      isTrue,
      reason: 'ışık yeni hedefe geçtiyse karartma da yenilenmeli',
    );

    key.currentState!.finish();
    await tester.pumpAndSettle();
  });

  testWidgets('hareket azaltıldığında nabız halkası hiç kurulmaz', (tester) async {
    final key = GlobalKey<CoachMarkHostState>();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _host(key),
      ),
    );

    unawaited(
      key.currentState!.start(const [
        CoachMarkStep(anchorId: 'hedef', title: 'Başlık', body: 'Gövde', icon: Icons.home),
      ]),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      _paintersNamed(tester, '_PulseRingPainter'),
      isEmpty,
      reason: 'hareket azaltıldığında nabız katmanı hiç oluşturulmamalı',
    );
    expect(_paintersNamed(tester, '_ScrimPainter'), isNotEmpty);

    key.currentState!.finish();
    await tester.pumpAndSettle();
  });
}

/// `start` bir `Future` döndürüyor; testte beklemeden ilerletmek istiyoruz.
void unawaited(Future<void> _) {}
