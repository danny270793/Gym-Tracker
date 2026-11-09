import 'package:equatable/equatable.dart';

import '../../../exercises/domain/entities/muscle_group.dart';

/// Totals for one Monday-to-Sunday week. Only completed sets count.
class WeekSummary extends Equatable {
  final DateTime weekStart;
  final int workouts;
  final int sets;
  final int reps;

  /// Pounds lifted on weight exercises (disc exercises excluded).
  final double volumeLb;

  const WeekSummary({
    required this.weekStart,
    this.workouts = 0,
    this.sets = 0,
    this.reps = 0,
    this.volumeLb = 0,
  });

  @override
  List<Object?> get props => [weekStart, workouts, sets, reps, volumeLb];
}

/// Best lift ever recorded for an exercise.
class PersonalRecord extends Equatable {
  final String exerciseId;

  /// Estimated one-rep max (Epley), pounds.
  final double e1rm;
  final double load;
  final int reps;
  final DateTime date;

  const PersonalRecord({
    required this.exerciseId,
    required this.e1rm,
    required this.load,
    required this.reps,
    required this.date,
  });

  @override
  List<Object?> get props => [exerciseId, e1rm, load, reps, date];
}

/// Strength trend: best e1RM in the last 4 weeks vs the 4 weeks before.
class ExerciseTrend extends Equatable {
  final String exerciseId;
  final double currentE1rm;
  final double? previousE1rm;

  const ExerciseTrend({
    required this.exerciseId,
    required this.currentE1rm,
    this.previousE1rm,
  });

  /// Fractional change (0.05 == +5%), or null when there is no earlier data.
  double? get change {
    final prev = previousE1rm;
    if (prev == null || prev <= 0) return null;
    return (currentE1rm - prev) / prev;
  }

  @override
  List<Object?> get props => [exerciseId, currentE1rm, previousE1rm];
}

class DashboardStats extends Equatable {
  final WeekSummary thisWeek;
  final WeekSummary lastWeek;

  /// Oldest first, ending with this week.
  final List<WeekSummary> weeklyHistory;

  /// Training days in the weekly plan.
  final int plannedDaysPerWeek;

  /// Consecutive weeks with at least one workout, ending this week (or last
  /// week, when this week has none yet).
  final int weekStreak;
  final int totalWorkouts;

  /// Sets per muscle this week: primary counts 1, secondary 0.5. Highest first.
  final List<MapEntry<MuscleGroup, double>> muscleSetsThisWeek;

  /// Most recent first.
  final List<PersonalRecord> personalRecords;

  /// Biggest gains first.
  final List<ExerciseTrend> trends;

  /// Average length of finished workouts in the last 30 days.
  final Duration? averageDuration;

  const DashboardStats({
    required this.thisWeek,
    required this.lastWeek,
    required this.weeklyHistory,
    required this.plannedDaysPerWeek,
    required this.weekStreak,
    required this.totalWorkouts,
    required this.muscleSetsThisWeek,
    required this.personalRecords,
    required this.trends,
    this.averageDuration,
  });

  @override
  List<Object?> get props => [
    thisWeek,
    lastWeek,
    weeklyHistory,
    plannedDaysPerWeek,
    weekStreak,
    totalWorkouts,
    muscleSetsThisWeek,
    personalRecords,
    trends,
    averageDuration,
  ];
}

/// One session of a single exercise, for the progress chart.
class ExerciseSessionPoint extends Equatable {
  final DateTime date;
  final String workoutId;
  final int sets;
  final int reps;
  final double topLoad;
  final double bestE1rm;

  /// reps × load, in the exercise's unit (lb or discs).
  final double volume;

  /// Most reps in one set (useful for bodyweight work).
  final int bestReps;

  const ExerciseSessionPoint({
    required this.date,
    required this.workoutId,
    required this.sets,
    required this.reps,
    required this.topLoad,
    required this.bestE1rm,
    required this.volume,
    required this.bestReps,
  });

  @override
  List<Object?> get props => [
    date,
    workoutId,
    sets,
    reps,
    topLoad,
    bestE1rm,
    volume,
    bestReps,
  ];
}
