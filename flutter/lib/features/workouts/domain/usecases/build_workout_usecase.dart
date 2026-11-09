import 'package:uuid/uuid.dart';

import '../../../plan/domain/entities/routine_entity.dart';
import '../entities/workout_entity.dart';

/// Builds a new, unsaved workout from a routine (or an empty one).
///
/// Each planned exercise gets its planned number of sets with the planned reps.
/// The weight is the plan's target, else the heaviest completed weight from the
/// most recent session of that exercise, so the log starts where you left off.
class BuildWorkoutUsecase {
  const BuildWorkoutUsecase();

  static const _uuid = Uuid();

  WorkoutEntity call({
    required DateTime date,
    required String title,
    RoutineEntity? routine,
    required List<WorkoutEntity> history,
  }) {
    final now = DateTime.now();
    return WorkoutEntity(
      id: _uuid.v4(),
      date: date,
      routineId: routine?.id,
      title: title,
      exercises: [
        for (final planned in routine?.exercises ?? const <PlannedExercise>[])
          entryFor(planned, history),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  WorkoutExercise entryFor(
    PlannedExercise planned,
    List<WorkoutEntity> history,
  ) {
    final weight = planned.load ?? lastLoad(planned.exerciseId, history) ?? 0;
    return WorkoutExercise(
      id: _uuid.v4(),
      exerciseId: planned.exerciseId,
      planned: PlannedTarget(
        sets: planned.sets,
        reps: planned.reps,
        load: planned.load,
      ),
      sets: [
        for (var i = 0; i < planned.sets; i++)
          WorkoutSet(reps: planned.reps, load: weight),
      ],
    );
  }

  /// A row for an exercise added during the workout (not in the plan).
  WorkoutExercise adHocEntry(String exerciseId, List<WorkoutEntity> history) {
    final last = lastSets(exerciseId, history);
    return WorkoutExercise(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      sets: last.isNotEmpty
          ? [for (final s in last) s.copyWith(completed: false)]
          : const [
              WorkoutSet(reps: 8),
              WorkoutSet(reps: 8),
              WorkoutSet(reps: 8),
            ],
    );
  }

  /// Heaviest completed weight in the latest session that did [exerciseId].
  static double? lastLoad(String exerciseId, List<WorkoutEntity> history) {
    final sets = lastSets(exerciseId, history);
    if (sets.isEmpty) return null;
    return sets.map((s) => s.load).reduce((a, b) => a > b ? a : b);
  }

  /// Completed sets from the latest session that did [exerciseId].
  static List<WorkoutSet> lastSets(
    String exerciseId,
    List<WorkoutEntity> history,
  ) {
    final sorted = [...history]..sort((a, b) => b.date.compareTo(a.date));
    for (final w in sorted) {
      final sets = [
        for (final e in w.exercises)
          if (e.exerciseId == exerciseId) ...e.completedSets,
      ];
      if (sets.isNotEmpty) return sets;
    }
    return const [];
  }
}
