import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/learn/learn_screen.dart';
import '../features/practice/practice_screen.dart';
import '../features/coach/coach_screen.dart';
import '../features/profile/profile_screen.dart';
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
          routes: [GoRoute(path: '/learn', builder: (_, _) => const LearnScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/practice', builder: (_, _) => const PracticeScreen())],
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
  ],
);
