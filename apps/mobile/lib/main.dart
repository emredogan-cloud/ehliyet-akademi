import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'domain/onboarding/ai_welcome_controller.dart';
import 'domain/onboarding/onboarding_controller.dart';
import 'domain/onboarding/study_profile.dart';
import 'domain/onboarding/welcome_controller.dart';
import 'domain/video/video_progress.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // İlk açılış tanıtımının durumunu + kişiselleştirme profilini senkron oku → returning
  // kullanıcıda tanıtım/panel flaşı olmaz.
  final onboardingSeen = await readOnboardingSeen();
  final welcomeSeen = await readWelcomeSeen();
  // Beta R1 — Ana Sayfa popup'ı da senkron okunur: dönen kullanıcıda popup flaşı olmaz.
  final aiWelcomeSeen = await readAiWelcomeSeen();
  final studyProfile = await readStudyProfile();
  // Faz E11 — video ilerlemesi/yer imleri açılışta senkron yüklenir (diğer tercihlerle aynı desen).
  final videoStates = await readVideoStates();
  runApp(
    ProviderScope(
      overrides: [
        onboardingSeenProvider.overrideWith(() => OnboardingController(onboardingSeen)),
        welcomeSeenProvider.overrideWith(() => WelcomeController(welcomeSeen)),
        aiWelcomeSeenProvider.overrideWith(() => AiWelcomeController(aiWelcomeSeen)),
        studyProfileProvider.overrideWith(() => StudyProfileController(studyProfile)),
        videoProgressProvider.overrideWith(() => VideoProgressController(videoStates)),
      ],
      child: const EhliyetAkademiApp(),
    ),
  );
}
