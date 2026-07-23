import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/learn/learn_screen.dart';
import '../features/learn/lessons_screen.dart';
import '../features/learn/lesson_detail_screen.dart';
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
import '../features/profile/profile_screen.dart';
import '../features/profile/notification_settings_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/auth/auth_screen.dart';
import 'shell.dart';

/// App routing — a StatefulShellRoute with 5 branches (one per bottom tab), each keeping its own
/// navigation stack. Deep-link friendly (push targets for notifications land here in later phases).
/// Exposed as a provider so each ProviderScope (incl. every test) gets an isolated router — no
/// leaked navigation state between instances.
final routerProvider = Provider<GoRouter>((ref) => _buildRouter());

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/home',
  routes: [
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
          routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())],
        ),
      ],
    ),
    // Full-screen over the tab shell (login/register).
    GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
    GoRoute(path: '/notifications', builder: (_, _) => const NotificationSettingsScreen()),
    GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
  ],
);
