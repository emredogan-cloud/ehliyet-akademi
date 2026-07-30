import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../domain/auth/app_user.dart';

/// Result of a login/register attempt.
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user, this.token, {this.referral});
  final AppUser user;
  final String token;

  /// Beta Faz 3 — kayıt isteğine eklenen davet kodunun SUNUCUDAKİ sonucu (yalnız kayıtta dolu).
  ///
  /// NEDEN taşınıyor: "davet kabul edildi" olayı, kodun GÖNDERİLDİĞİNİ değil KABUL EDİLDİĞİNİ
  /// ölçmeli. İkisi aynı değil — sunucu kodu sessizce reddedebilir (kendi kodu, aynı IP'den
  /// üçüncü kayıt, bilinmeyen kod). İstemci varsayımla ölçerse pano gerçekte olmayan davetleri
  /// sayar ve ödül merdiveni ile tutmaz.
  final ReferralOutcome? referral;
}

/// Sunucunun davet kodu hakkındaki kararı (`POST /api/auth/register` yanıtındaki `referral`).
class ReferralOutcome {
  const ReferralOutcome({required this.accepted, this.reason});
  final bool accepted;

  /// Reddedilme nedeni: `self` | `already-referred` | `unknown-code` | `bad-format` | `ip-limit`.
  final String? reason;

  static ReferralOutcome? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final ok = raw['ok'] == true;
    final reason = raw['reason']?.toString();
    // `none` = istemci hiç kod göndermedi; ölçülecek bir davet yok.
    if (!ok && reason == 'none') return null;
    return ReferralOutcome(accepted: ok, reason: ok ? null : reason);
  }
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.message);
  final String message;
}

/// Auth API contract (overridable in tests with a fake).
abstract class AuthApi {
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,

    /// Faz 8 — isteğe bağlı davet kodu. Geçersiz kod KAYDI ENGELLEMEZ (sunucu sessizce yok sayar).
    String? referralCode,
  });
  Future<AuthResult> login({required String email, required String password});

  /// Beta Faz 2 — Google ID token'ını sunucuda doğrulatıp Bearer oturumuna çevirir.
  /// Token SUNUCUDA doğrulanır; istemcinin kimlik iddiasına güvenilmez.
  Future<AuthResult> loginWithGoogle(String idToken);

  /// Beta Faz 5 — parola sıfırlama talebi (`POST /api/auth/forgot`).
  ///
  /// Sunucu **hesabın var olup olmadığını SIZDIRMAZ**: hesap bulunmasa da başarı döner. Sıfırlama
  /// bağlantısı e-postayla gönderilir ve web'deki `/sifirla` sayfasında tamamlanır — bu yüzden
  /// mobilde ayrı bir sıfırlama ekranı YOKTUR (olsaydı token'ı elle girmek gerekirdi).
  ///
  /// Dönüş: `null` başarı, aksi hâlde kullanıcıya gösterilecek hata metni.
  Future<String?> requestPasswordReset(String email);

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
    String? referralCode,
  }) => _auth('/api/auth/register', {
    'name': name,
    'email': email,
    'password': password,
    if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
  });

  @override
  Future<AuthResult> login({required String email, required String password}) =>
      _auth('/api/auth/login', {'email': email, 'password': password});

  @override
  Future<AuthResult> loginWithGoogle(String idToken) =>
      _auth('/api/auth/google', {'idToken': idToken});

  Future<AuthResult> _auth(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(path, data: body);
      final data = res.data;
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (data is Map && data['token'] is String && data['user'] is Map) {
          return AuthSuccess(
            AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
            data['token'] as String,
            referral: ReferralOutcome.fromJson(data['referral']),
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
  Future<String?> requestPasswordReset(String email) async {
    try {
      final res = await _dio.post(
        '/api/auth/forgot',
        data: {'email': email},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode == 200) return null;
      final data = res.data;
      return (data is Map && data['error'] is String)
          ? data['error'] as String
          : 'İstek gönderilemedi (${res.statusCode}).';
    } on DioException catch (_) {
      return 'Bağlantı hatası. İnternetini kontrol et.';
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
