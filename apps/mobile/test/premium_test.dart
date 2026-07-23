import 'package:ehliyet_akademi/data/premium/quota_repository.dart';
import 'package:ehliyet_akademi/domain/premium/products.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  group('products + capabilities', () {
    test('capabilitiesOf / hasCapability; komple-b grants everything', () {
      expect(hasCapability(['premium-teori'], 'teori-premium'), isTrue);
      expect(hasCapability(['premium-teori'], 'ai-sinirsiz'), isFalse);
      final all = capabilitiesOf(['komple-b']);
      expect(all, containsAll(['teori-premium', 'direksiyon-premium', 'sinirsiz-deneme', 'soru-bankasi-tam', 'ai-sinirsiz']));
      expect(hasCapability([], 'teori-premium'), isFalse);
    });

    test('canAccessLesson: free open, unmapped-premium open, mapped locked/unlocked', () {
      expect(canAccessLesson(slug: 'trafik-temel', premium: false, owned: []), isTrue);
      expect(canAccessLesson(slug: 'bilinmeyen', premium: true, owned: []), isTrue); // unmapped → open
      expect(canAccessLesson(slug: 'park-manevra', premium: true, owned: []), isFalse);
      expect(
        canAccessLesson(slug: 'park-manevra', premium: true, owned: ['premium-direksiyon']),
        isTrue,
      );
      expect(canAccessLesson(slug: 'park-manevra', premium: true, owned: ['komple-b']), isTrue);
    });

    test('productForLesson/Capability picks the cheapest owning product', () {
      expect(productForCapability('sinirsiz-deneme').id, 'simulator-paketi'); // 149, cheapest
      expect(productForLesson('park-manevra').id, 'premium-direksiyon'); // 199
      expect(productByStoreId('komple_b')?.id, 'komple-b');
      expect(productById('komple-b')!.storeProductId, 'komple_b');
    });
  });

  group('free-tier quotas', () {
    test('AI: 5 free/day then blocked; unlimited with ai-sinirsiz', () async {
      SharedPreferences.setMockInitialValues({});
      final q = QuotaRepository(await SharedPreferences.getInstance());
      expect(q.remainingAi([]), freeAiDaily);
      for (var i = 0; i < freeAiDaily; i++) {
        expect(q.canAskAi([]), isTrue);
        await q.consumeAi([]);
      }
      expect(q.canAskAi([]), isFalse); // exhausted
      expect(q.remainingAi([]), 0);
      // premium bypasses
      expect(q.canAskAi(['komple-b']), isTrue);
      expect(q.remainingAi(['komple-b']), -1);
    });

    test('exam: 1 free/day then blocked; unlimited with sinirsiz-deneme', () async {
      SharedPreferences.setMockInitialValues({});
      final q = QuotaRepository(await SharedPreferences.getInstance());
      expect(q.canStartExam([]), isTrue);
      await q.consumeExam([]);
      expect(q.canStartExam([]), isFalse);
      expect(q.canStartExam(['simulator-paketi']), isTrue); // premium
      expect(q.canStartExam(['komple-b']), isTrue);
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
      await pumpApp(tester, owned: const ['premium-direksiyon']);
      await tester.tap(find.text('Öğren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dersler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Park Manevrası'));
      await tester.pumpAndSettle();

      // opens the real lesson detail (not the paywall gate)
      expect(find.text('Bu derste'), findsOneWidget);
      expect(find.text('Bu ileri ders premium'), findsNothing);
    });
  });
}
