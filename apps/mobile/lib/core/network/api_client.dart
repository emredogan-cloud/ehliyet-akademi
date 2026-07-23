import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../storage/token_store.dart';

/// The shared HTTP client (dio). Attaches the session bearer token to every request and, on a 401,
/// clears the stored token (the auth controller then reflects the signed-out state).
Dio buildDio(TokenStore tokens) {
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
    ),
  );
  return dio;
}

final dioProvider = Provider<Dio>((ref) => buildDio(ref.watch(tokenStoreProvider)));
