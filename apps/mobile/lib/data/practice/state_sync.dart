import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

/// Sunucu senkron köprüsü — web `/api/state` (Bearer-korumalı). Best-effort: ağ/oturum yoksa sessizce
/// atlanır (yerel depo çevrimdışı çalışmaya devam eder). Anahtarlar web ile birebir (`ea:*:v1`).
class StateSync {
  StateSync(this._dio);
  final Dio _dio;

  /// Sunucudaki tüm durum anahtarlarını çek. Oturum yoksa (401) veya ağ hatasında null döner.
  Future<Map<String, dynamic>?> pull() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/state',
        options: Options(responseType: ResponseType.json, validateStatus: (s) => s == 200),
      );
      final items = (res.data?['items'] as List?) ?? const [];
      final out = <String, dynamic>{};
      for (final it in items) {
        final m = it as Map;
        out[m['key'] as String] = m['value'];
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  /// Bir anahtarı sunucuya yaz (best-effort; hata yutulur).
  Future<void> push(String key, Object? value) async {
    try {
      await _dio.put(
        '/api/state',
        data: {
          'items': [
            {'key': key, 'value': value},
          ],
        },
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
    } catch (_) {
      // guest/offline → local remains source of truth
    }
  }
}

final stateSyncProvider = Provider<StateSync>((ref) => StateSync(ref.watch(dioProvider)));
