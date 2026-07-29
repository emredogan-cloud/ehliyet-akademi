import 'package:ehliyet_akademi/design/coach_marks.dart';
import 'package:ehliyet_akademi/features/onboarding/product_tour.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Faz 1 — ilk açılış deneyimi: gerçek arayüzün üstünde koç işaretleri turu.
void main() {
  /// Tur ilk kare sonrası başlar ve hedefi görünür alana kaydırır; sabit kare sayısı yerine
  /// `pumpAndSettle` kullanılır (hareket testlerde zaten kapalı).
  Future<void> bootWithTour(WidgetTester tester) async {
    await useTallSurface(tester);
    await pumpApp(tester, coachMarksSeen: false);
    await tester.pumpAndSettle();
  }

  group('tur içeriği', () {
    test('istenen dokuz yüzeyin hepsi tanıtılıyor', () {
      final ids = productTourSteps.map((s) => s.anchorId).toList();
      expect(ids, [
        ProductTourAnchors.home,
        ProductTourAnchors.smartStudy,
        ProductTourAnchors.practiceExam,
        ProductTourAnchors.realExam,
        ProductTourAnchors.aiCoach,
        ProductTourAnchors.progress,
        ProductTourAnchors.premium,
        ProductTourAnchors.community,
        ProductTourAnchors.bottomNav,
      ]);
    });

    test('her adımın başlığı ve gövdesi doludur', () {
      for (final s in productTourSteps) {
        expect(s.title.trim(), isNotEmpty);
        expect(s.body.trim().length, greaterThan(30), reason: '${s.title}: gövde çok kısa');
      }
    });
  });

  group('ilk açılış', () {
    testWidgets('tur ilk açılışta kendiliğinden başlar', (tester) async {
      await bootWithTour(tester);
      expect(find.text('Ana Sayfa').last, findsOneWidget);
      expect(find.text('1/9'), findsOneWidget);
      expect(find.text('Atla'), findsOneWidget);
      expect(find.text('İleri'), findsOneWidget);
      // İlk adımda "Geri" YOKTUR — geri gidilecek yer yok.
      expect(find.text('Geri'), findsNothing);
    });

    testWidgets('görülmüşse tur HİÇ açılmaz', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester); // varsayılan: görülmüş
      expect(find.text('1/9'), findsNothing);
      expect(find.text('Atla'), findsNothing);
    });
  });

  group('gezinme', () {
    testWidgets('İleri sonraki adıma geçer, Geri öncekine döner', (tester) async {
      await bootWithTour(tester);

      await tester.tap(find.text('İleri'));
      await tester.pumpAndSettle();
      expect(find.text('2/9'), findsOneWidget);
      expect(find.text('Akıllı Çalışma'), findsWidgets);
      expect(find.text('Geri'), findsOneWidget);

      await tester.tap(find.text('Geri'));
      await tester.pumpAndSettle();
      expect(find.text('1/9'), findsOneWidget);
      expect(find.text('Geri'), findsNothing);
    });

    testWidgets('son adımda düğme "Başla" olur ve tur biter', (tester) async {
      await bootWithTour(tester);
      for (var i = 0; i < productTourSteps.length - 1; i++) {
        await tester.tap(find.text('İleri'));
        await tester.pumpAndSettle();
      }
      expect(find.text('9/9'), findsOneWidget);
      expect(find.text('Başla'), findsOneWidget);
      expect(find.text('İleri'), findsNothing);

      await tester.tap(find.text('Başla'));
      await tester.pumpAndSettle();
      expect(find.text('9/9'), findsNothing);
    });

    testWidgets('Atla turu hemen bitirir', (tester) async {
      await bootWithTour(tester);
      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();
      expect(find.text('1/9'), findsNothing);
      expect(find.byType(CoachMarkHost), findsOneWidget); // ev sahibi kalır, tur biter
    });
  });

  group('tamamlanma hatırlanır', () {
    testWidgets('tur bitince işaret kalıcı yazılır', (tester) async {
      await bootWithTour(tester);
      for (var i = 0; i < productTourSteps.length - 1; i++) {
        await tester.tap(find.text('İleri'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Başla'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('ea:coachMarksSeen:v1'), isTrue);
    });

    /// "Atla" da tamamlanma sayılır: kullanıcı turu istemediğini söylemiştir. Aksi hâlde her
    /// açılışta aynı karartma geri gelirdi.
    testWidgets('Atla da tamamlanma sayılır', (tester) async {
      await bootWithTour(tester);
      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('ea:coachMarksSeen:v1'), isTrue);
    });
  });

  group('davranış', () {
    /// Tur sırasında arkadaki gerçek arayüze dokunuş GEÇMEMELİ — yoksa kullanıcı yanlışlıkla
    /// bir ekran açar ve tur hedefini kaybeder.
    testWidgets('karartma arkadaki arayüzü korur, dokunuş ilerletir', (tester) async {
      await bootWithTour(tester);
      expect(find.text('1/9'), findsOneWidget);

      // Ekranın ortasına dokun: arkada bir kart var ama karartma dokunuşu alır ve ilerletir.
      await tester.tapAt(tester.getCenter(find.byType(MaterialApp)));
      await tester.pumpAndSettle();
      expect(find.text('2/9'), findsOneWidget);
      // Arkadaki kart açılmadı — hâlâ kabuktayız.
      expect(find.byType(CoachMarkHost), findsOneWidget);
    });

    /// CİHAZDA YAKALANAN HATA — testte görünmüyordu.
    ///
    /// Bindirme kabuğun `Scaffold`'unun ÜSTÜNDE duruyor; ağaçta `Material` atası olmayınca Flutter
    /// metni "eksik stil" işaretiyle (daktilo yazı tipi + sarı çift alt çizgi) çiziyordu. Metin
    /// BULUNUYORDU, yalnız yanlış çiziliyordu — bu yüzden içerik testleri sessiz kaldı. Kural
    /// artık burada: baloncuğun bir `Material` atası olmalı.
    testWidgets('baloncuk metni bir Material altında çizilir (sarı alt çizgi hatası)', (
      tester,
    ) async {
      await bootWithTour(tester);
      expect(
        find.ancestor(of: find.text('Ana Sayfa').last, matching: find.byType(Material)),
        findsWidgets,
        reason: 'Material atası yok → metin "eksik stil" olarak çizilir',
      );
    });

    /// Turun tanıttığı her düğme GERÇEKTEN Ana Sayfa'da olmalı. Bu test, tur ile ekranın
    /// birbirinden ayrı düşmesini (çapası silinmiş bir adım) yakalar.
    testWidgets('her adımın çapası gerçekten bulunuyor', (tester) async {
      await bootWithTour(tester);
      for (var i = 0; i < productTourSteps.length; i++) {
        expect(
          find.text('${i + 1}/${productTourSteps.length}'),
          findsOneWidget,
          reason: '${productTourSteps[i].title} adımı atlandı — çapası bulunamamış',
        );
        if (i < productTourSteps.length - 1) {
          await tester.tap(find.text('İleri'));
          await tester.pumpAndSettle();
        }
      }
    });
  });
}
