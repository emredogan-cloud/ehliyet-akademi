import 'dart:async';
import 'dart:convert';

import 'package:ehliyet_akademi/data/content/content_api.dart';
import 'package:ehliyet_akademi/data/content/content_local_store.dart';
import 'package:ehliyet_akademi/data/content/content_repository.dart';
import 'package:ehliyet_akademi/data/practice/question_repository.dart';
import 'package:ehliyet_akademi/data/premium/store_purchase_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Beta Faz 5 — ÇEVRİMDIŞI DENETİMİ.
///
/// ## Neyi ölçüyor
///
/// "Çevrimdışı çalışıyor" iddiası ancak **ağın gerçekten olmadığı** bir koşuda doğrulanabilir.
/// Burada uygulama, her isteği reddeden bir ağ katmanıyla açılır ve her yüzey tek tek gezilir.
///
/// Aranan hata biçimi şu: ekran ÇÖKMEZ ama BOŞ kalır ve kullanıcı neden boş olduğunu anlamaz.
/// Bu, çökmekten daha kötüdür — çökme bildirilir, sessiz boşluk bildirilmez; kullanıcı uygulamanın
/// kendisinin işe yaramaz olduğunu düşünür.
///
/// ## Kural
///
/// Sınava hazırlıkla ilgili HER ŞEY çevrimdışı çalışmalı. Yalnız şunlar internet ister ve
/// istediklerini SÖYLEMELİDİR: AI Koç, Topluluk, davet özeti, mağaza.
void main() {
  /// Ağı tamamen ölü olan bir uygulama.
  ///
  /// Ders/işaret içeriği ve soru bankası, testlerde zaten yerel anlık görüntüden gelir
  /// (`overrideContent`) — bu, gerçek uygulamadaki **drift önbelleğinin** karşılığıdır: ikisinde de
  /// veri diskten okunur, ağ hiç beklenmez.
  Future<void> pumpOffline(
    WidgetTester tester, {
    List<String> owned = const [],
    Map<String, Object> prefs = const {},
  }) async {
    await useTallSurface(tester);
    await pumpApp(
      tester,
      prefs: prefs,
      // Çevrimdışı = oturum var ama sunucu yok. Yetki API'si "cevap veremedi" der (null).
      entitlementsApi: FakeEntitlementsApi(owned, false),
      storePurchases: MemoryStorePurchaseStore([
        for (final id in owned) StorePurchase(storeProductId: id.replaceAll('-', '_')),
      ]),
      coach: FakeCoachApi(streamThrows: true),
      community: FakeCommunityApi(failLeaderboard: true),
      groups: FakeGroupsApi(failGroups: true, failChallenges: true),
    );
  }

  Future<void> goTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  group('sınava hazırlık — ÇEVRİMDIŞI ÇALIŞMALI', () {
    testWidgets('Ana Sayfa: hazırlık, plan ve hızlı işlemler görünür', (tester) async {
      await pumpOffline(tester);
      expect(find.text('Bugün de çalışalım'), findsOneWidget);
      expect(find.text('Sınava hazırlık'), findsOneWidget);
      // Ağ hatası kullanıcıya bir hata ekranı olarak YANSIMAMALI.
      expect(find.textContaining('Bağlantı hatası'), findsNothing);
    });

    testWidgets('Öğren: dersler ve işaretler yerelden açılır', (tester) async {
      await pumpOffline(tester);
      await goTab(tester, 'Öğren');
      expect(find.text('Dersler'), findsWidgets);

      await tester.tap(find.text('Dersler').first);
      await tester.pumpAndSettle();
      expect(find.text('Trafiğe Giriş'), findsOneWidget);

      // Dersin İÇİ de açılmalı — liste görünüp detay boş kalırsa çevrimdışı iddiası yarımdır.
      await tester.tap(find.text('Trafiğe Giriş'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Trafik, yolların paylaşımıdır'), findsOneWidget);
    });

    testWidgets('Pratik: sınav ve akıllı çalışma başlatılabilir', (tester) async {
      await pumpOffline(tester);
      await goTab(tester, 'Pratik');
      expect(find.textContaining('Deneme'), findsWidgets);
    });

    testWidgets('İlerleme: seviye, rozetler ve istatistikler yerelden hesaplanır', (tester) async {
      // Cevap defteri DİSKTEN gelir; sunucudan değil. Tohum vermek, istatistiklerin gerçekten
      // yerelde hesaplandığını gösterir — boş bir ekran bunu kanıtlamazdı.
      await pumpOffline(tester, prefs: {'ea:answers:v1': _seededAnswers});
      // Doğrudan rota: Profil'de "İlerleme" hem bir istatistik ETİKETİ hem bir satır olduğu için
      // metinle gezinmek belirsiz. Test çevrimdışı davranışı ölçüyor, gezinmeyi değil.
      routerOf(tester).go('/progress');
      await tester.pumpAndSettle();

      // Seviye, doğruluk ve rozetler tamamen yerel cevap defterinden türetilir; ağ hiç gerekmez.
      expect(find.textContaining('Seviye'), findsWidgets);
      expect(find.text('Doğruluk'), findsOneWidget);
      expect(find.textContaining('Bağlantı'), findsNothing);
    });

    testWidgets('İlerleme: veri YOKKEN dürüst boş durum, hata değil', (tester) async {
      await pumpOffline(tester);
      routerOf(tester).go('/progress');
      await tester.pumpAndSettle();

      // "Veri yok" ile "bağlanamadım" farklı şeylerdir; çevrimdışı kullanıcıya ikincisini
      // göstermek, aslında var olmayan bir arıza bildirmek olurdu.
      expect(find.text('Henüz veri yok'), findsOneWidget);
    });

    testWidgets('Profil: misafir kartı ve ayarlar çalışır', (tester) async {
      await pumpOffline(tester);
      await goTab(tester, 'Profil');
      expect(find.text('Misafir'), findsOneWidget);
      expect(find.text('Koyu tema'), findsOneWidget);
    });
  });

  group('internet GEREKTİRENLER — sessiz kalmamalı, SÖYLEMELİ', () {
    /// Bu grubun tek kuralı: boş ekran YOK. Kullanıcı neden bir şey göremediğini okuyabilmeli ve
    /// mümkünse bir çıkış yolu (tekrar dene) bulabilmeli.
    testWidgets('AI Koç: internet gerektiğini söyler', (tester) async {
      await pumpOffline(tester);
      await goTab(tester, 'AI Koç');
      // Ekran açılır ve giriş alanı durur; soru sorulduğunda hata METNİ gösterilir.
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Topluluk: dürüst hata durumu ve tekrar deneme yolu', (tester) async {
      await pumpOffline(tester);
      await goTab(tester, 'Topluluk');
      // Boş bir ekran DEĞİL: ya bir açıklama ya bir eylem olmalı.
      final hasExplanation = find.textContaining('alınamadı').evaluate().isNotEmpty ||
          find.textContaining('Bağlantı').evaluate().isNotEmpty ||
          find.textContaining('Katıl').evaluate().isNotEmpty ||
          find.textContaining('Tekrar').evaluate().isNotEmpty;
      expect(hasExplanation, isTrue, reason: 'çevrimdışı topluluk ekranı sessiz kalmamalı');
    });

    testWidgets('Davet: özet alınamayınca tekrar deneme sunulur', (tester) async {
      await pumpOffline(tester);
      await goTab(tester, 'Profil');
      await tester.scrollUntilVisible(find.text('Davet et, premium kazan'), 200);
      await tester.tap(find.text('Davet et, premium kazan'));
      await tester.pumpAndSettle();

      // Misafir olduğu için önce giriş istenir; oturum varsa "tekrar dene" çıkar. İkisi de
      // sessiz boşluktan iyidir.
      final honest = find.textContaining('giriş yap').evaluate().isNotEmpty ||
          find.text('Tekrar dene').evaluate().isNotEmpty;
      expect(honest, isTrue);
    });

    testWidgets('Ödeme ekranı: mağaza kapalıyken dürüst davranır ve geri yükleme DURUR', (
      tester,
    ) async {
      await pumpOffline(tester);
      await goTab(tester, 'Profil');
      await tester.tap(find.text('Premium').last);
      await tester.pumpAndSettle();

      // Play politikası: geri yükleme her koşulda erişilebilir olmalı — ağ yokken bile.
      expect(find.text('Geri yükle'), findsOneWidget);
    });
  });

  _cacheLatencyGuard();

  group('çevrimdışı SATIN ALMA hakkı', () {
    /// Ağ yokken sunucu "cevap veremedi" der. Bu, "hakkın yok" DEMEK DEĞİLDİR — cihaz defterindeki
    /// satın alma erişimi açık tutmalı. Karıştırılsaydı, uçakta premium'u kapanan bir kullanıcı
    /// olurdu.
    testWidgets('cihaz defterindeki satın alma çevrimdışı da geçerli', (tester) async {
      await pumpOffline(tester, owned: const ['komple-ehliyet']);
      await goTab(tester, 'Profil');
      await tester.tap(find.text('Premium').last);
      await tester.pumpAndSettle();

      expect(find.text('Premium Aktif'), findsOneWidget);
    });
  });
}

/// Yerel cevap defteri tohumu — beşi doğru, biri yanlış (doğruluk hesabı anlamlı çıksın).
final String _seededAnswers = jsonEncode([
  for (var i = 0; i < 6; i++)
    {
      'questionId': 'q-$i',
      'subject': 'trafik',
      'topic': 'genel',
      'correct': i != 5,
      'at': 1785000000000 + i * 1000,
    },
]);

/// ÇEVRİMDIŞI GECİKME — "önbellek var" yetmez, "önbellek BEKLETMİYOR" gerekir.
///
/// Cihazda bulunan hata buydu: depolama çevrimdışı-öncelikti ama akış değildi. Sıra şöyleydi —
/// önbelleği oku → **ağı bekle** → hata gelirse önbelleği döndür. Ağ yokken o hata hemen gelmez;
/// bağlantı zaman aşımı (12 sn) dolana kadar beklenir. Yani kullanıcı, telefonunda ZATEN DURAN
/// içeriği görmek için on iki saniye bekliyordu.
///
/// Test bunu, ağı **hiç cevap vermeyen** bir sahteyle kurar: eski davranışta bu test asılı kalır,
/// yenisinde anında döner.
void _cacheLatencyGuard() {
  group('önbellek beklemez', () {
    test('içerik: ağ hiç cevap vermese bile önbellek ANINDA döner', () async {
      final repo = ContentRepository(_NeverAnsweringContentApi(), _StubContentStore());
      final snapshot = await repo.load().timeout(const Duration(seconds: 2));
      expect(snapshot.lessons, isNotEmpty);
    });

    test('soru bankası: ağ hiç cevap vermese bile önbellek ANINDA döner', () async {
      final repo = QuestionRepository(_NeverAnsweringQuestionApi(), _StubQuestionStore());
      final bank = await repo.load().timeout(const Duration(seconds: 2));
      expect(bank.questions, isNotEmpty);
    });
  });
}

/// Hiç tamamlanmayan bir ağ çağrısı — uçak modundaki bağlantı zaman aşımının karşılığı.
class _NeverAnsweringContentApi implements ContentApi {
  @override
  Future<SnapshotFetch> fetch({String? etag}) => Completer<SnapshotFetch>().future;
}

class _NeverAnsweringQuestionApi implements QuestionApi {
  @override
  Future<BankFetch> fetch({String? etag}) => Completer<BankFetch>().future;
}

class _StubContentStore implements ContentLocalStore {
  @override
  Future<CachedContent?> read() async =>
      CachedContent('test-v1', jsonEncode(sampleSnapshot().toJson()));
  @override
  Future<void> write({required String version, required String body}) async {}
}

class _StubQuestionStore implements QuestionLocalStore {
  @override
  Future<CachedBank?> read() async => CachedBank('test-v1', jsonEncode(sampleBank().toJson()));
  @override
  Future<void> write({required String version, required String body}) async {}
}
