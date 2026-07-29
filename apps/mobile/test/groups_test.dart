import 'package:ehliyet_akademi/domain/community/community_models.dart';
import 'package:ehliyet_akademi/domain/community/group_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Evolution Faz E10 — çalışma grupları ve meydan okumalar (widget testleri).
///
/// Kural doğrulaması (tavanlar, üyelik, engel) SUNUCU entegrasyon testlerindedir. Burada
/// doğrulanan şey arayüzün her durumu — boş, dolu, hata, sahiplik — dürüstçe göstermesidir.
/// E10 yüzeyleri topluluk profiline bağlıdır (E8 opt-in) — katılmamış kullanıcı merkezi görmez.
FakeCommunityApi joinedCommunity() => FakeCommunityApi(
  profile: const CommunityProfile(
    displayName: 'Ben',
    avatarId: 'owl-wave',
    licence: 'b',
    visibility: 'public',
  ),
);

/// Topluluk merkezinden E10 yüzeylerine gider (E9 testlerindeki desenin aynısı).
Future<void> _openHub(WidgetTester tester) async {
  // Faz 4: Topluluk artık alt gezinmede birinci sınıf sekme.
  await tapTab(tester, 'Topluluk');
}

Future<void> _openHubButton(WidgetTester tester, String label) async {
  await _openHub(tester);
  await tester.scrollUntilVisible(find.text(label), 150,
      scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> openGroups(WidgetTester tester) => _openHubButton(tester, 'Gruplar');

Future<void> openChallenges(WidgetTester tester) => _openHubButton(tester, 'Meydan okuma');

void main() {
  StudyGroup makeGroup({
    String id = 'g1',
    String name = 'Sabah Ekibi',
    bool isOwner = false,
    int memberCount = 3,
  }) => StudyGroup(
    id: id,
    name: name,
    licence: 'b',
    joinCode: 'ABC234',
    isOwner: isOwner,
    memberCount: memberCount,
    totalXp: 4200,
    totalAnswered: 310,
  );

  Challenge makeChallenge({
    String id = 'c1',
    String title = 'Haftada 200 soru',
    bool joined = false,
    int percent = 0,
    bool done = false,
  }) => Challenge(
    id: id,
    title: title,
    description: 'Bu hafta 200 soru çöz.',
    metric: 'answered',
    target: 200,
    joined: joined,
    value: (200 * percent) ~/ 100,
    percent: percent,
    done: done,
    endsAt: null,
  );

  group('kod normalleştirme (sunucu kuralıyla aynı)', () {
    test('küçük harf, boşluk ve tire kabul edilir', () {
      expect(normalizeJoinCode(' abc-234 '), 'ABC234');
    });

    test('karışan karakter SESSİZCE eşlenmez — reddedilir', () {
      // Alfabede ne 0 ne O var; yazım hatası BAŞKA bir gruba düşmemeli.
      expect(normalizeJoinCode('ABC0EF'), isNull);
      expect(normalizeJoinCode('ABC1EF'), isNull);
      expect(normalizeJoinCode('ABCLEF'), isNull);
    });

    test('yanlış uzunluk reddedilir', () {
      expect(normalizeJoinCode('ABC'), isNull);
      expect(normalizeJoinCode('ABCDEFG'), isNull);
    });
  });

  group('grup adı doğrulama', () {
    test('kısa ad reddedilir, boşluk sadeleşir', () {
      expect(validateGroupName('ab'), isNotNull);
      expect(validateGroupName('  Sabah   Ekibi '), isNull);
    });

    test('uzun ad ve geçersiz karakter reddedilir', () {
      expect(validateGroupName('x' * 41), isNotNull);
      expect(validateGroupName('grup <script>'), isNotNull);
    });
  });

  group('gruplar ekranı', () {
    testWidgets('grubu yokken davetkâr boş durum gösterir', (tester) async {
      await pumpApp(tester, community: joinedCommunity(), groups: FakeGroupsApi());
      await openGroups(tester);

      expect(find.text('Henüz grubun yok'), findsOneWidget);
      expect(find.text('Kodla katıl'), findsOneWidget);
    });

    testWidgets('gruplar listelenir; kurucu rozeti ve kod görünür', (tester) async {
      await pumpApp(
        tester,
        community: joinedCommunity(),
        groups: FakeGroupsApi(groups: [makeGroup(isOwner: true), makeGroup(id: 'g2', name: 'Akşam Ekibi')]),
      );
      await openGroups(tester);

      expect(find.text('Sabah Ekibi'), findsOneWidget);
      expect(find.text('Akşam Ekibi'), findsOneWidget);
      expect(find.text('kurucu'), findsOneWidget); // yalnız sahibi olduğum grupta
      expect(find.text('ABC234'), findsNWidgets(2));
      expect(find.textContaining('3 üye'), findsNWidgets(2));
    });

    testWidgets('hata durumunda dürüst mesaj ve tekrar dene', (tester) async {
      await pumpApp(tester, community: joinedCommunity(), groups: FakeGroupsApi(failGroups: true));
      await openGroups(tester);

      expect(find.text('Gruplar alınamadı'), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
    });

    testWidgets('geçersiz kod sunucuya GİTMEDEN reddedilir', (tester) async {
      final api = FakeGroupsApi();
      await pumpApp(tester, community: joinedCommunity(), groups: api);
      await openGroups(tester);

      await tester.enterText(find.widgetWithText(TextField, 'ABC123'), 'ABC0EF');
      await tester.tap(find.widgetWithText(FilledButton, 'Katıl'));
      await tester.pumpAndSettle();

      expect(api.lastJoinCode, isNull); // istek hiç yapılmadı
      expect(find.textContaining('6 karakter olmalı'), findsOneWidget);
    });

    testWidgets('geçerli kod normalleştirilmiş biçimde gönderilir', (tester) async {
      final api = FakeGroupsApi();
      await pumpApp(tester, community: joinedCommunity(), groups: api);
      await openGroups(tester);

      await tester.enterText(find.widgetWithText(TextField, 'ABC123'), ' abc-234 ');
      await tester.tap(find.widgetWithText(FilledButton, 'Katıl'));
      await tester.pumpAndSettle();

      expect(api.lastJoinCode, 'ABC234');
      expect(find.text('Gruba katıldın.'), findsOneWidget);
    });

    testWidgets('sunucu hatası kullanıcıya AYNEN gösterilir', (tester) async {
      await pumpApp(tester, community: joinedCommunity(), groups: FakeGroupsApi(joinError: 'Grup dolu.'));
      await openGroups(tester);

      await tester.enterText(find.widgetWithText(TextField, 'ABC123'), 'ABC234');
      await tester.tap(find.widgetWithText(FilledButton, 'Katıl'));
      await tester.pumpAndSettle();

      expect(find.text('Grup dolu.'), findsOneWidget);
    });
  });

  group('grup ayrıntısı', () {
    testWidgets('üye değilsem varlık sızdırılmaz', (tester) async {
      await pumpApp(
        tester,
        community: joinedCommunity(),
        groups: FakeGroupsApi(groups: [makeGroup()], groupNotFound: true),
      );
      await openGroups(tester);
      await tester.tap(find.text('Sabah Ekibi'));
      await tester.pumpAndSettle();

      expect(find.text('Grup bulunamadı'), findsOneWidget);
    });

    testWidgets('üye listesi sırayla ve kendi satırım vurgulu', (tester) async {
      await pumpApp(
        tester,
        community: joinedCommunity(),
        groups: FakeGroupsApi(
          groups: [makeGroup()],
          detail: GroupDetail(
            group: makeGroup(),
            members: const [
              GroupMember(
                userId: 'u1',
                displayName: 'Ayse',
                avatarId: 'owl-wave',
                role: 'owner',
                xp: 2500,
                streak: 7,
                rank: 1,
                isSelf: false,
              ),
              GroupMember(
                userId: 'u2',
                displayName: 'Burak',
                avatarId: 'owl-wave',
                role: 'member',
                xp: 1700,
                streak: 3,
                rank: 2,
                isSelf: true,
              ),
            ],
          ),
        ),
      );
      await openGroups(tester);
      await tester.tap(find.text('Sabah Ekibi'));
      await tester.pumpAndSettle();

      expect(find.text('Ayse'), findsOneWidget);
      expect(find.text('Burak'), findsOneWidget);
      expect(find.text('4200'), findsOneWidget); // toplam XP
      expect(find.text('ABC234'), findsOneWidget); // katılım kodu kartı
    });
  });

  group('meydan okumalar', () {
    testWidgets('etkin meydan okuma yoksa dürüst boş durum', (tester) async {
      await pumpApp(tester, community: joinedCommunity(), groups: FakeGroupsApi());
      await openChallenges(tester);

      expect(find.text('Şu an etkin meydan okuma yok'), findsOneWidget);
    });

    testWidgets('katılmadığım meydan okumada Katıl düğmesi vardır', (tester) async {
      final api = FakeGroupsApi(challenges: [makeChallenge()]);
      await pumpApp(tester, community: joinedCommunity(), groups: api);
      await openChallenges(tester);

      expect(find.text('Haftada 200 soru'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Katıl'));
      await tester.pumpAndSettle();

      expect(api.joinedChallenges, ['c1']);
      expect(find.textContaining('kendiliğinden işlenir'), findsOneWidget);
    });

    testWidgets('katıldığım meydan okumada ilerleme görünür, Katıl düğmesi YOKTUR', (tester) async {
      await pumpApp(
        tester,
        community: joinedCommunity(),
        groups: FakeGroupsApi(challenges: [makeChallenge(joined: true, percent: 45)]),
      );
      await openChallenges(tester);

      expect(find.text('%45'), findsOneWidget);
      expect(find.text('90 / 200 soru'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Katıl'), findsNothing);
    });

    testWidgets('tamamlanan meydan okuma tamamlandı olarak işaretlenir', (tester) async {
      await pumpApp(
        tester,
        community: joinedCommunity(),
        groups: FakeGroupsApi(challenges: [makeChallenge(joined: true, percent: 100, done: true)]),
      );
      await openChallenges(tester);

      expect(find.text('Tamamlandı'), findsOneWidget);
    });

    testWidgets('ilerlemeyi ELLE bildiren bir yüzey yoktur', (tester) async {
      await pumpApp(
        tester,
        community: joinedCommunity(),
        groups: FakeGroupsApi(challenges: [makeChallenge(joined: true, percent: 20)]),
      );
      await openChallenges(tester);

      // İlerleme sunucuda türetilir → katıldıktan sonra ekranda ilerlemeye dokunan HİÇBİR
      // etkileşimli denetim kalmamalı. (Metinle değil, DÜĞMELERLE doğrula: açıklama metninin
      // kendisi "elle bildirim yoktur" dediği için metin araması yanıltıcı olur.)
      expect(find.widgetWithText(FilledButton, 'Katıl'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(find.byType(TextField), findsNothing);
      // Kullanıcıya bu güvence açıkça yazılır.
      expect(find.textContaining('kimse ilerlemesini şişiremez'), findsOneWidget);
    });
  });
}
