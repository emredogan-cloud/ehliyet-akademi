import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/tokens.dart';

import '../features/home/home_screen.dart';
import '../features/learn/learn_screen.dart';
import '../features/learn/lessons_screen.dart';
import '../features/learn/lesson_detail_screen.dart';
import '../features/learn/cabin_control_detail_screen.dart';
import '../features/learn/cabin_controls_screen.dart';
import '../features/learn/dash_lights_screen.dart';
import '../features/learn/signs_screen.dart';
import '../features/learn/sign_detail_screen.dart';
import '../features/learn/vehicle_screen.dart';
import '../features/learn/vehicle_detail_screen.dart';
import '../features/learn/videos_screen.dart';
import '../features/learn/video_detail_screen.dart';
import '../features/practice/practice_screen.dart';
import '../features/practice/practice_runner_screen.dart';
import '../features/practice/exam_runner_screen.dart';
import '../features/practice/collections_screen.dart';
import '../features/practice/historical_screen.dart';
import '../domain/practice/historical.dart';
import '../features/coach/coach_screen.dart';
import '../features/community/blocked_users_screen.dart';
import '../features/community/challenges_screen.dart';
import '../features/community/chat_screen.dart';
import '../features/community/community_screen.dart';
import '../features/community/discussions_screen.dart';
import '../features/community/discussion_thread_screen.dart';
import '../features/community/friends_screen.dart';
import '../features/community/group_detail_screen.dart';
import '../features/community/groups_screen.dart';
import '../features/community/join_community_screen.dart';
import '../features/community/user_profile_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/notification_settings_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/premium/paywall_screen.dart';
import '../features/referral/referral_invite_screen.dart';
import '../features/referral/referral_screen.dart';
import '../data/referral/referral_api.dart';
import '../domain/referral/pending_referral.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/auth/auth_screen.dart';
import '../domain/onboarding/onboarding_controller.dart';
import '../domain/onboarding/welcome_controller.dart';
import 'shell.dart';

/// App routing — a StatefulShellRoute with 5 branches (one per bottom tab), each keeping its own
/// navigation stack. Deep-link friendly (push targets for notifications land here in later phases).
/// Exposed as a provider so each ProviderScope (incl. every test) gets an isolated router — no
/// leaked navigation state between instances.
final routerProvider = Provider<GoRouter>((ref) => _buildRouter(ref));

