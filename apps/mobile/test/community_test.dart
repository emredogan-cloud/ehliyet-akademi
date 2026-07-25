import 'package:ehliyet_akademi/design/brand.dart';
import 'package:ehliyet_akademi/domain/community/community_models.dart';
import 'package:ehliyet_akademi/domain/progress/gamification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Evolution Faz E8 — topluluk: opt-in katılım, sıralama, engelle/bildir, gizlilik.
void main() {
  group('modeller (saf)', () {
    test('görünen ad kuralları sunucuyla aynı', () {
      expect(validateDisplayName('ab'), isNotNull);
      expect(validateDisplayName('a' * 21), isNotNull);
      expect(validateDisplayName('kisi@ornek.com'), isNotNull);
      expect(validateDisplayName('kötü<script>'), isNotNull);
      expect(validateDisplayName('Ayşe K_1'), isNull);
    });

    test('avatar kimliği bilinmeyense güvenli varsayılana düşer', () {
      expect(CommunityAvatar.fromId('owl-teacher'), CommunityAvatar.owlTeacher);
      expect(CommunityAvatar.fromId('../../gizli'), CommunityAvatar.owlWave);
      expect(CommunityAvatar.fromId(null), CommunityAvatar.owlWave);
    });

    test('profil JSON çözümlemesi görünürlüğü korur', () {
      final p = CommunityProfile.fromJson({
        'displayName': 'Ali',
        'avatarId': 'owl-shield',
        'licence': 'd',
        'visibility': 'public',
      });
      expect(p.isPublic, isTrue);
      expect(p.avatar, CommunityAvatar.owlShield);
      // Eksik alanlarda gizli varsayılan (opt-in).
      expect(CommunityProfile.fromJson(const {'displayName': 'X'}).isPublic, isFalse);
    });

    test('sıralama sayfası kendi sırasını taşır', () {
      final page = LeaderboardPage.fromJson({
        'weekStart': '2026-07-20',
        'licence': 'a',
        'total': 2,
        'rows': [
          {'userId': 'u1', 'displayName': 'Bir', 'xp': 90, 'rank': 1, 'licence': 'a'},
          {'userId': 'u2', 'displayName': 'İki', 'xp': 40, 'rank': 2, 'licence': 'a'},
        ],
        'me': {'userId': 'u2', 'displayName': 'İki', 'xp': 40, 'rank': 2, 'licence': 'a'},
      });
      expect(page.rows.length, 2);
      expect(page.me!.rank, 2);
      expect(page.weekStart, '2026-07-20');
    });

    test('rozet kimliği yerel katalogdan çözülür', () {
      expect(achievementById('first-steps')?.title, isNotEmpty);
      expect(achievementById('boyle-bir-rozet-yok'), isNull);
      expect(achievementCatalog(), isNotEmpty);
    });
  });

  group('ekranlar', () {
    /// Profil sekmesinden topluluk ekranını açar (liste tembel olduğu için kaydırarak).
    /// Üstte açılan ekranın kaydırıcısı (kabuk diğer sekmelerinkini ağaçta tuttuğu için `.last`).
    Finder topScrollable() => find.byType(Scrollable).last;

    /// Katılma ekranının kendi listesi. DİKKAT: metin alanı listenin İÇİNDEDİR, yani onun
    /// Scrollable'ı da bu sorguya düşer. Listenin kendi kaydırıcısı ağaçta ÖNCE gelir → `.first`.
    /// (`.last` metin alanınınkini seçer; sürükleme hiçbir şey yapmaz ve hedef asla bulunmaz.)
    Finder joinList() =>
        find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;

    Future<void> openCommunity(WidgetTester tester) async {
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Sıralama ve topluluk profilin (isteğe bağlı)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Sıralama ve topluluk profilin (isteğe bağlı)'));
      await tester.pumpAndSettle();
    }

    testWidgets('katılmamış kullanıcıya OPT-IN daveti gösterilir, sıralama gösterilmez', (
      tester,
    ) async {
      await pumpApp(tester, community: FakeCommunityApi());
      await openCommunity(tester);

      expect(find.text('Varsayılan olarak KAPALI'), findsOneWidget);
      expect(find.text('Gerçek adın görünmez'), findsOneWidget);
      expect(find.text('Fotoğraf yüklenmez'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Topluluğa katıl'),
        200,
        scrollable: topScrollable(),
      );
      expect(find.text('Topluluğa katıl'), findsWidgets);
    });

    testWidgets('katılan kullanıcı sıralamayı görür ve kendi satırı işaretlenir', (tester) async {
      final api = FakeCommunityApi(
        profile: const CommunityProfile(
          displayName: 'Ben',
          avatarId: 'owl-wave',
          licence: 'b',
          visibility: 'public',
        ),
      );
      await pumpApp(tester, community: api);
      await openCommunity(tester);

      expect(find.text('Rakip Kisi'), findsOneWidget);
      // Kendi satırın sayfadaysa YALNIZ BİR KEZ çizilir (üstte sabitlenmiş kopya yok).
      expect(find.text('Ben'), findsOneWidget);
      expect(find.text('Varsayılan olarak KAPALI'), findsNothing);
    });

    testWidgets('kendi sıran sayfa DIŞINDAYSA üstte sabitlenir', (tester) async {
      final api = FakeCommunityApi(
        profile: const CommunityProfile(
          displayName: 'Ben',
          avatarId: 'owl-wave',
          licence: 'b',
          visibility: 'public',
        ),
        meOutsidePage: true,
      );
      await pumpApp(tester, community: api);
      await openCommunity(tester);

      // Sayfada olmadığın hâlde sıran görünür (aramak zorunda kalmazsın).
      expect(find.text('Ben'), findsOneWidget);
      expect(find.text('Rakip Kisi'), findsOneWidget);
    });

    testWidgets('gizli profilde "listede görünmezsin" uyarısı çıkar', (tester) async {
      final api = FakeCommunityApi(
        profile: const CommunityProfile(
          displayName: 'Gizli Ben',
          avatarId: 'owl-wave',
          licence: 'b',
          visibility: 'private',
        ),
      );
      await pumpApp(tester, community: api);
      await openCommunity(tester);

      expect(find.textContaining('listede görünmezsin'), findsOneWidget);
    });

    testWidgets('sıralama alınamazsa dürüst hata durumu ve tekrar dene çıkar', (tester) async {
      final api = FakeCommunityApi(
        profile: const CommunityProfile(
          displayName: 'Ben',
          avatarId: 'owl-wave',
          licence: 'b',
          visibility: 'public',
        ),
        failLeaderboard: true,
      );
      await pumpApp(tester, community: api);
      await openCommunity(tester);

      expect(find.text('Sıralama alınamadı'), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
    });

    testWidgets('katılma ekranı geçersiz adı reddeder, geçerli adla katılır', (tester) async {
      final api = FakeCommunityApi();
      await pumpApp(tester, community: api);
      await openCommunity(tester);
      await tester.scrollUntilVisible(
        find.text('Topluluğa katıl'),
        200,
        scrollable: topScrollable(),
      );
      await tester.tap(find.byType(GradientPillButton));
      await tester.pumpAndSettle();

      expect(find.text('Katılım tamamen sana bağlı'), findsOneWidget);

      // Geçersiz: e-posta
      await tester.enterText(find.byType(TextField), 'kisi@ornek.com');
      // CTA tembel listede kat altında kalıyor → ÖNCE kaydır (ensureVisible kurulmamış öğeyi
      // bulamaz). Metin alanının da kendi Scrollable'ı olduğu için liste açıkça hedeflenir.
      await tester.scrollUntilVisible(
        find.byType(GradientPillButton),
        200,
        scrollable: joinList(),
      );
      await tester.tap(find.byType(GradientPillButton));
      await tester.pumpAndSettle();
      expect(find.text('Görünen ad e-posta olamaz.'), findsOneWidget);
      expect(api.saved, isEmpty);

      // Geçerli
      await tester.enterText(find.byType(TextField), 'Yeni Kullanici');
      await tester.scrollUntilVisible(
        find.byType(GradientPillButton),
        200,
        scrollable: joinList(),
      );
      await tester.tap(find.byType(GradientPillButton));
      await tester.pumpAndSettle();
      expect(api.saved.single, 'Yeni Kullanici');
    });

    testWidgets('başka kullanıcının profilinde engelle ve bildir vardır', (tester) async {
      final api = FakeCommunityApi(
        profile: const CommunityProfile(
          displayName: 'Ben',
          avatarId: 'owl-wave',
          licence: 'b',
          visibility: 'public',
        ),
      );
      await pumpApp(tester, community: api);
      await openCommunity(tester);

      await tester.tap(find.text('Rakip Kisi'));
      await tester.pumpAndSettle();

      // Faz E9'da profile "Arkadaşlık" bölümü eklendi → güvenlik düğmeleri daha aşağıda.
      // Kaydırdıktan sonra AYRICA ensureVisible: satır ekranın en altında yarı örtülü kalabiliyor.
      await tester.scrollUntilVisible(
        find.widgetWithText(OutlinedButton, 'Engelle'),
        200,
        scrollable: topScrollable(),
      );
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Engelle'));
      await tester.pumpAndSettle();
      expect(find.text('Engelle'), findsOneWidget);
      expect(find.text('Bildir'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Engelle'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Engelle'));
      await tester.pumpAndSettle();
      expect(api.blocked.single, 'u2');
    });

    testWidgets('erişilemeyen profil ayrım SIZDIRMADAN tek mesaj gösterir', (tester) async {
      final api = FakeCommunityApi(
        profile: const CommunityProfile(
          displayName: 'Ben',
          avatarId: 'owl-wave',
          licence: 'b',
          visibility: 'public',
        ),
        userNotFound: true,
      );
      await pumpApp(tester, community: api);
      await openCommunity(tester);
      await tester.tap(find.text('Rakip Kisi'));
      await tester.pumpAndSettle();

      expect(find.text('Profil görüntülenemiyor'), findsOneWidget);
      // "gizli mi engelli mi" ayrımı verilmez.
      expect(find.textContaining('engelledi'), findsNothing);
    });
  });
}
