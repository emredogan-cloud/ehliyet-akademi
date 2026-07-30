import 'package:ehliyet_akademi/core/analytics/analytics_sink.dart';
import 'package:ehliyet_akademi/core/storage/token_store.dart';
import 'package:ehliyet_akademi/domain/auth/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Beta Faz 1 — davet derin bağlantısının UÇTAN UCA akışı.
///
/// Buradaki testler `referralCodeFromPath` gibi saf fonksiyonları DEĞİL, kullanıcının gerçekten
/// gördüğü zinciri ölçer: bağlantı → karşılama ekranı → kayıt formunda dolu kod.
///
/// Bu zincirin sessizce kırılması mümkündür ve en pahalı hata biçimidir: davet eden arkadaşına
/// bağlantı gönderir, arkadaşı kayıt olur, ama kod forma düşmediği için davet HİÇ SAYILMAZ. Kimse
/// bir hata görmez.
void main() {
  const code = 'ABCD2345';

  group('davet karşılama ekranı', () {
    testWidgets('misafire kodu ve kabul yolunu gösterir', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, pendingReferralCode: code);

      // Derin bağlantı: yönlendirici `/davet/<KOD>` yoluna gider.
      final router = routerOf(tester);
      router.go('/davet/$code');
      await tester.pumpAndSettle();

      expect(find.text(code), findsOneWidget);
      expect(find.text('Bir arkadaşın seni davet etti'), findsOneWidget);
      expect(find.text('Hesap oluştur ve kodu kullan'), findsOneWidget);
    });

    testWidgets('oturumu açık kullanıcıya daveti KULLANAMAYACAĞI dürüstçe söylenir', (
      tester,
    ) async {
      await useTallSurface(tester);
      await pumpApp(
        tester,
        auth: FakeAuthApi(
          user: const AppUser(id: 'u1', email: 'a@ea.dev', name: 'Ali', role: 'user'),
        ),
        tokens: MemoryTokenStore()..write('abc'),
        pendingReferralCode: code,
      );

      routerOf(tester).go('/davet/$code');
      await tester.pumpAndSettle();

      // Bunu söylemezsek kullanıcı kodu bir yere yazmayı dener, olmaz, hatayı kendinde arar.
      expect(find.textContaining('yalnız YENİ bir hesap açılırken'), findsOneWidget);
      expect(find.text('Kendi davet kodumu gör'), findsOneWidget);
      // Kabul düğmesi GÖSTERİLMEZ — çalışmayacak bir düğme ölü gezinmedir.
      expect(find.text('Hesap oluştur ve kodu kullan'), findsNothing);
    });

    testWidgets('bağlantının açıldığı analitiğe TEK KEZ düşer', (tester) async {
      final sink = MemoryAnalyticsSink();
      await useTallSurface(tester);
      await pumpApp(tester, pendingReferralCode: code, analytics: sink);

      routerOf(tester).go('/davet/$code');
      await tester.pumpAndSettle();
      // Yeniden çizim (tema değişimi gibi) olayı tekrarlamamalı.
      await tester.pump();

      expect(sink.count('referral_link_opened'), 1);
      expect(sink.propsOf('referral_link_opened'), {'signed_in': false});
    });
  });

  /// GERÇEK CİHAZDA yakalanan hatanın kalıcı testi.
  ///
  /// Davet bağlantısı ilk kurulumda uygulamayı açtığında yönlendirici tanıtım turuna çevirir.
  /// Tur bittiğinde `OnboardingScreen` DOĞRUDAN `/home`'a gider — yönlendiricinin "tur bitti mi"
  /// dalı o anda `/onboarding` konumunu görmez. İlk yazımda karşılama bu yüzden hiç açılmıyordu:
  /// kod korunuyordu ama kullanıcıya bekleyen bir daveti olduğu SÖYLENMİYORDU.
  ///
  /// Widget testleri bunu kaçırmıştı çünkü hepsi `onboardingSeen: true` ile başlıyor — yani
  /// kırılan yolu hiç geçmiyorlardı.
  group('tanıtım turundan sonra karşılama', () {
    testWidgets('tur bittikten sonra Ana Sayfa yerine davet ekranına inilir', (tester) async {
      await useTallSurface(tester);
      // Tanıtım GÖRÜLMEMİŞ: gerçek ilk kurulum yolu.
      await pumpApp(
        tester,
        pendingReferralCode: code,
        onboardingSeen: false,
        welcomeSeen: false,
      );

      // Derin bağlantı geldi ama tanıtım kapısı öne alıyor.
      routerOf(tester).go('/davet/$code');
      await tester.pumpAndSettle();
      expect(find.text('Atla'), findsOneWidget, reason: 'önce tanıtım turu gösterilmeli');

      // Tur "Atla" ile bitirilir → uygulama doğrudan /home'a gider…
      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      // …ve yönlendirici oradan daveti karşılayan ekrana çevirir.
      expect(find.text('Bir arkadaşın seni davet etti'), findsOneWidget);
      expect(find.text(code), findsOneWidget);
    });

    testWidgets('karşılama BİR KEZ olur — sonra Ana Sayfa ele geçirilmez', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, pendingReferralCode: code);

      final router = routerOf(tester);
      router.go('/davet/$code');
      await tester.pumpAndSettle();
      expect(find.text('Bir arkadaşın seni davet etti'), findsOneWidget);

      // Kullanıcı Ana Sayfa'ya dönmek isterse dönebilmeli; aksi hâlde uygulamada kilitlenirdi.
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.text('Bir arkadaşın seni davet etti'), findsNothing);
    });

    testWidgets('bekleyen kod YOKSA tur sonrası normal akış bozulmaz', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, onboardingSeen: false, welcomeSeen: false);

      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      expect(find.text('Bir arkadaşın seni davet etti'), findsNothing);
    });
  });

  group('kod kayıt formuna taşınır', () {
    testWidgets('bekleyen kod kayıt kipini açar ve alanı DOLDURUR', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester, pendingReferralCode: code);

      routerOf(tester).go('/auth');
      await tester.pumpAndSettle();

      // Kod dolu geldiyse kullanıcının işi kayıt olmaktır → ekran kayıt kipinde açılır.
      expect(find.widgetWithText(TextFormField, 'Davet kodu (isteğe bağlı)'), findsOneWidget);
      expect(find.text(code), findsOneWidget);
      // Kendiliğinden dolmuş alan AÇIKLANIR; açıklanmazsa kullanıcı silebilir.
      expect(find.text('Davet bağlantısından geldi — dokunmana gerek yok.'), findsOneWidget);
    });

    testWidgets('bekleyen kod yoksa ekran GİRİŞ kipinde açılır ve alan boştur', (tester) async {
      await useTallSurface(tester);
      await pumpApp(tester);

      routerOf(tester).go('/auth');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Davet kodu (isteğe bağlı)'), findsNothing);
    });

    testWidgets('kayıt tamamlanınca kod SUNUCUYA gider ve kuyruktan düşer', (tester) async {
      final api = FakeAuthApi();
      final sink = MemoryAnalyticsSink();
      await useTallSurface(tester);
      await pumpApp(tester, auth: api, pendingReferralCode: code, analytics: sink);

      routerOf(tester).go('/auth');
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Ad Soyad'), 'Ayşe');
      await tester.enterText(find.widgetWithText(TextFormField, 'E-posta adresiniz'), 'a@b.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Şifreniz'), 'parola1234');
      await tester.tap(find.text('Kayıt Ol'));
      await tester.pumpAndSettle();

      expect(api.lastReferralCode, code, reason: 'davet kodu kayıt isteğine eklenmeli');
      expect(sink.propsOf('registration'), {'referral': true});
    });
  });
}
