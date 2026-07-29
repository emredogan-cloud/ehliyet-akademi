import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../data/premium/entitlements_repository.dart';
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
      builder: (context, child) => _EntitlementsBootstrap(
        child: AppBackground(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

/// Faz 2 — sahiplik durumunu uygulama açılışında CANLI tutar.
///
/// NEDEN GEREKLİ: `entitlementsProvider` tembeldi; ilk kez ödeme ekranı açıldığında kuruluyordu.
/// Bu, bekleyen bir makbuzun (misafirken alınmış, sunucuya bağlanamamış satın alma) yalnız
/// kullanıcı ödeme ekranına GİRERSE sunucuya bağlanması demekti — girmezse satın alma o cihazda
/// mahsur kalıyordu. Burada bir kez izlenerek sağlayıcı açılışta kurulur; kuyruk kendiliğinden
/// boşalır.
///
/// Maliyeti yok denecek kadar az: yalnız bu sarmalayıcı yeniden kurulur, alt ağaç `child` olarak
/// geçtiği için yeniden İNŞA EDİLMEZ.
class _EntitlementsBootstrap extends ConsumerWidget {
  const _EntitlementsBootstrap({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(entitlementsProvider);
    return child;
  }
}
