import 'package:dio/dio.dart';
import 'package:ehliyet_akademi/core/analytics/analytics.dart';
import 'package:ehliyet_akademi/core/analytics/analytics_event.dart';
import 'package:ehliyet_akademi/core/analytics/analytics_sink.dart';
import 'package:ehliyet_akademi/core/app_version.dart';
import 'package:ehliyet_akademi/core/network/api_client.dart';
import 'package:ehliyet_akademi/core/storage/token_store.dart';
import 'package:ehliyet_akademi/core/observability/error_report.dart';
import 'package:ehliyet_akademi/core/observability/error_reporter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Beta Faz 4 — çökme ve hata gözlemlenebilirliği.
///
/// Buradaki testlerin çoğu "rapor yazıldı mı" değil, **raporlamanın ürünü bozmadığını** ve
/// gruplamanın işe yaradığını ölçer. Kötü bir gruplama, bin kopya hatayı bin ayrı satır gibi
/// gösterir ve "kaç farklı hatamız var" sorusunu cevapsız bırakır — bu, hiç raporlamamaktan çok
/// daha sinsi bir başarısızlıktır.
void main() {
  late Dio dio;
  late _RecordingAdapter adapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppVersion.setForTest(const AppVersion(name: '1.0.0', build: '4'));
    adapter = _RecordingAdapter();
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'))..httpClientAdapter = adapter;
  });

  tearDown(() => AppVersion.setForTest(null));

  group('parmak izi (gruplama)', () {
    const stack = '''
#0      List._setIndexed (dart:core-patch/growable_array.dart:158:60)
#1      ExamRunner.build (package:ehliyet_akademi/features/practice/exam_runner_screen.dart:221:14)
#2      StatefulElement.build (package:flutter/src/widgets/framework.dart:5876:27)
''';

    test('KENDİ kodumuzdaki en üst çerçeve seçilir, Flutter içi değil', () {
      // Flutter'ın kendi çerçeveleriyle gruplamak, birbiriyle ilgisi olmayan hataları aynı kovaya
      // atardı: hepsi "framework.dart:5876" olurdu.
      expect(topAppFrame(stack), 'features/practice/exam_runner_screen.dart:221');
    });

    test('mesajdaki DEĞİŞKEN, parmak izini bölmez', () {
      // Aynı hatanın iki farklı çalıştırması ("index 7", "index 12") tek grup olmalı; yoksa tek
      // bir hata yüzlerce satıra dağılır.
      final a = fingerprintOf(
        kind: ErrorKind.flutter,
        error: RangeError('index 7 out of range'),
        stack: stack,
      );
      final b = fingerprintOf(
        kind: ErrorKind.flutter,
        error: RangeError('index 12 out of range'),
        stack: stack,
      );
      expect(a, b);
      expect(a, contains('exam_runner_screen.dart:221'));
    });

    test('FARKLI tür ya da farklı yer → farklı grup', () {
      final range = fingerprintOf(kind: ErrorKind.flutter, error: RangeError('x'), stack: stack);
      final state = fingerprintOf(kind: ErrorKind.flutter, error: StateError('x'), stack: stack);
      expect(range, isNot(state));

      final other = fingerprintOf(
        kind: ErrorKind.flutter,
        error: RangeError('x'),
        stack: stack.replaceAll('exam_runner_screen.dart:221', 'home_screen.dart:12'),
      );
      expect(range, isNot(other));
    });

    test('kendi kodumuzdan çerçeve yoksa çökmez', () {
      expect(topAppFrame('#0 something (dart:core/foo.dart:1:1)'), isNotEmpty);
      expect(topAppFrame(''), 'unknown');
    });
  });

  group('çökme döngüsü susturma', () {
    /// Her karede fırlatan bir çizim hatası saniyede yüzlerce rapor üretir. Yüzüncü kopya
    /// birincisinden fazlasını söylemez; hepsini göndermek pili ve sunucuyu boşuna yorar.
    test('aynı parmak izi kısa pencerede sınırlanır', () async {
      final reporter = ErrorReporter(dio: dio);
      for (var i = 0; i < 20; i++) {
        await reporter.report(StateError('döngü'), StackTrace.current, kind: ErrorKind.flutter);
      }
      expect(reporter.suppressedCount, greaterThan(0));
      expect(await ErrorReporter.pendingCount(), lessThanOrEqualTo(kSameFingerprintBurst));
    });

    test('FARKLI hatalar birbirini susturmaz', () async {
      final reporter = ErrorReporter(dio: dio);
      // Farklı türler → farklı parmak izi → her biri kendi kotasını kullanır.
      await reporter.report(StateError('a'), StackTrace.current, kind: ErrorKind.flutter);
      await reporter.report(ArgumentError('b'), StackTrace.current, kind: ErrorKind.network);
      expect(reporter.suppressedCount, 0);
    });
  });

  group('rapor içeriği', () {
    test('platform ve ağ hatalarının ÖZETİ, koda/duruma göre öne çıkar', () async {
      final reporter = ErrorReporter(dio: dio);
      await reporter.report(
        PlatformException(code: 'sign_in_failed', message: 'ApiException: 10'),
        StackTrace.current,
        kind: ErrorKind.platform,
      );
      await pumpEventQueue();

      final sent = adapter.lastReports.single;
      // Teşhiste ilk bakılan şey koddur; `toString()` onu gürültünün içine gömer.
      expect(sent['message'], contains('sign_in_failed'));
      expect(sent['message'], contains('ApiException: 10'));
    });

    /// Yığın izi NEREDE kırıldığını söyler, NASIL gelindiğini söylemez. Kullanıcıya "ne yaptınız?"
    /// diye sormak da güvenilir bir cevap vermez — kimse adımlarını hatırlamaz.
    test('son olaylar (breadcrumb) rapora eklenir', () async {
      final analytics = Analytics(sink: MemoryAnalyticsSink());
      await analytics.log(AnalyticsEvent.appOpened);
      await analytics.log(AnalyticsEvent.progressScreen);
      await analytics.log(AnalyticsEvent.premiumScreenViewed(source: 'home'));

      final reporter = ErrorReporter(dio: dio, analytics: analytics);
      await reporter.report(StateError('patladı'), StackTrace.current, kind: ErrorKind.flutter);
      await pumpEventQueue();

      expect(
        adapter.lastReports.single['context'],
        containsPair('breadcrumbs', 'app_opened > progress_screen > premium_screen_viewed'),
      );
    });

    test('rota rapora yazılır — "nerede" sorusunun cevabı', () async {
      final reporter = ErrorReporter(dio: dio, currentRoute: () => '/practice/exam');
      await reporter.report(StateError('x'), StackTrace.current, kind: ErrorKind.flutter);
      await pumpEventQueue();
      expect(adapter.lastReports.single['route'], '/practice/exam');
    });

    test('tür TEL ÜZERİNDEKİ adıyla gider (sunucu beyaz listesiyle aynı)', () {
      expect(ErrorKind.async_.wire, 'async');
      expect(ErrorKind.googleSignIn.wire, 'google-signin');
      // Dart'a özgü kaçışlar (`async_`) sunucuya sızmamalı.
      for (final k in ErrorKind.values) {
        expect(k.wire, isNot(contains('_')), reason: '${k.name} tel adı tire kullanmalı');
      }
    });
  });

  _networkInterceptorGuard();

  group('dayanıklılık', () {
    test('ağ yokken rapor KUYRUKTA kalır', () async {
      final offline = Dio(BaseOptions(baseUrl: 'http://test.local'))
        ..httpClientAdapter = _FailingAdapter();
      final reporter = ErrorReporter(dio: offline);
      await reporter.report(StateError('x'), StackTrace.current, kind: ErrorKind.flutter);
      await pumpEventQueue();
      expect(await ErrorReporter.pendingCount(), 1);
    });

    test('kuyruk sınırı aşılmaz — çökme döngüsü diski doldurmaz', () async {
      final offline = Dio(BaseOptions(baseUrl: 'http://test.local'))
        ..httpClientAdapter = _FailingAdapter();
      final reporter = ErrorReporter(dio: offline);
      // Susturmayı aşmak için her seferinde FARKLI bir hata türü üret.
      for (var i = 0; i < kErrorQueueLimit + 30; i++) {
        await reporter.report(
          StateError('x'),
          StackTrace.fromString('#0 f (package:ehliyet_akademi/a$i.dart:$i:1)'),
          kind: ErrorKind.flutter,
        );
      }
      expect(await ErrorReporter.pendingCount(), lessThanOrEqualTo(kErrorQueueLimit));
    });

    test('raporlama ASLA fırlatmaz — bozuk yığın izi bile', () async {
      final reporter = ErrorReporter(dio: dio);
      await expectLater(
        reporter.report('düz metin hata', null, kind: ErrorKind.async_),
        completes,
      );
    });

    test('bozuk kuyruk kaydı atılır, sağlamlar KALIR', () {
      const raw = '[{"id":"ok","kind":"flutter","at":"2026-07-30T12:00:00Z"},{"bozuk":1},9]';
      expect(decodeReports(raw).map((r) => r.id), ['ok']);
      expect(decodeReports('bu json değil'), isEmpty);
    });

    test('bilinmeyen TÜR taşıyan kayıt atılır', () {
      // Eski/yeni sürüm arasında tür adı değişirse, tanınmayan kayıt sessizce düşer.
      const raw = '[{"id":"x","kind":"uydurma","at":"2026-07-30T12:00:00Z"}]';
      expect(decodeReports(raw), isEmpty);
    });
  });
}

