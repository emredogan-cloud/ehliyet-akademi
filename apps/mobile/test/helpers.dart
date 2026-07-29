// `material` import'u burada Badge çakışması yaratır (helpers `content_enums`'un Badge'ini
// kullanıyor) → yalnız gereken tip alınır.
import 'dart:ui' show Size;

import 'package:ehliyet_akademi/app/app.dart';
import 'package:ehliyet_akademi/app/shell.dart';
import 'package:ehliyet_akademi/core/storage/token_store.dart';
import 'package:ehliyet_akademi/data/auth/auth_api.dart';
import 'package:ehliyet_akademi/data/coach/coach_api.dart';
import 'package:ehliyet_akademi/data/community/community_repository.dart';
import 'package:ehliyet_akademi/data/auth/google_auth_service.dart';
import 'package:ehliyet_akademi/data/community/groups_repository.dart';
import 'package:ehliyet_akademi/data/community/social_repository.dart';
import 'package:ehliyet_akademi/data/content/content_repository.dart';
import 'package:ehliyet_akademi/data/practice/question_repository.dart';
import 'package:ehliyet_akademi/data/premium/billing_gateway.dart';
import 'package:ehliyet_akademi/data/premium/entitlements_repository.dart';
import 'package:ehliyet_akademi/domain/auth/app_user.dart';
import 'package:ehliyet_akademi/domain/community/community_models.dart';
import 'package:ehliyet_akademi/domain/community/group_models.dart';
import 'package:ehliyet_akademi/domain/community/social_models.dart';
import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/content/content_snapshot.dart';
import 'package:ehliyet_akademi/domain/content/lesson.dart';
import 'package:ehliyet_akademi/domain/content/traffic_sign.dart';
import 'package:ehliyet_akademi/domain/content/vehicle_part.dart';
import 'package:ehliyet_akademi/domain/content/video_content.dart';
import 'package:ehliyet_akademi/domain/onboarding/ai_welcome_controller.dart';
import 'package:ehliyet_akademi/domain/onboarding/onboarding_controller.dart';
import 'package:ehliyet_akademi/domain/onboarding/study_profile.dart';
import 'package:ehliyet_akademi/domain/onboarding/welcome_controller.dart';
import 'package:ehliyet_akademi/domain/practice/question.dart';
import 'package:ehliyet_akademi/domain/practice/question_bank.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fake AuthApi for tests — no network. Configurable success/failure.
class FakeAuthApi implements AuthApi {
  FakeAuthApi({this.user, this.token, this.failMessage});
  AppUser? user;
  String? token;
  String? failMessage;
  int meCalls = 0;

  @override
  Future<AuthResult> login({required String email, required String password}) async =>
      _result(email);

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async =>
      _result(email, name: name);

  /// Beta Faz 2 — sunucuya gönderilen ID token kaydedilir ki test doğrulayabilsin.
  String? lastGoogleIdToken;

  @override
  Future<AuthResult> loginWithGoogle(String idToken) async {
    lastGoogleIdToken = idToken;
    return _result('google@ea.dev', name: 'Google Kullanıcı');
  }

  /// Beta Faz 5 — parola sıfırlama talebi kaydedilir ki test doğrulayabilsin.
  String? lastResetEmail;
  int resetCalls = 0;

  /// Doluysa `requestPasswordReset` bu hatayı döndürür (sunucu reddi taklidi).
  String? resetFailMessage;

  @override
  Future<String?> requestPasswordReset(String email) async {
    resetCalls++;
    lastResetEmail = email;
    return resetFailMessage;
  }

  AuthResult _result(String email, {String name = 'Test'}) {
    if (failMessage != null) return AuthFailure(failMessage!);
    final u = AppUser(id: 'u1', email: email, name: name, role: 'user');
    return AuthSuccess(u, token ?? 'token123');
  }

  @override
  Future<AppUser?> me() async {
    meCalls++;
    return user;
  }

  @override
  Future<void> logout() async {}
}

