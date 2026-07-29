import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faz 7 — uygulama puanlama isteğinin SAF kural katmanı.
///
/// Puanlama isteği, kullanıcıyı en kolay rahatsız eden yüzeydir: yanlış anda ya da çok sık
/// sorulursa hem kötü puan hem kötü deneyim üretir. Bu yüzden karar ekrandan ayrı, saf bir
/// fonksiyondadır ve doğrudan test edilir (`premium_prompt.dart` ile aynı disiplin).

/// İsteği tetikleyen bağlam.
enum RatingTrigger {
  /// Üç deneme sınavını bitirdi — ürünün asıl işini yaptı ve iyi hissediyor.
  examsCompleted,

  /// AI Koç ile uzun bir sohbet yürüttü — ürünle gerçekten etkileşti.
  coachConversation,

  /// Kullanıcı Profil'den KENDİSİ istedi. Sınır uygulanmaz.
  manual,
}

/// Kalıcı puanlama durumu.
class RatingPromptState {
  const RatingPromptState({
    this.lastShownMs = 0,
    this.count = 0,
    this.rated = false,
    this.snoozedUntilMs = 0,
  });

  final int lastShownMs;

  /// Şimdiye kadar kaç kez gösterildi.
  final int count;

  /// Kullanıcı puanlamaya gitti — bir daha SORULMAZ.
  final bool rated;

  /// "Daha sonra hatırlat" ile ertelendiği an sonu.
  final int snoozedUntilMs;

  RatingPromptState copyWith({int? lastShownMs, int? count, bool? rated, int? snoozedUntilMs}) =>
      RatingPromptState(
        lastShownMs: lastShownMs ?? this.lastShownMs,
        count: count ?? this.count,
        rated: rated ?? this.rated,
        snoozedUntilMs: snoozedUntilMs ?? this.snoozedUntilMs,
      );

  Map<String, dynamic> toJson() => {
    'lastMs': lastShownMs,
    'count': count,
    'rated': rated,
    'snoozeMs': snoozedUntilMs,
  };

  static RatingPromptState fromJson(Map<String, dynamic> j) => RatingPromptState(
    lastShownMs: (j['lastMs'] as num?)?.toInt() ?? 0,
    count: (j['count'] as num?)?.toInt() ?? 0,
    rated: j['rated'] as bool? ?? false,
    snoozedUntilMs: (j['snoozeMs'] as num?)?.toInt() ?? 0,
  );
}

const int _dayMs = 24 * 60 * 60 * 1000;

/// İki gösterim arasındaki en kısa süre.
const int ratingCooldownMs = 45 * _dayMs;

/// "Daha sonra hatırlat" ne kadar erteler.
const int ratingSnoozeMs = 14 * _dayMs;

/// Ömür boyu en fazla kaç kez sorulur. Üçten sonra ısrar etmek dilenmektir.
const int ratingMaxPrompts = 3;

/// Otomatik tetik eşiği — tamamlanan deneme sınavı sayısı.
const int ratingExamThreshold = 3;

/// Otomatik tetik eşiği — bir AI Koç sohbetindeki mesaj sayısı ("uzun sohbet").
///
/// Sekiz mesaj ≈ dört soru-cevap turu: kullanıcı gerçekten kullanmış, tek soru sorup çıkmamış.
const int ratingCoachMessageThreshold = 8;

/// Bu an puanlama istenmeli mi?
///
/// [trigger] `manual` ise kullanıcı KENDİSİ istemiştir; hiçbir sınır uygulanmaz — kendi
/// isteğiyle açtığı bir pencereyi "çok erken" diye kapatmak saçma olurdu.
bool shouldAskForRating({
  required RatingTrigger trigger,
  required RatingPromptState state,
  required int nowMs,
}) {
  if (trigger == RatingTrigger.manual) return true;
  if (state.rated) return false; // puanladı → bir daha sorulmaz
  if (state.count >= ratingMaxPrompts) return false;
  if (nowMs < state.snoozedUntilMs) return false;
  if (state.lastShownMs > 0 && nowMs - state.lastShownMs < ratingCooldownMs) return false;
  return true;
}

/// Otomatik tetik koşulu oluştu mu? (Eşiğe TAM ULAŞILDIĞINDA — her sınavdan sonra değil.)
///
/// Eşit karşılaştırma bilinçli: dördüncü, beşinci sınavda tekrar tetiklenmez. Zaten soğuma
/// süresi de var ama iki savunma birden ucuz.
bool ratingTriggeredByExams(int examsFinished) => examsFinished == ratingExamThreshold;

/// Sohbet uzunluğu eşiği geçti mi? Yine TAM eşikte tetiklenir.
bool ratingTriggeredByCoach(int messageCount) => messageCount == ratingCoachMessageThreshold;

const _kRating = 'ea:ratingPrompt:v1';

class RatingPromptController extends Notifier<RatingPromptState> {
  @override
  RatingPromptState build() {
    Future.microtask(_load);
    return const RatingPromptState();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kRating);
      if (raw != null) {
        state = RatingPromptState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  Future<void> recordShown(int nowMs) =>
      _save(state.copyWith(lastShownMs: nowMs, count: state.count + 1));

  /// Kullanıcı puanlamaya gitti. Gerçekten puan verip vermediğini BİLEMEYİZ (mağaza bunu
  /// söylemez) — ama istediğimizi yaptı; tekrar sormak saygısızlık olur.
  Future<void> recordRated() => _save(state.copyWith(rated: true));

  Future<void> recordSnoozed(int nowMs) =>
      _save(state.copyWith(snoozedUntilMs: nowMs + ratingSnoozeMs));

  Future<void> _save(RatingPromptState next) async {
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRating, jsonEncode(next.toJson()));
    } catch (_) {}
  }
}

final ratingPromptProvider = NotifierProvider<RatingPromptController, RatingPromptState>(
  RatingPromptController.new,
);
