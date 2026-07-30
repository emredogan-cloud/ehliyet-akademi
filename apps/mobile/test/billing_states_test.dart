import 'package:ehliyet_akademi/core/storage/token_store.dart';
import 'package:ehliyet_akademi/data/premium/store_purchase_store.dart';
import 'package:ehliyet_akademi/domain/premium/products.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Beta Faz 2 — SATIN ALMA DURUM DENETİMİ.
///
/// ## Bu dosya neden var
///
/// Ödeme akışının durumları çoğunlukla **sessizce** kırılır: kullanıcı vazgeçer ya da ödemesi
/// beklemeye düşer, ekran yanlış bir şey gösterir, kimse bir hata görmez.
///
/// Mevcut testler `FakeBillingGateway` üzerinden geçiyordu ve sahte ağ geçidi GERÇEK ağ geçidinden
/// **tam olarak kritik yerde** ayrılıyordu:
///
/// · Sahte `purchase()` → `BillingCancelled()` döner; ekran bunu işler ve meşguliyeti temizler.
/// · Gerçek `PlayBillingGateway.purchase()` → `BillingSuccess([])` döner. Vazgeçme, satın alma
///   AKIŞINDAN `PurchaseStatus.canceled` olarak gelir ve `IapService` onu SESSİZCE DÜŞÜRÜYORDU.
///
/// Sonuç: gerçek cihazda Play sayfasını kapatan kullanıcının satın alma düğmesi SONSUZA KADAR
/// dönüyordu. Testler yeşildi çünkü sahte ağ geçidi o yolu hiç kullanmıyordu.
///
/// [StreamBillingGateway] bu yüzden gerçek ağ geçidinin sözleşmesini taklit eder: `purchase()`
/// hemen boş başarı döner, sonuç **akıştan** gelir.
void main() {
  /// Ödeme ekranını aç (Profil → Premium) — mevcut testlerdeki yol.
  Future<void> openPaywall(WidgetTester tester) async {
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Premium').last);
    await tester.pumpAndSettle();
  }

  /// Satın alma düğmesinin etiketi — meşgulken yerini dönen göstergeye bırakır.
  ///
  /// Meşguliyeti bu yolla ölçmek dolaylı değil DOĞRUDANDIR: kullanıcının gördüğü şey tam olarak
  /// budur — "PAKETİ SATIN AL" yazısı mı, dönen halka mı.
  final buyLabel = find.text('PAKETİ SATIN AL');

  bool buyButtonBusy(WidgetTester tester) => buyLabel.evaluate().isEmpty;

  group('gerçek ağ geçidi sözleşmesi — sonuç akıştan gelir', () {
    testWidgets('VAZGEÇME: Play sayfası kapatılınca düğme meşguliyetten ÇIKAR', (tester) async {
      final gateway = StreamBillingGateway();
      await useTallSurface(tester);
      await pumpApp(tester, billing: gateway);
      await openPaywall(tester);

      await tester.tap(buyLabel);
      await tester.pump();
      // Akış henüz konuşmadı → ekran meşgul. Bu DOĞRU davranış.
      expect(buyButtonBusy(tester), isTrue);

      // Kullanıcı Play sayfasını kapattı.
      gateway.emitCancelled();
      await tester.pumpAndSettle();

      expect(
        buyButtonBusy(tester),
        isFalse,
        reason: 'vazgeçme akıştan gelir; düğme sonsuza kadar dönmemeli',
      );
      // Vazgeçme HATA DEĞİLDİR: mesaj gösterilmez.
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('BEKLEMEDE: kullanıcıya durum SÖYLENİR, düğme serbest kalır, erişim AÇILMAZ', (
      tester,
    ) async {
      final gateway = StreamBillingGateway();
      await useTallSurface(tester);
      await pumpApp(tester, billing: gateway);
      await openPaywall(tester);

      await tester.tap(buyLabel);
      await tester.pump();

      // Nakit / operatör faturası: Play "beklemede" der. Para HENÜZ alınmadı.
      gateway.emitPending();
      await tester.pumpAndSettle();

      expect(buyButtonBusy(tester), isFalse);
      // Sessiz kalmak "ödedim mi, ödemedim mi?" sorusunu doğurur ve destek yükü olur.
      expect(find.textContaining('onay bekliyor'), findsOneWidget);
      // Erişim AÇILMAZ: ödeme tamamlanmadı. Açmak, ödenmemiş bir hak vermek olurdu.
      expect(find.text('Premium Aktif'), findsNothing);
    });

    testWidgets('BAŞARILI: erişim açılır', (tester) async {
      final gateway = StreamBillingGateway();
      final store = MemoryStorePurchaseStore();
      await useTallSurface(tester);
      await pumpApp(tester, billing: gateway, storePurchases: store);
      await openPaywall(tester);

      await tester.tap(buyLabel);
      await tester.pump();
      gateway.emitPurchased(token: 'tok-1');
      // Kutlama penceresi açılır ve kullanıcı kapatana kadar durur; `pumpAndSettle` onu
      // "yerleşmemiş" sayardı. Sınırlı pump, akışın işlenmesine yeter.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect((await store.read()).single.storeProductId, premiumProduct.storeProductId);
      // Satın alma başarısı KULLANICIYA gösterilir — bu pencere daha önce hiçbir testte
      // açılmamıştı (Beta Faz 2 denetiminde fark edildi).
      expect(find.text('Premium Paketiniz Aktif!'), findsOneWidget);
    });

    testWidgets('ZATEN SAHİPSİN: hata gösterilmez, geri yükleme KENDİLİĞİNDEN tetiklenir', (
      tester,
    ) async {
      final gateway = StreamBillingGateway();
      await useTallSurface(tester);
      await pumpApp(tester, billing: gateway);
      await openPaywall(tester);

      await tester.tap(buyLabel);
      await tester.pump();
      gateway.emitAlreadyOwned();
      await tester.pumpAndSettle();

      expect(buyButtonBusy(tester), isFalse);
      expect(gateway.restoreCalls, 1, reason: '"zaten sahipsin" bir çıkmaz değil, geri yükleme sebebidir');
    });
  });

  group('iade / geri alma — cihaz defteri ile sunucu uzlaşması', () {
    /// İADE gerçek bir gelir bütünlüğü sorunuydu.
    ///
    /// Defter EKLEME-ODAKLIYDI ve sahiplik `birleşim(sunucu, defter)` olarak yayımlanıyordu. Sunucu
    /// iade sonrası hakkı geri alsa bile defterdeki kayıt SONSUZA KADAR premium veriyordu.
    ///
    /// Uzlaşma kuralı üç koşulun HEPSİNİ ister:
    ///   1. sunucu gerçekten CEVAP VERDİ (200 — `fetchOwned` null değil),
    ///   2. defterdeki kayıt daha önce sunucuya BAĞLANMIŞTI (`bound`),
    ///   3. sunucu artık o ürünü vermiyor.
    /// Üçü birlikte "geri alındı" demektir; eksiği "bilmiyoruz" demektir ve defter korunur.
    testWidgets('sunucuya bağlanmış hak, sunucu artık vermiyorsa DÜŞER', (tester) async {
      final store = MemoryStorePurchaseStore([
        const StorePurchase(storeProductId: 'komple_ehliyet', bound: true),
      ]);
      await useTallSurface(tester);
      await pumpApp(
        tester,
        entitlementsApi: FakeEntitlementsApi(const []),
        storePurchases: store,
        tokens: MemoryTokenStore()..write('abc'),
      );
      await tester.pumpAndSettle();

      expect(await store.read(), isEmpty, reason: 'iade edilmiş satın alma erişim vermeye devam etmemeli');
    });

    /// KRİTİK KARŞI DURUM: oturum yoksa sunucu 401 döner. Bu bir iade DEĞİLDİR.
    /// Karıştırmak, misafir kullanıcının ödediği paketi silmek olurdu.
    testWidgets('sunucu CEVAP VERMEZSE (401 / ağ yok) defter KORUNUR', (tester) async {
      final store = MemoryStorePurchaseStore([
        const StorePurchase(storeProductId: 'komple_ehliyet', bound: true),
      ]);
      await useTallSurface(tester);
      await pumpApp(
        tester,
        entitlementsApi: FakeEntitlementsApi(const [], false), // misafir → 401
        storePurchases: store,
      );
      await tester.pumpAndSettle();

      expect(await store.read(), hasLength(1), reason: 'oturumsuzluk iade değildir');
    });

    /// Misafirken alınmış, sunucuya HİÇ bağlanmamış satın alma: sunucu onu bilmiyor ama bu
    /// "geri alındı" demek değil, "hiç kaydedilmedi" demek.
    testWidgets('sunucuya HİÇ bağlanmamış (misafir) satın alma KORUNUR', (tester) async {
      final store = MemoryStorePurchaseStore([
        const StorePurchase(storeProductId: 'komple_ehliyet', purchaseToken: 'tok', bound: false),
      ]);
      await useTallSurface(tester);
      await pumpApp(
        tester,
        entitlementsApi: FakeEntitlementsApi(const []),
        storePurchases: store,
        tokens: MemoryTokenStore()..write('abc'),
      );
      await tester.pumpAndSettle();

      expect(await store.read(), hasLength(1));
    });

    testWidgets('sunucu hakkı vermeye devam ediyorsa defter korunur', (tester) async {
      final store = MemoryStorePurchaseStore([
        const StorePurchase(storeProductId: 'komple_ehliyet', bound: true),
      ]);
      await useTallSurface(tester);
      await pumpApp(
        tester,
        entitlementsApi: FakeEntitlementsApi(const ['komple-ehliyet']),
        storePurchases: store,
        tokens: MemoryTokenStore()..write('abc'),
      );
      await tester.pumpAndSettle();

      expect(await store.read(), hasLength(1));
    });
  });

  group('defter kalıcılığı', () {
    test('bağlanma işareti diske yazılır ve geri okunur', () async {
      final store = PrefsStorePurchaseStore();
      await store.add(
        const StorePurchase(storeProductId: 'komple_ehliyet', purchaseToken: 'tok', atMs: 5),
      );
      expect((await store.read()).single.bound, isFalse);

      await store.markBound('komple_ehliyet');
      final after = (await store.read()).single;
      // Makbuz düşer (bağlandı, tekrar denemeye gerek yok) ama KAYIT ve işaret kalır.
      expect(after.purchaseToken, isNull);
      expect(after.bound, isTrue);
      expect(after.storeProductId, 'komple_ehliyet');
    });

    test('kaldırma yalnız hedef ürünü siler', () async {
      final store = MemoryStorePurchaseStore([
        const StorePurchase(storeProductId: 'a'),
        const StorePurchase(storeProductId: 'b'),
      ]);
      await store.remove('a');
      expect((await store.read()).map((p) => p.storeProductId), ['b']);
    });
  });
}
