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

abstract class CoachApi {
  Future<CoachAnswer> ask(String question, {String? context});
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
}

final coachApiProvider = Provider<CoachApi>((ref) => DioCoachApi(ref.watch(dioProvider)));
