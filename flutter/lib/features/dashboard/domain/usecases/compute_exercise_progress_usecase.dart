import '../../../workouts/domain/entities/workout_entity.dart';
import '../entities/dashboard_stats.dart';
import 'compute_dashboard_stats_usecase.dart';

/// Per-session history of one exercise, oldest first.
class ComputeExerciseProgressUsecase {
  const ComputeExerciseProgressUsecase();

  List<ExerciseSessionPoint> call({
    required String exerciseId,
    required List<WorkoutEntity> workouts,
  }) {
    final points = <ExerciseSessionPoint>[];
    for (final w in workouts) {
      final sets = [
        for (final e in w.exercises)
          if (e.exerciseId == exerciseId) ...e.completedSets,
      ];
      if (sets.isEmpty) continue;
      var top = 0.0, e1rm = 0.0, volume = 0.0;
      var reps = 0, bestReps = 0;
      for (final s in sets) {
        if (s.load > top) top = s.load;
        final est = estimatedOneRepMax(s.load, s.reps);
        if (est > e1rm) e1rm = est;
        if (s.reps > bestReps) bestReps = s.reps;
        volume += s.volume;
        reps += s.reps;
      }
      points.add(
        ExerciseSessionPoint(
          date: w.date,
          workoutId: w.id,
          sets: sets.length,
          reps: reps,
          topLoad: top,
          bestE1rm: e1rm,
          volume: volume,
          bestReps: bestReps,
        ),
      );
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }
}
