import 'dart:isolate';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/analytics.dart';
import '../app_version.dart';
import 'error_report.dart';

const _kQueue = 'ea:errors:queue:v1';

/// Kuyrukta tutulan en fazla rapor sayısı.
///
/// Analitik kuyruğundan (500) çok daha KÜÇÜK ve nedeni var: çökme döngüsüne giren bir uygulama
/// saniyede onlarca aynı raporu üretebilir. Elli, teşhis için fazlasıyla yeterlidir; ötesi aynı
/// bilginin tekrarıdır.
const int kErrorQueueLimit = 50;

/// Aynı parmak izinden ARKA ARKAYA kaç rapor gönderilir.
///
/// Çökme döngüsü (her karede fırlatan bir çizim hatası) saniyede yüzlerce olay üretir. Hepsini
/// göndermek hem cihazın pilini hem sunucuyu boşuna yorar ve teşhise HİÇBİR ŞEY katmaz: yüzüncü
/// kopya, birincisinden fazlasını söylemez. Bu yüzden aynı parmak izi kısa pencerede susturulur.
const int kSameFingerprintBurst = 3;

/// Susturma penceresi.
const Duration kFingerprintWindow = Duration(minutes: 5);

/// Beta Faz 4 — üretim hata gözlemlenebilirliği.
///
/// ## Neden üçüncü taraf SDK yok
///
/// Crashlytics/Sentry taşımak, KVKK açısından ayrı bir karar (üçüncü tarafa veri aktarımı) ve
/// uygulamaya ek bir yerel bağımlılık demek. Raporlar kendi sunucumuza gider; şema, saklama süresi
/// ve içerik bizim denetimimizde kalır. Gerekirse üçüncü taraf sonradan **eklenebilir** — bu sınıf
/// bir sink soyutlaması olduğu için o değişiklik çağrı yerlerine dokunmaz.
///
/// ## Neden analitikle aynı desen
///
/// Kalıcı kuyruk, toplu gönderim, yutulan hatalar. Bir çökme raporunun kendisi çökmeye yol
/// açamaz ve ağ yokken kaybolamaz — çökmelerin çoğu zaten ağın kötü olduğu anlarda olur.
class ErrorReporter {
  ErrorReporter({
    required Dio dio,
    String Function()? currentRoute,
    Analytics? analytics,
    DateTime Function()? clock,
    Random? random,
  }) : _dio = dio,
       _currentRoute = currentRoute,
       _analytics = analytics,
       _now = clock ?? DateTime.now,
       _random = random ?? Random.secure();

  final Dio _dio;
  final String Function()? _currentRoute;
  final Analytics? _analytics;
  final DateTime Function() _now;
  final Random _random;

  bool _flushing = false;

  /// Parmak izi → (pencere başlangıcı, o pencerede gönderilen sayı).
  final Map<String, ({DateTime since, int count})> _burst = {};

  /// Test/tanılama: bu oturumda susturulan rapor sayısı.
  int suppressedCount = 0;

  /// Hatayı kaydet. **Asla fırlatmaz** ve beklenmesi gerekmez.
  Future<void> report(
    Object error,
    StackTrace? stack, {
    required ErrorKind kind,
    bool fatal = false,
    Map<String, Object?> extra = const {},
  }) async {
    try {
      final stackText = (stack ?? StackTrace.current).toString();
      final fingerprint = fingerprintOf(kind: kind, error: error, stack: stackText);
      if (_isSuppressed(fingerprint)) {
        suppressedCount++;
        return;
      }

      final version = await AppVersion.load();
      final report = ErrorReport(
        id: _newId(),
        kind: kind,
        fingerprint: fingerprint,
        message: _describe(error),
        // Yığın izi KIRPILIR: sunucu da kırpıyor ama kuyruk dosyasını şişirmenin anlamı yok.
        stack: stackText.length > 8000 ? stackText.substring(0, 8000) : stackText,
        route: _currentRoute?.call() ?? '',
        at: _now(),
        fatal: fatal,
        anonId: _analytics?.context?.anonId ?? '',
        appVersion: version.label,
        context: {
          ...extra,
          // Son olaylar = "kullanıcı bu hatadan hemen önce ne yaptı". Tek başına yığın izinin
          // söylemediği şey budur ve çoğu zaman yeniden üretmenin tek yoludur.
          if (_analytics != null) 'breadcrumbs': _analytics.breadcrumbs.join(' > '),
        },
      );
      // Hata ayıklama derlemesinde konsola da düşer — bir hatanın gerçekten YAKALANDIĞINI
      // görmenin en hızlı yolu budur (analitikteki `DebugAnalyticsSink` ile aynı gerekçe) ve
      // üretim derlemesine sızmaz.
      if (kDebugMode) {
        debugPrint('[error:${kind.wire}] ${report.message} @${report.route} (${report.fingerprint})');
      }
      await _appendToQueue(report);
      flush().ignore();
    } catch (_) {
      // Raporlamanın kendisi hiçbir koşulda ürünü etkilemez.
    }
  }

