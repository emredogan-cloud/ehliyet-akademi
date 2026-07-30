import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/analytics/analytics.dart';
import 'core/analytics/analytics_sink.dart';
import 'core/network/api_client.dart';
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

  runApp(
    ProviderScope(
      overrides: [
        onboardingSeenProvider.overrideWith(() => OnboardingController(onboardingSeen)),
        welcomeSeenProvider.overrideWith(() => WelcomeController(welcomeSeen)),
        aiWelcomeSeenProvider.overrideWith(() => AiWelcomeController(aiWelcomeSeen)),
        coachMarksSeenProvider.overrideWith(() => CoachMarksController(coachMarksSeen)),
        studyProfileProvider.overrideWith(() => StudyProfileController(studyProfile)),
        videoProgressProvider.overrideWith(() => VideoProgressController(videoStates)),
        pendingReferralProvider.overrideWithValue(
          PendingReferral(initial: pendingReferralCode),
        ),
        // Beta Faz 3 — gerçek analitik: olaylar diske kuyruklanır, ağ geldiğinde toplu gönderilir.
        //
        // Hata ayıklama derlemesinde konsola da yazılır; bir olayın gerçekten gönderildiğini
        // görmenin en hızlı yolu budur ve üretim derlemesine sızmaz (`kDebugMode`).
        analyticsProvider.overrideWith((ref) {
          final remote = RemoteAnalyticsSink(ref.watch(dioProvider));
          return Analytics(
            sink: kDebugMode
                ? FanOutAnalyticsSink([DebugAnalyticsSink(), remote])
                : remote,
          );
        }),
      ],
      child: const EhliyetAkademiApp(),
    ),
  );
}
