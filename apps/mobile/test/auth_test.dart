import 'package:ehliyet_akademi/core/storage/token_store.dart';
import 'package:ehliyet_akademi/design/brand.dart';
import 'package:ehliyet_akademi/domain/auth/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  testWidgets('guest sees "Misafir" + login CTA on Profil', (tester) async {
    await pumpApp(tester); // no token -> guest

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Misafir'), findsOneWidget);
    expect(find.text('Giriş yap / Kayıt ol'), findsOneWidget);
    expect(find.text('Çıkış yap'), findsNothing);
  });

  testWidgets('existing token resolves to authenticated user', (tester) async {
    final tokens = MemoryTokenStore()..write('abc');
    final api = FakeAuthApi(
      user: const AppUser(id: 'u1', email: 'ayse@ea.dev', name: 'Ayşe Yılmaz', role: 'user'),
    );
    await pumpApp(tester, tokens: tokens, auth: api);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(api.meCalls, greaterThan(0)); // validated the token
    expect(find.text('Ayşe Yılmaz'), findsOneWidget);
    expect(find.text('ayse@ea.dev'), findsOneWidget);
    expect(find.text('Çıkış yap'), findsOneWidget);
    expect(find.text('Giriş yap / Kayıt ol'), findsNothing);
  });

  testWidgets('login flow: guest -> auth screen -> authenticated', (tester) async {
    final api = FakeAuthApi();
    // Faz 5: giriş ekranı hero + güven şeridiyle uzadı; 800×600'de gönder düğmesi görünüm
    // alanının dışında kalıyordu (cihazda sorun yok — test yüzeyi artefaktı).
    await useTallSurface(tester);
    await pumpApp(tester, auth: api);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giriş yap / Kayıt ol'));
    await tester.pumpAndSettle();

    // Auth screen
    expect(find.text('Tekrar Hoş Geldin! 👋'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'E-posta adresiniz'), 'user@ea.dev');
    await tester.enterText(find.widgetWithText(TextFormField, 'Şifreniz'), 'parola-1234');
    // Beta Faz 5: gönder düğmesi GradientPillButton oldu. AppBar başlığı da "Giriş yap"
    // olduğu için düğme AÇIKÇA hedeflenir — aksi hâlde başlığa dokunulur ve giriş hiç olmaz.
    await tester.tap(find.widgetWithText(GradientPillButton, 'Giriş Yap'));
    await tester.pumpAndSettle();

    // Back on Profil, now authenticated. Giriş ekranı kapandığı için e-posta artık form
    // alanından değil, profil kartından geliyor.
    expect(find.text('Giriş yap / Kayıt ol'), findsNothing); // auth ekranı kapandı
    expect(find.text('user@ea.dev'), findsOneWidget);
    expect(find.text('Çıkış yap'), findsOneWidget);
  });

  /// Faz 3 — çıkış, kullanıcıyı Profil'de BIRAKMAZ.
  ///
  /// Eski davranış: durum misafire dönüyordu ama ekran aynı kalıyordu; kullanıcı için hiçbir şey
  /// olmamış gibi görünüyordu. Doğru davranış: oturum kapanır, **yığın temizlenir**, Giriş ekranı
  /// açılır.
  testWidgets('logout: oturum kapanır, yığın temizlenir, Giriş ekranına inilir', (tester) async {
    final tokens = MemoryTokenStore()..write('abc');
    final api = FakeAuthApi(
      user: const AppUser(id: 'u1', email: 'a@ea.dev', name: 'Ali', role: 'user'),
    );
    final google = FakeGoogleAuthService();
    await useTallSurface(tester);
    await pumpApp(
      tester,
      tokens: tokens,
      auth: api,
      google: google,
      // Cihazdaki sızıntı senaryosu: çıkış öncesi premium sahipliği önbellekte.
      prefs: {'ea:entitlements:v1': '["komple-ehliyet"]'},
    );

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Çıkış yap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çıkış yap'));
    await tester.pumpAndSettle();

    // Giriş ekranındayız — Profil'de DEĞİL.
    expect(find.text('Tekrar Hoş Geldin! 👋'), findsOneWidget);
    expect(find.text('Çıkış yap'), findsNothing);
    expect(await tokens.read(), isNull); // yerel jeton silindi
    expect(google.signOutCalls, 1); // cihazdaki Google oturumu da kapandı
    // Sahiplik önbelleği ÖNCEKİ kullanıcının ürününü artık taşımaz (silinmiş ya da boş).
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ea:entitlements:v1') ?? '[]', isNot(contains('komple-ehliyet')));
  });

  /// Yığın çıkış sonrası BOŞTUR; "geri" bir şeye dönemez. Bunu ayırmayan bir uygulama, kullanıcıyı
  /// giriş ekranında kilitler.
  testWidgets('logout sonrası giriş yapınca uygulamaya dönülür (kilitlenme yok)', (tester) async {
    final tokens = MemoryTokenStore()..write('abc');
    final api = FakeAuthApi(
      user: const AppUser(id: 'u1', email: 'a@ea.dev', name: 'Ali', role: 'user'),
    );
    await useTallSurface(tester);
    await pumpApp(tester, tokens: tokens, auth: api);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Çıkış yap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çıkış yap'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'E-posta adresiniz'), 'a@ea.dev');
    await tester.enterText(find.widgetWithText(TextFormField, 'Şifreniz'), 'parola-1234');
    await tester.tap(find.widgetWithText(GradientPillButton, 'Giriş Yap'));
    await tester.pumpAndSettle();

    // Giriş ekranı kapandı ve uygulamaya (Ana Sayfa) inildi.
    expect(find.text('Tekrar Hoş Geldin! 👋'), findsNothing);
    expect(find.text('Bugün de çalışalım'), findsOneWidget);
  });
}
