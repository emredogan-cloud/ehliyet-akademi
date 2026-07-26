import 'package:ehliyet_akademi/data/auth/google_auth_service.dart';
import 'package:ehliyet_akademi/design/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Beta Faz 2 — Google ile giriş yüzeyi.
///
/// `GoogleAuthService` arayüzü sayesinde platform kanalı GEREKMEZ: sahte servis bütün akışı sürer.
void main() {
  Future<void> openAuth(WidgetTester tester) async {
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giriş yap / Kayıt ol'));
    await tester.pumpAndSettle();
  }

  group('yapılandırma', () {
    testWidgets('YAPILANDIRILMAMIŞSA Google düğmesi hiç GÖSTERİLMEZ', (tester) async {
      // Çalışmayan düğme ölü gezinmedir (disiplin kural 3).
      await useTallSurface(tester);
      await pumpApp(tester, google: FakeGoogleAuthService(configured: false));
      await openAuth(tester);

      expect(find.text('Google ile devam et'), findsNothing);
      expect(find.text('veya'), findsNothing);
    });

    testWidgets('yapılandırılmışsa düğme ve ayırıcı görünür', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, google: FakeGoogleAuthService());
      await openAuth(tester);

      expect(find.text('Google ile devam et'), findsOneWidget);
      expect(find.text('veya'), findsOneWidget);
    });
  });

  group('giriş akışı', () {
    testWidgets('başarılı girişte ID token SUNUCUYA gönderilir', (tester) async {
      final auth = FakeAuthApi();
      await useTallSurface(tester);
      await pumpApp(
        tester,
        auth: auth,
        google: FakeGoogleAuthService(outcome: const GoogleSignInToken('test-id-token')),
      );
      await openAuth(tester);

      await tester.tap(find.text('Google ile devam et'));
      await tester.pumpAndSettle();

      // İstemci kimlik iddiasını kendi başına kabul etmez; token sunucuya gider.
      expect(auth.lastGoogleIdToken, 'test-id-token');
    });

    testWidgets('VAZGEÇME hata sayılmaz — mesaj gösterilmez', (tester) async {
      await useTallSurface(tester);
      await pumpApp(
        tester,
        google: FakeGoogleAuthService(outcome: const GoogleSignInCancelled()),
      );
      await openAuth(tester);

      await tester.tap(find.text('Google ile devam et'));
      await tester.pumpAndSettle();

      // Hesap seçiciyi kapatan kullanıcıya hata göstermek yanlış olurdu.
      expect(find.textContaining('tamamlanamadı'), findsNothing);
      expect(find.textContaining('Hata'), findsNothing);
    });

    testWidgets('gerçek hata kullanıcıya gösterilir', (tester) async {
      await useTallSurface(tester);
      await pumpApp(
        tester,
        google: FakeGoogleAuthService(
          outcome: const GoogleSignInError('Google ile giriş tamamlanamadı.'),
        ),
      );
      await openAuth(tester);

      await tester.tap(find.text('Google ile devam et'));
      await tester.pumpAndSettle();

      expect(find.text('Google ile giriş tamamlanamadı.'), findsOneWidget);
    });

    testWidgets('sunucu reddederse hata gösterilir', (tester) async {
      await useTallSurface(tester);
      await pumpApp(
        tester,
        auth: FakeAuthApi(failMessage: 'Google ile giriş doğrulanamadı.'),
        google: FakeGoogleAuthService(outcome: const GoogleSignInToken('sahte')),
      );
      await openAuth(tester);

      await tester.tap(find.text('Google ile devam et'));
      await tester.pumpAndSettle();

      expect(find.text('Google ile giriş doğrulanamadı.'), findsOneWidget);
    });
  });

  group('mevcut giriş yolları KORUNUR', () {
    testWidgets('e-posta + parola alanları ve düğmesi hâlâ var', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, google: FakeGoogleAuthService());
      await openAuth(tester);

      expect(find.widgetWithText(TextFormField, 'E-posta adresiniz'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Şifreniz'), findsOneWidget);
      expect(find.widgetWithText(GradientPillButton, 'Giriş Yap'), findsOneWidget);
    });

    testWidgets('kayıt moduna geçiş çalışmaya devam eder', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, google: FakeGoogleAuthService());
      await openAuth(tester);

      await tester.tap(find.text('Hesabın yok mu? Kayıt ol'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(GradientPillButton, 'Kayıt Ol'), findsOneWidget);
    });
  });
}
