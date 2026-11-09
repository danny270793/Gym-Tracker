import 'package:equatable/equatable.dart';

/// One performed (or to-do) set. Only [completed] sets count in stats.
class WorkoutSet extends Equatable {
  final int reps;

  /// Pounds, or a disc count for stack exercises (see `LoadType`).
  /// 0 for bodyweight.
  final double load;
  final bool completed;

  const WorkoutSet({this.reps = 0, this.load = 0, this.completed = false});

  /// reps × load, in the exercise's own unit.
  double get volume => reps * load;

  WorkoutSet copyWith({int? reps, double? load, bool? completed}) => WorkoutSet(
    reps: reps ?? this.reps,
    load: load ?? this.load,
    completed: completed ?? this.completed,
  );

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
    reps: (json['reps'] as num?)?.toInt() ?? 0,
    load: ((json['load'] ?? json['weightLb']) as num?)?.toDouble() ?? 0,
    completed: json['completed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'reps': reps,
    'load': load,
    'completed': completed,
  };

  @override
  List<Object?> get props => [reps, load, completed];
}

/// Snapshot of what the plan asked for, kept so later plan edits don't rewrite history.
class PlannedTarget extends Equatable {
  final int sets;
  final int reps;
  final double? load;

  const PlannedTarget({required this.sets, required this.reps, this.load});

  factory PlannedTarget.fromJson(Map<String, dynamic> json) => PlannedTarget(
    sets: (json['sets'] as num?)?.toInt() ?? 0,
    reps: (json['reps'] as num?)?.toInt() ?? 0,
    load: ((json['load'] ?? json['weightLb']) as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {'sets': sets, 'reps': reps, 'load': load};

  @override
  List<Object?> get props => [sets, reps, load];
}

class WorkoutExercise extends Equatable {
  /// Row id, so the same exercise can appear twice in one workout.
  final String id;
  final String exerciseId;

  /// Null when the exercise was added during the workout (not in the plan).
  final PlannedTarget? planned;
  final List<WorkoutSet> sets;
  final String? notes;

  const WorkoutExercise({
    required this.id,
    required this.exerciseId,
    this.planned,
    this.sets = const [],
    this.notes,
  });

  Iterable<WorkoutSet> get completedSets => sets.where((s) => s.completed);

  WorkoutExercise copyWith({
    List<WorkoutSet>? sets,
    String? Function()? notes,
  }) => WorkoutExercise(
    id: id,
    exerciseId: exerciseId,
    planned: planned,
    sets: sets ?? this.sets,
    notes: notes != null ? notes() : this.notes,
  );

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        id: json['id'] as String,
        exerciseId: json['exerciseId'] as String,
        planned: json['planned'] is Map<String, dynamic>
            ? PlannedTarget.fromJson(json['planned'] as Map<String, dynamic>)
            : null,
        sets: [
          for (final s in (json['sets'] as List? ?? const []))
            if (s is Map<String, dynamic>) WorkoutSet.fromJson(s),
        ],
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseId': exerciseId,
    'planned': planned?.toJson(),
    'sets': [for (final s in sets) s.toJson()],
    'notes': notes,
  };

  @override
  List<Object?> get props => [id, exerciseId, planned, sets, notes];
}

/// A logged training day. Starts as a copy of the planned routine and is then
/// edited freely: drop exercises, change sets/reps/weight, add new ones.
class WorkoutEntity extends Equatable {
  final String id;

  /// Local date and start time of the session.
  final DateTime date;

  /// The routine it was started from, if any.
  final String? routineId;
  final String title;
  final List<WorkoutExercise> exercises;
  final String? notes;

  /// Null while the workout is in progress.
  final DateTime? finishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutEntity({
    required this.id,
    required this.date,
    this.routineId,
    required this.title,
    this.exercises = const [],
    this.notes,
    this.finishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFinished => finishedAt != null;

  int get completedSetCount =>
      exercises.fold(0, (sum, e) => sum + e.completedSets.length);

  int get totalSetCount => exercises.fold(0, (sum, e) => sum + e.sets.length);

  int get completedReps => exercises.fold(
    0,
    (sum, e) => sum + e.completedSets.fold(0, (s, set) => s + set.reps),
  );

  /// Completed reps × pounds over exercises where [isWeight] is true. Disc
  /// (stack) exercises are left out so pounds and discs never mix.
  double weightVolumeLb(bool Function(String exerciseId) isWeight) => exercises
      .where((e) => isWeight(e.exerciseId))
      .fold(
        0,
        (sum, e) => sum + e.completedSets.fold(0.0, (s, set) => s + set.volume),
      );

  WorkoutEntity copyWith({
    DateTime? date,
    String? title,
    List<WorkoutExercise>? exercises,
    String? Function()? notes,
    DateTime? Function()? finishedAt,
    DateTime? updatedAt,
  }) => WorkoutEntity(
    id: id,
    date: date ?? this.date,
    routineId: routineId,
    title: title ?? this.title,
    exercises: exercises ?? this.exercises,
    notes: notes != null ? notes() : this.notes,
    finishedAt: finishedAt != null ? finishedAt() : this.finishedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory WorkoutEntity.fromJson(Map<String, dynamic> json) => WorkoutEntity(
    id: json['id'] as String,
    date:
        DateTime.tryParse(json['date'] as String? ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
    routineId: json['routineId'] as String?,
    title: json['title'] as String? ?? '',
    exercises: [
      for (final e in (json['exercises'] as List? ?? const []))
        if (e is Map<String, dynamic>) WorkoutExercise.fromJson(e),
    ],
    notes: json['notes'] as String?,
    finishedAt: DateTime.tryParse(json['finishedAt'] as String? ?? '')
        ?.toLocal(),
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toUtc().toIso8601String(),
    'routineId': routineId,
    'title': title,
    'exercises': [for (final e in exercises) e.toJson()],
    'notes': notes,
    'finishedAt': finishedAt?.toUtc().toIso8601String(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    date,
    routineId,
    title,
    exercises,
    notes,
    finishedAt,
    createdAt,
    updatedAt,
  ];
}
