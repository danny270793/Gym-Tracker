import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/date/week.dart';
import 'package:gym_tracker/core/units/app_weight_unit_controller.dart';
import 'package:gym_tracker/features/dashboard/domain/usecases/compute_dashboard_stats_usecase.dart';
import 'package:gym_tracker/features/dashboard/domain/usecases/compute_exercise_progress_usecase.dart';
import 'package:gym_tracker/features/exercises/domain/entities/load_type.dart';
import 'package:gym_tracker/features/exercises/domain/entities/muscle_group.dart';
import 'package:gym_tracker/features/plan/domain/entities/weekly_plan_entity.dart';
import 'package:gym_tracker/features/workouts/domain/entities/workout_entity.dart';

import 'test_data.dart';

void main() {
  // Wednesday.
  final now = DateTime(2026, 3, 11, 20);

  test('week helpers start on Monday', () {
    expect(startOfWeek(now), DateTime(2026, 3, 9));
    expect(startOfWeek(DateTime(2026, 3, 15, 23)), DateTime(2026, 3, 9));
    expect(addDays(DateTime(2026, 3, 9), -7), DateTime(2026, 3, 2));
  });

  test('e1RM (Epley)', () {
    expect(estimatedOneRepMax(100, 1), 100);
    expect(estimatedOneRepMax(100, 10), closeTo(133.33, 0.01));
    expect(estimatedOneRepMax(0, 10), 0);
  });

  test('weekly totals, delta inputs, streak, muscles, plan', () {
    final workouts = [
      // This week.
      workout('w1', DateTime(2026, 3, 9, 18), {
        'press': [
          done(8, 50),
          done(8, 50),
          const WorkoutSet(reps: 8, load: 50),
        ],
      }, finishedAt: DateTime(2026, 3, 9, 19)),
      // Last week.
      workout('w0', DateTime(2026, 3, 3, 18), {
        'press': [done(8, 45)],
      }, finishedAt: DateTime(2026, 3, 3, 19, 30)),
      // Two weeks ago.
      workout('w-1', DateTime(2026, 2, 24), {
        'press': [done(8, 40)],
      }),
      // Gap week, then older: not part of the streak.
      workout('w-3', DateTime(2026, 2, 10), {
        'press': [done(8, 40)],
      }),
    ];
    final stats = const ComputeDashboardStatsUsecase()(
      workouts: workouts,
      exercises: [
        exercise(
          'press',
          primary: const [MuscleGroup.chest],
          secondary: const [MuscleGroup.triceps],
        ),
      ],
      weeklyPlan: const WeeklyPlanEntity(routineIdByWeekday: {1: 'a', 4: 'b'}),
      now: now,
    );
    expect(stats.thisWeek.workouts, 1);
    expect(stats.thisWeek.sets, 2);
    expect(stats.thisWeek.reps, 16);
    expect(stats.thisWeek.volumeLb, 800);
    expect(stats.lastWeek.volumeLb, 360);
    expect(stats.weeklyHistory, hasLength(8));
    expect(stats.weeklyHistory.last.weekStart, DateTime(2026, 3, 9));
    expect(stats.weekStreak, 3);
    expect(stats.totalWorkouts, 4);
    expect(stats.plannedDaysPerWeek, 2);
    expect(stats.muscleSetsThisWeek.map((e) => (e.key, e.value)), [
      (MuscleGroup.chest, 2.0),
      (MuscleGroup.triceps, 1.0),
    ]);
    expect(stats.averageDuration, const Duration(minutes: 75));
    expect(stats.personalRecords.single.load, 50);
    final trend = stats.trends.single;
    expect(trend.currentE1rm, closeTo(estimatedOneRepMax(50, 8), 1e-9));
    expect(trend.change, greaterThan(0));
  });

  test('streak counts from last week when this week is empty', () {
    final stats = const ComputeDashboardStatsUsecase()(
      workouts: [
        workout('a', DateTime(2026, 3, 3), {
          'x': [done(5, 100)],
        }),
      ],
      exercises: const [],
      weeklyPlan: const WeeklyPlanEntity(),
      now: now,
    );
    expect(stats.weekStreak, 1);
    expect(stats.thisWeek.workouts, 0);
  });

  test('exercise progress, oldest first', () {
    final points = const ComputeExerciseProgressUsecase()(
      exerciseId: 'press',
      workouts: [
        workout('b', DateTime(2026, 3, 9), {
          'press': [done(8, 50), done(6, 55)],
        }),
        workout('a', DateTime(2026, 3, 2), {
          'press': [done(8, 45)],
          'other': [done(1, 300)],
        }),
      ],
    );
    expect(points.map((p) => p.workoutId), ['a', 'b']);
    expect(points.last.topLoad, 55);
    expect(points.last.volume, 8 * 50 + 6 * 55);
    expect(points.last.sets, 2);
  });

  test('weight unit converts and formats', () {
    expect(WeightUnit.lb.format(135), '135');
    expect(WeightUnit.kg.format(135), '61.2');
    expect(WeightUnit.kg.toLb(WeightUnit.kg.fromLb(225)), closeTo(225, 1e-9));
  });

  test('disc exercises are left out of lb volume but count reps and sets', () {
    final stats = const ComputeDashboardStatsUsecase()(
      workouts: [
        workout('w', DateTime(2026, 3, 10), {
          'press': [done(8, 50)],
          'pushdown': [done(10, 6)],
        }),
      ],
      exercises: [
        exercise('press'),
        exercise('pushdown').copyWith(loadType: LoadType.discs),
      ],
      weeklyPlan: const WeeklyPlanEntity(),
      now: now,
    );
    expect(stats.thisWeek.volumeLb, 400);
    expect(stats.thisWeek.reps, 18);
    expect(stats.thisWeek.sets, 2);
  });

  test(
    'reps per main muscle ignore secondary muscles; kg still counts as lb',
    () {
      final stats = const ComputeDashboardStatsUsecase()(
        workouts: [
          workout('w', DateTime(2026, 3, 10), {
            'press': [done(8, 50), done(6, 50)],
            'curl': [done(10, 20)],
          }),
        ],
        exercises: [
          exercise(
            'press',
            primary: const [MuscleGroup.chest],
            secondary: const [MuscleGroup.triceps],
          ),
          exercise(
            'curl',
            primary: const [MuscleGroup.biceps],
          ).copyWith(weightUnit: WeightUnit.kg),
        ],
        weeklyPlan: const WeeklyPlanEntity(),
        now: now,
      );
      expect(stats.muscleRepsThisWeek.map((e) => (e.key, e.value)), [
        (MuscleGroup.chest, 14),
        (MuscleGroup.biceps, 10),
      ]);
      // Loads are stored in pounds whatever the display unit.
      expect(stats.thisWeek.volumeLb, 14 * 50 + 10 * 20);
    },
  );
}
