import 'package:ehliyet_akademi/data/feedback/store_review_service.dart';
import 'package:ehliyet_akademi/domain/feedback/rating_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Faz 7 — uygulama puanlama: kural katmanı, tasarım, tetikler ve spam koruması.
void main() {
  group('kural katmanı (saf)', () {
    const now = 1000000000000;

    test('temiz durumda otomatik tetik sorabilir', () {
      expect(
        shouldAskForRating(
          trigger: RatingTrigger.examsCompleted,
          state: const RatingPromptState(),
          nowMs: now,
        ),
        isTrue,
      );
    });

    test('puanladıysa bir daha SORULMAZ', () {
      expect(
        shouldAskForRating(
          trigger: RatingTrigger.coachConversation,
          state: const RatingPromptState(rated: true),
          nowMs: now,
        ),
        isFalse,
      );
    });

    test('soğuma süresi dolmadan sorulmaz, dolunca sorulur', () {
      const state = RatingPromptState(lastShownMs: now, count: 1);
      expect(
        shouldAskForRating(trigger: RatingTrigger.examsCompleted, state: state, nowMs: now + 1000),
        isFalse,
      );
      expect(
        shouldAskForRating(
          trigger: RatingTrigger.examsCompleted,
          state: state,
          nowMs: now + ratingCooldownMs + 1,
        ),
        isTrue,
      );
    });

    test('erteleme süresi biterse tekrar sorulabilir', () {
      const state = RatingPromptState(snoozedUntilMs: now + ratingSnoozeMs);
      expect(
        shouldAskForRating(trigger: RatingTrigger.examsCompleted, state: state, nowMs: now),
        isFalse,
      );
      expect(
        shouldAskForRating(
          trigger: RatingTrigger.examsCompleted,
          state: state,
          nowMs: now + ratingSnoozeMs + 1,
        ),
        isTrue,
      );
    });

    test('ömür boyu üst sınır aşılınca susulur', () {
      expect(
        shouldAskForRating(
          trigger: RatingTrigger.examsCompleted,
          state: const RatingPromptState(count: ratingMaxPrompts),
          nowMs: now,
        ),
        isFalse,
      );
    });

    /// Kullanıcı KENDİSİ istediyse hiçbir sınır uygulanmaz.
    test('elle açışta sınırlar uygulanmaz', () {
      expect(
        shouldAskForRating(
          trigger: RatingTrigger.manual,
          state: const RatingPromptState(rated: true, count: 99, lastShownMs: now),
          nowMs: now,
        ),
        isTrue,
      );
    });

    /// Eşikte TAM tetiklenir — dördüncü, beşinci sınavda tekrar tetiklenmez.
    test('tetik eşikleri yalnız eşik değerinde çalışır', () {
      expect(ratingTriggeredByExams(2), isFalse);
      expect(ratingTriggeredByExams(3), isTrue);
      expect(ratingTriggeredByExams(4), isFalse);
      expect(ratingTriggeredByCoach(ratingCoachMessageThreshold - 1), isFalse);
      expect(ratingTriggeredByCoach(ratingCoachMessageThreshold), isTrue);
      expect(ratingTriggeredByCoach(ratingCoachMessageThreshold + 1), isFalse);
    });
  });

  /// Pencere içeriği görünüm alanından uzundur → dokunmadan önce hedefi görünür alana getir.
  Future<void> tapIn(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  group('pencere — referans tasarım', () {
    Future<void> openFromProfile(WidgetTester tester, {FakeStoreReviewService? store}) async {
      await useTallSurface(tester);
      await pumpApp(tester, storeReview: store);
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Uygulamayı puanla'), 200);
      await tester.tap(find.text('Uygulamayı puanla'));
      await tester.pumpAndSettle();
    }

    testWidgets('Profil’den açılır ve referans içeriği taşır', (tester) async {
      await openFromProfile(tester);

      expect(find.text('Deneyimin bizim için\nçok değerli!'), findsOneWidget);
      expect(find.text('Puanlamak için bir yıldız seç'), findsOneWidget);
      for (final t in const ['Desteğin Önemli', 'Daha İyi Olalım', 'Daha Fazla Kişiye Ulaşalım']) {
        expect(find.text(t), findsOneWidget, reason: '"$t" sütunu eksik');
      }
      expect(find.text('Uygulamayı Puanla'), findsOneWidget);
      expect(find.text('Daha Sonra Hatırlat'), findsOneWidget);
      // Dürüstlük satırı: puan burada değil, mağazada veriliyor.
      expect(find.text("Puanını Google Play'de vereceksin."), findsOneWidget);
    });

    testWidgets('yıldıza dokunmak görsel geri bildirim verir', (tester) async {
      await openFromProfile(tester);
      expect(find.text('Teşekkürler!'), findsNothing);

      await tester.tap(find.byIcon(Icons.star_border_rounded).at(3));
      await tester.pumpAndSettle();
      expect(find.text('Teşekkürler!'), findsOneWidget);
    });

    /// POLİTİKA: hangi yıldız seçilirse seçilsin AYNI yere gidilir. Düşük puanı başka bir yola
    /// ayırmak (feedback formu) Play politikasına aykırıdır.
    testWidgets('düşük yıldız da mağazaya gider — yol AYRILMAZ', (tester) async {
      final store = FakeStoreReviewService();
      await openFromProfile(tester, store: store);

      await tester.tap(find.byIcon(Icons.star_border_rounded).first); // 1 yıldız
      await tester.pumpAndSettle();
      await tapIn(tester, 'Uygulamayı Puanla');

      expect(store.openCalls, 1);
    });

    testWidgets('mağaza açılamazsa dürüst mesaj', (tester) async {
      final store = FakeStoreReviewService(succeeds: false);
      await openFromProfile(tester, store: store);
      await tapIn(tester, 'Uygulamayı Puanla');

      expect(find.text('Mağaza açılamadı. Google Play yüklü mü?'), findsOneWidget);
      // Açılamadıysa "puanladı" işareti KONMAZ — yoksa kullanıcıya bir daha hiç sorulmazdı.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ea:ratingPrompt:v1') ?? '', isNot(contains('"rated":true')));
    });
  });

  group('kalıcılık', () {
    testWidgets('puanlamaya gidince işaret kalıcı yazılır', (tester) async {
      final store = FakeStoreReviewService();
      await useTallSurface(tester);
      await pumpApp(tester, storeReview: store);
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Uygulamayı puanla'), 200);
      await tester.tap(find.text('Uygulamayı puanla'));
      await tester.pumpAndSettle();
      await tapIn(tester, 'Uygulamayı Puanla');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ea:ratingPrompt:v1'), contains('"rated":true'));
    });

    testWidgets('"Daha Sonra Hatırlat" erteleme yazar', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester);
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Uygulamayı puanla'), 200);
      await tester.tap(find.text('Uygulamayı puanla'));
      await tester.pumpAndSettle();
      await tapIn(tester, 'Daha Sonra Hatırlat');

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('ea:ratingPrompt:v1') ?? '';
      expect(raw, isNot(contains('"snoozeMs":0')));
      expect(find.text('Deneyimin bizim için\nçok değerli!'), findsNothing);
    });
  });
}

/// Testlerde mağaza kanalına gidilmez.
class FakeStoreReviewService implements StoreReviewService {
  FakeStoreReviewService({this.succeeds = true});
  final bool succeeds;
  int openCalls = 0;

  @override
  Future<bool> openStoreListing() async {
    openCalls++;
    return succeeds;
  }
}
