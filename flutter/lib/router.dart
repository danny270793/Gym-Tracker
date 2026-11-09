import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_session_notifier.dart';
import 'core/di/injection.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/exercise_detail_page.dart';
import 'pages/exercise_editor_page.dart';
import 'pages/exercise_progress_page.dart';
import 'pages/exercises_page.dart';
import 'pages/home_shell.dart';
import 'pages/legal_info_page.dart';
import 'pages/plan_page.dart';
import 'pages/routine_editor_page.dart';
import 'pages/settings_page.dart';
import 'pages/splash_page.dart';
import 'pages/workout_session_page.dart';
import 'pages/workouts_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  final session = getIt<AuthSessionNotifier>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) {
      final signedIn = session.isSignedIn;
      final loc = state.matchedLocation;
      if (loc == '/') return signedIn ? '/dashboard' : '/login';
      if (!signedIn && loc != '/login') return '/login';
      if (signedIn && loc == '/login') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workouts',
                builder: (context, state) => const WorkoutsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plan',
                builder: (context, state) => const PlanPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/exercises',
                builder: (context, state) => const ExercisesPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/workout/:id',
        builder: (context, state) =>
            WorkoutSessionPage(workoutId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/routine/new',
        builder: (context, state) => RoutineEditorPage(
          assignToWeekday: int.tryParse(
            state.uri.queryParameters['weekday'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/routine/:id',
        builder: (context, state) =>
            RoutineEditorPage(routineId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/exercise/new',
        builder: (context, state) => const ExerciseEditorPage(),
      ),
      GoRoute(
        path: '/exercise/:id',
        builder: (context, state) =>
            ExerciseDetailPage(exerciseId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) =>
                ExerciseEditorPage(exerciseId: state.pathParameters['id']),
          ),
          GoRoute(
            path: 'progress',
            builder: (context, state) =>
                ExerciseProgressPage(exerciseId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'about',
            builder: (context, state) =>
                const LegalInfoPage(kind: LegalInfoKind.about),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) =>
                const LegalInfoPage(kind: LegalInfoKind.privacy),
          ),
          GoRoute(
            path: 'terms',
            builder: (context, state) =>
                const LegalInfoPage(kind: LegalInfoKind.terms),
          ),
        ],
      ),
    ],
  );
}
