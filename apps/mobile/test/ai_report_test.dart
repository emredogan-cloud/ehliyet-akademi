import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ehliyet_akademi/data/coach/ai_report_api.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faz D — AI Koç yanıtı bildirimi (Play üretken yapay zekâ politikası).
///
/// Politika, rahatsız edici AI çıktısının **uygulamadan çıkmadan** bildirilebilmesini bekliyor.
/// Uygulama AI Koç'u hesapsız da sunduğu için bildirim yolu misafirde de çalışmak zorunda;
/// bu yüzden topluluk bildirimi ucu değil, anonim kabul eden soru bildirimi ucu kullanılıyor.
void main() {
  /// Sunucuya giden gövdeyi yakalayan sahte taşıma.
  ({Dio dio, List<Map<String, dynamic>> sent}) fakeDio(int status) {
    final sent = <Map<String, dynamic>>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dio.httpClientAdapter = _CapturingAdapter(sent, status);
    return (dio: dio, sent: sent);
  }

  test('bildirim gövdesi sunucunun beklediği alanları taşır', () async {
    final f = fakeDio(200);
    final ok = await DioAiReportApi(f.dio).reportReply(
      messageId: 'ai-abc123',
      reason: AiReportReason.harmful,
      replyExcerpt: 'Bu bir AI yanıtıdır.',
    );

    expect(ok, isTrue);
    expect(f.sent, hasLength(1));
    final body = f.sent.single;
    expect(body['questionId'], 'ai-abc123');
    expect(body['kind'], 'harmful');
    expect(body['message'], 'Bu bir AI yanıtıdır.');
    // İki yüzeyi ayıran alan: bu olmadan AI bildirimleri soru bildirimlerine karışırdı.
    expect(body['source'], 'ai-reply');
  });

  test('sebep kimlikleri sunucudaki taksonomiyle birebir aynıdır', () {
    // Sunucu bilinmeyen bir `kind` değerini 400 ile reddeder; ayrışma sessizce bildirim
    // kaybettirirdi. Bu liste `apps/web/lib/server/reports.ts` → REPORT_KINDS ile eşleşmeli.
    expect(AiReportReason.values.map((r) => r.wire).toList(), [
      'harmful',
      'wrong-answer',
      'unclear',
      'other',
    ]);
    for (final r in AiReportReason.values) {
      expect(r.label, isNotEmpty);
    }
  });

  test('çok uzun yanıt kırpılır — istek gövdesi sınırsız büyümez', () async {
    final f = fakeDio(200);
    await DioAiReportApi(f.dio).reportReply(
      messageId: 'ai-uzun',
      reason: AiReportReason.other,
      replyExcerpt: 'x' * 5000,
    );
    final message = f.sent.single['message'] as String;
    expect(message.length, lessThanOrEqualTo(901));
    expect(message.endsWith('…'), isTrue);
  });

  test(
    'sunucu hatası kullanıcı akışını KESMEZ — false döner, fırlatmaz',
    () async {
      final f = fakeDio(400);
      await expectLater(
        DioAiReportApi(f.dio).reportReply(
          messageId: 'ai-x',
          reason: AiReportReason.unclear,
          replyExcerpt: 'y',
        ),
        completion(isFalse),
      );
    },
  );

  test('ağ yokken de fırlatmaz', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dio.httpClientAdapter = _ThrowingAdapter();
    await expectLater(
      DioAiReportApi(dio).reportReply(
        messageId: 'ai-x',
        reason: AiReportReason.other,
        replyExcerpt: 'y',
      ),
      completion(isFalse),
    );
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.sent, this.status);
  final List<Map<String, dynamic>> sent;
  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sent.add(Map<String, dynamic>.from(options.data as Map));
    return ResponseBody.fromString(
      '{"ok":true,"id":"r1"}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'ağ yok',
    );
  }

  @override
  void close({bool force = false}) {}
}
