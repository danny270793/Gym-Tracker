import 'package:equatable/equatable.dart';

import 'equipment.dart';
import 'load_type.dart';
import 'muscle_group.dart';

/// A reusable exercise (e.g. "Incline dumbbell press"). Routines and workouts
/// reference it by [id], so editing it here updates every day that uses it.
class ExerciseEntity extends Equatable {
  final String id;
  final String name;

  /// Muscles trained directly. Counted as one set each on the dashboard.
  final List<MuscleGroup> primaryMuscles;

  /// Muscles that help. Counted as half a set each on the dashboard.
  final List<MuscleGroup> secondaryMuscles;
  final Equipment equipment;

  /// Pounds or stack discs. Defaults from [equipment] (cable/machine: discs).
  final LoadType loadType;
  final String? notes;

  /// Object paths in the `gym-exercise-images` Storage bucket
  /// (`<userId>/<uuid>.jpg`).
  final List<String> imagePaths;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExerciseEntity({
    required this.id,
    required this.name,
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.equipment = Equipment.other,
    this.loadType = LoadType.weight,
    this.notes,
    this.imagePaths = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  ExerciseEntity copyWith({
    String? name,
    List<MuscleGroup>? primaryMuscles,
    List<MuscleGroup>? secondaryMuscles,
    Equipment? equipment,
    LoadType? loadType,
    String? Function()? notes,
    List<String>? imagePaths,
    DateTime? updatedAt,
  }) => ExerciseEntity(
    id: id,
    name: name ?? this.name,
    primaryMuscles: primaryMuscles ?? this.primaryMuscles,
    secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
    equipment: equipment ?? this.equipment,
    loadType: loadType ?? this.loadType,
    notes: notes != null ? notes() : this.notes,
    imagePaths: imagePaths ?? this.imagePaths,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory ExerciseEntity.fromJson(Map<String, dynamic> json) {
    final equipment = Equipment.fromStorage(json['equipment']);
    return ExerciseEntity(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      primaryMuscles: _muscles(json['primaryMuscles']),
      secondaryMuscles: _muscles(json['secondaryMuscles']),
      equipment: equipment,
      loadType:
          LoadType.fromStorage(json['loadType']) ??
          LoadType.defaultFor(equipment),
      notes: json['notes'] as String?,
      imagePaths:
          ((json['imagePaths'] ?? json['imageNames']) as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'primaryMuscles': [for (final m in primaryMuscles) m.name],
    'secondaryMuscles': [for (final m in secondaryMuscles) m.name],
    'equipment': equipment.name,
    'loadType': loadType.name,
    'notes': notes,
    'imagePaths': imagePaths,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  static List<MuscleGroup> _muscles(Object? raw) => [
    if (raw is List)
      for (final v in raw) ?MuscleGroup.fromStorage(v),
  ];

  @override
  List<Object?> get props => [
    id,
    name,
    primaryMuscles,
    secondaryMuscles,
    equipment,
    loadType,
    notes,
    imagePaths,
    createdAt,
    updatedAt,
  ];
}
