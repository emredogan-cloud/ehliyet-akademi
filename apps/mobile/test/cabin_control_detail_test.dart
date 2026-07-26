import 'package:ehliyet_akademi/domain/content/vehicle_visuals.dart';
import 'package:ehliyet_akademi/features/learn/cabin_control_detail_screen.dart';
import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Beta Faz 10 — kabin kumandası detay sayfası.
///
/// Faz öncesi durum: kartlar **hiçbir yere gitmiyordu**. Bu dosya hem yönlendirmeyi hem de
/// "mekanik kütüphanesiyle aynı kalite" şartının ölçülebilir kısmını (her kumandada gerçek
/// ipucu ve en az iki adım) sabitler.
/// Detay ekranını tek başına çizer.
///
/// Tam yönlendirme zinciri (sekme → Öğren → liste → kart) ayrı bir testte zaten koşuyor; burada
/// ekranın KENDİSİ ölçülüyor. Tema, uygulamanın gerçek temasıdır — token testinin koruduğu
/// renkler burada da geçerli olsun diye.
Future<void> pumpDetail(WidgetTester tester, String asset) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: CabinControlDetailScreen(asset: asset),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('içerik bütünlüğü', () {
    test('HER kumandanın dolu ipucu ve en az iki adımı var', () {
      expect(kCabinControls, isNotEmpty);
      for (final c in kCabinControls) {
        expect(c.tip.trim().length, greaterThan(40), reason: '${c.asset}: ipucu çok kısa');
        expect(c.tip.trim().endsWith('.'), isTrue, reason: '${c.asset}: ipucu cümle değil');
        expect(c.steps.length, greaterThanOrEqualTo(2), reason: '${c.asset}: adım yetersiz');
        for (final s in c.steps) {
          expect(s.trim().length, greaterThan(15), reason: '${c.asset}: adım çok kısa — "$s"');
          expect(s.trim().endsWith('.'), isTrue, reason: '${c.asset}: adım cümle değil — "$s"');
        }
      }
    });

    test('ipucu açıklamanın KOPYASI değildir', () {
      // Aksi hâlde detay sayfası listedeki kartı tekrar etmiş olur; yeni bilgi vermez.
      for (final c in kCabinControls) {
        expect(c.tip.trim(), isNot(c.desc.trim()), reason: c.asset);
      }
    });

    test('hata alanı varsa DOLUDUR — boş string bırakılmamıştır', () {
      for (final c in kCabinControls) {
        if (c.mistake != null) {
          expect(c.mistake!.trim().length, greaterThan(30), reason: c.asset);
        }
      }
    });

    test('görsel kimlikleri TEKİLDİR (yönlendirme anahtarı olacak)', () {
      final ids = kCabinControls.map((c) => c.asset).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('cabinControlByAsset bulur; bilinmeyende null döner', () {
      expect(cabinControlByAsset('ac-button')?.title, 'Klima (A/C)');
      expect(cabinControlByAsset('yok-boyle-bir-sey'), isNull);
    });
  });

  group('detay yüzeyi', () {
    testWidgets('listeden karta dokununca detay AÇILIR', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester);

      await tester.tap(find.text('Öğren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kabin Kumandaları'));
      await tester.pumpAndSettle();

      final first = kCabinControls.first;
      await tester.ensureVisible(find.text(first.title).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(first.title).first);
      await tester.pumpAndSettle();

      expect(find.byType(CabinControlDetailScreen), findsOneWidget);
      expect(find.text('Nasıl kullanılır'), findsOneWidget);
    });

    testWidgets('detayda büyük görsel ZOOM edilebilir', (tester) async {
      await useTallSurface(tester);
      await pumpDetail(tester, 'ac-button');

      // Zoom yeteneği yüzeyin kendisinde olmalı — "büyük görsel" tek başına yetmez.
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.textContaining('yakınlaştır'), findsOneWidget);
    });

    testWidgets('ÇİFT DOKUNUŞ görseli gerçekten yakınlaştırır', (tester) async {
      // `InteractiveViewer` kendi jest tanıyıcısını kurar; üstüne konan `GestureDetector`
      // jest arenasını kaybedebilir ve çift dokunuş sessizce ÇALIŞMAZ. Cihazda `adb input tap`
      // ile çift dokunuş üretilemediği için (her dokunuş ayrı süreç, ~300 ms'yi aşıyor) bu
      // davranışın tek güvenilir ölçüsü burasıdır.
      await useTallSurface(tester);
      await pumpDetail(tester, 'ac-button');

      expect(find.text('Çift dokun veya parmakla yakınlaştır'), findsOneWidget);

      final viewer = find.byType(InteractiveViewer);
      await tester.tap(viewer);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(viewer);
      await tester.pumpAndSettle();

      expect(
        find.text('Sürükleyerek gez · çift dokun: küçült'),
        findsOneWidget,
        reason: 'çift dokunuş yakınlaştırmayı açmalı',
      );

      // Tekrar çift dokunuş → eski hâline döner.
      await tester.tap(viewer);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(viewer);
      await tester.pumpAndSettle();
      expect(find.text('Çift dokun veya parmakla yakınlaştır'), findsOneWidget);
    });

    testWidgets('ipucu, adımlar ve hata kartı gösterilir', (tester) async {
      await useTallSurface(tester);
      await pumpDetail(tester, 'esp-off-button');

      final c = cabinControlByAsset('esp-off-button')!;
      expect(find.text('💡 İpucu'), findsOneWidget);
      expect(find.text(c.tip), findsOneWidget);
      expect(find.text(c.steps.first), findsOneWidget);
      expect(find.text('⚠️ Sık yapılan hata'), findsOneWidget);
    });

    testWidgets('hatası OLMAYAN kumandada uyarı kartı ÇİZİLMEZ', (tester) async {
      await useTallSurface(tester);
      await pumpDetail(tester, 'usb-c-socket');

      expect(cabinControlByAsset('usb-c-socket')!.mistake, isNull);
      expect(find.text('⚠️ Sık yapılan hata'), findsNothing);
    });

    testWidgets('bilinmeyen kimlik ÇÖKMEZ, dürüst boş durum gösterir', (tester) async {
      await useTallSurface(tester);
      await pumpDetail(tester, 'yok-boyle-bir-sey');

      expect(find.text('Kumanda bulunamadı'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
