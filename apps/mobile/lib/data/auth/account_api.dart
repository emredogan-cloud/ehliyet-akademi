import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

/// Faz 5 — hesap silme ucu (`/api/account`).
///
/// AYRI BİR API: `AuthApi` oturum yaşam döngüsüne (giriş/kayıt/çıkış) aittir. Hesabın kendisini
/// yok etmek farklı bir eylemdir ve farklı bir güvenlik sözleşmesi taşır (yeniden kimlik
/// doğrulama). İkisini aynı arayüze yığmak, sahte bir yakınlık kurardı.

/// Silme öncesi sunucunun bildirdiği koşullar.
class AccountDeletionRequirements {
  const AccountDeletionRequirements({required this.requiresPassword, required this.email});

  /// Bu hesapta parola var mı? Google ile açılmış hesapta parola YOKTUR ve istenemez.
  final bool requiresPassword;
  final String email;
}

/// Silme denemesinin sonucu.
sealed class AccountDeletionResult {
  const AccountDeletionResult();
}

class AccountDeleted extends AccountDeletionResult {
  const AccountDeleted();
}

/// Parola yanlış ya da eksik — kullanıcı düzeltebilir, alan açık kalır.
class AccountDeletionWrongPassword extends AccountDeletionResult {
  const AccountDeletionWrongPassword(this.message);
  final String message;
}

/// Başka bir hata (ağ, oturum, sunucu).
class AccountDeletionFailed extends AccountDeletionResult {
  const AccountDeletionFailed(this.message);
  final String message;
}

abstract class AccountApi {
  /// Hesabın silme için parola isteyip istemediğini sor.
  Future<AccountDeletionRequirements?> requirements();

  /// Hesabı sil. [password] yalnız gerekiyorsa gönderilir.
  Future<AccountDeletionResult> delete({String? password});
}

class DioAccountApi implements AccountApi {
  DioAccountApi(this._dio);
  final Dio _dio;

  @override
  Future<AccountDeletionRequirements?> requirements() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/account',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200) return null;
      return AccountDeletionRequirements(
        requiresPassword: res.data?['requiresPassword'] == true,
        email: (res.data?['email'] ?? '').toString(),
      );
    } on DioException catch (_) {
      return null;
    }
  }

  @override
  Future<AccountDeletionResult> delete({String? password}) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        '/api/account',
        data: password == null ? null : {'password': password},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      final message = (res.data?['error'] ?? '').toString();
      return switch (res.statusCode) {
        200 => const AccountDeleted(),
        // 400 (parola verilmedi) ve 403 (parola hatalı) kullanıcının DÜZELTEBİLECEĞİ durumlardır.
        400 || 403 => AccountDeletionWrongPassword(
          message.isEmpty ? 'Parola hatalı.' : message,
        ),
        401 => const AccountDeletionFailed('Oturumun sona ermiş. Tekrar giriş yap.'),
        _ => AccountDeletionFailed(
          message.isEmpty ? 'Hesap silinemedi. Daha sonra tekrar dene.' : message,
        ),
      };
    } on DioException catch (_) {
      return const AccountDeletionFailed('Bağlantı hatası. İnternetini kontrol et.');
    }
  }
}

final accountApiProvider = Provider<AccountApi>((ref) => DioAccountApi(ref.watch(dioProvider)));
