import 'package:ehliyet_akademi/domain/premium/retention.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faz 4 + 5 — tutundurma kararlarının kapısı.
///
/// Buradaki testlerin çoğu bir özelliğin ÇALIŞTIĞINI değil, **fazla çalışmadığını** doğruluyor:
/// hatırlatma bir kezdir, hemen gelmez ve satın almış kullanıcıya hiç gelmez.
void main() {
  const hour = 60 * 60 * 1000;
  const t0 = 1800000000000;

  group('Faz 4 — ödeme ekranı hatırlatması', () {
    test('hiç terk edilmediyse hatırlatma yok', () {
      expect(
        shouldRemindAfterPaywall(
          state: const PaywallReminderState(),
          premium: false,
          nowMs: t0,
        ),
        isFalse,
      );
    });

    /// "Hemen değil" şartı — terk edildiği an gösterilmesi ısrar olurdu.
    test('terkin hemen ardından gösterilmez', () {
      final state = PaywallReminderState(leftAtMs: t0);
      expect(shouldRemindAfterPaywall(state: state, premium: false, nowMs: t0), isFalse);
      expect(
        shouldRemindAfterPaywall(state: state, premium: false, nowMs: t0 + hour),
        isFalse,
      );
    });

    test('bekleme süresi dolunca bir kez gösterilir', () {
      final state = PaywallReminderState(leftAtMs: t0);
      expect(
        shouldRemindAfterPaywall(
          state: state,
          premium: false,
          nowMs: t0 + kPaywallReminderDelayMs,
        ),
        isTrue,
      );
    });

    /// TEK hatırlatma — ikincisi taciz olur.
    test('gösterildikten sonra bir daha gösterilmez', () {
      final state = PaywallReminderState(leftAtMs: t0, reminded: true);
      expect(
        shouldRemindAfterPaywall(
          state: state,
          premium: false,
          nowMs: t0 + 10 * kPaywallReminderDelayMs,
        ),
        isFalse,
      );
    });

    test('satın almış kullanıcıya hatırlatma yok', () {
      final state = PaywallReminderState(leftAtMs: t0);
      expect(
        shouldRemindAfterPaywall(
          state: state,
          premium: true,
          nowMs: t0 + kPaywallReminderDelayMs,
        ),
        isFalse,
      );
    });
  });

  group('Faz 5 — geri kazanım', () {
    test('hiç sahip olmamış kullanıcıya geri kazanım YOK', () {
      expect(
        shouldOfferWinBack(
          state: const WinBackState(lostAtMs: t0),
          premium: false,
          nowMs: t0 + 10 * hour,
        ),
        isFalse,
        reason: 'everOwned false — bu ilk satış, geri kazanım değil',
      );
    });

    test('erişim sürüyorsa teklif yok', () {
      expect(
        shouldOfferWinBack(
          state: const WinBackState(everOwned: true, lostAtMs: t0),
          premium: true,
          nowMs: t0 + 10 * hour,
        ),
        isFalse,
      );
    });

    /// Kaybın hemen ardından teklif etmek riskli: açılışta sunucu senkronu geçici olarak
    /// "sahip değil" diyebilir. Bekleme, gerçek kaybı gürültüden ayırır.
    test('kaybın hemen ardından teklif edilmez', () {
      expect(
        shouldOfferWinBack(
          state: const WinBackState(everOwned: true, lostAtMs: t0),
          premium: false,
          nowMs: t0,
        ),
        isFalse,
      );
    });

    test('bekleme dolunca bir kez teklif edilir', () {
      expect(
        shouldOfferWinBack(
          state: const WinBackState(everOwned: true, lostAtMs: t0),
          premium: false,
          nowMs: t0 + kWinBackDelayMs,
        ),
        isTrue,
      );
    });

    test('teklif edildikten sonra bir daha edilmez', () {
      expect(
        shouldOfferWinBack(
          state: const WinBackState(everOwned: true, lostAtMs: t0, offered: true),
          premium: false,
          nowMs: t0 + 100 * hour,
        ),
        isFalse,
      );
    });
  });

  group('durum serileştirme', () {
    test('hatırlatma durumu gidip gelir', () {
      const s = PaywallReminderState(leftAtMs: t0, reminded: true);
      final back = PaywallReminderState.fromJson(s.toJson());
      expect(back.leftAtMs, t0);
      expect(back.reminded, isTrue);
    });

    test('geri kazanım durumu gidip gelir', () {
      const s = WinBackState(everOwned: true, lostAtMs: t0, offered: true);
      final back = WinBackState.fromJson(s.toJson());
      expect(back.everOwned, isTrue);
      expect(back.lostAtMs, t0);
      expect(back.offered, isTrue);
    });

    test('bozuk/eksik JSON güvenli varsayılana düşer', () {
      final r = PaywallReminderState.fromJson(const {});
      expect(r.leftAtMs, 0);
      expect(r.reminded, isFalse);
      final w = WinBackState.fromJson(const {});
      expect(w.everOwned, isFalse);
      expect(w.offered, isFalse);
    });
  });
}
