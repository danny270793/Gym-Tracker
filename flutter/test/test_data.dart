import 'package:gym_tracker/features/exercises/domain/entities/equipment.dart';
import 'package:gym_tracker/features/exercises/domain/entities/exercise_entity.dart';
import 'package:gym_tracker/features/exercises/domain/entities/muscle_group.dart';
import 'package:gym_tracker/features/workouts/domain/entities/workout_entity.dart';

final epoch = DateTime(2026, 1, 1);

ExerciseEntity exercise(
  String id, {
  List<MuscleGroup> primary = const [MuscleGroup.chest],
  List<MuscleGroup> secondary = const [],
}) => ExerciseEntity(
  id: id,
  name: id,
  primaryMuscles: primary,
  secondaryMuscles: secondary,
  equipment: Equipment.dumbbell,
  createdAt: epoch,
  updatedAt: epoch,
);

WorkoutEntity workout(
  String id,
  DateTime date,
  Map<String, List<WorkoutSet>> sets, {
  DateTime? finishedAt,
}) => WorkoutEntity(
  id: id,
  date: date,
  title: id,
  exercises: [
    for (final e in sets.entries)
      WorkoutExercise(id: '$id-${e.key}', exerciseId: e.key, sets: e.value),
  ],
  finishedAt: finishedAt,
  createdAt: date,
  updatedAt: date,
);

WorkoutSet done(int reps, double lb) =>
    WorkoutSet(reps: reps, load: lb, completed: true);
