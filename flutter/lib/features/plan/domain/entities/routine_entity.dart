import 'package:equatable/equatable.dart';

/// One line of a routine: "3x8 incline dumbbell press @ 50 lb".
class PlannedExercise extends Equatable {
  final String exerciseId;
  final int sets;
  final int reps;

  /// Optional target weight, in pounds.
  final double? load;
  final String? notes;

  const PlannedExercise({
    required this.exerciseId,
    this.sets = 3,
    this.reps = 8,
    this.load,
    this.notes,
  });

  PlannedExercise copyWith({
    int? sets,
    int? reps,
    double? Function()? load,
    String? Function()? notes,
  }) => PlannedExercise(
    exerciseId: exerciseId,
    sets: sets ?? this.sets,
    reps: reps ?? this.reps,
    load: load != null ? load() : this.load,
    notes: notes != null ? notes() : this.notes,
  );

  factory PlannedExercise.fromJson(Map<String, dynamic> json) =>
      PlannedExercise(
        exerciseId: json['exerciseId'] as String,
        sets: (json['sets'] as num?)?.toInt() ?? 3,
        reps: (json['reps'] as num?)?.toInt() ?? 8,
        load: ((json['load'] ?? json['weightLb']) as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'sets': sets,
    'reps': reps,
    'load': load,
    'notes': notes,
  };

  @override
  List<Object?> get props => [exerciseId, sets, reps, load, notes];
}

/// A reusable day template (e.g. "Push"). The weekly plan points days at it, so
/// the same routine can be done several times a week.
class RoutineEntity extends Equatable {
  final String id;
  final String title;
  final String? notes;
  final List<PlannedExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoutineEntity({
    required this.id,
    required this.title,
    this.notes,
    this.exercises = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);

  factory RoutineEntity.fromJson(Map<String, dynamic> json) => RoutineEntity(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    notes: json['notes'] as String?,
    exercises: [
      for (final e in (json['exercises'] as List? ?? const []))
        if (e is Map<String, dynamic>) PlannedExercise.fromJson(e),
    ],
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'exercises': [for (final e in exercises) e.toJson()],
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    title,
    notes,
    exercises,
    createdAt,
    updatedAt,
  ];
}
