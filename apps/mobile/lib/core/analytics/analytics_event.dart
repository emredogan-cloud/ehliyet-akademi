/// Beta Faz 3 — ürün analitiğinin MERKEZÎ olay sözlüğü.
///
/// **Kural: olay adı bu dosyanın dışında yazılmaz.** Çağıran taraf `Analytics.log(...)` fonksiyonuna
/// bir [AnalyticsEvent] verir; adı kendi yazmaz.
///
/// NEDEN böyle: dize sabitleriyle olay göndermek, aynı olayın iki farklı adla ("exam_passed" ve
/// "examPassed") iki farklı yerden gitmesiyle sonuçlanır. Bu, panoyu sessizce yanlış gösterir ve
/// hata ancak "sayılar tutmuyor" diye fark edilir. Buradaki üretici fonksiyonlar hem adı hem de
/// **hangi alanların zorunlu olduğunu** derleme zamanında dayatır.
///
/// GİZLİLİK: `props` içine **kişisel veri konmaz** — e-posta, ad, serbest metin, soru cevabı yok.
/// Yalnız sayılar, kısa kimlikler ve numaralandırılmış değerler. Her üreticinin yanındaki yorum
/// bunun neden güvenli olduğunu söyler.
class AnalyticsEvent {
  const AnalyticsEvent(this.name, [this.props = const <String, Object?>{}]);

  /// `snake_case` olay adı — sunucuda ve panoda görünen ad budur.
  final String name;

  /// Olayın boyutları. Yalnız `String`, `int`, `double`, `bool` ve bunların listeleri.
  final Map<String, Object?> props;

  @override
  String toString() => props.isEmpty ? name : '$name $props';

  // ── Yaşam döngüsü ────────────────────────────────────────────────────────────────────────────

  /// Uygulama bu cihazda İLK KEZ açıldı. `logOnce` ile gönderilir; kurulum sayısının tabanı.
  static const installed = AnalyticsEvent('app_installed');

  /// Her soğuk açılış. `installed` ile birlikte "kaç kurulum, kaç dönüş" sorusunu cevaplar.
  static const firstLaunch = AnalyticsEvent('first_launch');

  /// Uygulama açıldı (her oturum). Gün/haftalık etkin kullanıcı bundan türetilir.
  static const appOpened = AnalyticsEvent('app_opened');

  // ── Tanıtım turu (coach marks) ───────────────────────────────────────────────────────────────

  static const coachMarksStarted = AnalyticsEvent('coach_marks_started');
  static const coachMarksCompleted = AnalyticsEvent('coach_marks_completed');

  /// Tur kaçıncı adımda bırakıldı — hangi adımın uzun/sıkıcı olduğunu bu söyler.
  static AnalyticsEvent coachMarksSkipped({required int atStep, required int totalSteps}) =>
      AnalyticsEvent('coach_marks_skipped', {'step': atStep, 'total': totalSteps});

  // ── Kimlik ───────────────────────────────────────────────────────────────────────────────────

  /// Kayıt tamamlandı. `withReferral`: davet kodu kullanıldı mı (kodun KENDİSİ gönderilmez).
  static AnalyticsEvent registration({required bool withReferral}) =>
      AnalyticsEvent('registration', {'referral': withReferral});

  static const login = AnalyticsEvent('login');
  static const googleLogin = AnalyticsEvent('google_login');

  /// Kullanıcı oturum açmadan devam etti. Misafir kullanım gerçek bir kitledir; ölçülmezse
  /// "kaç kişi hesap açmadan kullanıyor" sorusu cevaplanamaz.
  static const guestSession = AnalyticsEvent('guest_session');

  static const logout = AnalyticsEvent('logout');
  static const accountDeleted = AnalyticsEvent('account_deleted');

  // ── Sınav / çalışma ──────────────────────────────────────────────────────────────────────────

  /// Kullanıcının HAYATINDAKİ ilk sınavı (`logOnce`). Etkinleşme (activation) metriği.
  static const firstExam = AnalyticsEvent('first_exam');

