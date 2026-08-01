import 'package:ehliyet_akademi/data/premium/quota_repository.dart';
import 'package:ehliyet_akademi/domain/premium/premium_prompt.dart';
import 'package:ehliyet_akademi/domain/premium/products.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  group('premium katalog + yetenekler', () {
    /// Ürün Evrimi v1.1 · Faz 10 — katalog üç pakete çıktı.
    test('üç paket: haftalık 50, aylık 200, ömür boyu 479,99 (önerilen)', () {
      expect(products, hasLength(3));
      expect(products.map((p) => p.id), [
        kWeeklyProductId,
        kMonthlyProductId,
        kPremiumProductId,
      ]);
      expect(productById(kWeeklyProductId)!.priceMinor, 5000);
      expect(productById(kMonthlyProductId)!.priceMinor, 20000);
      expect(productById(kPremiumProductId)!.priceMinor, 47999);
      expect(recommendedProduct.id, kPremiumProductId);
      expect(products.where((p) => p.highlight), hasLength(1));
    });

    /// GERİYE UYUMLULUK — bu testin kırılması, ödeme yapmış kullanıcıların premium'unu
    /// kaybetmesi demektir. Ömür boyu paketin kimliği değiştirilemez.
    test('ömür boyu paketin kimliği DEĞİŞMEDİ — eski satın almalar geçerli kalır', () {
      expect(kPremiumProductId, 'komple-ehliyet');
      expect(premiumProduct.storeProductId, 'komple_ehliyet');
      expect(isPremium(['komple-ehliyet']), isTrue);
    });

    test('yedek fiyat etiketi kuruşu doğru biçimler', () {
      expect(productById(kWeeklyProductId)!.fallbackPriceLabel, '₺50/hafta');
      expect(productById(kMonthlyProductId)!.fallbackPriceLabel, '₺200/ay');
      expect(productById(kPremiumProductId)!.fallbackPriceLabel, '₺479,99');
    });

    test('abonelik/tek-seferlik ayrımı', () {
      expect(productById(kWeeklyProductId)!.period.isSubscription, isTrue);
      expect(productById(kMonthlyProductId)!.period.isSubscription, isTrue);
      expect(productById(kPremiumProductId)!.period.isSubscription, isFalse);
    });

    test('activeProduct en iyi paketi seçer', () {
      expect(activeProduct([]), isNull);
      expect(activeProduct([kWeeklyProductId])!.id, kWeeklyProductId);
      expect(activeProduct([kWeeklyProductId, kPremiumProductId])!.id, kPremiumProductId);
      expect(activeProduct([kWeeklyProductId, kMonthlyProductId])!.id, kMonthlyProductId);
      expect(activeProduct(['yok-boyle']), isNull);
    });

    test('üç paket de AYNI yetenekleri açar — fark yalnız süre', () {
      for (final p in products) {
        expect(p.capabilities, kAllCapabilities);
      }
      expect(isPremium([kWeeklyProductId]), isTrue);
      expect(isPremium([kMonthlyProductId]), isTrue);
    });

    test('the pack grants every capability; empty owns nothing', () {
      final all = capabilitiesOf([kPremiumProductId]);
      expect(all, containsAll(['teori-premium', 'direksiyon-premium', 'sinirsiz-deneme', 'soru-bankasi-tam', 'ai-sinirsiz']));
      expect(isPremium([kPremiumProductId]), isTrue);
      expect(isPremium([]), isFalse);
      expect(capabilitiesOf(['yok-boyle']), isEmpty);
    });

    test('canAccessLesson: free open, unmapped-premium open, mapped locked/unlocked', () {
      expect(canAccessLesson(slug: 'trafik-temel', premium: false, owned: []), isTrue);
      expect(canAccessLesson(slug: 'bilinmeyen', premium: true, owned: []), isTrue); // unmapped → open
      expect(canAccessLesson(slug: 'park-manevra', premium: true, owned: []), isFalse);
      expect(canAccessLesson(slug: 'park-manevra', premium: true, owned: [kPremiumProductId]), isTrue);
    });

    test('canAccessVideo: first free, rest premium', () {
      expect(canAccessVideo(index: 0, owned: []), isTrue); // önizleme ücretsiz
      expect(canAccessVideo(index: 1, owned: []), isFalse);
      expect(canAccessVideo(index: 3, owned: [kPremiumProductId]), isTrue);
    });

    test('productForLesson/Capability → the single pack; store id bridge', () {
      expect(productForCapability('sinirsiz-deneme').id, kPremiumProductId);
      expect(productForLesson('park-manevra').id, kPremiumProductId);
      expect(productByStoreId('komple_ehliyet')?.id, kPremiumProductId);
    });
  });

  group('free-tier quotas', () {
    test('AI: 5 free/day then blocked; unlimited with premium', () async {
      SharedPreferences.setMockInitialValues({});
      final q = QuotaRepository(await SharedPreferences.getInstance());
      expect(q.remainingAi([]), freeAiDaily);
      for (var i = 0; i < freeAiDaily; i++) {
        expect(q.canAskAi([]), isTrue);
        await q.consumeAi([]);
      }
      expect(q.canAskAi([]), isFalse); // exhausted
      expect(q.canAskAi([kPremiumProductId]), isTrue);
      expect(q.remainingAi([kPremiumProductId]), -1);
    });

    test('exam: 1 free/day then blocked; unlimited with premium', () async {
      SharedPreferences.setMockInitialValues({});
      final q = QuotaRepository(await SharedPreferences.getInstance());
      expect(q.canStartExam([]), isTrue);
      await q.consumeExam([]);
      expect(q.canStartExam([]), isFalse);
      expect(q.canStartExam([kPremiumProductId]), isTrue);
    });
  });

  group('premium prompt (frequency-capped)', () {
    const s0 = PremiumPromptState();
    test('never prompts a premium user', () {
      expect(shouldPromptPremium(premium: true, state: s0, nowMs: 1000000), isFalse);
    });
    test('prompts once, then respects the 24h cooldown', () {
      expect(shouldPromptPremium(premium: false, state: s0, nowMs: 1000000), isTrue);
      final shown = PremiumPromptState(lastShownMs: 1000000, count: 1);
      expect(shouldPromptPremium(premium: false, state: shown, nowMs: 1000000 + 1000), isFalse); // cooldown
      expect(shouldPromptPremium(premium: false, state: shown, nowMs: 1000000 + 25 * 3600 * 1000), isTrue);
    });
    test('stops nagging after the lifetime cap', () {
      const capped = PremiumPromptState(lastShownMs: 0, count: 6);
      expect(shouldPromptPremium(premium: false, state: capped, nowMs: 10 * 24 * 3600 * 1000), isFalse);
    });
  });

  group('premium lesson gating (UI)', () {
    testWidgets('locked premium lesson shows a lock in the list (guest)', (tester) async {
      await pumpApp(tester, owned: const []);
      await tester.tap(find.text('Öğren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dersler'));
      await tester.pumpAndSettle();

      expect(find.text('Park Manevrası'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsWidgets); // premium lesson locked
    });

    testWidgets('owning the pack unlocks the lesson detail', (tester) async {
      await pumpApp(tester, owned: const [kPremiumProductId]);
      await tester.tap(find.text('Öğren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dersler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Park Manevrası'));
      await tester.pumpAndSettle();

      expect(find.text('Bu derste'), findsOneWidget);
      expect(find.text('Bu ileri ders premium'), findsNothing);
    });
  });
}