/// A small, valid content snapshot covering every domain + sign-shape variety (octagon text,
/// triangle glyph, ring glyphText). Used to render the Learn screens without network/drift.
ContentSnapshot sampleSnapshot() => ContentSnapshot(
  version: 'test-v1',
  generatedAt: '2026-07-23T00:00:00.000Z',
  counts: const SnapshotCounts(lessons: 3, signs: 3, vehicleParts: 2, videos: 2),
  lessons: const [
    Lesson(
      id: 'trafik-temel',
      slug: 'trafik-temel',
      no: 1,
      subject: Subject.trafik,
      title: 'Trafiğe Giriş',
      summary: 'Temel trafik kavramları ve kuralları.',
      minutes: 10,
      objectives: ['Temel kuralları anla'],
      sections: [
        LessonSection(
          heading: 'Giriş',
          badge: Badge.official,
          body: 'Trafik, yolların paylaşımıdır.',
          callout: Callout(tone: CalloutTone.info, title: 'Not', text: 'Kurallara uy.'),
          compare: CompareTable(
            headers: ['Durum', 'Kural'],
            rows: [
              ['Kırmızı', 'Dur'],
              ['Yeşil', 'Geç'],
            ],
          ),
        ),
      ],
      mistakes: [LessonMistake(text: 'Işığı geç sanmak', fix: 'Sarıda yavaşla')],
      tips: ['Erken planla'],
      keyTakeaways: ['Kurallar güvenlik içindir'],
      reviewCards: [ReviewCard(front: 'Kırmızı ne demek?', back: 'Dur')],
    ),
    Lesson(
      id: 'ilk-yardim-temel',
      slug: 'ilk-yardim-temel',
      no: 2,
      subject: Subject.ilkyardim,
      title: 'İlk Yardım Temeli',
      summary: 'ABC yaklaşımı ve temel müdahale.',
      minutes: 12,
      objectives: ['ABC sırasını bil'],
      sections: [LessonSection(heading: 'ABC', body: 'Hava yolu, solunum, dolaşım.')],
    ),
    // premium + capability-mapped (park-manevra → direksiyon-premium) → lockable in tests
    Lesson(
      id: 'park-manevra',
      slug: 'park-manevra',
      no: 3,
      subject: Subject.pratik,
      title: 'Park Manevrası',
      summary: 'İleri park teknikleri (premium).',
      minutes: 15,
      objectives: ['Paralel parkı uygula'],
      sections: [LessonSection(heading: 'Giriş', body: 'Adım adım paralel park.')],
      premium: true,
    ),
  ],
  signs: const [
    TrafficSign(
      id: 'dur',
      category: SignCategory.oncelik,
      name: 'Dur',
      shape: SignShape.octagon,
      meaning: 'Tam olarak dur.',
      memoryTip: 'Kırmızı sekizgen',
      examImportance: ExamImportance.cokYuksek,
      keywords: ['dur', 'stop'],
    ),
    TrafficSign(
      id: 'kaygan-yol',
      category: SignCategory.tehlike,
      name: 'Kaygan Yol',
      shape: SignShape.triangle,
      glyph: 'slippery',
      meaning: 'Yol kaygan olabilir.',
      memoryTip: 'Kayan araç',
      examImportance: ExamImportance.yuksek,
      commonMistake: 'Hızı korumak',
      relatedLessonSlug: 'trafik-temel',
      keywords: ['kaygan'],
    ),
    TrafficSign(
      id: 'azami-30',
      category: SignCategory.yasak,
      name: 'Azami Hız 30',
      shape: SignShape.ring,
      glyphText: '30',
      meaning: 'En fazla 30 km/s.',
      memoryTip: 'Kırmızı halka = yasak',
      examImportance: ExamImportance.orta,
      keywords: ['hız', '30'],
    ),
  ],
  vehicleParts: const [
    VehiclePart(
      id: 'engine-bay',
      name: 'Motor Bölmesi',
      system: VehicleSystem.motorBolmesi,
      desc: 'Motor ve sıvı depolarının bulunduğu bölme.',
      tip: 'Seviyeleri sırayla kontrol et.',
      relatedLessonSlug: 'trafik-temel',
      inspection: ['Yağ seviyesi', 'Su seviyesi'],
      mistake: 'Sıcakken kapağı açmak',
    ),
    VehiclePart(
      id: 'lastik',
      name: 'Lastikler',
      system: VehicleSystem.dis,
      desc: 'Yol tutuşunu sağlar.',
      tip: 'Diş derinliğini kontrol et.',
    ),
  ],
  videos: const [
    VideoContent(
      id: 'parallel-park',
      title: 'Paralel Park',
      description: 'Adım adım paralel park.',
      status: 'available',
      src: '/videos/parallel-park.mp4',
      poster: '/videos/parallel-park-poster.jpg',
      duration: 120,
      chapters: [VideoChapter(t: 0, title: 'Giriş'), VideoChapter(t: 30, title: 'Manevra')],
    ),
    // Faz E12 — manevra seti; ilki ücretsiz önizleme, kalanı premium kapısının arkasında.
    VideoContent(
      id: 'l-park',
      title: 'L Park (Animasyon)',
      description: 'Dik park.',
      status: 'available',
      src: '/videos/l-park.mp4',
      poster: '/videos/l-park-poster.jpg',
      captions: '/videos/l-park.tr.vtt',
      duration: 13,
      chapters: [
        VideoChapter(t: 0, title: 'Yanaş ve referansı yakala'),
        VideoChapter(t: 3.2, title: 'Dur, geri vitese al'),
        VideoChapter(t: 5.4, title: 'Direksiyonu tam kır'),
      ],
    ),
    VideoContent(
      id: 'planned-video',
      title: 'Yakında Video',
      description: 'Henüz hazır değil.',
      status: 'planned',
    ),
  ],
);

