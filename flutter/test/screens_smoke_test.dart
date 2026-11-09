import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/auth/auth_session_notifier.dart';
import 'package:gym_tracker/core/di/injection.dart';
import 'package:gym_tracker/core/storage/local_json_store.dart';
import 'package:gym_tracker/features/exercises/data/datasources/exercises_remote_datasource.dart';
import 'package:gym_tracker/features/exercises/domain/entities/muscle_group.dart';
import 'package:gym_tracker/features/plan/data/datasources/plan_remote_datasource.dart';
import 'package:gym_tracker/features/workouts/data/datasources/workouts_remote_datasource.dart';
import 'package:gym_tracker/features/exercises/domain/repositories/exercises_repository.dart';
import 'package:gym_tracker/features/exercises/presentation/cubit/exercises_cubit.dart';
import 'package:gym_tracker/features/plan/domain/entities/routine_entity.dart';
import 'package:gym_tracker/features/plan/domain/repositories/plan_repository.dart';
import 'package:gym_tracker/features/plan/presentation/cubit/plan_cubit.dart';
import 'package:gym_tracker/features/workouts/domain/repositories/workouts_repository.dart';
import 'package:gym_tracker/features/workouts/presentation/cubit/workouts_cubit.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:gym_tracker/pages/dashboard_page.dart';
import 'package:gym_tracker/pages/exercise_detail_page.dart';
import 'package:gym_tracker/pages/exercise_editor_page.dart';
import 'package:gym_tracker/pages/exercise_progress_page.dart';
import 'package:gym_tracker/pages/exercises_page.dart';
import 'package:gym_tracker/pages/plan_page.dart';
import 'package:gym_tracker/pages/routine_editor_page.dart';
import 'package:gym_tracker/pages/workout_session_page.dart';
import 'package:gym_tracker/pages/workouts_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_remotes.dart';
import 'test_data.dart';

class _User with CurrentUser {
  @override
  String? get userId => 'tester';
}

void main() {
  late Directory tmp;
  late ExercisesCubit exercises;
  late PlanCubit plan;
  late WorkoutsCubit workouts;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('gym_tracker_smoke');
    getIt.allowReassignment = true;
    setupDi(store: LocalJsonStore(tmp));
    getIt.registerSingleton<CurrentUser>(_User());
    final server = FakeServer();
    getIt.registerSingleton<ExercisesRemoteDatasource>(
      FakeExercisesRemote(server),
    );
    getIt.registerSingleton<PlanRemoteDatasource>(FakePlanRemote(server));
    getIt.registerSingleton<WorkoutsRemoteDatasource>(
      FakeWorkoutsRemote(server),
    );

    final now = DateTime.now();
    await getIt<ExercisesRepository>().save(
      exercise(
        'press',
        primary: const [MuscleGroup.chest],
        secondary: const [MuscleGroup.triceps],
      ),
    );
    await getIt<ExercisesRepository>().save(
      exercise('pushdown', primary: const [MuscleGroup.triceps]),
    );
    await getIt<PlanRepository>().saveRoutine(
      RoutineEntity(
        id: 'push',
        title: 'Push',
        exercises: const [
          PlannedExercise(exerciseId: 'press', sets: 3, reps: 8),
          PlannedExercise(exerciseId: 'pushdown', sets: 3, reps: 12),
        ],
        createdAt: epoch,
        updatedAt: epoch,
      ),
    );
    await getIt<PlanRepository>().setDay(now.weekday, 'push');
    for (var i = 0; i < 6; i++) {
      final d = now.subtract(Duration(days: 7 * i));
      await getIt<WorkoutsRepository>().save(
        workout('w$i', d, {
          'press': [done(8, 50.0 - i * 2.5), done(8, 50.0 - i * 2.5)],
          'pushdown': [done(12, 30)],
        }, finishedAt: d.add(const Duration(hours: 1))),
      );
    }
    exercises = getIt<ExercisesCubit>();
    plan = getIt<PlanCubit>();
    workouts = getIt<WorkoutsCubit>();
    await Future.wait([exercises.load(), plan.load(), workouts.load()]);
  });

  tearDownAll(() => tmp.delete(recursive: true));

  Future<void> pumpPage(WidgetTester tester, Widget page, Locale locale) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: exercises),
          BlocProvider.value(value: plan),
          BlocProvider.value(value: workouts),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true),
          home: page,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  final pages = <String, Widget Function()>{
    'dashboard': () => const DashboardPage(),
    'workouts': () => const WorkoutsPage(),
    'plan': () => const PlanPage(),
    'exercises': () => const ExercisesPage(),
    'session': () => const WorkoutSessionPage(workoutId: 'w0'),
    'routine editor': () => const RoutineEditorPage(routineId: 'push'),
    'exercise editor': () => const ExerciseEditorPage(exerciseId: 'press'),
    'exercise detail': () => const ExerciseDetailPage(exerciseId: 'press'),
    'exercise progress': () => const ExerciseProgressPage(exerciseId: 'press'),
  };

  for (final locale in const [Locale('en'), Locale('es')]) {
    for (final e in pages.entries) {
      testWidgets('${e.key} renders (${locale.languageCode})', (tester) async {
        await pumpPage(tester, e.value(), locale);
        expect(tester.takeException(), isNull);
        expect(find.byType(Scaffold), findsWidgets);
      });
    }
  }

  testWidgets('dashboard shows this week and personal records', (tester) async {
    await pumpPage(tester, const DashboardPage(), const Locale('en'));
    expect(find.text('This week'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Personal records'), 300);
    expect(find.text('Personal records'), findsOneWidget);
  });

  testWidgets('workouts page shows today as done (seeded workout today)', (
    tester,
  ) async {
    await pumpPage(tester, const WorkoutsPage(), const Locale('en'));
    expect(find.text('Done for today. Nice work!'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
  });
}
