import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSeen = 'ea:onboardingSeen:v1';

/// İlk açılış tanıtımının görülüp görülmediği. Başlangıç değeri main()'de senkron okunur (flaş yok),
/// tamamlanınca kalıcı işaretlenir.
class OnboardingController extends Notifier<bool> {
  OnboardingController(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;

  Future<void> markSeen() async {
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSeen, true);
    } catch (_) {}
  }
}

/// Varsayılan: görülmemiş (main() override eder). Testlerde de override edilir.
final onboardingSeenProvider = NotifierProvider<OnboardingController, bool>(
  () => OnboardingController(false),
);

/// main()'de bir kez okunur.
Future<bool> readOnboardingSeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSeen) ?? false;
  } catch (_) {
    return false;
  }
}
