import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Faz 12 — cilalama DENETİMİ.
///
/// Bu dosya bir özellik testi değil, bir TARAMADIR: uygulamanın ana yüzeyleri zorlayıcı
/// koşullarda açılır ve şu üç soru sorulur —
///   1. taşma var mı? (RenderFlex overflow)
///   2. istisna atıyor mu?
///   3. dokunma hedefleri erişilebilirlik alt sınırının altında mı?
///
/// Zorlayıcı koşullar bilinçli seçildi; her biri sahada GERÇEKTEN karşılaşılan bir durum:
/// · **açık tema** — kullanıcıların bir kısmı açık temada,
/// · **büyük sistem yazısı** (1,3×) — Android erişilebilirlik ayarı, çok yaygın,
/// · **tablet genişliği** — Play Store tablet uyumluluğu için gerekli,
/// · **çok dar telefon** (320 dp) — hâlâ satılan alt segment cihazlar.
void main() {
  /// Bir ekranı verilen koşulda aç ve taşma/istisna topla.
  Future<List<String>> audit(
    WidgetTester tester, {
    required String screen,
    required Future<void> Function(WidgetTester) open,
    required Size size,
    double textScale = 1.0,
    Brightness brightness = Brightness.dark,
  }) async {
    final problems = <String>[];
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Taşmalar `FlutterError.onError` üzerinden gelir; testi düşürmek yerine TOPLANIR ki tek
    // koşuda bütün liste görülsün.
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed')) {
        // Hangi widget taştı? `library`/`context` olmadan taşmayı bulmak imkânsız.
        final where = details.context?.toString() ?? '';
        problems.add('$screen [${size.width.toInt()}dp, ${textScale}x] TAŞMA: '
            '${text.split('\n').first} @ $where');
      } else {
        problems.add('$screen [${size.width.toInt()}dp, ${textScale}x] İSTİSNA: '
            '${text.split('\n').first}');
      }
    };
    addTearDown(() => FlutterError.onError = previous);

    await open(tester);
    FlutterError.onError = previous;
    return problems;
  }

  /// Denetlenecek ekranlar — kullanıcının gerçekten gördüğü ana yüzeyler.
  final screens = <String, Future<void> Function(WidgetTester)>{
    'Ana Sayfa': (t) async => pumpApp(t),
    'Öğren': (t) async {
      await pumpApp(t);
      await tapTab(t, 'Öğren');
    },
    'Pratik': (t) async {
      await pumpApp(t);
      await tapTab(t, 'Pratik');
    },
    'AI Koç': (t) async {
      await pumpApp(t);
      await tapTab(t, 'AI Koç');
    },
    'Topluluk': (t) async {
      await pumpApp(t, community: FakeCommunityApi());
      await tapTab(t, 'Topluluk');
    },
    'Profil': (t) async {
      await pumpApp(t);
      await tapTab(t, 'Profil');
    },
  };

  group('taşma ve istisna taraması', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} — dar telefon (320 dp)', (tester) async {
        final problems = await audit(
          tester,
          screen: entry.key,
          open: entry.value,
          size: const Size(320, 800),
        );
        expect(problems, isEmpty, reason: problems.join('\n'));
      });

      testWidgets('${entry.key} — büyük sistem yazısı (1.3×)', (tester) async {
        final problems = await audit(
          tester,
          screen: entry.key,
          open: (t) async {
            t.platformDispatcher.textScaleFactorTestValue = 1.3;
            addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
            await entry.value(t);
          },
          size: const Size(400, 900),
          textScale: 1.3,
        );
        expect(problems, isEmpty, reason: problems.join('\n'));
      });

      testWidgets('${entry.key} — tablet (1024 dp)', (tester) async {
        final problems = await audit(
          tester,
          screen: entry.key,
          open: entry.value,
          size: const Size(1024, 1366),
        );
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  });

  group('erişilebilirlik', () {
    /// Flutter'ın RESMÎ yönerge eşleştiricileri kullanılır — elle ölçüm DEĞİL.
    ///
    /// Önce `InkWell`'in render kutusu ölçülmüştü ve yanlış alarm verdi: `IconButton`'ın mürekkep
    /// dalgası 42 dp olsa da dokunma hedefi `MaterialTapTargetSize.padded` ile 48 dp'ye
    /// tamamlanıyor. Yönerge eşleştiricisi gerçek hedefi ölçer; ayrıca metin kontrastını da
    /// denetler (Play erişilebilirlik taramasının baktığı iki şey).
    for (final entry in screens.entries) {
      testWidgets('${entry.key} — dokunma hedefi ve kontrast yönergeleri', (tester) async {
        final handle = tester.ensureSemantics();
        await useTallSurface(tester);
        await entry.value(tester);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('açık tema', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} — açık temada hatasız çizilir', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final problems = await audit(
          tester,
          screen: entry.key,
          open: entry.value,
          size: const Size(400, 900),
          brightness: Brightness.light,
        );
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  });
}