  /// Sınav bitti. `passed` ayrı olaylarla da gönderilir — pano ikisini de kullanır.
  static AnalyticsEvent examCompleted({
    required int correct,
    required int total,
    required bool passed,
    required int durationSeconds,
  }) => AnalyticsEvent('exam_completed', {
    'correct': correct,
    'total': total,
    'passed': passed,
    'duration_s': durationSeconds,
  });

  static AnalyticsEvent examPassed({required int correct, required int total}) =>
      AnalyticsEvent('exam_passed', {'correct': correct, 'total': total});

  static AnalyticsEvent examFailed({required int correct, required int total}) =>
      AnalyticsEvent('exam_failed', {'correct': correct, 'total': total});

  // ── AI Koç ───────────────────────────────────────────────────────────────────────────────────

  static const aiCoachStarted = AnalyticsEvent('ai_coach_started');

  /// Oturum ne kadar sürdü ve kaç tur konuşuldu. Süre SANİYE; ham metin gönderilmez.
  static AnalyticsEvent aiCoachSessionLength({
    required int seconds,
    required int turns,
  }) => AnalyticsEvent('ai_coach_session_length', {'seconds': seconds, 'turns': turns});

  // ── Ekranlar ─────────────────────────────────────────────────────────────────────────────────

  static const progressScreen = AnalyticsEvent('progress_screen');

  /// Ödeme ekranı görüntülendi. `source` HANGİ yüzeyden gelindiği — dönüşümü bu ayırır.
  static AnalyticsEvent premiumScreenViewed({required String source}) =>
      AnalyticsEvent('premium_screen_viewed', {'source': source});

  // ── Satın alma ───────────────────────────────────────────────────────────────────────────────

  static AnalyticsEvent purchaseStarted({required String productId}) =>
      AnalyticsEvent('purchase_started', {'product_id': productId});

  static AnalyticsEvent purchaseCompleted({required String productId, required bool guest}) =>
      AnalyticsEvent('purchase_completed', {'product_id': productId, 'guest': guest});

  /// Satın alma yarıda kaldı. `reason` numaralandırılmış: `cancelled` | `error` | `pending`.
  static AnalyticsEvent purchaseAbandoned({required String productId, required String reason}) =>
      AnalyticsEvent('purchase_abandoned', {'product_id': productId, 'reason': reason});

  /// Geri yükleme denendi ve kaç satın alma bulundu.
  static AnalyticsEvent restorePurchases({required int found}) =>
      AnalyticsEvent('restore_purchases', {'found': found});

  // ── Davet ────────────────────────────────────────────────────────────────────────────────────

  /// Kullanıcı KENDİ davet bağlantısını paylaştı (`channel`: `share` | `copy`).
  static AnalyticsEvent referralCreated({required String channel}) =>
      AnalyticsEvent('referral_created', {'channel': channel});

  /// Beta Faz 1 — davet derin bağlantısı uygulamada AÇILDI. `installed`: uygulama zaten kuruluydu.
  ///
  /// Kodun kendisi gönderilmez: davet edeni tanımlar ve panoda gerekmez — gereken, kaç bağlantının
  /// uygulamayı açtığıdır. (Sunucu tarafı huni `referral_visits` tablosundan gelir.)
  static AnalyticsEvent referralLinkOpened({required bool signedIn}) =>
      AnalyticsEvent('referral_link_opened', {'signed_in': signedIn});

  /// Davet kodu bir KAYITTA kullanıldı (`accepted`: sunucu daveti kabul etti mi).
  static AnalyticsEvent referralAccepted({required bool accepted, String? reason}) =>
      AnalyticsEvent('referral_accepted', {'accepted': accepted, 'reason': ?reason});

  // ── Rozet / paylaşım / puanlama ──────────────────────────────────────────────────────────────

  static AnalyticsEvent badgeEarned({required String badgeId}) =>
      AnalyticsEvent('badge_earned', {'badge_id': badgeId});

  static AnalyticsEvent badgeShared({required String badgeId}) =>
      AnalyticsEvent('badge_shared', {'badge_id': badgeId});

  /// Puanlama penceresi açıldı ve kullanıcı mağazaya gitti. Verilen YILDIZ gönderilmez —
  /// uygulama onu hiç kaydetmiyor (Play politikası; bkz. `rating_prompt.dart`).
  static const appRated = AnalyticsEvent('app_rated');
}
