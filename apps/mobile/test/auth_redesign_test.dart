import 'package:ehliyet_akademi/core/assets.dart';
import 'package:ehliyet_akademi/design/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Beta Faz 5 — giriş ekranı yeniden tasarımı.
///
/// Referanslar `apps/assets/interface-assets/` (`022` hero · `023` form · `024` güven şeridi).
/// Bu testler yalnız "güzel görünüyor mu" değil, **mockup'tan bilinçli sapmaları** de sabitler:
/// Apple düğmesi konmadı, "Şifremi unuttum?" gerçek bir uç çağırıyor.
void main() {
  /// `Image.asset(..., cacheWidth: …)` sağlayıcıyı ResizeImage içine SARAR — testin bunu
  /// çözmesi gerekir, aksi hâlde AssetImage araması boş döner.
  String? assetNameOf(ImageProvider provider) {
    final p = provider is ResizeImage ? provider.imageProvider : provider;
    return p is AssetImage ? p.assetName : null;
  }

  /// Diyalog açıkken ekranda da bir "E-posta" alanı vardır → arama diyaloğa DARALTILIR.
  Finder dialogField(String label) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(TextFormField, label),
  );

  Future<void> openAuth(WidgetTester tester, {FakeAuthApi? auth}) async {
    await useTallSurface(tester);
    await pumpApp(tester, auth: auth ?? FakeAuthApi());
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giriş yap / Kayıt ol'));
    await tester.pumpAndSettle();
  }

  group('hero (referans 022)', () {
    testWidgets('hero görseli gösterilir ve marka kimliği üstünde durur', (tester) async {
      await openAuth(tester);

      final hero = tester
          .widgetList<Image>(find.byType(Image))
          .where((i) => assetNameOf(i.image) == AppImages.authHero);
      expect(hero, isNotEmpty, reason: 'auth_hero.webp ekranda olmalı');

      expect(find.text('Ehliyet Akademi'), findsOneWidget);
      expect(find.byType(BrandMark), findsWidgets);
    });

    testWidgets('AppBar YOKTUR; geri düğmesi hero içindedir', (tester) async {
      // Saydam bir AppBar kaydırmada geri okunu marka işaretinin üstüne bindiriyordu
      // (cihazda görüldü). Üst alanı hero yönetir.
      await openAuth(tester);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byTooltip('Geri'), findsOneWidget);
    });

    testWidgets('geri düğmesi ekranı kapatır', (tester) async {
      await openAuth(tester);
      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
      // Profil'e dönülür — giriş ekranı kapanmıştır.
      expect(find.text('Tekrar hoş geldin'), findsNothing);
      expect(find.text('Giriş yap / Kayıt ol'), findsOneWidget);
    });

    testWidgets('hero DEKORATİFTİR — ekran okuyucuya ayrı bir etiket sızdırmaz', (tester) async {
      await openAuth(tester);
      final hero = tester
          .widgetList<Image>(find.byType(Image))
          .firstWhere((i) => assetNameOf(i.image) == AppImages.authHero);
      expect(hero.excludeFromSemantics, isTrue);
      expect(hero.semanticLabel, isNull);
    });
  });

  group('güven şeridi (referans 024)', () {
    testWidgets('üç güvence de gösterilir', (tester) async {
      await openAuth(tester);
      expect(find.text('Güvenli Platform'), findsOneWidget);
      expect(find.text('Güncel İçerik'), findsOneWidget);
      expect(find.text('Sınava Hazırlık'), findsOneWidget);
    });

    testWidgets('müfredat ifadesi ürünün MEVCUT iddiasıyla aynıdır', (tester) async {
      // Faz 1 uyarısı: doğrulanabilir iddia. Web giriş sayfasında zaten yayında olan ifade
      // kullanılır; burada YENİ bir iddia üretilmez.
      await openAuth(tester);
      expect(find.text('MEB/MTSK müfredatına uygun'), findsOneWidget);
    });
  });

  group('mockuptan bilinçli SAPMALAR', () {
    testWidgets('APPLE ile giriş düğmesi YOKTUR — iOS yok, ölü gezinme olurdu', (tester) async {
      await openAuth(tester);
      expect(find.textContaining('Apple'), findsNothing);
    });

    testWidgets('"Şifremi unuttum?" yalnız GİRİŞ kipinde vardır', (tester) async {
      await openAuth(tester);
      expect(find.text('Şifremi unuttum?'), findsOneWidget);

      await tester.tap(find.text('Hesabın yok mu? Kayıt ol'));
      await tester.pumpAndSettle();
      // Kayıtta parolayı kullanıcı zaten belirliyor.
      expect(find.text('Şifremi unuttum?'), findsNothing);
    });
  });

  group('parola sıfırlama — SÜS DEĞİL, gerçek uç', () {
    testWidgets('e-posta sorulur ve sunucuya iletilir', (tester) async {
      final api = FakeAuthApi();
      await openAuth(tester, auth: api);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-posta'),
        'unutkan@ea.dev',
      );
      await tester.tap(find.text('Şifremi unuttum?'));
      await tester.pumpAndSettle();

      // Ekrandaki e-posta diyaloğa taşınır — kullanıcı iki kez yazmaz.
      expect(find.text('Parolamı sıfırla'), findsOneWidget);
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();

      expect(api.resetCalls, 1);
      expect(api.lastResetEmail, 'unutkan@ea.dev');
    });

    testWidgets('hesabın VAR OLUP OLMADIĞI sızdırılmaz', (tester) async {
      final api = FakeAuthApi();
      await openAuth(tester, auth: api);

      await tester.tap(find.text('Şifremi unuttum?'));
      await tester.pumpAndSettle();
      await tester.enterText(dialogField('E-posta'), 'olmayan@ea.dev');
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();

      // Sunucu hesabı bulamasa da başarı döner; mesaj koşullu konuşmalı.
      expect(find.textContaining('kayıtlı bir hesap varsa'), findsOneWidget);
    });

    testWidgets('geçersiz e-posta sunucuya HİÇ gitmez', (tester) async {
      final api = FakeAuthApi();
      await openAuth(tester, auth: api);

      await tester.tap(find.text('Şifremi unuttum?'));
      await tester.pumpAndSettle();
      await tester.enterText(dialogField('E-posta'), 'bozuk');
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();

      expect(api.resetCalls, 0);
      expect(find.text('Geçerli bir e-posta gir.'), findsOneWidget);
    });

    testWidgets('vazgeçilirse istek gönderilmez', (tester) async {
      final api = FakeAuthApi();
      await openAuth(tester, auth: api);

      await tester.tap(find.text('Şifremi unuttum?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      expect(api.resetCalls, 0);
    });

    testWidgets('sunucu hatası kullanıcıya AYNEN iletilir', (tester) async {
      final api = FakeAuthApi()..resetFailMessage = 'Çok fazla deneme. Sonra tekrar dene.';
      await openAuth(tester, auth: api);

      await tester.tap(find.text('Şifremi unuttum?'));
      await tester.pumpAndSettle();
      await tester.enterText(dialogField('E-posta'), 'user@ea.dev');
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();

      expect(find.text('Çok fazla deneme. Sonra tekrar dene.'), findsOneWidget);
    });
  });

  group('mevcut yollar KORUNUR', () {
    testWidgets('e-posta/parola alanları, gönder düğmesi ve kip geçişi durur', (tester) async {
      await openAuth(tester);
      expect(find.widgetWithText(TextFormField, 'E-posta'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Parola'), findsOneWidget);
      expect(find.widgetWithText(GradientPillButton, 'Giriş yap'), findsOneWidget);

      await tester.tap(find.text('Hesabın yok mu? Kayıt ol'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Ad Soyad'), findsOneWidget);
      expect(find.widgetWithText(GradientPillButton, 'Kayıt ol'), findsOneWidget);
    });

    testWidgets('parola göster/gizle ipucu korunur (E13 erişilebilirlik)', (tester) async {
      await openAuth(tester);
      expect(find.byTooltip('Parolayı göster'), findsOneWidget);
      await tester.tap(find.byTooltip('Parolayı göster'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Parolayı gizle'), findsOneWidget);
    });
  });
}
