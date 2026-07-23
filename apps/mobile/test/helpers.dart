import 'package:ehliyet_akademi/app/app.dart';
import 'package:ehliyet_akademi/core/storage/token_store.dart';
import 'package:ehliyet_akademi/data/auth/auth_api.dart';
import 'package:ehliyet_akademi/data/coach/coach_api.dart';
import 'package:ehliyet_akademi/data/content/content_repository.dart';
import 'package:ehliyet_akademi/data/practice/question_repository.dart';
import 'package:ehliyet_akademi/data/premium/entitlements_repository.dart';
import 'package:ehliyet_akademi/domain/auth/app_user.dart';
import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/content/content_snapshot.dart';
import 'package:ehliyet_akademi/domain/content/lesson.dart';
import 'package:ehliyet_akademi/domain/content/traffic_sign.dart';
import 'package:ehliyet_akademi/domain/content/vehicle_part.dart';
import 'package:ehliyet_akademi/domain/content/video_content.dart';
import 'package:ehliyet_akademi/domain/onboarding/onboarding_controller.dart';
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
    VideoContent(
      id: 'planned-video',
      title: 'Yakında Video',
      description: 'Henüz hazır değil.',
      status: 'planned',
    ),
  ],
);

/// A fake CoachApi for tests — no network. Returns a fixed grounded answer.
class FakeCoachApi implements CoachApi {
  FakeCoachApi({this.answer = 'Kırmızı ışıkta durulur.', this.grounded = true});
  final String answer;
  final bool grounded;
  int calls = 0;
  String? lastQuestion;

  @override
  Future<CoachAnswer> ask(String question, {String? context}) async {
    calls++;
    lastQuestion = question;
    return CoachAnswer(answer: answer, grounded: grounded, sources: const ['trafik'], model: 'mock');
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

/// Pump the full app with test-safe overrides (no platform channels / network / native drift).
Future<void> pumpApp(
  WidgetTester tester, {
  TokenStore? tokens,
  AuthApi? auth,
  ContentSnapshot? content,
  QuestionBank? bank,
  CoachApi? coach,
  List<String>? owned,
  Map<String, Object>? prefs,
  bool onboardingSeen = true,
  bool overrideContent = true,
}) async {
  SharedPreferences.setMockInitialValues(prefs ?? {});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingSeenProvider.overrideWith(() => OnboardingController(onboardingSeen)),
        tokenStoreProvider.overrideWithValue(tokens ?? MemoryTokenStore()),
        if (auth != null) authApiProvider.overrideWithValue(auth),
        coachApiProvider.overrideWithValue(coach ?? FakeCoachApi()),
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
