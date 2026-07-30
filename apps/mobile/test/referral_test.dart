import 'package:ehliyet_akademi/core/storage/token_store.dart';
import 'package:ehliyet_akademi/data/referral/referral_api.dart';
import 'package:ehliyet_akademi/design/brand.dart';
import 'package:ehliyet_akademi/domain/auth/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Faz 8 — davet sistemi (mobil taraf).
///
/// Kurallar SUNUCUDA doğrulanıyor (`apps/web/lib/server/referrals.integration.test.ts`); burada
/// istemcinin onları DOĞRU GÖSTERDİĞİ ve kodu doğru gönderdiği test ediliyor.
void main() {
  group('kod biçimi (istemci)', () {
    /// Kod telefonda okunup ELLE yazılıyor: `0`/`O` ve `1`/`I`/`L` ayırt edilemediğinde
    /// kullanıcı kendi hatasını bizim hatamız sanar. Alfabe sunucudakiyle AYNI olmak zorunda.
    test('alfabede karıştırılabilir harf YOK', () {
      for (final ch in ['0', '1', 'I', 'L', 'O']) {
        expect(kReferralAlphabet.contains(ch), isFalse, reason: '"$ch" alfabede olmamalı');
      }
    });

    test('normalleştirme sunucudakiyle aynı', () {
      expect(normalizeReferralCode(' ab-cd ef gh '), 'ABCDEFGH');
      expect(normalizeReferralCode('abcdefghXYZ'), 'ABCDEFGH');
    });

    /// Beta Faz 1 — bu beklenti DEĞİŞTİ. Eskiden `AB0DEF1H` → `ABODEFIH` çevrilirdi; ama üstteki
    /// test `O` ve `I`nın da alfabede olmadığını söylüyor, yani çeviri geçersiz bir karakteri
    /// başka bir geçersiz karaktere dönüştürüyordu. Kullanıcı sonuçta kendisiyle çelişen bir hata
    /// görüyordu: "Davet kodu 8 karakter olmalı (şu an 8)."
    test('alfabe dışı karakter UYDURULMAZ', () {
      expect(normalizeReferralCode('AB0DEF1H'), 'AB0DEF1H');
      expect(isValidReferralCodeFormat('AB0DEF1H'), isFalse);
    });

    test('geçerlilik kontrolü', () {
      expect(isValidReferralCodeFormat('ABCDEFGH'), isTrue);
      expect(isValidReferralCodeFormat('ABCDEFG'), isFalse);
      expect(isValidReferralCodeFormat('ABCDEFG0'), isFalse);
    });

    /// Hata mesajı SORUNU ADIYLA söyler; iki farklı sorun iki farklı cümle kurar.
    test('geçersizlik nedeni adıyla söylenir', () {
      final badChar = describeReferralCodeProblem('AB0DEF1H');
      expect(badChar, contains('0'));
      expect(badChar, contains('1'));
      // Kendisiyle çelişen eski mesaj bir daha kurulmamalı.
      expect(badChar, isNot(contains('şu an 8')));

      expect(describeReferralCodeProblem('ABCDEFG'), contains('8 karakter olmalı'));
      expect(describeReferralCodeProblem('ABCDEFGH'), isNull);
      expect(describeReferralCodeProblem(''), isNull);
    });
  });

  group('davet ekranı', () {
    Future<void> open(WidgetTester tester, {ReferralApi? api, bool signedIn = true}) async {
      await useTallSurface(tester);
      await pumpApp(
        tester,
        referral: api,
        tokens: signedIn ? (MemoryTokenStore()..write('abc')) : null,
        auth: signedIn
            ? FakeAuthApi(
                user: const AppUser(id: 'u1', email: 'a@ea.dev', name: 'Ali', role: 'user'),
              )
            : null,
      );
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Davet et, premium kazan'), 200);
      await tester.tap(find.text('Davet et, premium kazan'));
      await tester.pumpAndSettle();
    }

    /// Kod hesaba bağlıdır; misafire kod gösterip sonra "aslında hesabın olmalı" demek yanıltıcı.
    testWidgets('misafire önce giriş yapması söylenir', (tester) async {
      await open(tester, signedIn: false);
      expect(find.text('Önce giriş yap'), findsOneWidget);
      expect(find.text('DAVET KODUN'), findsNothing);
    });

    testWidgets('kod, ilerleme ve ödüller gösterilir', (tester) async {
      await open(tester, api: FakeReferralApi(qualified: 2, pending: 1, invited: 3));

      expect(find.text('DAVET KODUN'), findsOneWidget);
      expect(find.text('ABCDEFGH'), findsOneWidget);
      expect(find.text('Sonraki ödül: 5 sayılan davette 1 ay premium (2/5)'), findsOneWidget);
      expect(find.text('5 davet → 1 ay premium'), findsOneWidget);
      expect(find.text('10 davet → 2 ay premium'), findsOneWidget);
    });

    /// DÜRÜSTLÜK: bekleyen davetin neden sayılmadığı açıkça yazılır — yoksa kullanıcı
    /// "5 kişi davet ettim, ödül nerede?" diye desteğe yazar.
    testWidgets('bekleyen davetin nedeni açıkça yazılır', (tester) async {
      await open(tester, api: FakeReferralApi(qualified: 1, pending: 2, invited: 3));
      expect(find.text('Bekleyen 2 davet'), findsOneWidget);
      expect(
        find.textContaining('e-posta adresini doğrulaması'),
        findsOneWidget,
      );
    });

    testWidgets('paylaş düğmesi kodu ve bağlantıyı gönderir', (tester) async {
      final share = FakeShareService();
      await useTallSurface(tester);
      await pumpApp(
        tester,
        share: share,
        referral: FakeReferralApi(),
        tokens: MemoryTokenStore()..write('abc'),
        auth: FakeAuthApi(
          user: const AppUser(id: 'u1', email: 'a@ea.dev', name: 'Ali', role: 'user'),
        ),
      );
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Davet et, premium kazan'), 200);
      await tester.tap(find.text('Davet et, premium kazan'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(GradientPillButton, 'Arkadaşını davet et'));
      await tester.pumpAndSettle();

      expect(share.textCalls, 1);
      expect(share.lastText, contains('ABCDEFGH'));
      expect(share.lastText, contains('https://'));
    });

    testWidgets('kazanılmış ödülün bitiş tarihi gösterilir', (tester) async {
      await open(
        tester,
        api: FakeReferralApi(
          qualified: 5,
          invited: 5,
          rewards: [
            ReferralReward(
              milestone: 5,
              months: 1,
              expiresAt: DateTime.now().add(const Duration(days: 20)),
            ),
          ],
        ),
      );
      expect(find.text('Premium erişimin açık'), findsOneWidget);
      expect(find.text('Kazanıldı'), findsOneWidget);
    });
  });

  group('kayıtta davet kodu', () {
    Future<void> openRegister(WidgetTester tester, FakeAuthApi api) async {
      await useTallSurface(tester);
      await pumpApp(tester, auth: api);
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giriş yap / Kayıt ol'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hesabın yok mu? Kayıt ol'));
      await tester.pumpAndSettle();
    }

    testWidgets('alan yalnız KAYIT kipinde görünür', (tester) async {
      final api = FakeAuthApi();
      await useTallSurface(tester);
      await pumpApp(tester, auth: api);
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giriş yap / Kayıt ol'));
      await tester.pumpAndSettle();

      expect(find.text('Davet kodu (isteğe bağlı)'), findsNothing); // giriş kipi
      await tester.tap(find.text('Hesabın yok mu? Kayıt ol'));
      await tester.pumpAndSettle();
      expect(find.text('Davet kodu (isteğe bağlı)'), findsOneWidget);
    });

    testWidgets('yazılan kod kanonik biçimde gönderilir', (tester) async {
      final api = FakeAuthApi();
      await openRegister(tester, api);

      await tester.enterText(find.widgetWithText(TextFormField, 'Ad Soyad'), 'Ali');
      await tester.enterText(find.widgetWithText(TextFormField, 'E-posta adresiniz'), 'a@ea.dev');
      await tester.enterText(find.widgetWithText(TextFormField, 'Şifreniz'), 'parola-1234');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Davet kodu (isteğe bağlı)'),
        'ab-cd ef gh',
      );
      await tester.tap(find.widgetWithText(GradientPillButton, 'Kayıt Ol'));
      await tester.pumpAndSettle();

      expect(api.lastReferralCode, 'ABCDEFGH');
    });

    /// Boş bırakmak SERBEST: davet alanı kayıt akışını zorlaştırmamalı.
    testWidgets('boş bırakılırsa kod GÖNDERİLMEZ ve kayıt tamamlanır', (tester) async {
      final api = FakeAuthApi();
      await openRegister(tester, api);

      await tester.enterText(find.widgetWithText(TextFormField, 'Ad Soyad'), 'Ali');
      await tester.enterText(find.widgetWithText(TextFormField, 'E-posta adresiniz'), 'a@ea.dev');
      await tester.enterText(find.widgetWithText(TextFormField, 'Şifreniz'), 'parola-1234');
      await tester.tap(find.widgetWithText(GradientPillButton, 'Kayıt Ol'));
      await tester.pumpAndSettle();

      expect(api.lastReferralCode, isNull);
      expect(find.text('Tekrar Hoş Geldin! 👋'), findsNothing); // kayıt tamamlandı, ekran kapandı
    });

    /// Eksik yazılmış kod bir HATA değil, nazik bir uyarıdır — kayıt yine yapılabilir.
    testWidgets('eksik kod uyarı verir ama kaydı engellemez', (tester) async {
      final api = FakeAuthApi();
      await openRegister(tester, api);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Davet kodu (isteğe bağlı)'),
        'ABC',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('8 karakter olmalı'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Ad Soyad'), 'Ali');
      await tester.enterText(find.widgetWithText(TextFormField, 'E-posta adresiniz'), 'a@ea.dev');
      await tester.enterText(find.widgetWithText(TextFormField, 'Şifreniz'), 'parola-1234');
      await tester.tap(find.widgetWithText(GradientPillButton, 'Kayıt Ol'));
      await tester.pumpAndSettle();

      expect(api.lastReferralCode, 'ABC'); // sunucu karar verir, istemci engellemez
    });
  });
}

/// Sahte davet ucu — sunucu davranışını değil, ekranın gösterdiğini test eder.
class FakeReferralApi implements ReferralApi {
  FakeReferralApi({
    this.qualified = 0,
    this.pending = 0,
    this.invited = 0,
    this.rewards = const [],
    this.unavailable = false,
  });

  final int qualified;
  final int pending;
  final int invited;
  final List<ReferralReward> rewards;
  final bool unavailable;

  @override
  Future<ReferralSummary?> fetch() async {
    if (unavailable) return null;
    return ReferralSummary(
      code: 'ABCDEFGH',
      link: 'https://www.ehliyetegitim.com/davet/ABCDEFGH',
      invited: invited,
      qualified: qualified,
      pending: pending,
      rewards: rewards,
      nextMilestone: qualified < 5
          ? const ReferralMilestone(count: 5, months: 1)
          : const ReferralMilestone(count: 10, months: 2),
      milestones: const [
        ReferralMilestone(count: 5, months: 1),
        ReferralMilestone(count: 10, months: 2),
        ReferralMilestone(count: 25, months: 6),
      ],
    );
  }
}
