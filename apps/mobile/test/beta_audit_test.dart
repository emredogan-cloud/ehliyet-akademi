import 'package:ehliyet_akademi/data/premium/store_purchase_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Beta Faz 11 — TAM YAYIN HAZIRLIK DENETİMİ.
///
/// ## Bu dosya `polish_audit_test.dart`'tan nasıl farklı
///
/// Cilalama denetimi altı ANA yüzeyi tarıyor. Bu dosya **yönlendiricideki her rotayı** tarıyor —
/// yani kullanıcının ulaşabildiği her ekranı, alt ekranlar ve ayrıntı sayfaları dâhil.
///
/// Gerekçe: hatalar ana ekranlarda değil, kimsenin bakmadığı ikinci seviyede birikir. Bir ders
/// ayrıntısı, bir işaret sayfası ya da bir sohbet ekranı 320 dp'de taşıyorsa bunu ancak o ekrana
/// giden bir kullanıcı görür — ve o kullanıcı hata bildirmez, uygulamayı siler.
///
/// ## Ne aranıyor
///
/// 1. **Yakalanmamış istisna** — ekran açılırken bir şey patlıyor mu.
/// 2. **Taşma** (`RenderFlex overflowed`) — düzen dar ekranda/büyük yazıda kırılıyor mu.
/// 3. **Sessiz boşluk** — ekran açılıyor ama hiçbir şey göstermiyor mu.
///
/// Üçüncüsü en sinsisi: çökme bildirilir, taşma sarı-siyah şeritle görünür, ama boş bir ekran
/// "bu özellik çalışmıyor" diye okunur ve hiçbir yere düşmez.
void main() {
  /// Yönlendiricideki TÜM rotalar (`lib/app/router.dart` ile eşleşmeli).
  ///
  /// Parametreli rotalar örnek verilerle doldurulur — sahte içerik anlık görüntüsündeki gerçek
  /// kimlikler kullanılır ki ekran gerçekten veri bulsun.
  const routes = <String, String>{
    'Ana Sayfa': '/home',
    'Öğren': '/learn',
    'Dersler': '/learn/lessons',
    'Ders ayrıntısı': '/learn/lessons/trafik-temel',
    'İşaretler': '/learn/signs',
    'İşaret ayrıntısı': '/learn/signs/dur',
    'Kabin kumandaları': '/learn/cabin',
    'İkaz ışıkları': '/learn/lights',
    'Araç tekniği': '/learn/vehicle',
    'Videolar': '/learn/videos',
    'Pratik': '/practice',
    'Akıllı çalışma': '/practice/study',
    'Deneme sınavı': '/practice/exam',
    'Koleksiyonlar': '/practice/collections',
    'Çıkmış sınavlar': '/practice/historical',
    'AI Koç': '/coach',
    'Topluluk': '/community',
    'Topluluğa katıl': '/community/join',
    'Engellenenler': '/community/blocked',
    'Arkadaşlar': '/community/friends',
    'Gruplar': '/community/groups',
    'Meydan okumalar': '/community/challenges',
    'Mesajlar': '/community/messages',
    'Tartışmalar': '/community/discussions',
    'Profil': '/profile',
    'Bildirimler': '/notifications',
    'İlerleme': '/progress',
    'Ödeme': '/premium',
    'Giriş/Kayıt': '/auth',
    'Davet': '/davet',
    'Davet bağlantısı': '/davet/ABCD2345',
  };

  /// Zorlayıcı koşullar — her biri sahada gerçekten karşılaşılan bir durum.
  const conditions = <String, ({Size size, double scale, Brightness theme})>{
    'dar telefon 320dp': (size: Size(320, 720), scale: 1.0, theme: Brightness.dark),
    'büyük yazı 1.3x': (size: Size(400, 900), scale: 1.3, theme: Brightness.dark),
    'açık tema': (size: Size(400, 900), scale: 1.0, theme: Brightness.light),
    'tablet 1024dp': (size: Size(1024, 1366), scale: 1.0, theme: Brightness.dark),
    'yatay 800x400': (size: Size(800, 400), scale: 1.0, theme: Brightness.dark),
  };

  /// Bir rotayı verilen koşulda aç, sorunları topla.
  Future<List<String>> sweep(
    WidgetTester tester, {
    required String label,
    required String route,
    required ({Size size, double scale, Brightness theme}) cond,
    required String condName,
  }) async {
    final problems = <String>[];
    await tester.binding.setSurfaceSize(cond.size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = cond.scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = cond.theme;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    // Taşmalar `FlutterError.onError` üzerinden gelir; testi düşürmek yerine TOPLANIR ki tek
    // koşuda bütün liste görülsün — tek tek düzeltip tekrar koşmak saatler alırdı.
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      problems.add('$label [$condName] ${text.split('\n').first}');
    };
    addTearDown(() => FlutterError.onError = previous);

    await pumpApp(
      tester,
      // Ödeme ekranı ve premium yüzeyleri için mağazası açık bir ağ geçidi.
      billing: FakeBillingGateway.withStore(),
      storePurchases: MemoryStorePurchaseStore(),
    );
    routerOf(tester).go(route);
    // `pumpAndSettle` KULLANILMAZ: bazı ekranlarda sürekli animasyon var ve sonsuza kadar bekler.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }

    final thrown = tester.takeException();
    if (thrown != null) problems.add('$label [$condName] İSTİSNA: $thrown');

    FlutterError.onError = previous;
    return problems;
  }

  group('her rota — taşma ve istisna taraması', () {
    for (final route in routes.entries) {
      for (final cond in conditions.entries) {
        testWidgets('${route.key} · ${cond.key}', (tester) async {
          final problems = await sweep(
            tester,
            label: route.key,
            route: route.value,
            cond: cond.value,
            condName: cond.key,
          );
          expect(problems, isEmpty, reason: problems.join('\n'));
        });
      }
    }
  });

  group('sessiz boşluk yok — her rota bir şey GÖSTERİR', () {
    /// Boş bir ekran, çökmekten daha kötüdür: çökme bildirilir, boşluk bildirilmez ve kullanıcı
    /// "bu özellik çalışmıyor" diye okur.
    for (final route in routes.entries) {
      testWidgets('${route.key} boş değil', (tester) async {
        await useTallSurface(tester);
        await pumpApp(
          tester,
          billing: FakeBillingGateway.withStore(),
        );
        routerOf(tester).go(route.value);
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }

        // En az bir görünür metin. Yükleniyor göstergesi de kabul: o da bir durumdur ve
        // kullanıcıya "çalışıyorum" der.
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .where((d) => d.trim().isNotEmpty)
            .toList();
        final spinning = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
        expect(
          texts.isNotEmpty || spinning,
          isTrue,
          reason: '${route.key} (${route.value}) hiçbir şey göstermiyor',
        );
      });
    }
  });

  group('tema geçişi — her iki temada da açılır', () {
    /// Açık tema, koyu temaya göre çok daha az kullanılıyor ve tam bu yüzden daha az test ediliyor.
    /// Sabit renk kullanılan bir yer yalnız orada patlar.
    for (final route in routes.entries) {
      testWidgets('${route.key} açık temada istisnasız', (tester) async {
        final problems = await sweep(
          tester,
          label: route.key,
          route: route.value,
          cond: (size: const Size(390, 844), scale: 1.0, theme: Brightness.light),
          condName: 'açık tema',
        );
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  });
}
