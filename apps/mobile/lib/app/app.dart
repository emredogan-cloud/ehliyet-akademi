import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../design/app_background.dart';
import 'router.dart';

/// Root application widget — themed (light+dark), router-driven.
class EhliyetAkademiApp extends ConsumerWidget {
  const EhliyetAkademiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Ehliyet Akademi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      // Faz 6 — canlı zemin, yönlendiricinin ÜSTÜNDE bir kez kurulur.
      //
      // NEDEN burada: her ekrana ayrı ayrı konsaydı sayfa geçişinde zemin sökülüp yeniden
      // kurulurdu ve hareket her geçişte başa sararak "zıplardı". Burada tek örnek vardır;
      // sayfalar onun üstünde gelip geçer, zemin akmaya devam eder.
      builder: (context, child) => AppBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}
