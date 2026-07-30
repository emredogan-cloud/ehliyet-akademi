import 'package:ehliyet_akademi/data/referral/referral_api.dart';
import 'package:ehliyet_akademi/domain/referral/pending_referral.dart';
import 'package:flutter_test/flutter_test.dart';

/// Beta Faz 1 — davet derin bağlantısının çözümlenmesi.
///
/// ## Bu testin var olma sebebi
///
/// Derin bağlantı, ürünün **cihazda sessizce kırılabilen** parçasıdır: yanlışsa hata mesajı yoktur,
/// kullanıcı yalnız "bağlantı uygulamayı açmadı" der ve nedeni görünmez. Zincir dört halkadır ve
/// hepsi aynı yol biçimini üretmek zorundadır:
///
/// 1. Android manifestosu (`intent-filter` → `pathPrefix`)
/// 2. Flutter'ın motoru — gelen URI'yi **olduğu gibi** yönlendiriciye verir (`data.toString()`)
/// 3. go_router — yalnız `uri.path` ile eşleştirir (`normalizeUri`)
/// 4. `referralCodeFromPath` — koddan kodu çıkarır
///
/// ## Geliştirme sırasında yakalanan gerçek hata
///
/// Özel şema ilk yazımda `ehliyetakademi://davet/<KOD>` idi. `Uri.parse` bunu **host = "davet",
/// path = ""** diye çözer; go_router boş yolu `/` yapar ve hiçbir rota eşleşmez. Yani bağlantı
/// uygulamayı açar ama davet ekranı YERİNE hata rotası görünürdü. Aşağıdaki `Uri.parse` iddiaları
/// bu hatayı yakalar; doğru biçim araya bir host koyar: `ehliyetakademi://app/davet/<KOD>`.
void main() {
  const code = 'ABCD2345';

  group('bağlantı biçimleri aynı yola çıkar', () {
    test('https App Link → /davet/<KOD>', () {
      final uri = Uri.parse('https://www.ehliyetegitim.com/davet/$code');
      expect(uri.path, '/davet/$code');
      expect(referralCodeFromPath(uri.path), code);
    });

    test('www\'suz alan adı da aynı yolu verir', () {
      final uri = Uri.parse('https://ehliyetegitim.com/davet/$code');
      expect(uri.path, '/davet/$code');
      expect(referralCodeFromPath(uri.path), code);
    });

    test('özel şema — host GEREKLİ, yoksa yol boş kalır', () {
      // Manifestodaki biçim: android:scheme="ehliyetakademi" android:host="app"
      final good = Uri.parse('ehliyetakademi://app/davet/$code');
      expect(good.path, '/davet/$code');
      expect(referralCodeFromPath(good.path), code);

      // Hostsuz biçim ÇALIŞMAZ: "davet" HOST olarak çözülür ve yolda yalnız kod kalır. go_router
      // `/ABCD2345` ile eşleşecek bir rota bulamaz → uygulama hata rotasında açılır.
      // Manifesto bu biçimi KULLANMAMALI.
      final bad = Uri.parse('ehliyetakademi://davet/$code');
      expect(bad.host, 'davet');
      expect(bad.path, '/$code', reason: 'yol "davet" içermiyor — rota eşleşmez');
      expect(referralCodeFromPath(bad.path), isNull);
    });

    test('sorgu ve parça (fragment) kodu bozmaz', () {
      final uri = Uri.parse('https://www.ehliyetegitim.com/davet/$code?utm=whatsapp#top');
      expect(referralCodeFromPath(uri.path), code);
    });
  });

  group('referralCodeFromPath', () {
    test('küçük harf ve boşluk kanonikleştirilir', () {
      expect(referralCodeFromPath('/davet/abcd2345'), code);
    });

    /// Alfabede ne `0`/`1` ne de `O`/`I`/`L` var (karıştırılabilir çiftin iki üyesi de çıkarılmış).
    /// Bu yüzden bağlantıda `0` görülmesi kurtarılabilir bir niyet DEĞİL, bozuk bir bağlantıdır —
    /// uydurma bir harfe çevirip forma doldurmak yerine reddedilir (Beta Faz 1).
    test('alfabe dışı karakter taşıyan bağlantı reddedilir', () {
      expect(referralCodeFromPath('/davet/ABCD2340'), isNull);
      expect(referralCodeFromPath('/davet/ABCD2341'), isNull);
      expect(referralCodeFromPath('/davet/ABCD234O'), isNull);
    });

    test('eksik kod REDDEDİLİR — yarım kodu forma doldurmak kullanıcıyı yanıltır', () {
      expect(referralCodeFromPath('/davet/ABC'), isNull);
      expect(referralCodeFromPath('/davet/'), isNull);
      expect(referralCodeFromPath('/davet'), isNull);
    });

    test('başka yollar davet sanılmaz', () {
      expect(referralCodeFromPath('/home'), isNull);
      expect(referralCodeFromPath('/premium'), isNull);
      // "/davetiye" davet DEĞİL — düzenli ifade sınırı burada önemli.
      expect(referralCodeFromPath('/davetiye/$code'), isNull);
    });

    test('alfabe dışı karakter reddedilir', () {
      expect(referralCodeFromPath('/davet/ABCD!@#\$'), isNull);
    });
  });

  group('PendingReferral', () {
    test('geçerli kod yakalanır ve okunabilir', () {
      final pending = PendingReferral();
      expect(pending.hasCode, isFalse);
      expect(pending.capture('abcd2345'), isTrue);
      expect(pending.code, code);
    });

    test('biçimsiz kod SESSİZCE yok sayılır — var olan kodu da EZMEZ', () {
      final pending = PendingReferral(initial: code);
      expect(pending.capture('ABC'), isFalse);
      // Kritik: yarım bir bağlantı, önceden yakalanmış geçerli kodu silmemeli.
      expect(pending.code, code);
    });

    test('temizlenince kod gider', () {
      final pending = PendingReferral(initial: code)..clear();
      expect(pending.code, isNull);
      expect(pending.hasCode, isFalse);
    });

    test('kod her zaman kanonik biçimde tutulur', () {
      final pending = PendingReferral();
      pending.capture('abcd-2345');
      expect(pending.code, code);
      expect(isValidReferralCodeFormat(pending.code!), isTrue);
    });
  });
}