  /// Aynı parmak izi kısa pencerede çok tekrarladı mı?
  bool _isSuppressed(String fingerprint) {
    final now = _now();
    final seen = _burst[fingerprint];
    if (seen == null || now.difference(seen.since) > kFingerprintWindow) {
      _burst[fingerprint] = (since: now, count: 1);
      return false;
    }
    if (seen.count >= kSameFingerprintBurst) return true;
    _burst[fingerprint] = (since: seen.since, count: seen.count + 1);
    return false;
  }

  /// Hatanın okunabilir özeti.
  ///
  /// `PlatformException` ve `DioException` için `toString()` gürültülüdür ve en önemli alanı
  /// (kod / durum) gömer; teşhiste ilk bakılan şey odur, bu yüzden öne çıkarılır.
  String _describe(Object error) {
    final text = switch (error) {
      PlatformException e => 'PlatformException(${e.code}): ${e.message ?? ''}',
      DioException e => 'DioException(${e.type.name}): ${e.response?.statusCode ?? ''} '
          '${e.requestOptions.path}',
      _ => error.toString(),
    };
    return text.length > 400 ? text.substring(0, 400) : text;
  }

  String _newId() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(20, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
  }

  Future<void> _appendToQueue(ErrorReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queued = decodeReports(prefs.getString(_kQueue) ?? '[]')..add(report);
      final trimmed = queued.length > kErrorQueueLimit
          ? queued.sublist(queued.length - kErrorQueueLimit)
          : queued;
      await prefs.setString(_kQueue, encodeReports(trimmed));
    } catch (_) {}
  }

  /// Bekleyen raporları gönder (açılışta ve her yeni raporda tetiklenir).
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      for (;;) {
        final prefs = await SharedPreferences.getInstance();
        final queued = decodeReports(prefs.getString(_kQueue) ?? '[]');
        if (queued.isEmpty) return;

        final batch = queued.take(kErrorQueueLimit).toList();
        if (!await _send(batch)) return;

        final sentIds = {for (final r in batch) r.id};
        final after = decodeReports(prefs.getString(_kQueue) ?? '[]')
            .where((r) => !sentIds.contains(r.id))
            .toList();
        await prefs.setString(_kQueue, encodeReports(after));
        if (after.isEmpty) return;
      }
    } catch (_) {
    } finally {
      _flushing = false;
    }
  }

  /// Kuyruktan düşürme kuralı analitikle AYNI (gerekçe: `analytics_sink.dart`).
  Future<bool> _send(List<ErrorReport> batch) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/errors/report',
        data: {'reports': [for (final r in batch) r.toJson()]},
        options: Options(validateStatus: (s) => s != null && s < 600),
      );
      final code = res.statusCode ?? 0;
      if (code >= 200 && code < 300) return true;
      return code == 400 || code == 401 || code == 403;
    } on DioException catch (_) {
      return false;
    }
  }

  /// Kuyrukta bekleyen rapor sayısı (tanılama ve test için).
  static Future<int> pendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return decodeReports(prefs.getString(_kQueue) ?? '[]').length;
    } catch (_) {
      return 0;
    }
  }
}

/// Uygulamanın hata raportörü. Testlerde bellek-içi bir Dio ile ezilir; varsayılan da zararsızdır
/// (ağ yoksa kuyrukta kalır ve hiçbir şey kırılmaz).
final errorReporterProvider = Provider<ErrorReporter>((ref) {
  throw UnimplementedError('errorReporterProvider main()/test içinde override edilir');
});