/// A fake CoachApi for tests — no network. Returns a fixed grounded answer.
///
/// Beta Faz 9: akış da taklit edilir. `chunks` verilirse parça parça (streamed:true), verilmezse
/// tek parça (streamed:false) döner — istemcinin sahte akış üretmediğini ölçebilmek için.
class FakeCoachApi implements CoachApi {
  FakeCoachApi({
    this.answer = 'Kırmızı ışıkta durulur.',
    this.grounded = true,
    this.chunks,
    this.streamThrows = false,
  });
  final String answer;
  final bool grounded;

  /// Verilirse akış bu parçaları sırayla yayar ve `streamed: true` bildirir.
  final List<String>? chunks;

  /// Akan uç yoksa/patlarsa çağıranın tek parça uca düşmesini sınamak için.
  final bool streamThrows;

  int calls = 0;
  int streamCalls = 0;
  String? lastQuestion;

  @override
  Future<CoachAnswer> ask(String question, {String? context}) async {
    calls++;
    lastQuestion = question;
    return CoachAnswer(answer: answer, grounded: grounded, sources: const ['trafik'], model: 'mock');
  }

  @override
  Stream<CoachStreamEvent> askStream(String question, {String? context}) async* {
    streamCalls++;
    lastQuestion = question;
    if (streamThrows) throw StateError('no_stream');
    final parts = chunks;
    yield CoachMeta(
      grounded: grounded,
      sources: const ['trafik'],
      model: 'mock',
      streamed: parts != null,
    );
    if (parts == null) {
      yield CoachDelta(answer);
    } else {
      for (final p in parts) {
        yield CoachDelta(p);
      }
    }
    yield const CoachDone();
  }
}

/// A fake entitlements API for tests — no network. Returns a fixed owned list.
class FakeEntitlementsApi implements EntitlementsApi {
  FakeEntitlementsApi([this.owned = const []]);
  List<String> owned;

  @override
  Future<List<String>> fetchOwned() async => owned;

  @override
  Future<List<String>> validatePurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
  }) async => [...owned, productId];
}

