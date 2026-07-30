import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Bir hatanın TÜRÜ — sunucudaki beyaz liste (`apps/web/lib/server/telemetry.ts`) ile aynı.
///
/// Tür, "nerede kırıldı" sorusunun ilk cevabıdır ve gruplamanın en kaba eksenidir. Hepsini tek bir
/// "hata" kovasına atmak, ağ kesintisiyle çizim hatasını aynı listede gösterirdi; ikisi tamamen
/// farklı işler gerektirir.
enum ErrorKind {
  /// `FlutterError.onError` — widget/çizim katmanında yakalanan hata.
  flutter('flutter'),

  /// Yakalanmamış asenkron hata (`PlatformDispatcher.onError` / zone).
  async_('async'),

  /// `PlatformException` — bir eklenti/kanal hatası.
  platform('platform'),

  /// Ağ hatası (zaman aşımı, bağlantı yok, DNS).
  network('network'),

  /// Mağaza (Play Billing) hatası.
  store('store'),

  /// Google ile giriş hatası.
  googleSignIn('google-signin'),

  /// Ana izolat dışında oluşan hata.
  isolate('isolate'),

  /// Düzen/çizim (overflow, sonsuz kısıt) hatası.
  rendering('rendering');

  const ErrorKind(this.wire);

  /// Sunucuya giden değer. Enum adı DEĞİL: `async_` gibi Dart'a özgü kaçışlar tel üzerinde
  /// görünmemeli ve enum yeniden adlandırıldığında sunucu beyaz listesi kırılmamalı.
  final String wire;
}

/// Sunucuya giden tek hata kaydı.
@immutable
class ErrorReport {
  const ErrorReport({
    required this.id,
    required this.kind,
    required this.fingerprint,
    required this.message,
    required this.stack,
    required this.route,
    required this.at,
    this.context = const {},
    this.fatal = false,
    this.anonId = '',
    this.appVersion = '',
  });

  final String id;
  final ErrorKind kind;

  /// Aynı hatayı gruplayan anahtar. Bkz. [fingerprintOf].
  final String fingerprint;
  final String message;
  final String stack;

  /// Hatanın olduğu ekran — "nerede" sorusunun cevabı.
  final String route;
  final DateTime at;

  /// Cihaz/oturum bağlamı + son olaylar (breadcrumb).
  final Map<String, Object?> context;

  /// Uygulama bu hatadan sonra kullanılamaz hâle geldi mi.
  final bool fatal;

  final String anonId;
  final String appVersion;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.wire,
    'fingerprint': fingerprint,
    'message': message,
    'stack': stack,
    'route': route,
    'context': context,
    'fatal': fatal,
    'anonId': anonId,
    'appVersion': appVersion,
    'at': at.toUtc().toIso8601String(),
  };

  static ErrorReport? fromJson(Map<String, Object?> j) {
    final id = j['id'];
    final at = DateTime.tryParse((j['at'] ?? '').toString());
    if (id is! String || at == null) return null;
    final wire = (j['kind'] ?? '').toString();
    final kind = ErrorKind.values.where((k) => k.wire == wire).firstOrNull;
    if (kind == null) return null;
    return ErrorReport(
      id: id,
      kind: kind,
      fingerprint: (j['fingerprint'] ?? '').toString(),
      message: (j['message'] ?? '').toString(),
      stack: (j['stack'] ?? '').toString(),
      route: (j['route'] ?? '').toString(),
      at: at,
      context: (j['context'] as Map?)?.cast<String, Object?>() ?? const {},
      fatal: j['fatal'] == true,
      anonId: (j['anonId'] ?? '').toString(),
      appVersion: (j['appVersion'] ?? '').toString(),
    );
  }
}

/// Yığın izindeki **kendi kodumuza ait** en üst çerçeve.
///
/// NEDEN kendi kodumuz: bir çökmenin ilk on çerçevesi genellikle Flutter'ın kendi iç katmanlarıdır
/// (`framework.dart`, `binding.dart`). Onlarla gruplamak, birbiriyle hiç ilgisi olmayan hataları
/// aynı kovaya atar — hepsi "framework.dart:5871" olur. Bizim dosyamız, hatanın gerçekten
/// düzeltilebileceği yerdir.
///
/// Kendi kodumuzdan çerçeve yoksa ilk çerçeveye düşülür: bilinen en iyi bilgi odur.
@visibleForTesting
String topAppFrame(String stack) {
  final lines = stack.split('\n');
  for (final line in lines) {
    // `package:ehliyet_akademi/...` — hata ayıklama ve yayın yığınlarının ikisinde de görünür.
    final match = RegExp(r'package:ehliyet_akademi/([\w/]+\.dart):(\d+)').firstMatch(line);
    if (match != null) return '${match.group(1)}:${match.group(2)}';
  }
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) return trimmed.length > 80 ? trimmed.substring(0, 80) : trimmed;
  }
  return 'unknown';
}

/// Aynı hatayı gruplayan anahtar: **tür + hata sınıfı + kendi kodumuzdaki en üst çerçeve**.
///
/// Mesajın KENDİSİ parmak izine girmez ve bu bilinçlidir: mesajlar çoğu zaman değişken taşır
/// ("index 7 out of range", "index 12 out of range") ve girseydi aynı hata yüzlerce ayrı gruba
/// bölünürdü — "kaç farklı hatamız var" sorusu cevapsız kalırdı.
String fingerprintOf({required ErrorKind kind, required Object error, required String stack}) {
  final type = error.runtimeType.toString();
  return '${kind.wire}:$type@${topAppFrame(stack)}';
}

String encodeReports(List<ErrorReport> reports) =>
    jsonEncode([for (final r in reports) r.toJson()]);

List<ErrorReport> decodeReports(String raw) {
  try {
    final list = jsonDecode(raw);
    if (list is! List) return const [];
    final out = <ErrorReport>[];
    for (final item in list) {
      if (item is! Map) continue;
      final report = ErrorReport.fromJson(item.cast<String, Object?>());
      if (report != null) out.add(report);
    }
    return out;
  } catch (_) {
    return const [];
  }
}
