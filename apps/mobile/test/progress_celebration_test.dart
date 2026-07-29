import 'dart:typed_data';

import 'package:ehliyet_akademi/data/share/share_service.dart';
import 'package:ehliyet_akademi/design/confetti.dart';
import 'package:ehliyet_akademi/design/share_card.dart';
import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/practice/srs.dart';
import 'package:ehliyet_akademi/domain/progress/badge_celebration.dart';
import 'package:ehliyet_akademi/domain/progress/gamification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Faz 10 — rozet kutlaması, konfeti ve paylaşım.
void main() {
  group('yeni rozet bulma (saf)', () {
    final achievements = computeAchievements(
      answers: [
        for (var i = 0; i < 3; i++)
          AnswerLog(questionId: 'q$i', subject: Subject.trafik, topic: 't', correct: true, at: i),
      ],
      streak: StreakState.empty,
      examsFinished: 0,
    );

    test('daha önce kutlanmamış açık rozet YENİDİR', () {
      final fresh = newlyUnlocked(achievements: achievements, alreadyCelebrated: const {});
      expect(fresh.map((a) => a.id), contains('first-steps'));
    });

    test('kutlanmış rozet tekrar dönmez', () {
      final fresh = newlyUnlocked(
        achievements: achievements,
        alreadyCelebrated: const {'first-steps'},
      );
      expect(fresh.map((a) => a.id), isNot(contains('first-steps')));
    });

    test('kilitli rozet asla dönmez', () {
      final fresh = newlyUnlocked(achievements: achievements, alreadyCelebrated: const {});
      for (final a in fresh) {
        expect(a.unlocked, isTrue);
      }
      expect(fresh.map((a) => a.id), isNot(contains('century')));
    });
  });

  group('kutlama penceresi', () {
    /// Rozet kazanınca kullanıcı ilerlemeye girdiğinde kutlama açılır ve işaret kalıcı yazılır —
    /// aynı rozet için ikinci kez açılmaz.
    testWidgets('yeni rozet kutlanır ve bir daha kutlanmaz', (tester) async {
      await useTallSurface(tester);
      await pumpApp(
        tester,
        prefs: {
          // Bir soru çözülmüş → "İlk Adım" açık. Kutlama defteri BOŞ DEĞİL ki ilk senkron
          // sessiz yolu çalışmasın; başka bir rozet kutlanmış gibi başlıyoruz.
          'ea:answers:v1':
              '[{"questionId":"q1","subject":"trafik","topic":"t","correct":true,"at":1}]',
          'ea:celebratedBadges:v1': '["century"]',
        },
      );

      await tester.tap(find.text('Ana Sayfa').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('İstatistiklerim'), 200);
      await tester.tap(find.text('İstatistiklerim'));
      await tester.pumpAndSettle();

      expect(find.text('ROZET KAZANDIN'), findsOneWidget);
      expect(find.text('İlk Adım'), findsWidgets);
      expect(find.text('Paylaş'), findsOneWidget);

      await tester.tap(find.text('Kapat'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ea:celebratedBadges:v1'), contains('first-steps'));
    });

    /// İLK senkron: defter boşken açık rozetler SESSİZCE işaretlenir. Aksi hâlde uygulamayı yeni
    /// kuran ama ilerlemesi olan kullanıcıya arka arkaya pencereler açılırdı.
    testWidgets('ilk senkronda kutlama açılmaz, rozetler sessizce işaretlenir', (tester) async {
      await useTallSurface(tester);
      await pumpApp(
        tester,
        prefs: {
          'ea:answers:v1':
              '[{"questionId":"q1","subject":"trafik","topic":"t","correct":true,"at":1}]',
        },
      );

      await tester.tap(find.text('Ana Sayfa').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('İstatistiklerim'), 200);
      await tester.tap(find.text('İstatistiklerim'));
      await tester.pumpAndSettle();

      expect(find.text('ROZET KAZANDIN'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ea:celebratedBadges:v1'), contains('first-steps'));
    });

    /// KAPSAM SINIRI — bilinçli.
    ///
    /// Gerçek görüntü alma (`toImage`) MOTORUN rasterleştirmesine bağlıdır ve widget testinin
    /// sahte-zaman bölgesinde tamamlanmaz. Bu yüzden burada YEDEK yol doğrulanır: görüntü
    /// alınamadığında kullanıcı elinde hiçbir şey olmadan kalmaz, metin paylaşılır.
    /// Görsel yolu `integration_test` içinde, gerçek cihazda doğrulanır.
    testWidgets('görüntü alınamazsa metin paylaşılır (kullanıcı boşta kalmaz)', (tester) async {
      final share = FakeShareService();
      await useTallSurface(tester);
      await pumpApp(
        tester,
        share: share,
        prefs: {
          'ea:answers:v1':
              '[{"questionId":"q1","subject":"trafik","topic":"t","correct":true,"at":1}]',
          'ea:celebratedBadges:v1': '["century"]',
        },
      );

      await tester.tap(find.text('Ana Sayfa').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('İstatistiklerim'), 200);
      await tester.tap(find.text('İstatistiklerim'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Paylaş'));
      await tester.pumpAndSettle();

      expect(share.imageCalls + share.textCalls, 1, reason: 'bir yolla paylaşılmalı');
      expect(share.lastText, contains('İlk Adım'));
    });
  });

  group('konfeti', () {
    /// E13 erişilebilirlik kuralı — kutlama da bu kurala tabidir.
    testWidgets('hareket azaltıldığında konfeti hiç çizilmez', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ConfettiBurst(colors: [Color(0xFF00FF00)]),
          ),
        ),
      );
      await tester.pumpAndSettle(); // sonsuz animasyon olsaydı burada asılırdı
      expect(find.byType(CustomPaint), findsNothing);
    });
  });

  group('paylaşım kartları', () {
    /// Kart SABİT ölçüdedir: paylaşılan görsel her cihazda aynı çıkmalı.
    testWidgets('rozet kartı 1080×1350 çizilir', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrapCard(BadgeShareCard(achievement: achievementCatalog().first)),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(BadgeShareCard)), const Size(1080, 1350));
    });

    testWidgets('sınav sonucu kartı yüzdeyi ve sonucu gösterir', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrapCard(
          const ExamResultShareCard(correct: 42, total: 50, passed: true, durationLabel: '32:14'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('%84'), findsOneWidget);
      expect(find.text('42/50'), findsOneWidget);
      expect(find.text('32:14'), findsOneWidget);
      expect(find.text('DENEME SINAVINI GEÇTİM'), findsOneWidget);
    });

    testWidgets('geçemeyen sonuç dürüstçe etiketlenir', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrapCard(
          const ExamResultShareCard(correct: 20, total: 50, passed: false, durationLabel: '18:02'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('DENEME SINAVI SONUCUM'), findsOneWidget);
      expect(find.text('TEKRAR'), findsOneWidget);
    });
  });
}

/// Sabit ölçülü paylaşım kartını test yüzeyine oturt.
///
/// Kart 1080×1350'dir ve ekran genişliğinden bağımsızdır; `MaterialApp`'in kısıtlarına
/// sokulursa küçülür ve ölçü iddiaları anlamsızlaşır. `UnconstrainedBox` doğal ölçüsünü korur.
Widget wrapCard(Widget card) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: UnconstrainedBox(child: card)),
);

/// Testlerde paylaşım kanalına gidilmez.
class FakeShareService implements ShareService {
  int imageCalls = 0;
  int textCalls = 0;
  String? lastText;

  @override
  Future<bool> shareImage({
    required Uint8List pngBytes,
    required String fileName,
    required String text,
  }) async {
    imageCalls++;
    lastText = text;
    return true;
  }

  @override
  Future<bool> shareText(String text) async {
    textCalls++;
    lastText = text;
    return true;
  }
}
