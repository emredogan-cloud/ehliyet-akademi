import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/referral/referral_api.dart';

const _kPendingCode = 'ea:referral:pending:v1';

/// Beta Faz 1 — derin bağlantıdan gelen davet kodunu KAYIT ANINA kadar taşıyan kap.
///
/// ## Neden gerekli
///
/// `/davet/<KOD>` bağlantısı uygulamayı açar, ama kullanıcı o anda kayıt olmaz: önce tanıtım turunu
/// görür, belki uygulamayı gezer, kaydı yarın yapar. Kod o yolculuk boyunca bir yerde durmak
/// zorundadır. Bellekte tutulsa uygulama kapanınca kaybolurdu; kaybolursa davet **sessizce**
/// sayılmaz — davet eden ödülünü alamaz ve kimse nedenini bilmez.
///
/// ## Neden bir Notifier DEĞİL
///
/// Kod, yönlendiricinin `redirect` geri çağrısı içinde yakalanır. `redirect` gezinme çözümlenirken
/// çalışır; orada dinleyicisi olan bir durumu değiştirmek "build sırasında setState" hatası verir.
/// Bu yüzden burada dinleyici YOKTUR: değer senkron yazılır, diske arka planda düşer, okuyan ekran
/// (`AuthScreen`) onu `initState` içinde bir kez okur.
///
/// ## Ömür
///
/// Kod, kayıt SONUCU ne olursa olsun temizlenir ([clear]). Sunucu daveti reddetse bile (kendi kodu,
/// zaten davet edilmiş, IP sınırı) kodu saklamak, sonraki her kayıt denemesinde aynı reddi
/// tekrarlamak olurdu.
class PendingReferral {
  PendingReferral({String? initial}) : _code = initial;

  String? _code;

  /// Bekleyen kod (yoksa null). Her zaman kanonik ve biçimsel olarak geçerlidir.
  String? get code => _code;

  bool get hasCode => _code != null;

  bool _greeted = false;

  /// Davet karşılama ekranı bu oturumda GÖSTERİLDİ Mİ — gösterilmediyse gösterilmeli.
  ///
  /// ## Neden gerekli (cihazda ölçülerek bulundu)
  ///
  /// Davet bağlantısı İLK KURULUMDA uygulamayı açtığında yönlendirici kullanıcıyı tanıtım turuna
  /// çevirir (doğru davranış: tur, gezinmeyi tanıtmak zorunda). Tur bittiğinde `OnboardingScreen`
  /// **doğrudan** `/home`'a gider. Yönlendiricinin "tur bitti mi" dalı o anda `/onboarding`
  /// konumunu artık GÖRMEZ; dolayısıyla davet ekranına yönlendirme hiç çalışmıyordu.
  ///
  /// Kod kaybolmuyordu (kayıt formunda yine dolu geliyordu), ama kullanıcıya bekleyen bir daveti
  /// olduğu HİÇ SÖYLENMİYORDU. Kayıt olmazsa davet sessizce buharlaşırdı.
  ///
  /// Bu bayrak, kararı tek yerde (yönlendiricide) tutmayı sürdürerek sorunu çözer: karşılama bir
  /// kez gösterilir, sonra `/home` bir daha ele geçirilmez.
  ///
  /// KALICI DEĞİL (bilinçli): uygulama yeniden açıldığında karşılama bir daha gösterilebilir.
  /// Kod hâlâ kullanılmamışsa bu bir hata değil, hatırlatmadır.
  bool get shouldGreet => _code != null && !_greeted;

  /// Karşılama gösterildi — `/home` artık ele geçirilmez.
  void markGreeted() => _greeted = true;

  /// Derin bağlantıdan gelen kodu yakala.
  ///
  /// Biçimsiz kod SESSİZCE YOK SAYILIR: bağlantı kopyalanırken eksilmiş olabilir ve yarım bir kodu
  /// kayıt formuna doldurmak kullanıcıya kendi hatası gibi görünen bir hata gösterirdi.
  ///
  /// Dönüş: kod kabul edildi mi.
  bool capture(String raw) {
    final normalized = normalizeReferralCode(raw);
    if (!isValidReferralCodeFormat(normalized)) return false;
    _code = normalized;
    _persist(normalized);
    return true;
  }

  /// Kodu tüket — bir kayıt denemesinde kullanıldıktan sonra çağrılır.
  void clear() {
    _code = null;
    // Kod gittiğine göre karşılanacak bir şey de kalmadı.
    _greeted = true;
    _persist(null);
  }

  /// Diske yaz (beklenmez: gezinme akışını disk yazımı kadar bekletmemek için).
  void _persist(String? value) {
    Future<void>(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (value == null) {
          await prefs.remove(_kPendingCode);
        } else {
          await prefs.setString(_kPendingCode, value);
        }
      } catch (_) {
        // Kalıcılık kaybı davet akışını kırmaz: bellekteki kod bu oturumda hâlâ geçerli.
      }
    });
  }

  /// Açılışta bir kez okunur (`main()`), diğer tercihlerle aynı desen.
  static Future<String?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_kPendingCode);
      if (stored == null) return null;
      return isValidReferralCodeFormat(stored) ? stored : null;
    } catch (_) {
      return null;
    }
  }
}

/// Uygulama genelinde tek örnek. `main()` diskten okunan değerle ezer.
final pendingReferralProvider = Provider<PendingReferral>((ref) => PendingReferral());

/// `/davet/<KOD>` yolundan kodu çıkar.
///
/// Hem `https://…/davet/<KOD>` (App Link) hem `ehliyetakademi://davet/<KOD>` (özel şema) aynı
/// yol biçimini üretir; ayırmaya gerek yoktur. Kod yoksa ya da biçimsizse null.
String? referralCodeFromPath(String path) {
  final match = RegExp(r'^/davet/([^/?#]+)').firstMatch(path);
  if (match == null) return null;
  final normalized = normalizeReferralCode(Uri.decodeComponent(match.group(1)!));
  return isValidReferralCodeFormat(normalized) ? normalized : null;
}
