import 'package:ehliyet_akademi/core/storage/token_store.dart';
import 'package:ehliyet_akademi/domain/auth/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await pumpApp(tester, auth: api);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giriş yap / Kayıt ol'));
    await tester.pumpAndSettle();

    // Auth screen
    expect(find.text('Tekrar hoş geldin'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'E-posta'), 'user@ea.dev');
    await tester.enterText(find.widgetWithText(TextFormField, 'Parola'), 'parola-1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Giriş yap'));
    await tester.pumpAndSettle();

    // Back on Profil, now authenticated
    expect(find.text('user@ea.dev'), findsOneWidget);
    expect(find.text('Çıkış yap'), findsOneWidget);
  });

  testWidgets('logout returns to guest', (tester) async {
    final tokens = MemoryTokenStore()..write('abc');
    final api = FakeAuthApi(
      user: const AppUser(id: 'u1', email: 'a@ea.dev', name: 'Ali', role: 'user'),
    );
    await pumpApp(tester, tokens: tokens, auth: api);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çıkış yap'));
    await tester.pumpAndSettle();

    expect(find.text('Misafir'), findsOneWidget);
    expect(await tokens.read(), isNull); // token cleared
  });
}
