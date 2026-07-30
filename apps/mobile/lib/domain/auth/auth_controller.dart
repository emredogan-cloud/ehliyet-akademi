import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/analytics_ref.dart';
import '../../core/observability/error_report.dart';
import '../../core/observability/error_reporter.dart';
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
    final err = await _apply(r);
    if (err == null) ref.track(AnalyticsEvent.login);
    return err;
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
    final err = await _apply(r);
    if (err == null) {
      ref.track(AnalyticsEvent.registration(withReferral: referralCode != null));
      // Davet KABULÜ ayrı bir olaydır: kod gönderilmiş olması kabul edildiği anlamına gelmez.
      // Sunucu onu sessizce reddedebilir (kendi kodu, IP sınırı, bilinmeyen kod) ve pano bunu
      // bilmezse gerçekte olmayan davetleri sayardı.
      final outcome = _lastReferralOutcome;
      if (outcome != null) {
        ref.track(
          AnalyticsEvent.referralAccepted(accepted: outcome.accepted, reason: outcome.reason),
        );
      }
    }
    return err;
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
        // Beta Faz 4 — Google girişi, bu projede EN ÇOK zaman kaybettiren yüzey oldu
        // (`GOOGLE_PLAY_SIGNIN_PLAYBOOK.md`). Hatanın kendisi kullanıcıya gösteriliyor ama
        // hangi cihazda kaç kez olduğu görünmüyordu; sahadan "çalışmıyor" haberi gelince de
        // hangi yapının konuşulduğu bilinemiyordu. Rapor bunu kapatır.
        ref
            .read(errorReporterProvider)
            .report(
              StateError(message),
              StackTrace.current,
              kind: ErrorKind.googleSignIn,
            )
            .ignore();
        return message;
      case GoogleSignInToken(:final idToken):
        final err = await _apply(await _api.loginWithGoogle(idToken));
        if (err == null) ref.track(AnalyticsEvent.googleLogin);
        return err;
    }
  }

  /// Beta Faz 5 — parola sıfırlama talebi.
  ///
  /// Oturum durumunu DEĞİŞTİRMEZ; yalnız sunucuya talebi iletir. Sunucu hesabın varlığını
  /// sızdırmadığı için başarı yanıtı "e-posta gönderildi" anlamına gelmez — arayüz bunu
  /// dürüstçe ifade eder.
  Future<String?> requestPasswordReset(String email) =>
      _api.requestPasswordReset(email);

  /// Son başarılı kimlik işleminde sunucunun davet kodu hakkındaki kararı.
  ///
  /// `_apply` tek bir hata metni döndürdüğü için (arayüzün ihtiyacı bu), davet sonucu ayrıca
  /// burada tutulur. Alternatif, `_apply`'ın dönüş tipini şişirip üç çağıranı da değiştirmekti;
  /// tek kullanımlık bir bilgi için değmezdi.
  ReferralOutcome? _lastReferralOutcome;

  Future<String?> _apply(AuthResult r) async {
    switch (r) {
      case AuthSuccess(:final user, :final token, :final referral):
        _lastReferralOutcome = referral;
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
    ref.track(AnalyticsEvent.logout);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
