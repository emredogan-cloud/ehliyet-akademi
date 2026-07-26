import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

/// Grounded AI yanıtı (web `/api/ai/ask` → `{ answer, grounded, sources, model }`).
class CoachAnswer {
  const CoachAnswer({
    required this.answer,
    required this.grounded,
    required this.sources,
    required this.model,
  });
  final String answer;
  final bool grounded;
  final List<String> sources;
  final String model;
}

/// Beta Faz 9 — akış olayı (`/api/ai/ask/stream`).
///
/// `streamed`, yanıtın GERÇEKTEN parça parça gelip gelmediğini söyler. Yol haritasının şartı
/// açıktı: **anlık yanıt asla sahte akış gibi gösterilmez.** Bu bayrak olmasaydı istemci
/// ayırt edemez, "güzel görünsün" diye uydurma bir yazma animasyonu eklenirdi.
sealed class CoachStreamEvent {
  const CoachStreamEvent();
}

class CoachMeta extends CoachStreamEvent {
  const CoachMeta({
    required this.grounded,
    required this.sources,
    required this.model,
    required this.streamed,
  });
  final bool grounded;
  final List<String> sources;
  final String model;
  final bool streamed;
}

class CoachDelta extends CoachStreamEvent {
  const CoachDelta(this.text);
  final String text;
}

class CoachDone extends CoachStreamEvent {
  const CoachDone();
}

abstract class CoachApi {
  Future<CoachAnswer> ask(String question, {String? context});

  /// Akan yanıt. Uç desteklenmiyorsa/başarısızsa fırlatır; çağıran tek parça uca düşer.
  Stream<CoachStreamEvent> askStream(String question, {String? context});
}

class DioCoachApi implements CoachApi {
  DioCoachApi(this._dio);
  final Dio _dio;

  @override
  Future<CoachAnswer> ask(String question, {String? context}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/ai/ask',
      data: {'question': question, if (context != null && context.isNotEmpty) 'context': context},
      options: Options(responseType: ResponseType.json, validateStatus: (s) => s == 200),
    );
    final data = res.data ?? const {};
    return CoachAnswer(
      answer: (data['answer'] as String?) ?? '',
      grounded: (data['grounded'] as bool?) ?? false,
      sources: ((data['sources'] as List?) ?? const []).map((e) => e.toString()).toList(),
      model: (data['model'] as String?) ?? '',
    );
  }

  @override
  Stream<CoachStreamEvent> askStream(String question, {String? context}) async* {
    final res = await _dio.post<ResponseBody>(
      '/api/ai/ask/stream',
      data: {'question': question, if (context != null && context.isNotEmpty) 'context': context},
      options: Options(responseType: ResponseType.stream, validateStatus: (s) => s == 200),
    );
    final body = res.data;
    if (body == null) throw StateError('ai_stream_empty');
    yield* parseCoachSse(body.stream);
  }
}

/// SSE gövdesini olaylara çevirir.
///
/// Ağ parçaları satır sınırına saygı GÖSTERMEZ: tek bir `data:` satırı iki parçaya bölünebilir.
/// Bu yüzden tampon tutulur ve yalnız TAM olay blokları (`\n\n`) işlenir — aksi hâlde JSON
/// çözümlemesi sessizce patlar ve akış ortada kesilir.
Stream<CoachStreamEvent> parseCoachSse(Stream<List<int>> bytes) async* {
  var buf = '';
  await for (final chunk in bytes) {
    buf += utf8.decode(chunk, allowMalformed: true);
    var idx = buf.indexOf('\n\n');
    while (idx != -1) {
      final block = buf.substring(0, idx).trim();
      buf = buf.substring(idx + 2);
      idx = buf.indexOf('\n\n');
      if (!block.startsWith('data:')) continue;
      final payload = block.substring(5).trim();
      if (payload.isEmpty) continue;
      try {
        final m = jsonDecode(payload) as Map<String, dynamic>;
        switch (m['type']) {
          case 'meta':
            yield CoachMeta(
              grounded: m['grounded'] as bool? ?? false,
              sources: ((m['sources'] as List?) ?? const []).map((e) => e.toString()).toList(),
              model: m['model'] as String? ?? '',
              streamed: m['streamed'] as bool? ?? false,
            );
          case 'delta':
            final t = m['text'] as String? ?? '';
            if (t.isNotEmpty) yield CoachDelta(t);
          case 'done':
            yield const CoachDone();
          case 'error':
            throw StateError('ai_stream_error');
        }
      } on FormatException {
        // Bozuk tek bir olay akışı öldürmez.
      }
    }
  }
}

final coachApiProvider = Provider<CoachApi>((ref) => DioCoachApi(ref.watch(dioProvider)));
