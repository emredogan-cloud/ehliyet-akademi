import 'package:ehliyet_akademi/core/analytics/analytics.dart';
import 'package:ehliyet_akademi/core/analytics/analytics_event.dart';
import 'package:ehliyet_akademi/core/analytics/analytics_sink.dart';
import 'package:ehliyet_akademi/core/app_version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Beta Faz 3 — analitik çekirdeği.
///
/// Burada ölçülen şey "olay gitti mi" değil, **analitiğin ürünü kırmadığı** ve olayların
/// merkezî sözlükten geldiğidir. Ağ katmanı ayrıca test edilir (`RemoteAnalyticsSink`).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppVersion.setForTest(const AppVersion(name: '1.0.0', build: '4'));
  });

  tearDown(() => AppVersion.setForTest(null));

  group('olay kaydı', () {
    test('olay sink\'e bağlamıyla birlikte düşer', () async {
      final sink = MemoryAnalyticsSink();
      final analytics = Analytics(sink: sink);

      await analytics.log(AnalyticsEvent.appOpened);

      expect(sink.names, ['app_opened']);
      expect(sink.records.single.context.appVersion, 'v1.0.0 (4)');
      expect(sink.records.single.context.anonId, isNotEmpty);
      expect(sink.records.single.context.userId, isNull);
    });

    test('anonim kimlik cihazda KALICIDIR — iki örnek aynı kimliği kullanır', () async {
      final first = MemoryAnalyticsSink();
      await Analytics(sink: first).log(AnalyticsEvent.appOpened);

      final second = MemoryAnalyticsSink();
      await Analytics(sink: second).log(AnalyticsEvent.appOpened);

      expect(second.records.single.context.anonId, first.records.single.context.anonId);
    });

    test('oturum açılınca olaylar kullanıcıya bağlanır, çıkışta ÇÖZÜLÜR', () async {
      final sink = MemoryAnalyticsSink();
      final analytics = Analytics(sink: sink);

      await analytics.log(AnalyticsEvent.guestSession);
      analytics.setUser('u-1');
      await analytics.log(AnalyticsEvent.login);
      analytics.setUser(null);
      await analytics.log(AnalyticsEvent.logout);

      expect(sink.records[0].context.userId, isNull);
      expect(sink.records[1].context.userId, 'u-1');
      // Kritik: çıkıştan sonraki olay ÖNCEKİ kullanıcıya yazılmamalı — aynı cihazdaki ikinci
      // kullanıcının davranışı birincisinin kimliğine karışırdı.
      expect(sink.records[2].context.userId, isNull);
    });

    test('sink patlasa bile log() FIRLATMAZ — ölçüm ürünü kırmaz', () async {
      final analytics = Analytics(sink: _ExplodingSink());
      await expectLater(analytics.log(AnalyticsEvent.appOpened), completes);
    });
  });

  group('logOnce', () {
    test('cihaz ömründe bir kez gönderir', () async {
      final sink = MemoryAnalyticsSink();
      final analytics = Analytics(sink: sink);

      expect(await analytics.logOnce(AnalyticsEvent.installed), isTrue);
      expect(await analytics.logOnce(AnalyticsEvent.installed), isFalse);
      expect(sink.count('app_installed'), 1);
    });

    test('işaret KALICIDIR — uygulama yeniden açılınca tekrar gitmez', () async {
      await Analytics(sink: MemoryAnalyticsSink()).logOnce(AnalyticsEvent.firstExam);

      final afterRestart = MemoryAnalyticsSink();
      expect(await Analytics(sink: afterRestart).logOnce(AnalyticsEvent.firstExam), isFalse);
      expect(afterRestart.count('first_exam'), 0);
    });

    test('farklı olaylar birbirinin işaretini tüketmez', () async {
      final sink = MemoryAnalyticsSink();
      final analytics = Analytics(sink: sink);
      expect(await analytics.logOnce(AnalyticsEvent.installed), isTrue);
      expect(await analytics.logOnce(AnalyticsEvent.firstLaunch), isTrue);
      expect(sink.names, ['app_installed', 'first_launch']);
    });
  });

  group('olay sözlüğü', () {
    test('adlar snake_case ve boşluksuz', () {
      for (final e in _allEvents) {
        expect(
          RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(e.name),
          isTrue,
          reason: '"${e.name}" snake_case olmalı',
        );
      }
    });

    test('boyutlar YALNIZ ilkel değer taşır (kişisel veri sızmasın)', () {
      for (final e in _allEvents) {
        for (final entry in e.props.entries) {
          expect(
            entry.value,
            anyOf(isA<String>(), isA<int>(), isA<double>(), isA<bool>()),
            reason: '${e.name}.${entry.key} ilkel olmalı',
          );
        }
      }
    });

    /// Sunucudaki beyaz liste (`apps/web/lib/server/telemetry.ts`) bu adları TANIMAK zorunda.
    /// Liste kaymışsa olay sessizce atılır; bu test ikisinin ayrılmasını zorlaştırır.
    test('sözlük beklenen olayların tamamını içerir', () {
      final names = _allEvents.map((e) => e.name).toSet();
      for (final expected in const [
        'app_installed',
        'first_launch',
        'app_opened',
        'coach_marks_started',
        'coach_marks_completed',
        'coach_marks_skipped',
        'registration',
        'login',
        'google_login',
        'guest_session',
        'logout',
        'account_deleted',
        'first_exam',
        'exam_completed',
        'exam_passed',
        'exam_failed',
        'ai_coach_started',
        'ai_coach_session_length',
        'progress_screen',
        'premium_screen_viewed',
        'purchase_started',
        'purchase_completed',
        'purchase_abandoned',
        'restore_purchases',
        'referral_created',
        'referral_link_opened',
        'referral_accepted',
        'badge_earned',
        'badge_shared',
        'app_rated',
      ]) {
        expect(names, contains(expected));
      }
    });
  });

  group('kayıt serileştirme', () {
    test('gidiş-dönüş bilgi kaybetmez', () {
      final record = AnalyticsRecord(
        id: 'abc123',
        name: 'exam_completed',
        props: const {'correct': 42, 'total': 50, 'passed': true},
        at: DateTime.utc(2026, 7, 30, 12),
        context: const AnalyticsContext(anonId: 'anon-1', appVersion: 'v1.0.0 (4)', userId: 'u-1'),
      );

      final decoded = decodeRecords(encodeRecords([record])).single;
      expect(decoded.id, record.id);
      expect(decoded.name, record.name);
      expect(decoded.props, record.props);
      expect(decoded.at.toUtc(), record.at);
      expect(decoded.context.userId, 'u-1');
    });

    /// Kuyruk dosyası eski bir sürümden kalmış olabilir. Tek bozuk satır yüzünden bütün kuyruğu
    /// çöpe atmak (ya da çökmek) kabul edilemez.
    test('bozuk kayıtlar atılır, sağlamlar KALIR', () {
      const raw = '[{"id":"ok","name":"login","at":"2026-07-30T12:00:00Z"},{"broken":true},7]';
      final decoded = decodeRecords(raw);
      expect(decoded.map((r) => r.name), ['login']);
    });

    test('bozuk JSON boş liste verir, fırlatmaz', () {
      expect(decodeRecords('{ bu json değil'), isEmpty);
      expect(decodeRecords(''), isEmpty);
    });
  });
}

