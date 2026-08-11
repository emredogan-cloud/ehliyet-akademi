import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

/// AI Koç yanıtı için bildirim sebepleri.
///
/// Sunucudaki `REPORT_KINDS` ile BİREBİR aynı olmalıdır (`apps/web/lib/server/reports.ts`);
/// `wire` değeri doğrudan gövdeye yazılır ve sunucu bilinmeyen bir değeri reddeder.
enum AiReportReason {
  harmful('harmful', 'Rahatsız edici veya zararlı'),
  wrongAnswer('wrong-answer', 'Bilgi yanlış'),
  unclear('unclear', 'Anlaşılmıyor'),
  other('other', 'Diğer');

  const AiReportReason(this.wire, this.label);
  final String wire;
  final String label;
}

/// AI yanıtı bildirimi gönderen uç.
///
/// ## Neden topluluk bildirimi ucu kullanılmadı
///
/// `/api/community/report` bir HEDEF KULLANICI kimliği istiyor (AI yanıtının sahibi yok) ve
/// topluluğa katılmış olmayı gerektiriyor. AI Koç ise **hesapsız** kullanılabiliyor. Bu yüzden
/// bildirim, anonim çalışan ve zaten insan inceleme kuyruğuna düşen soru bildirimi ucundan
/// gönderiliyor; `source: 'ai-reply'` iki yüzeyi birbirinden ayırıyor.
abstract class AiReportApi {
  /// Bir AI yanıtını bildir. **Asla fırlatmaz**: bildirim gönderilemese bile kullanıcı akışı
  /// kesilmemeli. Gönderilebildiyse `true`.
  Future<bool> reportReply({
    required String messageId,
    required AiReportReason reason,
    required String replyExcerpt,
  });
}

class DioAiReportApi implements AiReportApi {
  DioAiReportApi(this._dio);
  final Dio _dio;

  @override
  Future<bool> reportReply({
    required String messageId,
    required AiReportReason reason,
    required String replyExcerpt,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/qip/report',
        data: {
          // İnceleyenin neyi okuduğunu bilmesi için yanıtın kendisi kısaltılarak gönderilir;
          // sunucu da ayrıca 1000 karakterde kırpar.
          'questionId': messageId,
          'kind': reason.wire,
          'message': replyExcerpt.length > 900
              ? '${replyExcerpt.substring(0, 900)}…'
              : replyExcerpt,
          'source': 'ai-reply',
        },
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      return res.statusCode == 200;
    } on DioException catch (_) {
      return false;
    }
  }
}

final aiReportApiProvider = Provider<AiReportApi>(
  (ref) => DioAiReportApi(ref.watch(dioProvider)),
);