/// A small question bank that fully covers the exam blueprint (23/12/9/6) with headroom + variety.
QuestionBank sampleBank() {
  Question q(String id, Subject s, {Difficulty d = Difficulty.orta, int answer = 0, String topic = 'genel'}) =>
      Question(
        id: id,
        subject: s,
        topic: topic,
        difficulty: d,
        stem: 'Soru $id — yeterince uzun bir soru metni burada.',
        options: const ['Birinci', 'İkinci', 'Üçüncü', 'Dördüncü'],
        answerIndex: answer,
        explanation: '**Doğru** cevabın açıklaması burada yeterince uzun.',
        whyWrong: const ['Diğer seçenek yanlış çünkü …'],
      );
  final questions = <Question>[
    for (var i = 0; i < 25; i++)
      q('t$i', Subject.trafik, topic: i.isEven ? 'isaretler' : 'hiz', d: i % 3 == 0 ? Difficulty.zor : Difficulty.kolay),
    for (var i = 0; i < 14; i++) q('i$i', Subject.ilkyardim, topic: 'kanama'),
    for (var i = 0; i < 10; i++) q('m$i', Subject.motor, topic: 'motor-temel', d: Difficulty.zor),
    for (var i = 0; i < 7; i++) q('a$i', Subject.adab, topic: 'empati'),
    for (var i = 0; i < 4; i++) q('p$i', Subject.pratik, topic: 'direksiyon'),
  ];
  return QuestionBank(
    version: 'bank-test-v1',
    generatedAt: '2026-07-23T00:00:00.000Z',
    count: questions.length,
    blueprint: const ExamBlueprint(
      totalQuestions: 50,
      passCorrect: 35,
      durationMinutes: 45,
      distribution: {'trafik': 23, 'ilkyardim': 12, 'motor': 9, 'adab': 6},
    ),
    questions: questions,
  );
}


/// Faz E8 — sahte topluluk API'si. Ağ/oturum olmadan opt-in, sıralama ve moderasyon akışlarını
/// çalıştırır; hangi çağrıların yapıldığını kaydeder.
class FakeCommunityApi implements CommunityApi {
  FakeCommunityApi({
    this.profile,
    this.failLeaderboard = false,
    this.userNotFound = false,
    this.meOutsidePage = false,
  });

  CommunityProfile? profile;
  final bool failLeaderboard;
  final bool userNotFound;

  /// true → kullanıcı görünen sayfanın dışındadır (sıran üstte sabitlenmeli).
  final bool meOutsidePage;

  final List<String> saved = [];
  final List<String> blocked = [];
  final List<String> reported = [];
  bool left = false;

  @override
  Future<({CommunityProfile? profile, CommunityStats? stats})> fetchMe() async =>
      (profile: profile, stats: profile == null ? null : CommunityStats.empty);

  @override
  Future<CommunityProfile> saveProfile({
    required String displayName,
    required String avatarId,
    required String licence,
    required bool public,
  }) async {
    saved.add(displayName);
    profile = CommunityProfile(
      displayName: displayName,
      avatarId: avatarId,
      licence: licence,
      visibility: public ? 'public' : 'private',
    );
    return profile!;
  }

  @override
  Future<void> leave() async {
    left = true;
    profile = null;
  }

  @override
  Future<CommunityStats> submitStats({
    required int xp,
    required int streak,
    required int lessons,
    required int exams,
    required int answered,
    required int accuracy,
    required List<String> achievements,
  }) async => CommunityStats.empty;

  @override
  Future<LeaderboardPage> fetchLeaderboard({String? licence, int limit = 25, int offset = 0}) async {
    if (failLeaderboard) throw CommunityException('ağ yok');
    const me = LeaderboardEntry(
      userId: 'u1',
      displayName: 'Ben',
      avatarId: 'owl-wave',
      licence: 'b',
      xp: 120,
      streak: 3,
      rank: 2,
    );
    const rival = LeaderboardEntry(
      userId: 'u2',
      displayName: 'Rakip Kisi',
      avatarId: 'owl-teacher',
      licence: 'b',
      xp: 300,
      streak: 5,
      rank: 1,
    );
    return LeaderboardPage(
      weekStart: '2026-07-20',
      licence: 'all',
      total: 2,
      rows: meOutsidePage ? const [rival] : const [rival, me],
      me: me,
    );
  }

