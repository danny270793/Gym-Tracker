import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/features/plan/domain/entities/routine_entity.dart';
import 'package:gym_tracker/features/workouts/domain/entities/workout_entity.dart';
import 'package:gym_tracker/features/workouts/domain/usecases/build_workout_usecase.dart';

import 'test_data.dart';

void main() {
  const builder = BuildWorkoutUsecase();
  final routine = RoutineEntity(
    id: 'push',
    title: 'Push',
    exercises: const [
      PlannedExercise(exerciseId: 'incline', sets: 3, reps: 8),
      PlannedExercise(exerciseId: 'ohp', sets: 2, reps: 10, load: 40),
    ],
    createdAt: epoch,
    updatedAt: epoch,
  );

  test('prefills planned sets and reps, weight from last session', () {
    final history = [
      workout('old', DateTime(2026, 3, 1), {
        'incline': [done(8, 45)],
      }),
      workout('recent', DateTime(2026, 3, 5), {
        'incline': [done(8, 50), done(6, 55)],
      }),
    ];
    final w = builder(
      date: DateTime(2026, 3, 9),
      title: 'Push',
      routine: routine,
      history: history,
    );
    expect(w.routineId, 'push');
    expect(w.exercises, hasLength(2));
    final incline = w.exercises[0];
    expect(incline.sets, hasLength(3));
    expect(incline.sets.every((s) => s.reps == 8 && s.load == 55), isTrue);
    expect(incline.sets.every((s) => !s.completed), isTrue);
    expect(incline.planned, const PlannedTarget(sets: 3, reps: 8));
    // Plan target weight wins over history.
    expect(w.exercises[1].sets.map((s) => s.load), [40, 40]);
  });

  test('empty workout without routine', () {
    final w = builder(date: DateTime(2026), title: 'Workout', history: []);
    expect(w.routineId, isNull);
    expect(w.exercises, isEmpty);
  });

  test('ad-hoc entry copies last sets, unchecked', () {
    final history = [
      workout('w', DateTime(2026, 3, 5), {
        'curl': [done(12, 25), done(10, 25)],
      }),
    ];
    final row = builder.adHocEntry('curl', history);
    expect(row.planned, isNull);
    expect(row.sets, const [
      WorkoutSet(reps: 12, load: 25),
      WorkoutSet(reps: 10, load: 25),
    ]);
    expect(builder.adHocEntry('new', history).sets, hasLength(3));
  });
}
