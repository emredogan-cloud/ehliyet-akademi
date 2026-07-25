import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kWelcomeSeen = 'ea:welcomeSeen:v1';

/// Evolution Faz E6/E7 — kişiselleştirme bittikten sonra gösterilen karşılama anının görülüp
/// görülmediği. `onboardingSeen` ile AYNI desen: başlangıç değeri main()'de senkron okunur
/// (açılışta karşılama flaşı olmaz) ve bir kez gösterildikten sonra kalıcı işaretlenir.
///
/// TEK SEFERLİK olması bilinçlidir: karşılama her açılışta gösterilse tanıtım değil engel olurdu.
class WelcomeController extends Notifier<bool> {
  WelcomeController(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;

  Future<void> markSeen() async {
    if (state) return;
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kWelcomeSeen, true);
    } catch (_) {}
  }
}

/// Varsayılan: görülmemiş (main() override eder; testlerde de override edilir).
final welcomeSeenProvider = NotifierProvider<WelcomeController, bool>(
  () => WelcomeController(false),
);

/// main()'de bir kez okunur.
Future<bool> readWelcomeSeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kWelcomeSeen) ?? false;
  } catch (_) {
    return false;
  }
}
