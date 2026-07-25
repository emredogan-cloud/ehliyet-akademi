import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/tokens.dart';

import '../features/home/home_screen.dart';
import '../features/learn/learn_screen.dart';
import '../features/learn/lessons_screen.dart';
import '../features/learn/lesson_detail_screen.dart';
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
import '../features/community/community_screen.dart';
import '../features/community/join_community_screen.dart';
import '../features/community/user_profile_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/notification_settings_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/premium/paywall_screen.dart';
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
    final onboarded = ref.read(onboardingSeenProvider);
    final welcomed = ref.read(welcomeSeenProvider);
    final loc = state.matchedLocation;
    if (!onboarded) return loc == '/onboarding' ? null : '/onboarding';
    if (!welcomed) return loc == '/welcome' ? null : '/welcome';
    if (loc == '/onboarding' || loc == '/welcome') return '/home';
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const ProfileScreen(),
              routes: [
                // Topluluk, Profil dalının altındadır: kimlik ve sosyal ayarlar oraya aittir.
                // (Alt gezinme çubuğuna 6. sekme EKLENMEDİ — beş sekme zaten dar ekranlarda sınırda.)
                GoRoute(
                  path: 'community',
                  builder: (_, _) => const CommunityScreen(),
                  routes: [
                    GoRoute(path: 'join', builder: (_, _) => const JoinCommunityScreen()),
                    GoRoute(
                      path: 'user/:id',
                      builder: (_, state) =>
                          CommunityUserScreen(userId: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // Full-screen over the tab shell (login/register).
    GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
    GoRoute(path: '/notifications', builder: (_, _) => const NotificationSettingsScreen()),
    GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
    GoRoute(path: '/premium', builder: (_, _) => const PaywallScreen()),
  ],
);