  @override
  Future<CommunityUser?> fetchUser(String userId) async {
    if (userNotFound) return null;
    return CommunityUser(
      userId: userId,
      displayName: 'Rakip Kisi',
      avatarId: 'owl-teacher',
      licence: 'b',
      stats: CommunityStats.empty,
      achievements: const ['first-steps'],
      isSelf: false,
    );
  }

  @override
  Future<void> report({
    required String userId,
    required ReportReason reason,
    String note = '',
  }) async => reported.add('$userId:${reason.wire}');

  @override
  Future<void> block(String userId) async => blocked.add(userId);

  @override
  Future<void> unblock(String userId) async => blocked.remove(userId);

  @override
  Future<List<BlockedUser>> fetchBlocked() async => blocked
      .map((id) => BlockedUser(userId: id, displayName: 'Engelli $id', avatarId: 'owl-wave'))
      .toList();
}

/// Faz E9 — sahte sosyal API. Arkadaşlık/mesaj/tartışma akışlarını ağsız çalıştırır ve
/// hangi çağrıların yapıldığını kaydeder.
class FakeSocialApi implements SocialApi {
  FakeSocialApi({
    this.friends = const [],
    this.incoming = const [],
    this.outgoing = const [],
    this.threads = const [],
    this.messages = const [],
    this.discussions = const [],
    this.detail,
    this.failFriends = false,
    this.failConversation = false,
    this.discussionNotFound = false,
    this.sendError,
  });

  List<FriendEntry> friends;
  List<FriendEntry> incoming;
  List<FriendEntry> outgoing;
  List<MessageThread> threads;
  List<ChatMessage> messages;
  List<DiscussionSummary> discussions;
  DiscussionDetail? detail;
  final bool failFriends;
  final bool failConversation;
  final bool discussionNotFound;

  /// Doluysa `sendMessage` bu mesajla CommunityException fırlatır (sunucu reddi taklidi).
  final String? sendError;

  final List<String> requested = [];
  final List<String> accepted = [];
  final List<String> removed = [];
  final List<String> sent = [];
  final List<String> posts = [];
  final List<String> createdThreads = [];
  final List<String> reports = [];

  @override
  Future<FriendsPage> fetchFriends() async {
    if (failFriends) throw CommunityException('ağ yok');
    return FriendsPage(friends: friends, incoming: incoming, outgoing: outgoing);
  }

  @override
  Future<void> sendFriendRequest(String userId) async => requested.add(userId);

  @override
  Future<void> acceptFriendRequest(String userId) async => accepted.add(userId);

  @override
  Future<void> removeFriend(String userId) async => removed.add(userId);

  @override
  Future<List<MessageThread>> fetchThreads() async => threads;

  @override
  Future<List<ChatMessage>> fetchConversation(String userId) async {
    if (failConversation) throw CommunityException('Konuşma açılamadı.');
    return messages;
  }

  @override
  Future<ChatMessage> sendMessage({required String userId, required String body}) async {
    if (sendError != null) throw CommunityException(sendError!);
    sent.add(body);
    return ChatMessage(
      id: 'm-${sent.length}',
      senderId: 'me',
      body: body,
      createdAt: null,
      mine: true,
    );
  }

  @override
  Future<List<DiscussionSummary>> fetchDiscussions({String? licence}) async => discussions;

  @override
  Future<DiscussionSummary> createDiscussion({
    required String title,
    required String licence,
    String? questionRef,
  }) async {
    createdThreads.add(title);
    return DiscussionSummary(
      id: 't-${createdThreads.length}',
      title: title,
      licence: licence,
      questionRef: questionRef,
      postCount: 0,
      authorId: 'me',
      authorName: 'Ben',
      authorAvatarId: 'owl-wave',
    );
  }

  @override
  Future<DiscussionDetail?> fetchDiscussion(String threadId) async =>
      discussionNotFound ? null : detail;

  @override
  Future<void> addPost({
    required String threadId,
    required String body,
    String? questionRef,
  }) async => posts.add(body);