class _ExplodingSink implements AnalyticsSink {
  @override
  Future<void> add(AnalyticsRecord record) async => throw StateError('sink bozuk');
  @override
  Future<void> flush() async => throw StateError('sink bozuk');
}

/// Sözlükteki her olayın bir örneği — üreticiler de dâhil.
final List<AnalyticsEvent> _allEvents = [
  AnalyticsEvent.installed,
  AnalyticsEvent.firstLaunch,
  AnalyticsEvent.appOpened,
  AnalyticsEvent.coachMarksStarted,
  AnalyticsEvent.coachMarksCompleted,
  AnalyticsEvent.coachMarksSkipped(atStep: 3, totalSteps: 9),
  AnalyticsEvent.registration(withReferral: true),
  AnalyticsEvent.login,
  AnalyticsEvent.googleLogin,
  AnalyticsEvent.guestSession,
  AnalyticsEvent.logout,
  AnalyticsEvent.accountDeleted,
  AnalyticsEvent.firstExam,
  AnalyticsEvent.examCompleted(correct: 42, total: 50, passed: true, durationSeconds: 1200),
  AnalyticsEvent.examPassed(correct: 42, total: 50),
  AnalyticsEvent.examFailed(correct: 20, total: 50),
  AnalyticsEvent.aiCoachStarted,
  AnalyticsEvent.aiCoachSessionLength(seconds: 300, turns: 6),
  AnalyticsEvent.progressScreen,
  AnalyticsEvent.premiumScreenViewed(source: 'home'),
  AnalyticsEvent.purchaseStarted(productId: 'premium_lifetime'),
  AnalyticsEvent.purchaseCompleted(productId: 'premium_lifetime', guest: false),
  AnalyticsEvent.purchaseAbandoned(productId: 'premium_lifetime', reason: 'cancelled'),
  AnalyticsEvent.restorePurchases(found: 1),
  AnalyticsEvent.referralCreated(channel: 'share'),
  AnalyticsEvent.referralLinkOpened(signedIn: false),
  AnalyticsEvent.referralAccepted(accepted: true),
  AnalyticsEvent.badgeEarned(badgeId: 'first_pass'),
  AnalyticsEvent.badgeShared(badgeId: 'first_pass'),
  AnalyticsEvent.appRated,
];
