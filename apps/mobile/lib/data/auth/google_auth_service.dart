import 'package:flutter/foundation.dart' show visibleForTesting;
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
  const GoogleSignInError(this.message, {this.technical});
  final String message;

  /// Geliştirici için HAM neden (Google'ın döndürdüğü kod + açıklama).
  ///
  /// Kullanıcıya **gösterilmez**. Bu alan olmadan kod, Google'ın verdiği asıl bilgiyi
  /// (`[28444] Developer console is not set up correctly` gibi) okumadan atıyordu ve başarısız
  /// bir giriş sahada teşhis edilemiyordu. Alan taşınır; bir hata bildirim katmanı eklendiğinde
  /// oraya verilecek hazır veridir. **Üretimde günlüğe yazılmaz.**
  final String? technical;
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
      final technical = 'GoogleSignInException code=${e.code} description=${e.description}';
      return GoogleSignInError(_messageFor(e.description), technical: technical);
    } catch (e) {
      final technical = '${e.runtimeType}: $e';
      return GoogleSignInError(
        'Google ile giriş tamamlanamadı. Tekrar dene.',
        technical: technical,
      );
    }
  }

  /// Google'ın açıklamasından KULLANICIYA anlamlı bir mesaj türetir.
  ///
  /// NEDEN: tek bir "tamamlanamadı" mesajı, düzeltilemeyecek bir durumda kullanıcıyı sonsuza
  /// kadar "tekrar dene"ye yönlendiriyordu. Yapılandırma hatasında tekrar denemek **düzelmez**;
  /// doğru davranış kullanıcıyı çalışan yola (e-posta) yönlendirmektir.
  @visibleForTesting
  static String messageForDescription(String? description) => _messageFor(description);

  static String _messageFor(String? description) {
    final d = (description ?? '').toLowerCase();
    // Google, uygulamanın OAuth istemcisiyle eşleşmediği durumda bu metni döndürür (hata 28444).
    if (d.contains('developer console') || d.contains('28444')) {
      return 'Google ile giriş şu an kullanılamıyor. E-posta ile giriş yapabilirsin.';
    }
    // Ağ kaynaklı geçici hatalarda tekrar denemek MANTIKLI.
    if (d.contains('network') || d.contains('timeout')) {
      return 'Bağlantı sorunu. İnternetini kontrol edip tekrar dene.';
    }
    return 'Google ile giriş tamamlanamadı. Tekrar dene.';
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
