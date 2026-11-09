import '../../../../core/date/week.dart';
import '../../../exercises/domain/entities/exercise_entity.dart';
import '../../../exercises/domain/entities/load_type.dart';
import '../../../exercises/domain/entities/muscle_group.dart';
import '../../../plan/domain/entities/weekly_plan_entity.dart';
import '../../../workouts/domain/entities/workout_entity.dart';
import '../entities/dashboard_stats.dart';

/// Epley estimated one-rep max. `weight` for a single, 0 for no weight.
double estimatedOneRepMax(double load, int reps) {
  if (load <= 0 || reps <= 0) return 0;
  if (reps == 1) return load;
  return load * (1 + reps / 30);
}

class ComputeDashboardStatsUsecase {
  const ComputeDashboardStatsUsecase();

  static const int historyWeeks = 8;

  DashboardStats call({
    required List<WorkoutEntity> workouts,
    required List<ExerciseEntity> exercises,
    required WeeklyPlanEntity weeklyPlan,
    required DateTime now,
  }) {
    final thisWeekStart = startOfWeek(now);
    final byId = {for (final e in exercises) e.id: e};
    bool isWeight(String id) => byId[id]?.loadType != LoadType.discs;
    final weekly = <DateTime, _WeekAcc>{};
    for (final w in workouts) {
      if (w.completedSetCount == 0) continue;
      weekly.putIfAbsent(startOfWeek(w.date), _WeekAcc.new).add(w, isWeight);
    }

    WeekSummary summary(DateTime start) =>
        weekly[start]?.toSummary(start) ?? WeekSummary(weekStart: start);

    final history = [
      for (var i = historyWeeks - 1; i >= 0; i--)
        summary(addDays(thisWeekStart, -7 * i)),
    ];

    return DashboardStats(
      thisWeek: summary(thisWeekStart),
      lastWeek: summary(addDays(thisWeekStart, -7)),
      weeklyHistory: history,
      plannedDaysPerWeek: weeklyPlan.trainingDays,
      weekStreak: _weekStreak(weekly.keys.toSet(), thisWeekStart),
      totalWorkouts: workouts.where((w) => w.completedSetCount > 0).length,
      muscleSetsThisWeek: _muscleSets(
        workouts.where((w) => !w.date.isBefore(thisWeekStart)),
        byId,
      ),
      muscleRepsThisWeek: _muscleReps(
        workouts.where((w) => !w.date.isBefore(thisWeekStart)),
        byId,
      ),
      personalRecords: personalRecords(workouts),
      trends: _trends(workouts, now),
      averageDuration: _averageDuration(workouts, now),
    );
  }

  static int _weekStreak(Set<DateTime> activeWeeks, DateTime thisWeekStart) {
    var cursor = activeWeeks.contains(thisWeekStart)
        ? thisWeekStart
        : addDays(thisWeekStart, -7);
    var streak = 0;
    while (activeWeeks.contains(cursor)) {
      streak++;
      cursor = addDays(cursor, -7);
    }
    return streak;
  }

  static List<MapEntry<MuscleGroup, double>> _muscleSets(
    Iterable<WorkoutEntity> workouts,
    Map<String, ExerciseEntity> byId,
  ) {
    final sets = <MuscleGroup, double>{};
    for (final w in workouts) {
      for (final entry in w.exercises) {
        final ex = byId[entry.exerciseId];
        final n = entry.completedSets.length;
        if (ex == null || n == 0) continue;
        for (final m in ex.primaryMuscles) {
          sets[m] = (sets[m] ?? 0) + n;
        }
        for (final m in ex.secondaryMuscles) {
          sets[m] = (sets[m] ?? 0) + n * 0.5;
        }
      }
    }
    return sets.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Completed reps per main muscle; secondary muscles are not counted.
  static List<MapEntry<MuscleGroup, int>> _muscleReps(
    Iterable<WorkoutEntity> workouts,
    Map<String, ExerciseEntity> byId,
  ) {
    final reps = <MuscleGroup, int>{};
    for (final w in workouts) {
      for (final entry in w.exercises) {
        final ex = byId[entry.exerciseId];
        if (ex == null) continue;
        final n = entry.completedSets.fold(0, (sum, s) => sum + s.reps);
        if (n == 0) continue;
        for (final m in ex.primaryMuscles) {
          reps[m] = (reps[m] ?? 0) + n;
        }
      }
    }
    return reps.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Best e1RM per exercise, most recent record first.
  static List<PersonalRecord> personalRecords(List<WorkoutEntity> workouts) {
    final best = <String, PersonalRecord>{};
    for (final w in workouts) {
      for (final entry in w.exercises) {
        for (final s in entry.completedSets) {
          final e1rm = estimatedOneRepMax(s.load, s.reps);
          if (e1rm <= 0) continue;
          final current = best[entry.exerciseId];
          if (current == null ||
              e1rm > current.e1rm ||
              (e1rm == current.e1rm && w.date.isBefore(current.date))) {
            best[entry.exerciseId] = PersonalRecord(
              exerciseId: entry.exerciseId,
              e1rm: e1rm,
              load: s.load,
              reps: s.reps,
              date: w.date,
            );
          }
        }
      }
    }
    return best.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<ExerciseTrend> _trends(
    List<WorkoutEntity> workouts,
    DateTime now,
  ) {
    final today = dateOnly(now);
    final currentStart = addDays(today, -27);
    final previousStart = addDays(today, -55);
    final current = <String, double>{};
    final previous = <String, double>{};
    for (final w in workouts) {
      final day = dateOnly(w.date);
      if (day.isBefore(previousStart) || day.isAfter(today)) continue;
      final target = day.isBefore(currentStart) ? previous : current;
      for (final entry in w.exercises) {
        for (final s in entry.completedSets) {
          final e1rm = estimatedOneRepMax(s.load, s.reps);
          if (e1rm > (target[entry.exerciseId] ?? 0)) {
            target[entry.exerciseId] = e1rm;
          }
        }
      }
    }
    final trends = [
      for (final e in current.entries)
        if (e.value > 0)
          ExerciseTrend(
            exerciseId: e.key,
            currentE1rm: e.value,
            previousE1rm: previous[e.key],
          ),
    ];
    trends.sort((a, b) {
      final ca = a.change, cb = b.change;
      if (ca == null && cb == null) {
        return b.currentE1rm.compareTo(a.currentE1rm);
      }
      if (ca == null) return 1;
      if (cb == null) return -1;
      return cb.compareTo(ca);
    });
    return trends;
  }

  static Duration? _averageDuration(
    List<WorkoutEntity> workouts,
    DateTime now,
  ) {
    final since = now.subtract(const Duration(days: 30));
    final durations = [
      for (final w in workouts)
        if (w.finishedAt != null && w.date.isAfter(since))
          w.finishedAt!.difference(w.date),
    ].where((d) => d > Duration.zero && d < const Duration(hours: 6)).toList();
    if (durations.isEmpty) return null;
    final total = durations.fold(Duration.zero, (a, b) => a + b);
    return Duration(seconds: total.inSeconds ~/ durations.length);
  }
}

class _WeekAcc {
  int workouts = 0;
  int sets = 0;
  int reps = 0;
  double volume = 0;

  void add(WorkoutEntity w, bool Function(String exerciseId) isWeight) {
    workouts++;
    sets += w.completedSetCount;
    reps += w.completedReps;
    volume += w.weightVolumeLb(isWeight);
  }

  WeekSummary toSummary(DateTime start) => WeekSummary(
    weekStart: start,
    workouts: workouts,
    sets: sets,
    reps: reps,
    volumeLb: volume,
  );
}
