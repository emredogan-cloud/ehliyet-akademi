import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Premium teşvik penceresinin bağlamsal + sık gösterilmeyen (frequency-capped) tetikleme mantığı.
/// Amaç: dönüşümü artırmak ama asla rahatsız etmemek. Saf karar fonksiyonu + kalıcı sayaç.

/// Teşvik penceresini tetikleyen bağlam (kopya/analitik için).
enum PremiumTrigger {
  firstExam('İlk deneme sınavını tamamladın! 🎉'),
  aiQuota('Bugünkü ücretsiz AI Koç hakkın doldu.'),
  examQuota('Günlük ücretsiz deneme hakkın doldu.'),
  achievement('Yeni bir başarı kazandın! 🏆'),
  engagement('Harika gidiyorsun — bir üst seviyeye geç.'),
  lessonLocked('Bu premium içeriğin kilidini aç.'),
  videoLocked('Video dersler premium içeriktir.');

  const PremiumTrigger(this.headline);
  final String headline;
}

/// Sık-gösterim sınırları.
const int _cooldownMs = 24 * 60 * 60 * 1000; // en fazla günde bir
const int _maxLifetimePrompts = 6; // bir noktadan sonra dürtme yok

class PremiumPromptState {
  const PremiumPromptState({this.lastShownMs = 0, this.count = 0});
  final int lastShownMs;
  final int count;

  Map<String, dynamic> toJson() => {'lastMs': lastShownMs, 'count': count};
  static PremiumPromptState fromJson(Map<String, dynamic> j) =>
      PremiumPromptState(lastShownMs: (j['lastMs'] as num?)?.toInt() ?? 0, count: (j['count'] as num?)?.toInt() ?? 0);
}

/// Saf karar: bu an teşvik gösterilmeli mi?
bool shouldPromptPremium({
  required bool premium,
  required PremiumPromptState state,
  required int nowMs,
}) {
  if (premium) return false; // zaten premium → asla
  if (state.count >= _maxLifetimePrompts) return false; // nazik ol, dürtmeyi bırak
  // Soğuma süresi yalnız daha önce gösterildiyse geçerli (ilk kez her zaman uygun).
  if (state.lastShownMs > 0 && nowMs - state.lastShownMs < _cooldownMs) return false;
  return true;
}

const _kPrompt = 'ea:premiumPrompt:v1';

/// Teşvik sayacı — kalıcı; `maybeTrigger` bağlamsal noktalarda çağrılır.
class PremiumPromptController extends Notifier<PremiumPromptState> {
  @override
  PremiumPromptState build() {
    Future.microtask(_load);
    return const PremiumPromptState();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrompt);
      if (raw != null) state = PremiumPromptState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  /// Gösterim kaydını işle (sayaç + zaman).
  Future<void> recordShown(int nowMs) async {
    state = PremiumPromptState(lastShownMs: nowMs, count: state.count + 1);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrompt, jsonEncode(state.toJson()));
    } catch (_) {}
  }
}

final premiumPromptProvider =
    NotifierProvider<PremiumPromptController, PremiumPromptState>(PremiumPromptController.new);
