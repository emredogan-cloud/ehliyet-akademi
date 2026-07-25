import 'package:ehliyet_akademi/domain/community/community_models.dart';
import 'package:ehliyet_akademi/domain/community/social_models.dart';
import 'package:ehliyet_akademi/features/community/chat_screen.dart';
import 'package:ehliyet_akademi/features/community/discussion_thread_screen.dart';
import 'package:ehliyet_akademi/features/community/discussions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Evolution Faz E9 — sosyal yüzeyler: arkadaşlık, mesajlaşma, tartışma, soru paylaşımı,
/// bildirme, engel kaldırma; boş/yükleniyor/hata durumları ve erişilebilirlik.
void main() {
  FriendEntry entry(String id, String name, FriendState state) => FriendEntry(
    userId: id,
    displayName: name,
    avatarId: 'owl-wave',
    licence: 'b',
    state: state,
  );

  group('saf model kuralları', () {
    test('istemci doğrulaması sunucudaki sınırlarla aynı', () {
      expect(validateMessageBody(''), isNotNull);
      expect(validateMessageBody('   '), isNotNull);
      expect(validateMessageBody('a' * (kMessageMaxLength + 1)), isNotNull);
      expect(validateMessageBody('Merhaba'), isNull);

      expect(validateThreadTitle('kısa'), isNotNull);
      expect(validateThreadTitle('a' * (kThreadTitleMax + 1)), isNotNull);
      expect(validateThreadTitle('Geçerli bir başlık'), isNull);

      expect(validatePostBody(''), isNotNull);
      expect(validatePostBody('a' * (kPostMaxLength + 1)), isNotNull);
      expect(validatePostBody('Bence B doğru.'), isNull);
    });

    test('arkadaşlık durumu tel değerinden çözülür, bilinmeyen "none" olur', () {
      expect(FriendState.fromWire('friends'), FriendState.friends);
      expect(FriendState.fromWire('incoming'), FriendState.incoming);
      expect(FriendState.fromWire('outgoing'), FriendState.outgoing);
      expect(FriendState.fromWire('bozuk'), FriendState.none);
      expect(FriendState.fromWire(null), FriendState.none);
    });

    test('tartışma modeli soru REFERANSINI taşır, soru METNİ alanı YOKTUR', () {
      final t = DiscussionSummary.fromJson({
        'id': 't1',
        'title': 'Başlık',
        'licence': 'a',
        'questionRef': 'trafik-101',
        'postCount': 3,
        'author': {'userId': 'u1', 'displayName': 'Ali', 'avatarId': 'owl-teacher'},
      });
      expect(t.questionRef, 'trafik-101');
      expect(t.authorName, 'Ali');
      // Modelde soru metni alanı bulunmadığı için sunucu metin gönderse bile taşınamaz.
      expect(t.toString(), isNot(contains('Kırmızı ışık')));
    });
  });

  group('arkadaşlar ekranı', () {
    Future<void> openFriends(WidgetTester tester) async {
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Sıralama ve topluluk profilin (isteğe bağlı)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Sıralama ve topluluk profilin (isteğe bağlı)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arkadaşlar'));
      await tester.pumpAndSettle();
    }

    final joined = FakeCommunityApi(
      profile: const CommunityProfile(
        displayName: 'Ben',
        avatarId: 'owl-wave',
        licence: 'b',
        visibility: 'public',
      ),
    );

    testWidgets('gelen istek kabul edilebilir ve reddedilebilir', (tester) async {
      final social = FakeSocialApi(incoming: [entry('u2', 'Isteyen', FriendState.incoming)]);
      await pumpApp(tester, community: joined, social: social);
      await openFriends(tester);

      expect(find.text('Gelen istekler  ·  1'), findsOneWidget);
      expect(find.text('Isteyen'), findsOneWidget);

      await tester.tap(find.byTooltip('Kabul et'));
      await tester.pumpAndSettle();
      expect(social.accepted, ['u2']);

      await tester.tap(find.byTooltip('Reddet'));
      await tester.pumpAndSettle();
      expect(social.removed, ['u2']);
    });

    testWidgets('gönderilen istek GERİ ALINABİLİR', (tester) async {
      final social = FakeSocialApi(outgoing: [entry('u3', 'Beklenen', FriendState.outgoing)]);
      await pumpApp(tester, community: joined, social: social);
      await openFriends(tester);

      expect(find.text('Yanıt bekleniyor'), findsOneWidget);
      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(social.removed, ['u3']);
    });

    testWidgets('arkadaş listesinden mesaj ekranına gidilir', (tester) async {
      final social = FakeSocialApi(friends: [entry('u4', 'Arkadas', FriendState.friends)]);
      await pumpApp(tester, community: joined, social: social);
      await openFriends(tester);

      expect(find.text('Arkadaşların  ·  1'), findsOneWidget);
      await tester.tap(find.byTooltip('Mesaj gönder'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('boş durumda yönlendirici mesaj gösterilir', (tester) async {
      await pumpApp(tester, community: joined, social: FakeSocialApi());
      await openFriends(tester);
      expect(find.text('Henüz arkadaşın yok'), findsOneWidget);
    });

    testWidgets('ağ hatasında dürüst hata + tekrar dene', (tester) async {
      await pumpApp(tester, community: joined, social: FakeSocialApi(failFriends: true));
      await openFriends(tester);
      expect(find.text('Arkadaşlar alınamadı'), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
    });
  });

  group('sohbet ekranı', () {
    final joined = FakeCommunityApi(
      profile: const CommunityProfile(
        displayName: 'Ben',
        avatarId: 'owl-wave',
        licence: 'b',
        visibility: 'public',
      ),
    );

    /// Arkadaş listesinden sohbete geç (gerçek yönlendirme yolu).
    Future<void> openChat(WidgetTester tester) async {
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Sıralama ve topluluk profilin (isteğe bağlı)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Sıralama ve topluluk profilin (isteğe bağlı)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arkadaşlar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mesaj gönder'));
      await tester.pumpAndSettle();
    }

    testWidgets('mesajlar çizilir ve gönderme API çağırır', (tester) async {
      final social = FakeSocialApi(
        friends: [entry('u2', 'Arkadas', FriendState.friends)],
        messages: const [
          ChatMessage(id: 'm1', senderId: 'u2', body: 'Selam', createdAt: null, mine: false),
          ChatMessage(id: 'm2', senderId: 'me', body: 'Merhaba', createdAt: null, mine: true),
        ],
      );
      await pumpApp(tester, community: joined, social: social);
      await openChat(tester);

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('Selam'), findsOneWidget);
      expect(find.text('Merhaba'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Nasılsın?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
      expect(social.sent, ['Nasılsın?']);
    });

    testWidgets('boş mesaj gönderilmez; istemci uyarır', (tester) async {
      final social = FakeSocialApi(friends: [entry('u2', 'Arkadas', FriendState.friends)]);
      await pumpApp(tester, community: joined, social: social);
      await openChat(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Mesaj boş olamaz.'), findsOneWidget);
      expect(social.sent, isEmpty);
    });

    testWidgets('SUNUCU REDDİ kullanıcıya olduğu gibi gösterilir (arkadaş değilse)', (
      tester,
    ) async {
      final social = FakeSocialApi(
        friends: [entry('u2', 'Arkadas', FriendState.friends)],
        sendError: 'Yalnız arkadaşlarınla mesajlaşabilirsin.',
      );
      await pumpApp(tester, community: joined, social: social);
      await openChat(tester);

      await tester.enterText(find.byType(TextField), 'selam');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Yalnız arkadaşlarınla mesajlaşabilirsin.'), findsOneWidget);
    });

    testWidgets('konuşma açılamazsa dürüst hata durumu gösterilir', (tester) async {
      final social = FakeSocialApi(
        friends: [entry('u2', 'Arkadas', FriendState.friends)],
        failConversation: true,
      );
      await pumpApp(tester, community: joined, social: social);
      await openChat(tester);
      expect(find.text('Konuşma açılamadı'), findsOneWidget);
    });

    testWidgets('gelen mesaj BİLDİRİLEBİLİR (uzun basınca)', (tester) async {
      final social = FakeSocialApi(
        friends: [entry('u2', 'Arkadas', FriendState.friends)],
        messages: const [
          ChatMessage(id: 'm1', senderId: 'u2', body: 'kaba mesaj', createdAt: null, mine: false),
        ],
      );
      await pumpApp(tester, community: joined, social: social);
      await openChat(tester);

      await tester.longPress(find.text('kaba mesaj'));
      await tester.pumpAndSettle();
      expect(find.text('Bildirme sebebi'), findsOneWidget);
      await tester.tap(find.text('Taciz veya hakaret'));
      await tester.pumpAndSettle();
      expect(social.reports.single, 'message:m1:taciz');
    });
  });

  group('tartışma ekranı', () {
    Future<void> openDiscussions(WidgetTester tester) async {
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Sıralama ve topluluk profilin (isteğe bağlı)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Sıralama ve topluluk profilin (isteğe bağlı)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tartışma'));
      await tester.pumpAndSettle();
    }

    final joined = FakeCommunityApi(
      profile: const CommunityProfile(
        displayName: 'Ben',
        avatarId: 'owl-wave',
        licence: 'b',
        visibility: 'public',
      ),
    );

    testWidgets('başlıklar listelenir; soru paylaşılan başlık işaretlenir', (tester) async {
      final social = FakeSocialApi(
        discussions: const [
          DiscussionSummary(
            id: 't1',
            title: 'Kavşakta öncelik',
            licence: 'b',
            questionRef: 'trafik-101',
            postCount: 2,
            authorId: 'u2',
            authorName: 'Soran',
            authorAvatarId: 'owl-teacher',
          ),
        ],
      );
      await pumpApp(tester, community: joined, social: social);
      await openDiscussions(tester);

      expect(find.byType(DiscussionsScreen), findsOneWidget);
      expect(find.text('Kavşakta öncelik'), findsOneWidget);
      expect(find.text('soru'), findsOneWidget); // soru referansı rozeti
    });

    testWidgets('boş listede yönlendirici mesaj', (tester) async {
      await pumpApp(tester, community: joined, social: FakeSocialApi());
      await openDiscussions(tester);
      expect(find.text('Henüz başlık yok'), findsOneWidget);
    });

    testWidgets('erişilemeyen başlık ayrım SIZDIRMADAN tek mesaj gösterir', (tester) async {
      final social = FakeSocialApi(
        discussions: const [
          DiscussionSummary(
            id: 't1',
            title: 'Gizli başlık',
            licence: 'b',
            questionRef: null,
            postCount: 0,
            authorId: 'u2',
            authorName: 'Yazar',
            authorAvatarId: 'owl-wave',
          ),
        ],
        discussionNotFound: true,
      );
      await pumpApp(tester, community: joined, social: social);
      await openDiscussions(tester);
      await tester.tap(find.text('Gizli başlık'));
      await tester.pumpAndSettle();

      expect(find.byType(DiscussionThreadScreen), findsOneWidget);
      expect(find.text('Başlık görüntülenemiyor'), findsOneWidget);
      expect(find.textContaining('engelledi'), findsNothing);
    });

    testWidgets('SORU PAYLAŞIMI: metin sunucudan gelmez, referans yerel bankadan çözülür', (
      tester,
    ) async {
      final social = FakeSocialApi(
        discussions: const [
          DiscussionSummary(
            id: 't1',
            title: 'Bu soruyu tartışalım',
            licence: 'b',
            questionRef: 't0',
            postCount: 0,
            authorId: 'u2',
            authorName: 'Yazar',
            authorAvatarId: 'owl-wave',
          ),
        ],
        detail: const DiscussionDetail(
          thread: DiscussionSummary(
            id: 't1',
            title: 'Bu soruyu tartışalım',
            licence: 'b',
            questionRef: 't0',
            postCount: 0,
            authorId: 'u2',
            authorName: 'Yazar',
            authorAvatarId: 'owl-wave',
          ),
          posts: [],
        ),
      );
      await pumpApp(tester, community: joined, social: social);
      await openDiscussions(tester);
      await tester.tap(find.text('Bu soruyu tartışalım'));
      await tester.pumpAndSettle();

      // Soru gövdesi YEREL bankadan geldi: sunucu yalnız `t0` referansını gönderdi.
      expect(find.text('Paylaşılan soru'), findsOneWidget);
      expect(find.textContaining('Soru t0'), findsOneWidget);
      // Seçenekler de yerelden çözüldü.
      expect(find.textContaining('A) Birinci'), findsOneWidget);
    });

    testWidgets('çözülemeyen referansta dürüst bilgilendirme gösterilir', (tester) async {
      const missing = DiscussionSummary(
        id: 't2',
        title: 'Bilinmeyen soru',
        licence: 'b',
        questionRef: 'trafik-9999',
        postCount: 0,
        authorId: 'u2',
        authorName: 'Yazar',
        authorAvatarId: 'owl-wave',
      );
      final social = FakeSocialApi(
        discussions: const [missing],
        detail: const DiscussionDetail(thread: missing, posts: []),
      );
      await pumpApp(tester, community: joined, social: social);
      await openDiscussions(tester);
      await tester.tap(find.text('Bilinmeyen soru'));
      await tester.pumpAndSettle();

      expect(find.textContaining('soru bankası henüz cihazında hazır değil'), findsOneWidget);
    });
  });

  group('engel kaldırma', () {
    testWidgets('engellenenler listelenir ve engel kaldırılabilir', (tester) async {
      final community = FakeCommunityApi(
        profile: const CommunityProfile(
          displayName: 'Ben',
          avatarId: 'owl-wave',
          licence: 'b',
          visibility: 'public',
        ),
      );
      community.blocked.add('u9');
      await pumpApp(tester, community: community, social: FakeSocialApi());

      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Sıralama ve topluluk profilin (isteğe bağlı)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Sıralama ve topluluk profilin (isteğe bağlı)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Topluluk profilim'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Engellediklerim'),
        200,
        scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
      );
      await tester.tap(find.text('Engellediklerim'));
      await tester.pumpAndSettle();

      expect(find.text('Engelli u9'), findsOneWidget);
      await tester.tap(find.text('Engeli kaldır'));
      await tester.pumpAndSettle();
      expect(community.blocked, isEmpty);
    });
  });
}
