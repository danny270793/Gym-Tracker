import 'package:equatable/equatable.dart';

import '../../domain/entities/exercise_entity.dart';

sealed class ExercisesState extends Equatable {
  const ExercisesState();

  /// Exercises known so far (empty while loading or after a load error).
  List<ExerciseEntity> get exercises => const [];

  /// True when the list is the offline copy of the last successful read.
  bool get fromCache => false;

  ExerciseEntity? byId(String id) {
    for (final e in exercises) {
      if (e.id == id) return e;
    }
    return null;
  }
}

class ExercisesInitial extends ExercisesState {
  const ExercisesInitial();
  @override
  List<Object?> get props => [];
}

class ExercisesLoading extends ExercisesState {
  const ExercisesLoading();
  @override
  List<Object?> get props => [];
}

class ExercisesLoaded extends ExercisesState {
  @override
  final List<ExerciseEntity> exercises;
  @override
  final bool fromCache;
  const ExercisesLoaded(this.exercises, {this.fromCache = false});
  @override
  List<Object?> get props => [exercises, fromCache];
}

class ExercisesError extends ExercisesState {
  const ExercisesError();
  @override
  List<Object?> get props => [];
}

/// A save/delete failed; [exercises] is the list before the action.
class ExercisesActionError extends ExercisesState {
  @override
  final List<ExerciseEntity> exercises;
  @override
  final bool fromCache;
  const ExercisesActionError(this.exercises, {this.fromCache = false});
  @override
  List<Object?> get props => [exercises, fromCache];
}
