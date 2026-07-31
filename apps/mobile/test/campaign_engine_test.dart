import 'package:ehliyet_akademi/domain/premium/campaign.dart';
import 'package:ehliyet_akademi/domain/premium/conversion.dart';
import 'package:ehliyet_akademi/domain/premium/paywall_offer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faz 3 — kampanya motoru ve dönüşüm kararlarının kapısı.
///
/// Bu dosyanın asıl işi bir DAVRANIŞI değil, bir GÜVENCEYİ korumak: kampanya yokken ekranda
/// sahte aciliyet (sayaç) ya da yanıltıcı fiyat (üstü çizili eski fiyat) **çıkamaz**.
void main() {
  final now = DateTime.utc(2026, 8, 10, 12);

  Campaign c({
    bool enabled = true,
    DateTime? startsAt,
    DateTime? endsAt,
    String? oldPrice,
    int discount = 0,
    CampaignKind kind = CampaignKind.general,
  }) => Campaign(
    id: 'k1',
    title: 'Kampanya',
    explanation: 'gerekçe',
    kind: kind,
    enabled: enabled,
    startsAt: startsAt,
    endsAt: endsAt,
    oldPriceLabel: oldPrice,
    discountPercent: discount,
  );

  group('kampanya yürürlüğü', () {
    test('kapalı kampanya hiçbir zaman yürürlükte değildir', () {
      expect(c(enabled: false).isActiveAt(now), isFalse);
      expect(c(enabled: false, endsAt: now.add(const Duration(days: 1))).hasCountdownAt(now), isFalse);
    });

    test('başlangıcı gelecekte olan kampanya henüz yürürlükte değildir', () {
      expect(c(startsAt: now.add(const Duration(hours: 1))).isActiveAt(now), isFalse);
    });

    test('bitişi geçmiş kampanya artık yürürlükte değildir', () {
      expect(c(endsAt: now.subtract(const Duration(seconds: 1))).isActiveAt(now), isFalse);
    });

    test('pencere içindeki açık kampanya yürürlüktedir', () {
      final k = c(
        startsAt: now.subtract(const Duration(days: 1)),
        endsAt: now.add(const Duration(days: 1)),
      );
      expect(k.isActiveAt(now), isTrue);
      expect(k.hasCountdownAt(now), isTrue);
      expect(k.remainingAt(now), const Duration(days: 1));
    });

    /// ASIL GÜVENCE: bitişi OLMAYAN bir kampanya sayaç göstermez. Sayaç, kapanacak bir şeyin
    /// habercisidir; kapanmayan bir şeyi geri saymak sahte aciliyettir.
    test('bitişi olmayan kampanyada sayaç YOKTUR', () {
      final k = c(endsAt: null);
      expect(k.isActiveAt(now), isTrue);
      expect(k.hasCountdownAt(now), isFalse);
      expect(k.remainingAt(now), Duration.zero);
    });
  });

  group('katalog ayrıştırma — bozuk veri ÇÖKME üretmez', () {
    test('boş yapılandırma boş katalog verir', () {
      expect(Campaign.parseCatalog(''), isEmpty);
      expect(Campaign.parseCatalog('   '), isEmpty);
    });

    test('bozuk JSON boş katalog verir', () {
      expect(Campaign.parseCatalog('{bu json değil'), isEmpty);
      expect(Campaign.parseCatalog('{"a":1}'), isEmpty, reason: 'liste değil');
    });

    test('kimliksiz ya da başlıksız giriş atlanır', () {
      final list = Campaign.parseCatalog('[{"title":"x"},{"id":"y"},{"id":"z","title":"Z"}]');
      expect(list, hasLength(1));
      expect(list.single.id, 'z');
    });

    test('enabled AÇIKÇA true değilse kampanya kapalıdır', () {
      final list = Campaign.parseCatalog('[{"id":"a","title":"A"}]');
      expect(list.single.enabled, isFalse);
      expect(list.single.isActiveAt(now), isFalse);
    });

    test('anlamsız indirim yüzdesi kırpılır', () {
      final list = Campaign.parseCatalog('[{"id":"a","title":"A","discountPercent":180}]');
      expect(list.single.discountPercent, 100);
    });

    test('tam kayıt okunur', () {
      final list = Campaign.parseCatalog(
        '[{"id":"welcome","title":"Hoş geldin","explanation":"neden",'
        '"kind":"firstExam","discountPercent":40,"oldPriceLabel":"₺799,99",'
        '"newPriceLabel":"₺479,99","endsAt":"2026-08-15T21:00:00Z","enabled":true}]',
      );
      final k = list.single;
      expect(k.kind, CampaignKind.firstExam);
      expect(k.discountPercent, 40);
      expect(k.oldPriceLabel, '₺799,99');
      expect(k.newPriceLabel, '₺479,99');
      expect(k.enabled, isTrue);
      expect(k.endsAt, isNotNull);
    });
  });

  group('kampanya seçimi', () {
    test('tür eşleşmesi genelin ÖNÜNDEDİR', () {
      final list = [
        c(kind: CampaignKind.general),
        Campaign(id: 'f', title: 'F', explanation: '', kind: CampaignKind.firstExam, enabled: true),
      ];
      expect(activeCampaign(list, now, kind: CampaignKind.firstExam)?.id, 'f');
    });

    test('tür yoksa genele düşülür', () {
      final list = [c(kind: CampaignKind.general)];
      expect(activeCampaign(list, now, kind: CampaignKind.firstExam)?.id, 'k1');
    });

    test('yürürlükte kampanya yoksa null', () {
      expect(activeCampaign([c(enabled: false)], now, kind: CampaignKind.firstExam), isNull);
      expect(activeCampaign(const [], now), isNull);
    });
  });

  group('sunum kararı', () {
    test('kampanya yoksa kart da sayaç da yok', () {
      final r = campaignPresentation(null, now);
      expect(r.showCard, isFalse);
      expect(r.showCountdown, isFalse);
    });

    test('kampanya var ama bitişi yoksa kart var, sayaç yok', () {
      final r = campaignPresentation(c(endsAt: null), now);
      expect(r.showCard, isTrue);
      expect(r.showCountdown, isFalse);
    });
  });

  group('ödeme ekranı teklifi kampanyadan türer', () {
    test('kampanya yoksa üstü çizili fiyat ve sayaç YOK', () {
      final offer = PaywallOffer.fromCampaign(null, now);
      expect(offer.hasListPrice, isFalse);
      expect(offer.isCountdownVisible(now), isFalse);
    });

    test('kapalı kampanya, kampanyasızla aynı sonucu verir', () {
      final offer = PaywallOffer.fromCampaign(
        c(enabled: false, oldPrice: '₺799,99', endsAt: now.add(const Duration(days: 1))),
        now,
      );
      expect(offer.hasListPrice, isFalse);
      expect(offer.isCountdownVisible(now), isFalse);
    });

    test('açık kampanyada üstü çizili fiyat ve sayaç gelir', () {
      final offer = PaywallOffer.fromCampaign(
        c(oldPrice: '₺799,99', endsAt: now.add(const Duration(hours: 5))),
        now,
      );
      expect(offer.listPriceLabel, '₺799,99');
      expect(offer.isCountdownVisible(now), isTrue);
    });
  });

  group('ilk sınav dönüşümü — ne zaman çalışır', () {
    test('yalnız BİRİNCİ sınavda', () {
      expect(
        shouldRunFirstExamConversion(examsFinished: 1, premium: false, alreadyShown: false),
        isTrue,
      );
      expect(
        shouldRunFirstExamConversion(examsFinished: 2, premium: false, alreadyShown: false),
        isFalse,
      );
      expect(
        shouldRunFirstExamConversion(examsFinished: 0, premium: false, alreadyShown: false),
        isFalse,
      );
    });

    test('premium kullanıcıya ASLA gösterilmez', () {
      expect(
        shouldRunFirstExamConversion(examsFinished: 1, premium: true, alreadyShown: false),
        isFalse,
      );
    });

    test('bir kez gösterildiyse tekrar gösterilmez', () {
      expect(
        shouldRunFirstExamConversion(examsFinished: 1, premium: false, alreadyShown: true),
        isFalse,
      );
    });
  });

  group('koçun okuması — sonuçtan bağımsız övgü YOK', () {
    test('geçen kullanıcıya geçtiği söylenir', () {
      final r = coachExamRead(correct: 42, total: 50, passMark: 35);
      expect(r.title, contains('Geçtin'));
      expect(r.body, contains('42'));
    });

    test('sınıra yakın kullanıcıya kaç soru kaldığı SAYIYLA söylenir', () {
      final r = coachExamRead(correct: 30, total: 50, passMark: 35);
      expect(r.body, contains('5 soru'));
      expect(r.title, isNot(contains('Geçtin')));
    });

    /// Düşük sonuç alan kullanıcıya "harikasın" denmez; ürün kendi ölçtüğü şeye inanmalı.
    test('düşük sonuçta abartılı övgü kullanılmaz', () {
      final r = coachExamRead(correct: 8, total: 50, passMark: 35);
      expect(r.body, contains('8'));
      expect(r.title.toLowerCase(), isNot(contains('harika')));
      expect(r.title.toLowerCase(), isNot(contains('tebrik')));
    });

    test('sıfır soruda çökmez', () {
      expect(() => coachExamRead(correct: 0, total: 0, passMark: 0), returnsNormally);
    });

    test('teklif girişi kullanıcının KENDİ sayısını taşır', () {
      final intro = coachOfferIntro(correct: 30, total: 50, passMark: 35);
      expect(intro, contains('30'));
      expect(intro, contains('5 soru'));
    });
  });

  group('karşılaştırma tablosu dürüst', () {
    /// Ücretsiz sütunu "hiçbir şey yok" demez — ücretsiz katmanda gerçekten olan yazılır.
    test('ücretsiz sütunda gerçek değerler var', () {
      final free = premiumComparison.map((r) => r.free).toList();
      expect(free.where((f) => f != '—'), isNotEmpty);
      expect(premiumComparison.every((r) => r.feature.isNotEmpty), isTrue);
    });

    test('premium-only satırlarda ücretsiz karşılığı yok işareti', () {
      for (final r in premiumComparison.where((r) => r.premiumOnly)) {
        expect(r.free, '—');
      }
    });
  });
}
