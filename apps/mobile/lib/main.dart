import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'domain/onboarding/onboarding_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // İlk açılış tanıtımının durumunu senkron oku → returning kullanıcıda tanıtım flaşı olmaz.
  final onboardingSeen = await readOnboardingSeen();
  runApp(
    ProviderScope(
      overrides: [
        onboardingSeenProvider.overrideWith(() => OnboardingController(onboardingSeen)),
      ],
      child: const EhliyetAkademiApp(),
    ),
  );
}
