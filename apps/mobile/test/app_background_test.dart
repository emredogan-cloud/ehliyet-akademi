import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:ehliyet_akademi/design/app_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Faz 6 — tek ortak canlı zemin.
void main() {
  Widget host({required bool reduceMotion, Brightness brightness = Brightness.dark}) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        home: const AppBackground(
          child: Scaffold(body: Center(child: Text('içerik'))),
        ),
      ),
    );
  }

  testWidgets('zemin tek örnektir ve uygulamanın kökünde kurulur', (tester) async {
    await pumpApp(tester);
    expect(find.byType(AppBackground), findsOneWidget);
  });

  /// ASIL kazanç: sayfa değişince zemin SÖKÜLMEZ. Sökülseydi hareket her geçişte başa sarardı.
  testWidgets('sekme değişse de zemin AYNI durumu korur', (tester) async {
    await pumpApp(tester);
    final before = tester.state(find.byType(AppBackground));

    await tapTab(tester, 'Pratik');
    await tapTab(tester, 'Profil');

    expect(find.byType(AppBackground), findsOneWidget);
    expect(
      identical(tester.state(find.byType(AppBackground)), before),
      isTrue,
      reason: 'zemin yeniden kurulmuş — hareket her geçişte başa sarar',
    );
  });

  /// E13 erişilebilirlik kuralı: "animasyonları azalt" açıkken hareket üretilmez. Bu aynı zamanda
  /// pil kararıdır — sürekli tikleyen bir zemin, arka planda ölçülebilir maliyet demektir.
  testWidgets('hareket azaltıldığında tikleyici kurulmaz', (tester) async {
    await tester.pumpWidget(host(reduceMotion: true));
    await tester.pumpAndSettle(); // sonsuz animasyon olsaydı burada asılırdı
    expect(find.byType(AppBackground), findsOneWidget);
    expect(find.text('içerik'), findsOneWidget);
  });

  testWidgets('hareket açıkken zemin canlıdır ve içerik üstünde çizilir', (tester) async {
    await tester.pumpWidget(host(reduceMotion: false));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('içerik'), findsOneWidget);

    // Sürekli animasyon: kare planlanmaya devam eder.
    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.hasScheduledFrame, isTrue);

    // Sonsuz animasyonu tester'a bırakmadan sök.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  /// Zemin içeriğin ARKASINDA kalmalı: dokunuşları yutarsa uygulama tamamen kilitlenir.
  testWidgets('zemin dokunuşları yutmaz', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: AppBackground(
            child: Scaffold(
              body: Center(
                child: ElevatedButton(onPressed: () => taps++, child: const Text('dokun')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('dokun'));
    expect(taps, 1);
  });

  /// Zemin her iki temada da çizilebilmeli — açık temada beyaz üstüne beyaz yıldız görünmez;
  /// renkler token'dan geldiği için tema değişince otomatik uyum sağlar.
  for (final b in Brightness.values) {
    testWidgets('${b.name} temada zemin hatasız çizilir', (tester) async {
      await tester.pumpWidget(host(reduceMotion: true, brightness: b));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
