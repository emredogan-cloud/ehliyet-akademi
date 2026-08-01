import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/asset_resolver.dart';
import 'data/duel/duel_energy_repository.dart';
import 'core/analytics/analytics.dart';
import 'core/analytics/analytics_sink.dart';
import 'core/network/api_client.dart';
import 'core/observability/error_report.dart';
import 'core/observability/error_reporter.dart';
import 'core/storage/token_store.dart';
import 'domain/onboarding/ai_welcome_controller.dart';
import 'domain/onboarding/coach_marks_controller.dart';
import 'domain/onboarding/onboarding_controller.dart';
import 'domain/onboarding/study_profile.dart';
import 'domain/onboarding/welcome_controller.dart';
import 'domain/referral/pending_referral.dart';
import 'domain/video/video_progress.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // İlk açılış tanıtımının durumunu + kişiselleştirme profilini senkron oku → returning
  // kullanıcıda tanıtım/panel flaşı olmaz.
  final onboardingSeen = await readOnboardingSeen();
  final welcomeSeen = await readWelcomeSeen();
  // Beta R1 — Ana Sayfa popup'ı da senkron okunur: dönen kullanıcıda popup flaşı olmaz.
  final aiWelcomeSeen = await readAiWelcomeSeen();
  // Faz 1 — ürün turu da senkron okunur: dönen kullanıcıda karartma flaşı olmaz.
  final coachMarksSeen = await readCoachMarksSeen();
  final studyProfile = await readStudyProfile();
  // Faz E11 — video ilerlemesi/yer imleri açılışta senkron yüklenir (diğer tercihlerle aynı desen).
  final videoStates = await readVideoStates();
  // Beta Faz 1 — önceki açılıştan kalmış davet kodu. Yönlendirici derin bağlantı gelmeden ÖNCE
  // buna bakabilmeli: uygulamayı davet bağlantısıyla kurup kaydı sonra yapan kullanıcının kodu
  // ancak böyle korunur.
  final pendingReferralCode = await PendingReferral.read();

  // Ürün Evrimi v1.1 · Faz 3 — paketteki varlık listesi bir kez okunur.
  //
  // `AssetCatalog` Post-Beta'da yazılmıştı ama HİÇBİR YERDEN çağrılmıyordu; denetimde bu çıktı.
  // Buradan yüklendiğinde `TrafficSignView` gibi senkron çizen widget'lar "bu dosya gerçekten
  // pakette var mı?" sorusunu sorabiliyor ve ayrılmış ama henüz üretilmemiş bir levha adına
  // düşüp kırık görsel çizmiyorlar.
  await AssetCatalog.load();

  // Faz 4 — düello enerjisi (günlük hak + bekleme) senkron okunabilsin diye açılışta yüklenir.
  await initDuelEnergyStorage();

  // ── Beta Faz 4 — gözlemlenebilirlik, uygulamadan ÖNCE kurulur ────────────────────────────────
  //
  // Sıra kritik: `installErrorHandlers` içinde `runZonedGuarded` var ve `runApp` onun İÇİNDE
  // çalışmak zorunda. Dışarıda çalıştırılırsa bölge hiçbir şey yakalamaz.
  //
  // Dairesel bağımlılık burada çözülür: raportör ağ istemcisine (dio) ihtiyaç duyar, dio ise ağ
  // hatalarını raportöre bildirmek ister. İkisi de sağlayıcı kapsamı dışında, elle kurulur ve
  // sonra sağlayıcılara ENJEKTE edilir — böylece ne dairesel bir sağlayıcı grafiği doğar ne de
  // ikinci bir dio örneği ortaya çıkar.
  late final ErrorReporter reporter;
  ProviderContainer? containerRef;

  final tokens = SecureTokenStore();
  final dio = buildDio(
    tokens,
    onNetworkFailure: (e) => reporter.report(e, e.stackTrace, kind: ErrorKind.network).ignore(),
  );
  final analytics = Analytics(
    sink: kDebugMode
        ? FanOutAnalyticsSink([DebugAnalyticsSink(), RemoteAnalyticsSink(dio)])
        : RemoteAnalyticsSink(dio),
  );
  reporter = ErrorReporter(
    dio: dio,
    analytics: analytics,
    // Rota, hatanın NEREDE olduğunu söyler. Yönlendirici sağlayıcıdan okunur ama raportör
    // kapsamdan önce kurulduğu için değer bir kapanışla, ihtiyaç anında alınır.
    currentRoute: () {
      try {
        return containerRef?.read(routerProvider).routerDelegate.currentConfiguration.uri.path ??
            '';
      } catch (_) {
        return '';
      }
    },
  );

  final container = ProviderContainer(
    overrides: [
      onboardingSeenProvider.overrideWith(() => OnboardingController(onboardingSeen)),
      welcomeSeenProvider.overrideWith(() => WelcomeController(welcomeSeen)),
      aiWelcomeSeenProvider.overrideWith(() => AiWelcomeController(aiWelcomeSeen)),
      coachMarksSeenProvider.overrideWith(() => CoachMarksController(coachMarksSeen)),
      studyProfileProvider.overrideWith(() => StudyProfileController(studyProfile)),
      videoProgressProvider.overrideWith(() => VideoProgressController(videoStates)),
      pendingReferralProvider.overrideWithValue(PendingReferral(initial: pendingReferralCode)),
      // Analitik, ağ istemcisi ve raportör TEK örnek olarak paylaşılır.
      //
      // Hata ayıklama derlemesinde olaylar konsola da yazılır; bir olayın gerçekten gönderildiğini
      // görmenin en hızlı yolu budur ve üretim derlemesine sızmaz (`kDebugMode`).
      tokenStoreProvider.overrideWithValue(tokens),
      dioProvider.overrideWithValue(dio),
      analyticsProvider.overrideWithValue(analytics),
      errorReporterProvider.overrideWithValue(reporter),
    ],
  );
  containerRef = container;

  // Önceki oturumdan kalan raporlar (çökmeden hemen önce yazılıp gönderilememiş olanlar) şimdi
  // gönderilir. Çökme ağı da götürmüş olabilir; kuyruk tam bunun için var.
  reporter.flush().ignore();

  installErrorHandlers(
    reporter,
    () => runApp(
      UncontrolledProviderScope(container: container, child: const EhliyetAkademiApp()),
    ),
  );
}
