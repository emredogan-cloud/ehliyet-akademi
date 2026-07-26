import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Beta R1 — **Ana Sayfa'da** açılan AI karşılama popup'ının görülüp görülmediği.
///
/// NEDEN AYRI BİR İŞARET: `welcomeSeen` (E7) onboarding'den sonraki **özet ekranını** temsil eder
/// ve o zincire aittir. Bu popup ise Ana Sayfa **göründükten sonra** açılır; iki farklı an, iki
/// farklı yaşam döngüsü. Tek bayrağa bindirilseydi, özeti atlayan kullanıcı popup'ı da hiç
/// görmezdi (ya da tersi).
///
/// TEK SEFERLİK: `ea:aiWelcomeSeen:v1`. Başlangıç değeri `main()`'de **senkron** okunur
/// (`onboardingSeen`/`welcomeSeen` ile aynı desen) — böylece dönen kullanıcıda popup flaşı olmaz.
class AiWelcomeController extends Notifier<bool> {
  AiWelcomeController(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;

  /// Popup kapandığında çağrılır. **Her kapanış yolu** buraya gelir (CTA, zemin dokunuşu,
  /// geri tuşu) — biri unutulursa popup tekrar açılırdı.
  Future<void> markSeen() async {
    if (state) return;
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAiWelcomeSeen, true);
    } catch (_) {}
  }
}

const _kAiWelcomeSeen = 'ea:aiWelcomeSeen:v1';

/// Varsayılan: görülmemiş (`main()` override eder; testlerde de override edilir).
final aiWelcomeSeenProvider = NotifierProvider<AiWelcomeController, bool>(
  () => AiWelcomeController(false),
);

/// `main()`'de bir kez okunur.
Future<bool> readAiWelcomeSeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAiWelcomeSeen) ?? false;
  } catch (_) {
    return false;
  }
}
