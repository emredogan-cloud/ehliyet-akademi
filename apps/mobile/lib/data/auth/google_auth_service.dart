import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Beta Faz 2 — Google ile giriş.
///
/// MİMARİ (Evolution'dan devam): platforma bağlı her şey **arayüz + uygulama** olarak yazılır.
/// `GoogleSignIn` platform kanalına bağlıdır ve widget testinde örneklenemez; bu yüzden yüzey
/// [GoogleAuthService] arayüzünü alır, testler sahte uygulamayla çalışır.
///
/// YAPILANDIRMA: `serverClientId`, derleme zamanında `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`
/// ile verilir. **Verilmezse uygulama çökmez**; [isConfigured] false olur ve arayüz Google
/// düğmesini hiç göstermez (dürüst davranış — çalışmayan düğme konmaz).

/// Google girişinin sonucu.
sealed class GoogleSignInOutcome {
  const GoogleSignInOutcome();
}

/// Başarılı: sunucuya gönderilecek ID token.
class GoogleSignInToken extends GoogleSignInOutcome {
  const GoogleSignInToken(this.idToken);
  final String idToken;
}

/// Kullanıcı hesap seçiciyi kapattı — bu bir HATA DEĞİLDİR, mesaj gösterilmez.
class GoogleSignInCancelled extends GoogleSignInOutcome {
  const GoogleSignInCancelled();
}

/// Gerçek hata; [message] kullanıcıya gösterilir.
class GoogleSignInError extends GoogleSignInOutcome {
  const GoogleSignInError(this.message);
  final String message;
}

abstract class GoogleAuthService {
  /// Sunucu istemci kimliği verilmiş mi? False ise arayüz Google düğmesini göstermez.
  bool get isConfigured;

  /// Hesap seçiciyi açar ve ID token döndürür.
  Future<GoogleSignInOutcome> signIn();

  /// Yerel Google oturumunu kapatır (uygulama oturumu ayrıca kapatılır).
  Future<void> signOut();
}

/// `google_sign_in` v7 uygulaması.
class GoogleSignInServiceImpl implements GoogleAuthService {
  GoogleSignInServiceImpl({String? serverClientId})
    : _serverClientId =
          serverClientId ?? const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  final String _serverClientId;
  bool _initialized = false;

  @override
  bool get isConfigured => _serverClientId.isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    // DİKKAT: `serverClientId` olarak **WEB** istemci kimliği verilir (Android istemci DEĞİL).
    // Yanlış verilirse `idToken` null döner ve giriş sessizce başarısız olur.
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  @override
  Future<GoogleSignInOutcome> signIn() async {
    if (!isConfigured) {
      return const GoogleSignInError('Google ile giriş bu sürümde yapılandırılmadı.');
    }
    try {
      await _ensureInitialized();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return const GoogleSignInError('Bu cihazda Google ile giriş desteklenmiyor.');
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        // En sık neden: `serverClientId` Web istemci kimliği değil.
        return const GoogleSignInError('Google kimliği alınamadı. Tekrar dene.');
      }
      return GoogleSignInToken(idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const GoogleSignInCancelled();
      }
      return const GoogleSignInError('Google ile giriş tamamlanamadı.');
    } catch (_) {
      return const GoogleSignInError('Google ile giriş tamamlanamadı.');
    }
  }

  @override
  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Yerel oturum kapatılamasa bile uygulama oturumu kapanır; kullanıcıyı engellemez.
    }
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>(
  (ref) => GoogleSignInServiceImpl(),
);
