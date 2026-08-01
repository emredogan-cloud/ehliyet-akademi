import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:ehliyet_akademi/domain/premium/products.dart';
import 'package:ehliyet_akademi/features/premium/paywall_plans.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Blok tek başına kurulur — tüm uygulamayı ayağa kaldırmaya gerek yok. Tema ŞART:
/// kartlar `context.palette` okuyor.
Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
);

/// Ürün Evrimi v1.1 · Faz 10 — ödeme ekranı yeniden tasarımı.
///
/// İSTENEN: kaydırma yok, üç paket tek bakışta, ömür boyu önerilen ve en büyük kart,
/// deneme süresi yok, sahte aciliyet yok.
void main() {
  group('paket blokları', () {
    testWidgets('üç paket de çizilir; ömür boyu ÖNERİLEN olarak işaretlenir', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PaywallPlans(selectedId: kPremiumProductId, storeProducts: const [], onSelect: (_) {}),
        ),
      );

      expect(find.text('Haftalık'), findsOneWidget);
      expect(find.text('Aylık'), findsOneWidget);
      expect(find.text('Ömür Boyu'), findsOneWidget);
      expect(find.text('ÖNERİLEN'), findsOneWidget);
    });

    testWidgets('önerilen kart en GENİŞ olanıdır', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PaywallPlans(selectedId: kPremiumProductId, storeProducts: const [], onSelect: (_) {}),
        ),
      );

      final weekly = tester.getSize(find.ancestor(
        of: find.text('Haftalık'),
        matching: find.byType(AnimatedContainer),
      ));
      final lifetime = tester.getSize(find.ancestor(
        of: find.text('Ömür Boyu'),
        matching: find.byType(AnimatedContainer),
      ));

      expect(
        lifetime.width,
        greaterThan(weekly.width),
        reason: 'önerilen paket görsel olarak da en büyük olmalı',
      );
    });

    testWidgets('dokunma seçimi bildirir', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _wrap(
          PaywallPlans(
            selectedId: kPremiumProductId,
            storeProducts: const [],
            onSelect: (id) => picked = id,
          ),
        ),
      );

      await tester.tap(find.text('Haftalık'));
      expect(picked, kWeeklyProductId);
    });

    /// FİYAT KAYNAĞI — mağaza yanıt vermezse yedek etiket görünür ama uydurulmaz.
    testWidgets('mağaza fiyatı yoksa katalog yedeği gösterilir', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PaywallPlans(selectedId: kPremiumProductId, storeProducts: const [], onSelect: (_) {}),
        ),
      );

      expect(find.text('₺50/hafta'), findsOneWidget);
      expect(find.text('₺200/ay'), findsOneWidget);
      expect(find.text('₺479,99'), findsOneWidget);
    });

    testWidgets('abonelik/tek-seferlik ayrımı kartta yazar', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PaywallPlans(selectedId: kPremiumProductId, storeProducts: const [], onSelect: (_) {}),
        ),
      );

      expect(find.text('abonelik'), findsNWidgets(2));
      expect(find.text('tek seferlik'), findsOneWidget);
    });

    /// Kullanıcının açıkça istediği iki yasak.
    testWidgets('DENEME SÜRESİ ve sahte aciliyet ifadesi geçmez', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PaywallPlans(selectedId: kPremiumProductId, storeProducts: const [], onSelect: (_) {}),
        ),
      );

      for (final yasak in [
        'deneme',
        'Deneme',
        'ücretsiz dene',
        'son şans',
        'Son şans',
        'acele',
        'tükeniyor',
      ]) {
        expect(
          find.textContaining(yasak),
          findsNothing,
          reason: '"$yasak" ifadesi ödeme ekranında bulunmamalı',
        );
      }
    });
  });
}
