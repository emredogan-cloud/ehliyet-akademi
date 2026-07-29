import 'package:ehliyet_akademi/core/storage/token_store.dart';
import 'package:ehliyet_akademi/data/auth/account_api.dart';
import 'package:ehliyet_akademi/domain/auth/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Faz 5 — hesap silme: tasarım, güvenlik adımı, ilerleme, çıkış ve gezinme.
void main() {
  /// Oturumlu bir kullanıcıyla Profil'i aç.
  Future<MemoryTokenStore> openProfile(WidgetTester tester, {AccountApi? account}) async {
    final tokens = MemoryTokenStore()..write('abc');
    await useTallSurface(tester);
    await pumpApp(
      tester,
      tokens: tokens,
      auth: FakeAuthApi(
        user: const AppUser(id: 'u1', email: 'a@ea.dev', name: 'Ali', role: 'user'),
      ),
      account: account,
    );
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    return tokens;
  }

  /// Pencere içeriği görünüm alanından uzundur (referans tasarım da öyle) → dokunmadan önce
  /// hedefi görünür alana getir. Aksi hâlde `tap` ıskalar ve test yanıltıcı biçimde "düğme
  /// çalışmıyor" der.
  Future<void> tapIn(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Hesabımı sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hesabımı sil'));
    await tester.pumpAndSettle();
  }

  group('giriş noktası', () {
    testWidgets('misafirde hesap silme satırı YOKTUR', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester);
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      expect(find.text('Hesabımı sil'), findsNothing);
    });

    testWidgets('oturumluda satır vardır ve pencereyi açar', (tester) async {
      await openProfile(tester);
      await openDialog(tester);
      expect(find.text('Hesabınızı silmek\nistediğinize emin misiniz?'), findsOneWidget);
    });
  });

  group('referans tasarımın içeriği', () {
    testWidgets('başlık, kırmızı vurgu, veri listesi, bilgi kutusu ve iki düğme', (tester) async {
      await openProfile(tester);
      await openDialog(tester);

      // Silinecek verilerin dördü de sayılıyor (referanstaki liste).
      for (final row in const [
        'Kişisel bilgileriniz',
        'Öğrenme verileriniz',
        'Kayıtlı içerikleriniz',
        'Topluluk verileriniz',
      ]) {
        expect(find.text(row), findsOneWidget, reason: '"$row" satırı eksik');
      }
      expect(find.text('Silinecek verileriniz:'), findsOneWidget);
      expect(
        find.text('Hesabınızı sildikten sonra aynı e-posta ile yeni hesap oluşturabilirsiniz.'),
        findsOneWidget,
      );
      expect(find.text('Evet, hesabımı sil'), findsOneWidget);
      expect(find.text('İptal, vazgeçtim'), findsOneWidget);
    });

    testWidgets('"İptal, vazgeçtim" hiçbir şey silmeden kapatır', (tester) async {
      final account = FakeAccountApi();
      await openProfile(tester, account: account);
      await openDialog(tester);
      await tapIn(tester, 'İptal, vazgeçtim');

      expect(find.text('Evet, hesabımı sil'), findsNothing);
      expect(account.deleteCalls, 0);
      expect(find.text('Profil'), findsWidgets); // hâlâ Profil'deyiz
    });
  });

  group('yeniden kimlik doğrulama', () {
    /// İlk düğme SİLMEZ — silme geri alınamaz ve oturum 30 gün açık kalıyor.
    testWidgets('parolalı hesapta ilk onay silmez, parola ister', (tester) async {
      final account = FakeAccountApi();
      await openProfile(tester, account: account);
      await openDialog(tester);
      await tapIn(tester, 'Evet, hesabımı sil');

      expect(account.deleteCalls, 0, reason: 'ilk dokunuşta silme İSTEĞİ gitmemeli');
      expect(find.text('Son bir adım'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Parolan'), findsOneWidget);
      // Alan boşken silme düğmesi çalışmaz.
      await tapIn(tester, 'Hesabımı kalıcı olarak sil');
      expect(account.deleteCalls, 0);
    });

    testWidgets('yanlış parola hatayı gösterir, hesap SİLİNMEZ', (tester) async {
      final account = FakeAccountApi();
      final tokens = await openProfile(tester, account: account);
      await openDialog(tester);
      await tapIn(tester, 'Evet, hesabımı sil');

      await tester.enterText(find.byType(TextField), 'yanlis');
      await tapIn(tester, 'Hesabımı kalıcı olarak sil');

      expect(find.text('Parola hatalı.'), findsOneWidget);
      expect(find.text('Son bir adım'), findsOneWidget); // pencere açık kalır
      expect(await tokens.read(), 'abc'); // oturum DURUYOR
    });

    /// Google ile açılmış hesapta parola YOKTUR; onay e-posta yazdırarak alınır.
    testWidgets('parolasız hesapta e-posta yazdırılır', (tester) async {
      final account = FakeAccountApi(requiresPassword: false, email: 'a@ea.dev');
      await openProfile(tester, account: account);
      await openDialog(tester);
      await tapIn(tester, 'Evet, hesabımı sil');

      expect(find.widgetWithText(TextField, 'E-posta adresin'), findsOneWidget);

      // Yanlış e-posta → düğme çalışmaz.
      await tester.enterText(find.byType(TextField), 'baska@ea.dev');
      await tapIn(tester, 'Hesabımı kalıcı olarak sil');
      expect(account.deleteCalls, 0);

      // Doğru e-posta → silinir ve parola GÖNDERİLMEZ.
      await tester.enterText(find.byType(TextField), 'a@ea.dev');
      await tapIn(tester, 'Hesabımı kalıcı olarak sil');
      expect(account.deleteCalls, 1);
      expect(account.lastPassword, isNull);
    });

    /// Koşullar okunamazsa (ağ yok) en TEMKİNLİ varsayım: parola iste.
    testWidgets('koşullar okunamazsa parola istenir', (tester) async {
      final account = FakeAccountApi(requirementsUnavailable: true);
      await openProfile(tester, account: account);
      await openDialog(tester);
      await tapIn(tester, 'Evet, hesabımı sil');
      expect(find.widgetWithText(TextField, 'Parolan'), findsOneWidget);
    });
  });

  group('başarılı silme', () {
    testWidgets('oturum temizlenir, Giriş ekranına inilir, bilgi verilir', (tester) async {
      final account = FakeAccountApi();
      final tokens = await openProfile(tester, account: account);
      await openDialog(tester);
      await tapIn(tester, 'Evet, hesabımı sil');
      await tester.enterText(find.byType(TextField), 'dogru-parola');
      await tapIn(tester, 'Hesabımı kalıcı olarak sil');

      expect(account.deleteCalls, 1);
      expect(account.lastPassword, 'dogru-parola');
      expect(await tokens.read(), isNull, reason: 'yerel oturum temizlenmeli');
      expect(find.text('Tekrar Hoş Geldin! 👋'), findsOneWidget); // Giriş ekranı
      expect(find.text('Hesabın ve tüm verilerin silindi.'), findsOneWidget);
    });

    /// Sunucu hatasında kullanıcı SEBEPSİZ YERE çıkmış olmamalı.
    testWidgets('sunucu hatasında oturum korunur ve pencere açık kalır', (tester) async {
      final account = FakeAccountApi(failure: 'Hesap silinemedi. Daha sonra tekrar dene.');
      final tokens = await openProfile(tester, account: account);
      await openDialog(tester);
      await tapIn(tester, 'Evet, hesabımı sil');
      await tester.enterText(find.byType(TextField), 'dogru-parola');
      await tapIn(tester, 'Hesabımı kalıcı olarak sil');

      expect(find.text('Hesap silinemedi. Daha sonra tekrar dene.'), findsOneWidget);
      expect(await tokens.read(), 'abc');
      expect(find.text('Tekrar Hoş Geldin! 👋'), findsNothing);
    });
  });
}