/// Gönderilen gövdeyi kaydeden sahte taşıma.
class _RecordingAdapter implements HttpClientAdapter {
  final List<Map<String, Object?>> lastReports = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = options.data;
    if (data is Map && data['reports'] is List) {
      for (final r in data['reports'] as List) {
        lastReports.add((r as Map).cast<String, Object?>());
      }
    }
    return ResponseBody.fromString('{"accepted":1}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Ağ yokmuş gibi davranan taşıma.
class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => throw DioException.connectionError(
    requestOptions: options,
    reason: 'ağ yok',
  );

  @override
  void close({bool force = false}) {}
}

/// Ağ hatalarının raportöre ULAŞTIĞINI doğrular.
///
/// Bu, `buildDio`'daki tek satırlık bir kancaya bağlı ve kanca sessizce kopabilir: kaldırıldığında
/// hiçbir test kırılmaz, hiçbir hata görünmez — yalnız ağ arızaları bir daha hiç raporlanmaz.
void _networkInterceptorGuard() {
  group('ağ hatası kancası', () {
    test('başarısız istek raportöre bildirilir', () async {
      final seen = <DioException>[];
      final dio = buildDio(MemoryTokenStore(), onNetworkFailure: seen.add)
        ..httpClientAdapter = _FailingAdapter();

      await dio.get<void>('/api/purchases').catchError((Object _) => Response<void>(
            requestOptions: RequestOptions(path: '/api/purchases'),
          ));

      expect(seen, hasLength(1));
      expect(seen.single.requestOptions.path, '/api/purchases');
    });

    /// TELEMETRİ uçlarının kendi hataları bildirilmez.
    ///
    /// Bildirilseydi: sunucu erişilemezken her başarısız gönderim yeni bir rapor üretir, o rapor da
    /// gönderilemeyip yeni bir rapor doğururdu. Kuyruk kendi kendini besleyen bir döngüye girerdi.
    test('telemetri uçlarının kendi hataları bildirilmez (geri besleme döngüsü)', () async {
      final seen = <DioException>[];
      final dio = buildDio(MemoryTokenStore(), onNetworkFailure: seen.add)
        ..httpClientAdapter = _FailingAdapter();

      for (final path in ['/api/analytics/collect', '/api/errors/report']) {
        await dio.post<void>(path).catchError(
              (Object _) => Response<void>(requestOptions: RequestOptions(path: path)),
            );
      }

      expect(seen, isEmpty);
    });
  });
}
