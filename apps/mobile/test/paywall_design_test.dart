import 'package:ehliyet_akademi/domain/premium/paywall_offer.dart';
import 'package:ehliyet_akademi/features/premium/paywall_sections.dart';
import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Faz 9 — ödeme ekranı yeniden tasarımı: referans içeriği + DÜRÜST fiyatlandırma.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  group('kampanya kuralı (saf)', () {
    final now = DateTime.utc(2026, 7, 29, 12);

    test('yapılandırma yoksa ne üstü çizili fiyat ne sayaç vardır', () {
      const offer = PaywallOffer();
      expect(offer.hasListPrice, isFalse);
      expect(offer.isCountdownVisible(now), isFalse);
    });

    test('geçmiş bitiş tarihi sayacı göstermez', () {
      final offer = PaywallOffer(endsAt: now.subtract(const Duration(minutes: 1)));
      expect(offer.isCountdownVisible(now), isFalse);
      expect(offer.remaining(now), Duration.zero);
    });

    test('gelecekteki bitiş tarihi sayacı gösterir', () {
      final offer = PaywallOffer(endsAt: now.add(const Duration(hours: 2)));
      expect(offer.isCountdownVisible(now), isTrue);
      expect(offer.remaining(now), const Duration(hours: 2));
    });

    test('geri sayım parçaları iki haneli; bir günü aşan süre saate eklenir', () {
      expect(countdownParts(const Duration(hours: 23, minutes: 59, seconds: 47)),
          (hours: '23', minutes: '59', seconds: '47'));
      expect(countdownParts(const Duration(seconds: 5)), (hours: '00', minutes: '00', seconds: '05'));
      // Üç günlük kampanya: 72 saat — üç kutu bozulmasın diye gün ayrı birim DEĞİL.
      expect(countdownParts(const Duration(days: 3)).hours, '72');
      expect(countdownParts(-const Duration(hours: 1)), (hours: '00', minutes: '00', seconds: '00'));
    });
  });

  group('fiyat bloğu — dürüstlük', () {
    /// Hiç uygulanmamış bir "eski fiyat" göstermek yanıltıcı fiyatlandırmadır. Yapılandırma
    /// yoksa ekran YALNIZ mağazanın bildirdiği gerçek fiyatı gösterir.
    testWidgets('kampanya yokken üstü çizili fiyat ve sayaç ÇİZİLMEZ', (tester) async {
      await tester.pumpWidget(
        host(
          const PaywallPriceBlock(
            priceLabel: '₺399,00',
            offer: PaywallOffer(),
            onBuy: null,
            busy: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('₺399,00'), findsOneWidget);
      expect(find.text('SINIRLI SÜRE'), findsNothing);
      expect(find.textContaining('yerine sadece'), findsNothing);
    });

    testWidgets('gerçek kampanya yapılandırıldığında ikisi de görünür', (tester) async {
      await tester.pumpWidget(
        host(
          PaywallPriceBlock(
            priceLabel: '₺479,99',
            offer: PaywallOffer(
              listPriceLabel: '₺799,99',
              endsAt: DateTime.now().add(const Duration(hours: 5)),
            ),
            onBuy: () {},
            busy: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('₺479,99'), findsOneWidget);
      expect(find.text('SINIRLI SÜRE'), findsOneWidget);
      expect(find.textContaining('₺799,99'), findsOneWidget);
      expect(find.text('tek seferlik ödeme'), findsOneWidget);

      // Sonsuz zamanlayıcıyı tester'a bırakmadan sök.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('mağaza kapalıyken satın alma düğmesi basılamaz', (tester) async {
      await tester.pumpWidget(
        host(
          const PaywallPriceBlock(
            priceLabel: '₺399,00',
            offer: PaywallOffer(),
            onBuy: null,
            busy: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final inkWell = find
          .ancestor(of: find.text('PAKETİ SATIN AL'), matching: find.byType(InkWell))
          .first;
      expect(tester.widget<InkWell>(inkWell).onTap, isNull);
    });
  });

  group('referans bölümleri', () {
    testWidgets('özellik şeridi dört sütunu taşır', (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(host(const PaywallFeatureStrip()));
      await tester.pumpAndSettle();

      for (final t in const [
        'SINIRSIZ ERİŞİM',
        'SINIRSIZ DENEME',
        'AI KOÇ DESTEĞİ',
        'VİDEO DERSLER',
      ]) {
        expect(find.text(t), findsOneWidget, reason: '"$t" sütunu eksik');
      }
    });

    /// Onay listesi ürün kataloğundan beslenir — metinler burada TEKRAR YAZILMAZ.
    testWidgets('onay listesi verilen özellikleri çizer', (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(
        host(const PaywallChecklist(features: ['Birinci özellik', 'İkinci özellik'])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Birinci özellik'), findsOneWidget);
      expect(find.text('İkinci özellik'), findsOneWidget);
      expect(find.text('DAHA\nYÜKSEK\nBAŞARI'), findsOneWidget);
    });
  });

  group('ekranda', () {
    testWidgets('referans başlığı ve bölümleri görünür', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, billing: FakeBillingGateway.withStore(priceLabel: '₺399,00'));
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Premium özellikleri keşfet'), 200);
      await tester.tap(find.text('Premium özellikleri keşfet'));
      await tester.pumpAndSettle();

      expect(find.text('TÜM POTANSİYELİNİ AÇ'), findsOneWidget);
      expect(find.text('SINAVA HAZIR OL!'), findsOneWidget);
      expect(find.text('SINIRSIZ ERİŞİM'), findsOneWidget);
      expect(find.text('PAKETİ SATIN AL'), findsOneWidget);
      expect(find.text('₺399,00'), findsOneWidget);
      // Kampanya yapılandırılmadığı için sahte aciliyet YOK.
      expect(find.text('SINIRLI SÜRE'), findsNothing);
    });
  });
}
