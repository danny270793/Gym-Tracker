import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/features/exercises/domain/entities/equipment.dart';
import 'package:gym_tracker/features/exercises/domain/entities/exercise_entity.dart';
import 'package:gym_tracker/features/exercises/domain/entities/load_type.dart';
import 'package:gym_tracker/features/exercises/domain/entities/muscle_group.dart';
import 'package:gym_tracker/features/plan/domain/entities/routine_entity.dart';
import 'package:gym_tracker/features/plan/domain/entities/weekly_plan_entity.dart';
import 'package:gym_tracker/features/workouts/domain/entities/workout_entity.dart';

import 'test_data.dart';

void main() {
  test('exercise round-trips through JSON', () {
    final e = ExerciseEntity(
      id: 'x',
      name: 'Incline dumbbell press',
      primaryMuscles: const [MuscleGroup.chest],
      secondaryMuscles: const [MuscleGroup.shoulders, MuscleGroup.triceps],
      equipment: Equipment.dumbbell,
      notes: 'Bench at 30°',
      imagePaths: const ['a.jpg'],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );
    expect(ExerciseEntity.fromJson(e.toJson()), e);
  });

  test('exercise JSON tolerates unknown and missing fields', () {
    final e = ExerciseEntity.fromJson({
      'id': 'x',
      'primaryMuscles': ['chest', 'notAMuscle'],
      'equipment': 'spaceship',
    });
    expect(e.name, '');
    expect(e.primaryMuscles, [MuscleGroup.chest]);
    expect(e.equipment, Equipment.other);
    expect(e.imagePaths, isEmpty);
  });

  test('routine and weekly plan round-trip', () {
    final r = RoutineEntity(
      id: 'push',
      title: 'Push',
      exercises: const [
        PlannedExercise(exerciseId: 'a', sets: 3, reps: 8, load: 50),
        PlannedExercise(exerciseId: 'b', sets: 3, reps: 8),
      ],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(RoutineEntity.fromJson(r.toJson()), r);

    const plan = WeeklyPlanEntity(
      routineIdByWeekday: {DateTime.monday: 'push', DateTime.thursday: 'push'},
    );
    expect(WeeklyPlanEntity.fromJson(plan.toJson()), plan);
    expect(plan.trainingDays, 2);
    expect(plan.withoutRoutine('push').trainingDays, 0);
    expect(plan.withDay(DateTime.monday, null).routineIdFor(1), isNull);
  });

  test('workout round-trips and only counts completed sets', () {
    final w = workout('w', DateTime(2026, 3, 2, 18), {
      'a': [done(8, 50), done(8, 50), const WorkoutSet(reps: 8, load: 50)],
    });
    expect(WorkoutEntity.fromJson(w.toJson()), w);
    expect(w.totalSetCount, 3);
    expect(w.completedSetCount, 2);
    expect(w.completedReps, 16);
    expect(w.weightVolumeLb((_) => true), 800);
    expect(w.weightVolumeLb((_) => false), 0);
  });

  test(
    'load type defaults from equipment for data saved before it existed',
    () {
      ExerciseEntity old(String equipment) =>
          ExerciseEntity.fromJson({'id': 'x', 'equipment': equipment});
      expect(old('cable').loadType, LoadType.discs);
      expect(old('machine').loadType, LoadType.discs);
      expect(old('dumbbell').loadType, LoadType.weight);
      final explicit = ExerciseEntity.fromJson({
        'id': 'x',
        'equipment': 'cable',
        'loadType': 'weight',
      });
      expect(explicit.loadType, LoadType.weight);
    },
  );

  test('sets saved with the old weightLb key still load', () {
    final s = WorkoutSet.fromJson({
      'reps': 8,
      'weightLb': 50,
      'completed': true,
    });
    expect(s.load, 50);
  });
}
