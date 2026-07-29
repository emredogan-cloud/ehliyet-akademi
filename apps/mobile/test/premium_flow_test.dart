import 'package:ehliyet_akademi/data/premium/billing_gateway.dart';
import 'package:ehliyet_akademi/data/premium/store_purchase_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Faz 2 — ödeme akışının üç somut hatası ve düzeltmeleri.
///
/// Her grup, sahada görülen ZİNCİRİ kurar; "şu widget var mı" testi değildir.
void main() {
  Future<void> openPaywall(WidgetTester tester) async {
    await useTallSurface(tester);
  }

  group('1) satın alma sonrası durum', () {
    testWidgets('sahipken satın alma yüzeyi yok, "Premium Aktif" var', (tester) async {
      await openPaywall(tester);
      await pumpApp(
        tester,
        owned: const ['komple-ehliyet'],
        billing: FakeBillingGateway.withStore(),
      );
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Premium'));
      await tester.tap(find.text('Premium').last);
      await tester.pumpAndSettle();

      expect(find.text('Premium Aktif'), findsOneWidget);
      // Satın alma düğmesi devre dışı DEĞİL — hiç ÇİZİLMİYOR.
      expect(find.text('PAKETİ SATIN AL'), findsNothing);
      expect(find.text('· tek seferlik'), findsNothing);
    });

    testWidgets('sahip değilken satın alma düğmesi görünür', (tester) async {
      await openPaywall(tester);
      await pumpApp(tester, billing: FakeBillingGateway.withStore());
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Premium').last);
      await tester.pumpAndSettle();

      expect(find.text('PAKETİ SATIN AL'), findsOneWidget);
      expect(find.text('Premium Aktif'), findsNothing);
    });
  });

  group('2) MİSAFİR satın alması — asıl hata', () {
    /// Sahadaki zincir: misafir → satın al → sunucu 401 → hak verilmez → özellikler KİLİTLİ.
    /// Artık mağazanın onayladığı satın alma cihaza yazılır ve erişim ANINDA açılır.
    testWidgets('sunucu 401 dönse bile erişim açılır', (tester) async {
      final api = FakeEntitlementsApi(const [], false); // misafir: her uç 401
      final store = MemoryStorePurchaseStore();
      final billing = FakeBillingGateway.withStore();
      await openPaywall(tester);
      await pumpApp(tester, billing: billing, entitlementsApi: api, storePurchases: store);

      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Premium').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PAKETİ SATIN AL'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PAKETİ SATIN AL'));
      await tester.pumpAndSettle();

      // Erişim AÇIK: ekran artık durum ekranı.
      expect(find.text('Premium Aktif'), findsOneWidget);
      // Makbuz kuyrukta: sunucuya bağlama denendi ve başarısız oldu ama satın alma kaybolmadı.
      final saved = await store.read();
      expect(saved.single.storeProductId, 'komple_ehliyet');
      expect(saved.single.purchaseToken, 'fake-token');
      expect(api.validateCalls, greaterThan(0), reason: 'sunucuya bağlama denenmeli');
    });

    /// "Bu ürüne zaten sahipsin" bir çıkmaz DEĞİL — satın almanın var olduğunun kanıtı.
    /// Ekran kullanıcıyı hata ile baş başa bırakmaz, geri yüklemeyi KENDİSİ tetikler.
    testWidgets('"zaten sahipsin" geri yüklemeyi kendiliğinden tetikler', (tester) async {
      final billing = FakeBillingGateway.withStore(
        purchaseResult: const BillingFailure('zaten sahipsin', alreadyOwned: true),
        restoreResult: const BillingSuccess([
          BillingPurchase(storeProductId: 'komple_ehliyet', purchaseToken: 'restored-token'),
        ]),
      );
      await openPaywall(tester);
      await pumpApp(
        tester,
        billing: billing,
        entitlementsApi: FakeEntitlementsApi(const [], false), // misafir
      );

      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Premium').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('PAKETİ SATIN AL'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PAKETİ SATIN AL'));
      await tester.pumpAndSettle();

      expect(billing.restoreCalls, 1, reason: 'geri yükleme kendiliğinden tetiklenmeli');
      expect(find.text('Premium Aktif'), findsOneWidget);
    });
  });

  group('3) geri yükleme', () {
    testWidgets('mağazadan gelen satın alma misafirde de erişimi açar', (tester) async {
      final store = MemoryStorePurchaseStore();
      final billing = FakeBillingGateway.withStore(
        restoreResult: const BillingSuccess([
          BillingPurchase(storeProductId: 'komple_ehliyet', purchaseToken: 'restored-token'),
        ]),
      );
      await openPaywall(tester);
      await pumpApp(
        tester,
        billing: billing,
        entitlementsApi: FakeEntitlementsApi(const [], false), // misafir
        storePurchases: store,
      );

      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Premium').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Geri yükle'));
      await tester.pumpAndSettle();

      expect(billing.restoreCalls, 1);
      expect(find.text('Premium Aktif'), findsOneWidget);
      expect(find.text('Satın almaların geri yüklendi.'), findsOneWidget);
      expect((await store.read()).single.storeProductId, 'komple_ehliyet');
    });

    testWidgets('gerçekten satın alma yoksa dürüst mesaj', (tester) async {
      final billing = FakeBillingGateway.withStore(restoreResult: const BillingSuccess([]));
      await openPaywall(tester);
      await pumpApp(tester, billing: billing);

      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Premium').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Geri yükle'));
      await tester.pumpAndSettle();

      expect(find.text('Geri yüklenecek bir satın alma bulunamadı.'), findsOneWidget);
      expect(find.text('Premium Aktif'), findsNothing);
    });

    /// Play politikası: geri yükleme her koşulda erişilebilir olmalı — mağaza kapalıyken bile.
    testWidgets('mağaza kapalıyken de geri yükleme düğmesi vardır', (tester) async {
      await openPaywall(tester);
      await pumpApp(tester, billing: FakeBillingGateway());

      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Premium').last);
      await tester.pumpAndSettle();

      expect(find.text('Geri yükle'), findsOneWidget);
    });
  });

  group('cihaz defteri', () {
    /// Defter CİHAZDAKİ Play hesabına aittir; çıkışta silinmez. Silinseydi çıkış yapan kullanıcı
    /// kendi satın aldığı paketi kaybederdi.
    testWidgets('açılışta cihaz defterindeki satın alma erişimi açar', (tester) async {
      final store = MemoryStorePurchaseStore([
        const StorePurchase(storeProductId: 'komple_ehliyet'),
      ]);
      await openPaywall(tester);
      await pumpApp(
        tester,
        billing: FakeBillingGateway.withStore(),
        entitlementsApi: FakeEntitlementsApi(const [], false), // oturum yok
        storePurchases: store,
      );

      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Premium').last);
      await tester.pumpAndSettle();

      expect(find.text('Premium Aktif'), findsOneWidget);
    });

    /// Bekleyen makbuz, oturum açılınca sunucuya bağlanmalı — yoksa satın alma başka cihaza geçmez.
    testWidgets('bekleyen makbuz açılışta sunucuya bağlanmayı dener', (tester) async {
      final api = FakeEntitlementsApi(const []); // oturum VAR
      final store = MemoryStorePurchaseStore([
        const StorePurchase(storeProductId: 'komple_ehliyet', purchaseToken: 'pending-token'),
      ]);
      await openPaywall(tester);
      await pumpApp(
        tester,
        billing: FakeBillingGateway.withStore(),
        entitlementsApi: api,
        storePurchases: store,
      );
      await tester.pumpAndSettle();

      expect(api.validatedTokens, contains('pending-token'));
      // Bağlandı → makbuz düşürüldü, kayıt (erişimin kaynağı) duruyor.
      final saved = await store.read();
      expect(saved.single.storeProductId, 'komple_ehliyet');
      expect(saved.single.purchaseToken, isNull);
    });
  });
}