  @override
  Future<void> reportContent({
    required String userId,
    required ReportReason reason,
    String? targetType,
    String? targetRef,
  }) async => reports.add('${targetType ?? 'user'}:${targetRef ?? userId}:${reason.wire}');
}

/// Alt gezinme çubuğundaki bir sekmeye dokun.
///
/// NEDEN yardımcı: sekme etiketi ekran içeriğinde de geçebilir ("Topluluk" hem sekme hem başlık).
/// Doğrudan `find.text` çift eşleşir ve test, ekranın ortasındaki bir metne dokunur. Bu yardımcı
/// dokunuşu HER ZAMAN çubuğa hedefler. Ayrıca çubuk uygulaması değişirse tek yer güncellenir.
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(AppBottomNav), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Test yüzeyini YÜKSELTİR (800×1400) — uzun ekranlar için.
///
/// NEDEN: varsayılan 800×600 test yüzeyinde uzun ekranların (ödeme, giriş) alt yarısı görünüm
/// alanının dışında kalır; `tap()` ıskalar ve akış hiç çalışmaz. **Genişlik 800'de BIRAKILIR**:
/// testlerin Ahem yazı tipi gerçeğinden geniştir ve daha dar bir yüzeyde cihazda BULUNMAYAN
/// taşmalar üretir (cihazda 393 dp'de taşma yok — Faz 3/4'te doğrulandı).
///
/// `pumpApp`'ten ÖNCE çağrılır; sökme işlemi otomatik kaydedilir.
Future<void> useTallSurface(WidgetTester tester, {Size size = const Size(800, 1400)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Pump the full app with test-safe overrides (no platform channels / network / native drift).
Future<void> pumpApp(
  WidgetTester tester, {
  TokenStore? tokens,
  AuthApi? auth,
  ContentSnapshot? content,
  QuestionBank? bank,
  CoachApi? coach,
  CommunityApi? community,
  SocialApi? social,
  GroupsApi? groups,
  GoogleAuthService? google,

  /// Beta Faz 3 — ödeme ağ geçidi. VARSAYILAN: mağazası KAPALI sahte ağ geçidi (test ortamında
  /// Play Store yoktur; dürüst varsayılan budur). Ödeme akışını test edenler kendi ağ geçidini verir.
  BillingGateway? billing,
  List<String>? owned,
  Map<String, Object>? prefs,
  bool onboardingSeen = true,

  /// Faz E7 — karşılama anı. VARSAYILAN `true`: kişiselleştirmeyi tamamlayan mevcut testler
  /// doğrudan Ana Sayfa'ya iner. Zinciri (tanıtım → karşılama → ana sayfa) test edenler `false` verir.
  bool welcomeSeen = true,

  /// Beta R1 — Ana Sayfa'daki AI karşılama popup'ı. VARSAYILAN `true`: mevcut testler Ana
  /// Sayfa'yı popup engellemeden görür. Popup'ı test edenler `false` verir.
  bool aiWelcomeSeen = true,
  bool overrideContent = true,
  /// Faz E5 — çalışma profili main()'de senkron okunup enjekte edildiği için (onboardingSeen ile
  /// aynı desen), testte de sağlanır. Verilmezse varsayılan profil (B sınıfı) kullanılır.
  StudyProfile? studyProfile,

  /// Faz E6 — hareket azaltma. VARSAYILAN `true`: onboarding'in dönen koç kartı ve süzülen
  /// maskotu kapalı kalır, böylece `pumpAndSettle` sonsuz kare kuyruğuna takılmaz. Dönüşü/animasyonu
  /// test eden testler bunu `false` yapar ve `pump(süre)` ile zamanı elle ilerletir.
  bool reduceMotion = true,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
    disableAnimations: reduceMotion,
  );
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  SharedPreferences.setMockInitialValues(prefs ?? {});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingSeenProvider.overrideWith(() => OnboardingController(onboardingSeen)),
        welcomeSeenProvider.overrideWith(() => WelcomeController(welcomeSeen)),
        aiWelcomeSeenProvider.overrideWith(() => AiWelcomeController(aiWelcomeSeen)),
        if (studyProfile != null)
          studyProfileProvider.overrideWith(() => StudyProfileController(studyProfile)),
        tokenStoreProvider.overrideWithValue(tokens ?? MemoryTokenStore()),
        if (auth != null) authApiProvider.overrideWithValue(auth),
        coachApiProvider.overrideWithValue(coach ?? FakeCoachApi()),
        communityApiProvider.overrideWithValue(community ?? FakeCommunityApi()),
        socialApiProvider.overrideWithValue(social ?? FakeSocialApi()),
        groupsApiProvider.overrideWithValue(groups ?? FakeGroupsApi()),
        googleAuthServiceProvider.overrideWithValue(google ?? FakeGoogleAuthService()),
        billingGatewayProvider.overrideWithValue(billing ?? FakeBillingGateway()),
        entitlementsApiProvider.overrideWithValue(FakeEntitlementsApi(owned ?? const [])),
        // Content + questions come from fixed snapshots in tests → never touch drift/network.
        if (overrideContent) ...[
          contentSnapshotProvider.overrideWith((ref) async => content ?? sampleSnapshot()),
          questionBankProvider.overrideWith((ref) async => bank ?? sampleBank()),
        ],
      ],
      child: const EhliyetAkademiApp(),
    ),
  );
  await tester.pumpAndSettle();
}