/// Beta Faz 4 — YAKALANMAMIŞ hataların TAMAMINI tek yerden bağla.
///
/// Üç kanal vardır ve **üçü de gereklidir**; biri eksikse o sınıf hata sessizce kaybolur:
///
/// 1. `FlutterError.onError` — widget ağacı, düzen ve çizim hataları.
/// 2. `PlatformDispatcher.instance.onError` — Flutter'ın yakalamadığı TÜM asenkron hatalar.
/// 3. `Isolate.addErrorListener` — ana izolat DIŞINDA (arka plan işlerinde) doğan hatalar.
///    Diğer ikisi bunu GÖRMEZ; `compute()` içinde patlayan bir iş sessizce kaybolurdu.
///
/// ## `runZonedGuarded` neden YOK (cihazda ölçülerek çıkarıldı)
///
/// İlk yazımda dördüncü bir kanal olarak `runZonedGuarded` vardı. Gerçek cihazda uygulama
/// açılışında **"Zone mismatch."** hatası üretti — ve bunu, tam da bu fazda kurulan raportörün
/// kendisi yakaladı.
///
/// Kök neden: `WidgetsFlutterBinding.ensureInitialized()` `main()` başında, KÖK bölgede çağrılıyor;
/// `runZonedGuarded` ise `runApp`'ı YENİ bir bölgede çalıştırıyor. Flutter, bağlayıcının kurulduğu
/// bölge ile çalıştığı bölgenin aynı olmasını şart koşar.
///
/// İki çözüm vardı: (a) bütün `main()` gövdesini korunmuş bölgenin içine almak, (b) bölgeyi hiç
/// kullanmamak. **(b) seçildi**, çünkü `PlatformDispatcher.onError` (Flutter 3.3'ten beri) zaten
/// yakalanmamış asenkron hataların tamamını görür ve Flutter'ın kendi belgeleri de artık bunu
/// önerir. (a) ise `main()`'i bölgeye sarmakla kalmaz; ileride oraya eklenen her satırın da o
/// bölgede kalmasını gerektiren, sessizce bozulabilen bir kural yaratırdı.
void installErrorHandlers(ErrorReporter reporter, void Function() runApp) {
  final previousOnError = FlutterError.onError;

  FlutterError.onError = (details) {
    // Konsola yazmayı SÜRDÜR: geliştirme sırasında kırmızı ekran ve yığın izi hâlâ görünmeli.
    previousOnError?.call(details);
    reporter.report(
      details.exception,
      details.stack,
      // Düzen/çizim hataları ayrı bir tür: taşma ve sonsuz kısıt, mantık hatalarından tamamen
      // farklı bir iş kolu ve karıştırılırsa ikisi de kaybolur.
      kind: _looksLikeRendering(details) ? ErrorKind.rendering : ErrorKind.flutter,
      extra: {
        if (details.library != null) 'library': details.library!,
        // `silent` olan hatalar geliştirme sırasında bilinçli olarak bastırılmıştır.
        'silent': details.silent,
      },
    ).ignore();
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.report(error, stack, kind: _kindOf(error), fatal: true).ignore();
    // `true` = "işlendi". `false` dönmek uygulamayı sonlandırırdı; kullanıcıyı bir ölçüm
    // uğruna uygulamadan atmak kabul edilemez.
    return true;
  };

  // Ana izolat dışındaki hatalar. Mesaj biçimi: [hata metni, yığın izi metni].
  Isolate.current.addErrorListener(
    RawReceivePort((List<dynamic> pair) {
      reporter
          .report(
            pair.isNotEmpty ? pair.first ?? 'isolate error' : 'isolate error',
            pair.length > 1 && pair[1] != null ? StackTrace.fromString('${pair[1]}') : null,
            kind: ErrorKind.isolate,
            fatal: true,
          )
          .ignore();
    }).sendPort,
  );

  runApp();
}

/// Hatanın türünü NESNESİNDEN çıkar — çağıranın elle sınıflandırmasına gerek kalmasın.
ErrorKind _kindOf(Object error) => switch (error) {
  DioException _ => ErrorKind.network,
  PlatformException _ => ErrorKind.platform,
  MissingPluginException _ => ErrorKind.platform,
  _ => ErrorKind.async_,
};

/// Hata düzen/çizim katmanından mı geldi?
///
/// Flutter bunu ayrı bir tiple bildirmez; kütüphane adı ("rendering library") ve bilinen taşma
/// metni en güvenilir işaretlerdir.
bool _looksLikeRendering(FlutterErrorDetails details) {
  final library = details.library ?? '';
  if (library.contains('rendering')) return true;
  final text = details.exception.toString();
  return text.contains('overflowed by') || text.contains('RenderBox was not laid out');
}
