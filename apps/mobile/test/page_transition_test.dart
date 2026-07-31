import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:ehliyet_akademi/core/theme/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faz 2 — sayfa geçişinde ÇAKIŞMA olmadığının kapısı.
///
/// Bu dosyanın koruduğu kusur cihazda videoya alındı: saydam iskele + kaydırmalı
/// (Cupertino) geçiş bileşimi yüzünden Öğren sayfasının baykuşu, gelen Dersler
/// sayfasının İÇİNDEN ~400 ms boyunca okunuyordu.
///
/// Kusur bir renk/cila meselesi değil, BİLEŞİM meselesi: iki saydam katman aynı anda
/// çizilirse ikisi de görünür. O yüzden buradaki kapı da görsel değil, ZAMANLAMA
/// üzerinedir — "hiçbir anda iki sayfa birden çizilmesin".
void main() {
  group('sayfa geçişi — sıralı solma', () {
    /// ASIL KAPI. Gelen ve giden opaklıkların ÇARPIMI her `t` için sıfır olmalı:
    /// çarpım sıfırsa en az biri tamamen görünmezdir, yani çakışma imkânsızdır.
    ///
    /// Bu, geçişin görsel bir "iyi görünüyor" testi değil; kusurun kök nedeninin
    /// (aynı anda iki görünür katman) matematiksel olarak dışlanmasıdır.
    test('gelen ve giden sayfa hiçbir anda AYNI ANDA görünmez', () {
      const steps = 1000;
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final enter = SharedAxisPageTransitionsBuilder.enterOpacity(t);
        final exit = SharedAxisPageTransitionsBuilder.exitOpacity(t);
        expect(
          enter * exit,
          0,
          reason:
              't=$t için iki sayfa birden görünür (gelen=$enter, giden=$exit) — '
              'saydam iskelede bu, alttaki sayfanın üstteki içinden okunması demektir',
        );
      }
    });

    test('opaklıklar uçlarda doğru: geçiş başında giden, sonunda gelen tam görünür', () {
      expect(SharedAxisPageTransitionsBuilder.exitOpacity(0), 1);
      expect(SharedAxisPageTransitionsBuilder.enterOpacity(0), 0);
      expect(SharedAxisPageTransitionsBuilder.enterOpacity(1), 1);
      expect(SharedAxisPageTransitionsBuilder.exitOpacity(1), 0);
    });

    test('devir teslim noktasında ikisi de görünmez — arada boşluk YOK, tam sıfır var', () {
      const h = SharedAxisPageTransitionsBuilder.handover;
      expect(SharedAxisPageTransitionsBuilder.enterOpacity(h), 0);
      expect(SharedAxisPageTransitionsBuilder.exitOpacity(h), 0);
    });

    /// Android'in geçişi bu olmalı. Cupertino'ya geri dönülürse kusur da geri döner;
    /// o yüzden yapılandırmanın kendisi de kapı altında.
    test('Android geçişi SharedAxis, iOS bilinçli olarak Cupertino', () {
      final builders = AppTheme.dark().pageTransitionsTheme.builders;
      expect(builders[TargetPlatform.android], isA<SharedAxisPageTransitionsBuilder>());
      expect(builders[TargetPlatform.iOS], isA<CupertinoPageTransitionsBuilder>());
    });

    /// Geçiş gerçekten çalışıyor mu — gezinme tamamlanıyor ve eski sayfa ağaçtan çıkıyor.
    testWidgets('itme ve geri alma tamamlanır; geçiş bitince eski sayfa kalmaz', (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          theme: AppTheme.dark(),
          home: const Scaffold(body: Center(child: Text('BİRİNCİ'))),
        ),
      );
      expect(find.text('BİRİNCİ'), findsOneWidget);

      navKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Center(child: Text('İKİNCİ'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('İKİNCİ'), findsOneWidget);
      expect(find.text('BİRİNCİ'), findsNothing, reason: 'itme bitince alttaki sayfa çizilmemeli');

      navKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('BİRİNCİ'), findsOneWidget);
      expect(find.text('İKİNCİ'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