/// Faz E10 — çalışma grupları ve meydan okumalar için sahte API.
///
/// Sunucu davranışını TAKLİT ETMEZ, yalnız arayüzün gösterdiği durumları besler. Kural
/// doğrulaması (tavanlar, üyelik, engel) sunucu entegrasyon testlerinde yapılır.
class FakeGroupsApi implements GroupsApi {
  FakeGroupsApi({
    this.groups = const [],
    this.detail,
    this.challenges = const [],
    this.failGroups = false,
    this.failChallenges = false,
    this.joinError,
    this.groupNotFound = false,
  });

  List<StudyGroup> groups;
  GroupDetail? detail;
  List<Challenge> challenges;
  final bool failGroups;
  final bool failChallenges;

  /// Sunucunun döndüreceği hata (ör. "Grup dolu.", "Grup bulunamadı.").
  final String? joinError;
  final bool groupNotFound;

  final List<String> joinedChallenges = [];
  final List<String> leftGroups = [];
  final List<String> deletedGroups = [];
  String? lastJoinCode;
  String? lastCreatedName;

  @override
  Future<List<StudyGroup>> fetchGroups() async {
    if (failGroups) throw CommunityException('Gruplar alınamadı.');
    return groups;
  }

  @override
  Future<StudyGroup> createGroup({required String name, required String licence}) async {
    lastCreatedName = name;
    final g = StudyGroup(
      id: 'g-new',
      name: name,
      licence: licence,
      joinCode: 'ABC234',
      isOwner: true,
      memberCount: 1,
      totalXp: 0,
      totalAnswered: 0,
    );
    groups = [...groups, g];
    return g;
  }

  @override
  Future<GroupDetail?> fetchGroup(String groupId) async {
    if (groupNotFound) return null;
    return detail;
  }

  @override
  Future<StudyGroup> joinByCode(String code) async {
    lastJoinCode = code;
    if (joinError != null) throw CommunityException(joinError!);
    final g = StudyGroup(
      id: 'g-joined',
      name: 'Katıldığım Grup',
      licence: 'b',
      joinCode: code,
      isOwner: false,
      memberCount: 2,
      totalXp: 0,
      totalAnswered: 0,
    );
    groups = [...groups, g];
    return g;
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    leftGroups.add(groupId);
    groups = groups.where((g) => g.id != groupId).toList();
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    deletedGroups.add(groupId);
    groups = groups.where((g) => g.id != groupId).toList();
  }

  @override
  Future<List<Challenge>> fetchChallenges() async {
    if (failChallenges) throw CommunityException('Meydan okumalar alınamadı.');
    return challenges;
  }

