import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics/analytics.dart';
import '../core/analytics/analytics_event.dart';
import '../core/analytics/analytics_ref.dart';
import '../core/theme/app_theme.dart';
import '../data/premium/entitlements_repository.dart';
import '../core/theme/theme_controller.dart';
import '../design/app_background.dart';
import '../domain/auth/auth_controller.dart';
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
      builder: (context, child) => _AnalyticsBootstrap(
        child: _EntitlementsBootstrap(
          child: AppBackground(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// Beta Faz 3 — açılış olaylarını gönderir ve oturum kimliğini analitiğe bağlar.
///
/// NEDEN burada (kökte): açılış olayları bir EKRANA bağlanamaz. Ana Sayfa'ya bağlansaydı, derin
/// bağlantıyla davet ekranında açılan oturum hiç sayılmazdı.
class _AnalyticsBootstrap extends ConsumerStatefulWidget {
  const _AnalyticsBootstrap({required this.child});
  final Widget child;

  @override
  ConsumerState<_AnalyticsBootstrap> createState() => _AnalyticsBootstrapState();
}

class _AnalyticsBootstrapState extends ConsumerState<_AnalyticsBootstrap> {
  @override
  void initState() {
    super.initState();
    // `addPostFrameCallback`: ilk kare çizilmeden önce analitik kurulumu yapmak açılışı geciktirir.
    // Ölçüm, ölçtüğü şeyi yavaşlatmamalı.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final analytics = ref.read(analyticsProvider);
    await analytics.ensureContext();

    /// `app_installed` ve `first_launch` ilk açılışta AYNI ANDA gider — bu bilinçli.
    ///
    /// Kurulup hiç açılmayan bir uygulamayı istemciden görmek MÜMKÜN DEĞİLDİR; o sayı yalnız Play
    /// Console'da vardır. Bu yüzden ikisi istemcide aynı anı işaretler: biri "bu cihazda kurulum"
    /// (huninin tabanı), diğeri "ilk oturum". Ayrı tutulmaları, ileride Play Install Referrer
    /// verisi bağlandığında kurulum ile ilk açılış arasındaki farkın ölçülebilmesi içindir.
    await analytics.logOnce(AnalyticsEvent.installed);
    await analytics.logOnce(AnalyticsEvent.firstLaunch);
    await analytics.log(AnalyticsEvent.appOpened);
    // Önceki oturumdan kalan kuyruk (çevrimdışıyken biriken olaylar) şimdi boşaltılır.
    await analytics.flush();
  }

  /// Bu uygulama oturumunda misafir kullanım zaten sayıldı mı.
  ///
  /// Oturum durumu `unknown` → `guest` → (belki) `authenticated` diye ilerler ve bu widget her
  /// değişimde yeniden çizilir. İşaret olmasaydı olay her çizimde tekrar giderdi.
  bool _guestCounted = false;

  @override
  Widget build(BuildContext context) {
    // Oturum değiştiğinde analitiğin kimliği de değişir. Çıkışta `null` verilir: aynı cihazdaki
    // ikinci kullanıcının olayları birincinin kimliğine yazılmaz.
    final auth = ref.watch(authControllerProvider);
    ref.read(analyticsProvider).setUser(auth.user?.id);

    /// Misafir kullanım — uygulama oturumu başına BİR KEZ.
    ///
    /// `AuthStatus.unknown` beklenir: jeton diskten okunana kadar herkes "misafir" görünür ve o
    /// anda saymak, oturumu AÇIK olan her kullanıcıyı da misafir olarak sayardı. `guest` durumu
    /// ancak okuma bittikten sonra kurulur.
    ///
    /// Kalıcı DEĞİL (`track`, `trackOnce` değil): "kaç kişi hesapsız kullanıyor" sorusu her açılış
    /// için sorulur; cihaz ömründe bir kez sayılsaydı düzenli misafir kullanımı görünmezdi.
    if (!_guestCounted && auth.status == AuthStatus.guest) {
      _guestCounted = true;
      ref.track(AnalyticsEvent.guestSession);
    }
    return widget.child;
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
