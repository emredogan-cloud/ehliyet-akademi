import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../storage/token_store.dart';

/// The shared HTTP client (dio). Attaches the session bearer token to every request and, on a 401,
/// clears the stored token (the auth controller then reflects the signed-out state).
///
/// Beta Faz 4 — [onNetworkFailure] verilirse ağ ve sunucu hataları gözlemlenebilirliğe bildirilir.
/// Geri çağırım İSTEĞE BAĞLIDIR: raportör dio'ya, dio da raportöre ihtiyaç duyduğu için (dairesel
/// bağımlılık) bağlanma `main()` içinde, ikisi de kurulduktan sonra yapılır.
Dio buildDio(TokenStore tokens, {void Function(DioException)? onNetworkFailure}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'content-type': 'application/json'},
      // Do not throw on 4xx — callers inspect status codes.
      validateStatus: (s) => s != null && s < 500,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokens.read();
        if (token != null) options.headers['authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onResponse: (response, handler) async {
        if (response.statusCode == 401) {
          await tokens.clear();
        }
        handler.next(response);
      },
      onError: (e, handler) {
        // Telemetri uçlarının KENDİ hataları bildirilmez — bildirilseydi, sunucu erişilemezken
        // her başarısız gönderim yeni bir rapor üretir ve o rapor da gönderilemeyip yeni bir
        // rapor doğururdu. Kuyruk kendi kendini besleyen bir döngüye girerdi.
        final path = e.requestOptions.path;
        if (!path.startsWith('/api/analytics/') && !path.startsWith('/api/errors/')) {
          onNetworkFailure?.call(e);
        }
        handler.next(e);
      },
    ),
  );
  return dio;
}

final dioProvider = Provider<Dio>((ref) => buildDio(ref.watch(tokenStoreProvider)));
