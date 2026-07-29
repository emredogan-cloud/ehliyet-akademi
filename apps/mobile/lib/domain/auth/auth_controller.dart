import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/token_store.dart';
import '../../data/auth/auth_api.dart';
import '../../data/auth/google_auth_service.dart';
import '../../data/premium/entitlements_repository.dart';
import 'app_user.dart';

enum AuthStatus { unknown, guest, authenticated }

@immutable
class AuthState {
  const AuthState(this.status, [this.user]);
  final AuthStatus status;
  final AppUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  static const unknown = AuthState(AuthStatus.unknown);
  static const guest = AuthState(AuthStatus.guest);
}

/// Owns the session: resolves the stored token on startup, and handles login/register/logout.
/// The app never gates on auth — guests use everything; auth adds identity + sync.
class AuthController extends Notifier<AuthState> {
  AuthApi get _api => ref.read(authApiProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);

  @override
  AuthState build() {
    // Resolve asynchronously without blocking the UI (shell renders immediately).
    Future.microtask(_resolve);
    return AuthState.unknown;
  }

  Future<void> _resolve() async {
    final token = await _tokens.read();
    if (token == null || token.isEmpty) {
      state = AuthState.guest;
      return;
    }
    final user = await _api.me();
    if (user != null) {
      state = AuthState(AuthStatus.authenticated, user);
    } else {
      await _tokens.clear();
      state = AuthState.guest;
    }
  }

  /// Returns null on success, or an error message.
  Future<String?> login({required String email, required String password}) async {
    final r = await _api.login(email: email, password: password);
    return _apply(r);
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final r = await _api.register(
      name: name,
      email: email,
      password: password,
      referralCode: referralCode,
    );
    return _apply(r);
  }

  /// Beta Faz 2 — Google ile giriş.
  ///
  /// Dönüş: `null` başarı · `''` KULLANICI VAZGEÇTİ (mesaj gösterilmez) · aksi hâlde hata metni.
  /// Vazgeçmeyi hatadan ayırmak önemli: hesap seçiciyi kapatan kullanıcıya hata göstermek yanlış.
  Future<String?> loginWithGoogle() async {
    final outcome = await ref.read(googleAuthServiceProvider).signIn();
    switch (outcome) {
      case GoogleSignInCancelled():
        return '';
      case GoogleSignInError(:final message):
        return message;
      case GoogleSignInToken(:final idToken):
        return _apply(await _api.loginWithGoogle(idToken));
    }
  }

  /// Beta Faz 5 — parola sıfırlama talebi.
  ///
  /// Oturum durumunu DEĞİŞTİRMEZ; yalnız sunucuya talebi iletir. Sunucu hesabın varlığını
  /// sızdırmadığı için başarı yanıtı "e-posta gönderildi" anlamına gelmez — arayüz bunu
  /// dürüstçe ifade eder.
  Future<String?> requestPasswordReset(String email) =>
      _api.requestPasswordReset(email);

  Future<String?> _apply(AuthResult r) async {
    switch (r) {
      case AuthSuccess(:final user, :final token):
        await _tokens.write(token);
        state = AuthState(AuthStatus.authenticated, user);
        // Oturum açıldı → sahiplik SUNUCUDAN yeniden türetilir. Bu, hem yeni kullanıcının
        // haklarını getirir hem de misafirken yapılmış bir satın almanın hesaba bağlanmasını
        // tetikler (bkz. `EntitlementsController.refresh`).
        await ref.read(entitlementsProvider.notifier).refresh();
        return null;
      case AuthFailure(:final message):
        return message;
    }
  }

  /// Oturumu SONLANDIR — sunucu, yerel jeton ve **cihazdaki kullanıcıya bağlı izler** birlikte
  /// temizlenir.
  ///
  /// NEDEN Google de kapatılır: yalnız uygulama jetonunu silmek, cihazdaki Google oturumunu açık
  /// bırakıyordu; "Çıkış yap" sonrası Google ile giriş, hesap seçici hiç açılmadan AYNI hesapla
  /// geri dönüyordu — kullanıcı için çıkış yapılmamış gibi. (Cihazda görüldü.)
  ///
  /// NEDEN yetki önbelleği silinir: `ea:entitlements:v1` cihaz genelindedir. Silinmezse aynı
  /// telefonda oturum açan İKİNCİ kullanıcı, birincinin premium'unu görürdü — web'de P0 olarak
  /// kayıtlı olan "aynı tarayıcıda kullanıcı sızıntısı" hatasının mobil karşılığı.
  Future<void> logout() async {
    await _api.logout();
    await _tokens.clear();
    await ref.read(googleAuthServiceProvider).signOut();
    await ref.read(entitlementsProvider.notifier).clearForSignOut();
    state = AuthState.guest;
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
