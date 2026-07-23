import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../domain/auth/app_user.dart';

/// Result of a login/register attempt.
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user, this.token);
  final AppUser user;
  final String token;
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.message);
  final String message;
}

/// Auth API contract (overridable in tests with a fake).
abstract class AuthApi {
  Future<AuthResult> register({required String name, required String email, required String password});
  Future<AuthResult> login({required String email, required String password});
  Future<AppUser?> me();
  Future<void> logout();
}

class DioAuthApi implements AuthApi {
  DioAuthApi(this._dio);
  final Dio _dio;

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _auth('/api/auth/register', {'name': name, 'email': email, 'password': password});

  @override
  Future<AuthResult> login({required String email, required String password}) =>
      _auth('/api/auth/login', {'email': email, 'password': password});

  Future<AuthResult> _auth(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(path, data: body);
      final data = res.data;
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (data is Map && data['token'] is String && data['user'] is Map) {
          return AuthSuccess(
            AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
            data['token'] as String,
          );
        }
        return const AuthFailure('Beklenmeyen sunucu yanıtı.');
      }
      final msg = (data is Map && data['error'] is String)
          ? data['error'] as String
          : 'İşlem başarısız (${res.statusCode}).';
      return AuthFailure(msg);
    } on DioException catch (_) {
      return const AuthFailure('Bağlantı hatası. İnternetini kontrol et.');
    }
  }

  @override
  Future<AppUser?> me() async {
    try {
      final res = await _dio.get('/api/auth/me');
      if (res.statusCode == 200 && res.data is Map && (res.data as Map)['user'] is Map) {
        return AppUser.fromJson(Map<String, dynamic>.from((res.data as Map)['user'] as Map));
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } on DioException catch (_) {
      // best-effort; the local token is cleared regardless by the controller.
    }
  }
}

final authApiProvider = Provider<AuthApi>((ref) => DioAuthApi(ref.watch(dioProvider)));
