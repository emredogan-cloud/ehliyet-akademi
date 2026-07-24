import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'domain/onboarding/onboarding_controller.dart';
import 'domain/onboarding/study_profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // İlk açılış tanıtımının durumunu + kişiselleştirme profilini senkron oku → returning
  // kullanıcıda tanıtım/panel flaşı olmaz.
  final onboardingSeen = await readOnboardingSeen();
  final studyProfile = await readStudyProfile();
  runApp(
    ProviderScope(
      overrides: [
        onboardingSeenProvider.overrideWith(() => OnboardingController(onboardingSeen)),
        studyProfileProvider.overrideWith(() => StudyProfileController(studyProfile)),
      ],
      child: const EhliyetAkademiApp(),
    ),
  );
}
