import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faz 1 — koç işaretleri turunun TAMAMLANMA işareti.
///
/// NEDEN AYRI BİR BAYRAK (`onboardingSeen` / `welcomeSeen` / `aiWelcomeSeen` zaten varken):
/// bunlar zincirin FARKLI anlarıdır ve biri diğerinin yerine geçemez —
/// · `onboardingSeen`  → uygulamadan ÖNCE gösterilen tanıtım/kişiselleştirme,
/// · `welcomeSeen`     → kişiselleştirme özeti,
/// · `aiWelcomeSeen`   → Ana Sayfa'daki AI karşılama penceresi,
/// · `coachMarksSeen`  → **gerçek arayüzün üstünde** yapılan tur (bu dosya).
/// Tek bayrağa bindirilseydi, önceki adımları atlamış bir kullanıcı turu da hiç görmezdi.
///
/// "Atla" da tamamlanma sayılır: kullanıcı turu istemediğini söylemiştir; her açılışta ısrar etmek
/// rahatsız edicidir.
class CoachMarksController extends Notifier<bool> {
  CoachMarksController(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;

  Future<void> markSeen() async {
    if (state) return;
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kCoachMarksSeen, true);
    } catch (_) {}
  }

  /// Turu yeniden görmek isteyen kullanıcı için (Profil → "Tanıtım turunu tekrar izle").
  Future<void> reset() async {
    state = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCoachMarksSeen);
    } catch (_) {}
  }
}

const _kCoachMarksSeen = 'ea:coachMarksSeen:v1';

final coachMarksSeenProvider = NotifierProvider<CoachMarksController, bool>(
  () => CoachMarksController(false),
);

/// `main()`'de bir kez **senkron** okunur — dönen kullanıcıda tur flaşı olmaz.
Future<bool> readCoachMarksSeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kCoachMarksSeen) ?? false;
  } catch (_) {
    return false;
  }
}
