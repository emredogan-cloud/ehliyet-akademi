import 'package:ehliyet_akademi/data/premium/billing_gateway.dart';
import 'package:ehliyet_akademi/data/premium/iap_service.dart';
import 'package:ehliyet_akademi/data/premium/play_billing_gateway.dart';
import 'package:ehliyet_akademi/data/premium/revenuecat_gateway.dart';
import 'package:ehliyet_akademi/design/brand.dart';
import 'package:ehliyet_akademi/domain/premium/entitlement_status.dart';
import 'package:ehliyet_akademi/domain/premium/products.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'helpers.dart';

/// Beta Faz 3 — RevenueCat / ödeme soyutlaması.
///
/// KAPSAM: yaşam döngüsü kuralları (saf) · ağ geçidi yapılandırması ve sunucu köprüsü ·
/// mevcut `in_app_purchase` yolunun bozulmadığı · ödeme ekranının bütün koşulları.
///
/// DÜRÜST SINIR: **gerçek satın alma bu ortamda TEST EDİLEMEZ** — Play Billing yalnız Play'den
/// yüklenmiş, imzalı bir yapıda çalışır. Burada sınanan, satın almanın etrafındaki bütün
/// mantık ve arayüz davranışıdır.
void main() {
  group('yaşam döngüsü — saf kural katmanı', () {
    EntitlementFacts facts({
      bool isActive = true,
      bool willRenew = true,
      String? expiresAt = '2026-12-31T00:00:00Z',
      String? billingIssue,
      String? unsubscribe,
    }) => EntitlementFacts(
      identifier: 'premium',
      isActive: isActive,
      willRenew: willRenew,
      expiresAt: expiresAt,
      billingIssueDetectedAt: billingIssue,
      unsubscribeDetectedAt: unsubscribe,
    );

    test('yetki yoksa none — ve erişim vermez', () {
      expect(premiumLifecycleOf(null), PremiumLifecycle.none);
      expect(PremiumLifecycle.none.grantsAccess, isFalse);
    });

    test('süresiz yetki = ömür boyu; iptal/grace/hold uygulanmaz', () {
      final s = premiumLifecycleOf(facts(expiresAt: null));
      expect(s, PremiumLifecycle.lifetime);
      expect(s.grantsAccess, isTrue);
      expect(premiumLifecycleMessage(s), isNull); // ömür boyu üründe uyarı YOKTUR
    });

    test('etkin + yenilenecek → active, mesaj yok', () {
      final s = premiumLifecycleOf(facts());
      expect(s, PremiumLifecycle.active);
      expect(premiumLifecycleMessage(s), isNull);
    });

    test('İPTAL: erişim dönem sonuna kadar SÜRER', () {
      final s = premiumLifecycleOf(facts(willRenew: false, unsubscribe: '2026-07-01T00:00:00Z'));
      expect(s, PremiumLifecycle.cancelled);
      expect(s.grantsAccess, isTrue);
      expect(s.needsUserAction, isFalse);
      expect(premiumLifecycleMessage(s), contains('sonuna kadar'));
    });

    test('ÖDEMESİZ DÖNEM: erişim sürer ama kullanıcı harekete geçmeli', () {
      final s = premiumLifecycleOf(facts(billingIssue: '2026-07-20T00:00:00Z'));
      expect(s, PremiumLifecycle.gracePeriod);
      expect(s.grantsAccess, isTrue);
      expect(s.needsUserAction, isTrue);
    });

    test('ödeme sorunu, iptalden ÖNCE gelir — en acil mesaj gösterilsin', () {
      final s = premiumLifecycleOf(
        facts(
          willRenew: false,
          unsubscribe: '2026-07-01T00:00:00Z',
          billingIssue: '2026-07-20T00:00:00Z',
        ),
      );
      expect(s, PremiumLifecycle.gracePeriod);
    });

    test('HESAP BEKLEMESİ: erişim DURUR', () {
      final s = premiumLifecycleOf(
        facts(isActive: false, willRenew: false, billingIssue: '2026-06-01T00:00:00Z'),
      );
      expect(s, PremiumLifecycle.accountHold);
      expect(s.grantsAccess, isFalse);
      expect(s.needsUserAction, isTrue);
    });

    test('etkin değil ve ödeme sorunu da yoksa → none (uydurma durum üretilmez)', () {
      expect(premiumLifecycleOf(facts(isActive: false, willRenew: false)), PremiumLifecycle.none);
    });

    test('süresiz yetki "etkin değil" ise yetki yoktur', () {
      expect(
        premiumLifecycleOf(facts(isActive: false, expiresAt: null)),
        PremiumLifecycle.none,
      );
    });

    test('istenmeyen yetki kimliği eşleşmezse none', () {
      final all = [facts()];
      expect(premiumLifecycleFor(all, 'premium'), PremiumLifecycle.active);
      expect(premiumLifecycleFor(all, 'baska-yetki'), PremiumLifecycle.none);
      expect(premiumLifecycleFor(const [], 'premium'), PremiumLifecycle.none);
    });
  });

  group('RevenueCat ağ geçidi — yapılandırma', () {
    test('anahtar YOKSA yapılandırılmamıştır (uygulama çökmez, mevcut yola düşülür)', () {
      // Test derlemesinde `--dart-define=REVENUECAT_PUBLIC_KEY` verilmez.
      expect(RevenueCatGateway().isConfigured, isFalse);
      expect(RevenueCatGateway(publicKey: '').isConfigured, isFalse);
    });

    test('anahtar VARSA yapılandırılmıştır ve WEBHOOK köprüsünü bildirir', () {
      final g = RevenueCatGateway(publicKey: 'anahtar-yer-tutucu');
      expect(g.isConfigured, isTrue);
      expect(g.serverBridge, BillingServerBridge.revenueCatWebhook);
      expect(g.name, 'revenuecat');
    });

    test('varsayılan yetki kimliği premium; abonelik ürünleri boş kalabilir', () {
      final g = RevenueCatGateway(publicKey: 'anahtar-yer-tutucu');
      expect(g.entitlementId, 'premium');
      expect(g.monthlyProductId, isEmpty);
      expect(g.yearlyProductId, isEmpty);
    });

    test('yapılandırılmamış ağ geçidi hiçbir çağrıda FIRLATMAZ', () async {
      final g = RevenueCatGateway();
      expect(await g.available(), isFalse);
      expect(await g.products(), isEmpty);
      expect(await g.entitlementFacts(), isEmpty);
      expect(await g.entitlements(), isEmpty);
      expect(
        await g.purchase(
          const BillingProduct(storeProductId: 'komple_ehliyet', priceLabel: '₺399,00'),
        ),
        isA<BillingFailure>(),
      );
      expect(await g.restore(), isA<BillingFailure>());
      g.listen((_) async {});
      g.dispose(); // kurulmamış SDK'da bile güvenli
    });
  });

  group('mevcut in_app_purchase yolu — SÖKÜLMEDİ', () {
    ProductDetails details(String id, String price) => ProductDetails(
      id: id,
      title: 'Komple Ehliyet Paketi',
      description: 'Ömür boyu erişim',
      price: price,
      rawPrice: 399,
      currencyCode: 'TRY',
    );

    test('her zaman yapılandırılmıştır ve MAKBUZ köprüsünü kullanır', () {
      final g = PlayBillingGateway(service: FakeIapService());
      expect(g.isConfigured, isTrue);
      expect(g.serverBridge, BillingServerBridge.clientReceipt);
      expect(g.name, 'in_app_purchase');
    });

    test('mağaza ürünlerini yansız modele çevirir (ömür boyu)', () async {
      final g = PlayBillingGateway(
        service: FakeIapService(catalog: {'komple_ehliyet': details('komple_ehliyet', '₺399,00')}),
      );
      expect(await g.available(), isTrue);
      final products = await g.products();
      expect(products, hasLength(1));
      expect(products.single.storeProductId, 'komple_ehliyet');
      expect(products.single.priceLabel, '₺399,00');
      expect(products.single.period, BillingPeriod.lifetime);
    });

    test('mağaza kapalıysa dürüstçe boş liste — FIRLATMAZ', () async {
      final g = PlayBillingGateway(service: FakeIapService(isAvailable: false, throwOnQuery: true));
      expect(await g.available(), isFalse);
      expect(await g.products(), isEmpty);
    });

    test('ürün mağazada yoksa satın alma dürüst hata verir', () async {
      final g = PlayBillingGateway(service: FakeIapService());
      final result = await g.purchase(
        const BillingProduct(storeProductId: 'yok', priceLabel: '₺0'),
      );
      expect(result, isA<BillingFailure>());
      expect((result as BillingFailure).message, contains('Mağaza şu an kullanılamıyor'));
    });

    test('satın alma akışı mevcut IapService üzerinden başlatılır', () async {
      final iap = FakeIapService(
        catalog: {'komple_ehliyet': details('komple_ehliyet', '₺399,00')},
      );
      final g = PlayBillingGateway(service: iap);
      final products = await g.products();
      expect(await g.purchase(products.single), isA<BillingSuccess>());
      expect(iap.bought, ['komple_ehliyet']);
    });

    test('PLAY MAKBUZU akıştan gelir ve sunucuya gidecek token korunur', () async {
      final iap = FakeIapService();
      final g = PlayBillingGateway(service: iap);
      final seen = <BillingPurchase>[];
      g.listen((p) async => seen.add(p));

      await iap.emit(
        productId: 'komple_ehliyet',
        serverVerificationData: 'play-purchase-token-xyz',
      );

      expect(seen, hasLength(1));
      expect(seen.single.storeProductId, 'komple_ehliyet');
      expect(seen.single.purchaseToken, 'play-purchase-token-xyz');
    });

    test('yaşam döngüsü BİLDİRMEZ — uydurma durum yok (sahiplik sunucudan gelir)', () async {
      final g = PlayBillingGateway(service: FakeIapService());
      expect(await g.entitlementFacts(), isEmpty);
      expect(await g.entitlements(), isEmpty);
    });

    test('geri yükleme mevcut yola devredilir', () async {
      final iap = FakeIapService();
      final g = PlayBillingGateway(service: iap);
      expect(await g.restore(), isA<BillingSuccess>());
      expect(iap.restoreCalls, 1);
    });

    test('ödeme ekranının aradığı mağaza kimliği katalogla aynıdır', () {
      expect(primaryStoreProductId, premiumProduct.storeProductId);
      expect(primaryStoreProductId, 'komple_ehliyet');
    });
  });

  group('ödeme ekranı — mağaza kapalıyken', () {
    testWidgets('dürüst "mağaza kullanılamıyor" gösterilir, satın alma DEVRE DIŞI', (tester) async {
      await _openPaywall(tester, FakeBillingGateway());

      expect(find.text('Mağaza kullanılamıyor'), findsOneWidget);
      expect(_buyEnabled(tester), isFalse, reason: 'mağaza kapalıyken satın alma basılamaz');
    });

    testWidgets('GERİ YÜKLE her koşulda VARDIR — Play politikası', (tester) async {
      await _openPaywall(tester, FakeBillingGateway());
      expect(find.text('Geri yükle'), findsOneWidget);
    });

    testWidgets('yapılandırılmamış ağ geçidiyle ekran ÇÖKMEZ', (tester) async {
      await _openPaywall(tester, FakeBillingGateway(configured: false));
      expect(find.text('Komple Ehliyet Paketi'), findsOneWidget);
      expect(find.text('Geri yükle'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ödeme ekranı — mağaza açıkken', () {
    testWidgets('mağazanın YERELLEŞTİRDİĞİ fiyat gösterilir (uygulama biçimlemez)', (tester) async {
      await _openPaywall(tester, FakeBillingGateway.withStore(priceLabel: '₺449,00'));
      expect(find.text('₺449,00'), findsOneWidget);
      expect(find.text('Mağaza kullanılamıyor'), findsNothing);
      expect(_buyEnabled(tester), isTrue);
    });

    testWidgets('satın alma ağ geçidine devredilir', (tester) async {
      final gateway = FakeBillingGateway.withStore();
      await _openPaywall(tester, gateway);

      await tester.tap(find.text('Paketi Satın Al'));
      await tester.pumpAndSettle();

      expect(gateway.purchaseCalls, 1);
    });

    testWidgets('VAZGEÇME hata değildir — uyarı gösterilmez, tekrar denenebilir', (tester) async {
      final gateway = FakeBillingGateway.withStore(purchaseResult: const BillingCancelled());
      await _openPaywall(tester, gateway);

      await tester.tap(find.text('Paketi Satın Al'));
      await tester.pumpAndSettle();

      expect(gateway.purchaseCalls, 1);
      expect(find.byType(SnackBar), findsNothing);
      expect(_buyEnabled(tester), isTrue);
    });

    testWidgets('gerçek hata kullanıcıya AYNEN gösterilir', (tester) async {
      await _openPaywall(
        tester,
        FakeBillingGateway.withStore(
          purchaseResult: const BillingFailure('Bu cihazda satın almaya izin verilmiyor.'),
        ),
      );

      await tester.tap(find.text('Paketi Satın Al'));
      await tester.pumpAndSettle();

      expect(find.text('Bu cihazda satın almaya izin verilmiyor.'), findsOneWidget);
    });

    testWidgets('geri yüklenecek satın alma yoksa DÜRÜSTÇE söylenir', (tester) async {
      final gateway = FakeBillingGateway.withStore();
      await _openPaywall(tester, gateway);

      await tester.tap(find.text('Geri yükle'));
      await tester.pumpAndSettle();

      expect(gateway.restoreCalls, 1);
      expect(find.text('Geri yüklenecek bir satın alma bulunamadı.'), findsOneWidget);
    });

    testWidgets('sahiplik varsa geri yükleme başarısı bildirilir', (tester) async {
      final gateway = FakeBillingGateway.withStore();
      await _openPaywall(tester, gateway, owned: const [kPremiumProductId]);

      await tester.tap(find.text('Geri yükle'));
      await tester.pumpAndSettle();

      expect(find.text('Satın almaların geri yüklendi.'), findsOneWidget);
    });

    testWidgets('geri yükleme hatası kullanıcıya iletilir', (tester) async {
      await _openPaywall(
        tester,
        FakeBillingGateway.withStore(
          restoreResult: const BillingFailure('Satın almalar geri yüklenemedi.'),
        ),
      );

      await tester.tap(find.text('Geri yükle'));
      await tester.pumpAndSettle();

      expect(find.text('Satın almalar geri yüklenemedi.'), findsOneWidget);
    });
  });

  group('ödeme ekranı — yaşam döngüsü uyarıları', () {
    testWidgets('ödemesiz dönemde ödeme sorunu uyarısı gösterilir', (tester) async {
      await _openPaywall(
        tester,
        FakeBillingGateway.withStore(
          facts: const [
            EntitlementFacts(
              identifier: 'premium',
              isActive: true,
              willRenew: true,
              expiresAt: '2026-12-31T00:00:00Z',
              billingIssueDetectedAt: '2026-07-20T00:00:00Z',
            ),
          ],
        ),
      );
      expect(find.text('Ödeme sorunu'), findsOneWidget);
    });

    testWidgets('iptalde erişimin sürdüğü SÖYLENİR, korkutulmaz', (tester) async {
      await _openPaywall(
        tester,
        FakeBillingGateway.withStore(
          facts: const [
            EntitlementFacts(
              identifier: 'premium',
              isActive: true,
              expiresAt: '2026-12-31T00:00:00Z',
              unsubscribeDetectedAt: '2026-07-01T00:00:00Z',
            ),
          ],
        ),
      );
      expect(find.text('Abonelik durumu'), findsOneWidget);
      expect(find.textContaining('sonuna kadar'), findsOneWidget);
    });

    testWidgets('yaşam döngüsü bilgisi YOKSA hiçbir uyarı gösterilmez', (tester) async {
      await _openPaywall(tester, FakeBillingGateway.withStore());
      expect(find.text('Ödeme sorunu'), findsNothing);
      expect(find.text('Abonelik durumu'), findsNothing);
    });
  });
}

/// Uygulamayı aç, Profil → Premium ile ödeme ekranına git.
///
/// Test yüzeyi YÜKSELTİLİR (800×1400): varsayılan 800×600'de ödeme ekranının alt yarısı `ListView`
/// içinde hiç inşa edilmiyor, dolayısıyla fiyat/uyarı/düğme bulunamıyor. **Genişlik 800'de
/// bırakılır** — testlerin Ahem yazı tipi gerçek yazı tipinden geniştir ve daha dar bir yüzeyde
/// ana ekranda gerçek olmayan taşmalar üretir (cihazda 393 dp'de taşma yoktur, E13'te doğrulandı).
Future<void> _openPaywall(
  WidgetTester tester,
  BillingGateway billing, {
  List<String> owned = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await pumpApp(tester, billing: billing, owned: owned);
  await tester.tap(find.text('Profil'));
  await tester.pumpAndSettle();

  final row = find.text('Premium özellikleri keşfet');
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

/// Ödeme ekranındaki "Paketi Satın Al" düğmesi basılabilir mi?
bool _buyEnabled(WidgetTester tester) {
  final button = tester.widget<GradientPillButton>(
    find.widgetWithText(GradientPillButton, 'Paketi Satın Al'),
  );
  return button.onPressed != null && !button.loading;
}

/// Sahte `IapService` — `implements` ile örtük arayüz kullanılır, böylece `iap_service.dart`
/// dosyasına DOKUNULMADAN mevcut yol test edilebilir (Play Billing bağlantısı açılmaz).
class FakeIapService implements IapService {
  FakeIapService({
    this.isAvailable = true,
    this.catalog = const {},
    this.throwOnQuery = false,
  });

  final bool isAvailable;
  final Map<String, ProductDetails> catalog;
  final bool throwOnQuery;

  final List<String> bought = [];
  int restoreCalls = 0;
  int disposeCalls = 0;
  Future<void> Function(PurchaseDetails)? _handler;

  @override
  Future<bool> available() async => isAvailable;

  @override
  Future<Map<String, ProductDetails>> queryProducts() async {
    if (throwOnQuery) throw Exception('mağaza yok');
    return catalog;
  }

  @override
  void listen(Future<void> Function(PurchaseDetails) onPurchased) => _handler = onPurchased;

  @override
  Future<void> buy(ProductDetails details) async => bought.add(details.id);

  @override
  Future<void> restore() async => restoreCalls++;

  @override
  void dispose() => disposeCalls++;

  /// Play'in satın alma akışından bir sonuç geldiğini taklit et.
  Future<void> emit({required String productId, required String serverVerificationData}) async {
    await _handler?.call(
      PurchaseDetails(
        productID: productId,
        purchaseID: 'p1',
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: serverVerificationData,
          source: 'google_play',
        ),
        transactionDate: '0',
        status: PurchaseStatus.purchased,
      ),
    );
  }
}