GoRouter _buildRouter(Ref ref) => GoRouter(
  initialLocation: '/home',
  /// İlk açılış zinciri (Faz E7): **tanıtım → karşılama → ana sayfa**. Sıra tek yerde ve
  /// yukarıdan aşağıya kuruludur; her adım kendi kalıcı işaretini bekler. Tamamlanmış bir adıma
  /// geri dönülmek istenirse ileriye taşınır (geri düşme yok).
  ///
  /// NOT: kişiselleştirmeyi "Atla" ile geçen kullanıcı karşılamayı da görmez — seçmediği değerleri
  /// özetleyen bir ekran göstermek yanıltıcı olurdu (`OnboardingScreen._finish` her iki işareti de koyar).
  redirect: (context, state) {
    // ── Beta Faz 1 — davet derin bağlantısı, tanıtım kapısından ÖNCE yakalanır ────────────────
    //
    // Sıra kritik: `/davet/<KOD>` bağlantısıyla açılan İLK kurulumda kullanıcı henüz tanıtımı
    // görmemiştir ve aşağıdaki kapı onu `/onboarding`'e çevirir. Kod o çevirmeden önce
    // alınmazsa SESSİZCE KAYBOLUR — davet eden ödülünü hiç almaz ve kimse nedenini bilemez.
    //
    // `capture` dinleyicisi olmayan bir kaba yazar (bkz. `PendingReferral`): `redirect` gezinme
    // çözümlenirken çalıştığı için burada durum bildirimi yapmak "build sırasında setState"
    // hatası verirdi.
    final pending = ref.read(pendingReferralProvider);
    final deepLinkCode = referralCodeFromPath(state.uri.path);
    if (deepLinkCode != null) pending.capture(deepLinkCode);

    final onboarded = ref.read(onboardingSeenProvider);
    final welcomed = ref.read(welcomeSeenProvider);
    final loc = state.matchedLocation;
    if (!onboarded) return loc == '/onboarding' ? null : '/onboarding';
    if (!welcomed) return loc == '/welcome' ? null : '/welcome';
    if (loc == '/onboarding' || loc == '/welcome') return '/home';

    // Davet bağlantısıyla gelen kullanıcı, tanıtım turu bittikten sonra Ana Sayfa'ya değil daveti
    // karşılayan ekrana iner. Onun uygulamayı açma sebebi bir davetti; sıradan bir ana sayfa
    // göstermek o sebebi görmezden gelmek olurdu.
    //
    // NEDEN `/home` üzerinden ve tek seferlik: tur bittiğinde `OnboardingScreen` DOĞRUDAN `/home`'a
    // gider, yani burada `/onboarding` konumu artık görünmez (cihazda ölçüldü — gerekçe
    // `PendingReferral.shouldGreet`). Karşılama bir kez gösterilir; `markGreeted` sonrası `/home`
    // bir daha ele geçirilmez.
    if (loc == '/home' && pending.shouldGreet) return '/davet/${pending.code}';
    return null;
  },
  routes: [
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(
      path: '/welcome',
      // Ana sayfaya geçiş "shared axis" hissi versin: solma + hafif ölçek.
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const WelcomeScreen(),
        transitionDuration: AppMotion.slow,
        reverseTransitionDuration: AppMotion.base,
        transitionsBuilder: (context, animation, secondary, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;
          final curved = CurvedAnimation(parent: animation, curve: AppMotion.easeOut);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(curved), child: child),
          );
        },
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/learn',
              builder: (_, _) => const LearnScreen(),
              routes: [
                GoRoute(
                  path: 'lessons',
                  builder: (_, _) => const LessonsScreen(),
                  routes: [
                    GoRoute(
                      path: ':slug',
                      builder: (_, state) => LessonDetailScreen(slug: state.pathParameters['slug']!),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'signs',
                  builder: (_, _) => const SignsScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (_, state) => SignDetailScreen(id: state.pathParameters['id']!),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'cabin',
                  builder: (_, _) => const CabinControlsScreen(),
                  routes: [
                    GoRoute(
                      path: ':asset',
                      builder: (_, st) =>
                          CabinControlDetailScreen(asset: st.pathParameters['asset']!),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'lights',
                  builder: (_, _) => const DashLightsScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (_, state) => DashLightDetailScreen(id: state.pathParameters['id']!),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'vehicle',
                  builder: (_, _) => const VehicleScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (_, state) => VehicleDetailScreen(id: state.pathParameters['id']!),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'videos',
                  builder: (_, _) => const VideosScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (_, state) => VideoDetailScreen(id: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/practice',
              builder: (_, _) => const PracticeScreen(),
              routes: [
                GoRoute(path: 'study', builder: (_, _) => const PracticeRunnerScreen()),
                GoRoute(
                  path: 'exam',
                  builder: (_, _) =>
                      const ExamRunnerScreen(source: ExamSource.standard, titleText: 'Deneme Sınavı'),
                ),
                GoRoute(path: 'collections', builder: (_, _) => const CollectionsScreen()),
                GoRoute(
                  path: 'collection/:id',
                  builder: (_, state) => ExamRunnerScreen(
                    source: ExamSource.collection,
                    id: state.pathParameters['id'],
                    titleText: 'Koleksiyon',
                  ),
                ),
                GoRoute(path: 'historical', builder: (_, _) => const HistoricalScreen()),
                GoRoute(
                  path: 'historical/:id',
                  builder: (_, state) {
                    final id = state.pathParameters['id']!;
                    return ExamRunnerScreen(
                      source: ExamSource.historical,
                      id: id,
                      titleText: historicalSessionById(id)?.label ?? 'Geçmiş Sınav',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/coach', builder: (_, _) => const CoachScreen())],
        ),
        // Faz 4 — Topluluk artık KENDİ dalıdır (alt gezinmede birinci sınıf sekme).
        //
        // NEDEN taşındı: Profil'in altındayken topluluk, bir "ayar" gibi görünüyor ve kendi
        // gezinme yığınını Profil'le paylaşıyordu — bir tartışmadan Profil sekmesine geçip geri
        // dönmek kullanıcıyı tartışmanın ortasına düşürüyordu. Ayrı dal, her sekmenin kendi
        // yığınını koruması demektir; yerel uygulamalarda beklenen davranış budur.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/community',
              builder: (_, _) => const CommunityScreen(),
              routes: [
                GoRoute(path: 'join', builder: (_, _) => const JoinCommunityScreen()),
                GoRoute(
                  path: 'user/:id',
                  builder: (_, state) => CommunityUserScreen(userId: state.pathParameters['id']!),
                ),
                // Faz E9 — sosyal grafik yüzeyleri.
                GoRoute(path: 'blocked', builder: (_, _) => const BlockedUsersScreen()),
                GoRoute(path: 'friends', builder: (_, _) => const FriendsScreen()),
                // Faz E10 — çalışma grupları ve meydan okumalar.
                GoRoute(
                  path: 'groups',
                  builder: (_, _) => const GroupsScreen(),
                  routes: [
                    GoRoute(
                      path: ':groupId',
                      builder: (_, state) =>
                          GroupDetailScreen(groupId: state.pathParameters['groupId']!),
                    ),
                  ],
                ),
                GoRoute(path: 'challenges', builder: (_, _) => const ChallengesScreen()),
                GoRoute(path: 'messages', builder: (_, _) => const ChatListScreen()),
                GoRoute(
                  path: 'chat/:id',
                  builder: (_, state) => ChatScreen(userId: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'discussions',
                  builder: (_, _) => const DiscussionsScreen(),
                  routes: [
                    GoRoute(
                      path: ':threadId',
                      builder: (_, state) =>
                          DiscussionThreadScreen(threadId: state.pathParameters['threadId']!),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())],
        ),
      ],
    ),
    // Full-screen over the tab shell (login/register).
    //
    // `?kayit=1` → ekran doğrudan KAYIT kipinde açılır. Davet ekranından gelen kullanıcının işi
    // hesap açmaktır; ona giriş sekmesini gösterip bir dokunuş daha istemek gereksiz.
    GoRoute(
      path: '/auth',
      builder: (_, state) =>
          AuthScreen(startInRegister: state.uri.queryParameters['kayit'] == '1'),
    ),
    GoRoute(path: '/notifications', builder: (_, _) => const NotificationSettingsScreen()),
    GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
    // `?from=` — ödeme ekranına HANGİ yüzeyden gelindiği. Ekran bunu kendisi bilemez; sekme
    // kabuğunda bu geçişler rota itmediği için bir gezinme gözlemcisi de göremez.
    GoRoute(
      path: '/premium',
      builder: (_, state) =>
          PaywallScreen(source: state.uri.queryParameters['from'] ?? 'unknown'),
    ),
    GoRoute(path: '/davet', builder: (_, _) => const ReferralScreen()),
    // Beta Faz 1 — davet derin bağlantısının indiği yer.
    //
    // `/davet`in ALT rotası DEĞİL, KARDEŞİ: alt rota olsaydı go_router soğuk açılışta yığını
    // `/davet` → `/davet/<KOD>` diye kurardı ve geri tuşu, yeni kullanıcıyı "önce giriş yap"
    // diyen kendi davet ekranına düşürürdü. Kardeş rota kendi başına durur.
    GoRoute(
      path: '/davet/:code',
      builder: (_, state) =>
          ReferralInviteScreen(code: normalizeReferralCode(state.pathParameters['code']!)),
    ),
  ],
);