  @override
  Future<void> joinChallenge(String challengeId) async {
    joinedChallenges.add(challengeId);
    challenges = challenges
        .map(
          (c) => c.id == challengeId
              ? Challenge(
                  id: c.id,
                  title: c.title,
                  description: c.description,
                  metric: c.metric,
                  target: c.target,
                  joined: true,
                  value: 0,
                  percent: 0,
                  done: false,
                  endsAt: c.endsAt,
                )
              : c,
        )
        .toList();
  }
}


/// Beta Faz 3 — sahte ödeme ağ geçidi. Platform kanalı / Play Store gerekmez.
///
/// Ödeme ekranının bütün koşulları (mağaza kapalı · ürün yok · satın alma · vazgeçme · hata ·
/// geri yükleme · yaşam döngüsü) bununla, gerçek bir mağazaya dokunmadan sınanır.
class FakeBillingGateway implements BillingGateway {
  FakeBillingGateway({
    this.configured = true,
    this.storeAvailable = false,
    this.catalog = const [],
    this.purchaseResult,
    this.restoreResult,
    this.facts = const [],
    this.bridge = BillingServerBridge.clientReceipt,
  });

  /// Mağazası açık, tek ömür boyu ürünü olan hazır bir ağ geçidi.
  factory FakeBillingGateway.withStore({
    String priceLabel = '₺399,00',
    BillingResult? purchaseResult,
    BillingResult? restoreResult,
    List<EntitlementFacts> facts = const [],
    BillingServerBridge bridge = BillingServerBridge.clientReceipt,
  }) => FakeBillingGateway(
    storeAvailable: true,
    catalog: [
      BillingProduct(
        storeProductId: 'komple_ehliyet',
        priceLabel: priceLabel,
        title: 'Komple Ehliyet Paketi',
        period: BillingPeriod.lifetime,
      ),
    ],
    purchaseResult: purchaseResult,
    restoreResult: restoreResult,
    facts: facts,
    bridge: bridge,
  );

  final bool configured;
  final bool storeAvailable;
  final List<BillingProduct> catalog;
  final BillingResult? purchaseResult;
  final BillingResult? restoreResult;
  final List<EntitlementFacts> facts;
  final BillingServerBridge bridge;

  int purchaseCalls = 0;
  int restoreCalls = 0;
  int disposeCalls = 0;
  Future<void> Function(BillingPurchase)? onPurchase;

  @override
  String get name => 'fake';

  @override
  bool get isConfigured => configured;

  @override
  BillingServerBridge get serverBridge => bridge;

  @override
  Future<bool> available() async => storeAvailable;

  @override
  Future<List<BillingProduct>> products() async => storeAvailable ? catalog : const [];

  @override
  Future<BillingResult> purchase(BillingProduct product) async {
    purchaseCalls++;
    return purchaseResult ??
        BillingSuccess([
          BillingPurchase(storeProductId: product.storeProductId, purchaseToken: 'fake-token'),
        ]);
  }

  @override
  Future<BillingResult> restore() async {
    restoreCalls++;
    return restoreResult ?? const BillingSuccess([]);
  }

  @override
  Future<List<EntitlementFacts>> entitlementFacts() async => facts;

  @override
  Future<Set<String>> entitlements() async => {
    for (final f in facts)
      if (f.isActive) f.identifier,
  };

  @override
  void listen(Future<void> Function(BillingPurchase) onPurchase) =>
      this.onPurchase = onPurchase;

  @override
  void dispose() => disposeCalls++;
}

/// Beta Faz 2 — sahte Google servisi. Platform kanalı gerekmez.
class FakeGoogleAuthService implements GoogleAuthService {
  FakeGoogleAuthService({
    this.configured = true,
    this.outcome = const GoogleSignInToken('fake-id-token'),
  });

  final bool configured;
  final GoogleSignInOutcome outcome;
  int signInCalls = 0;
  int signOutCalls = 0;

  @override
  bool get isConfigured => configured;

  @override
  Future<GoogleSignInOutcome> signIn() async {
    signInCalls++;
    return outcome;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}
