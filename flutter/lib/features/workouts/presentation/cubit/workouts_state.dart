import 'package:equatable/equatable.dart';

import '../../domain/entities/workout_entity.dart';

sealed class WorkoutsState extends Equatable {
  const WorkoutsState();

  /// Newest first.
  List<WorkoutEntity> get workouts => const [];

  /// True when the list is the offline copy of the last successful read.
  bool get fromCache => false;

  WorkoutEntity? byId(String id) {
    for (final w in workouts) {
      if (w.id == id) return w;
    }
    return null;
  }
}

class WorkoutsInitial extends WorkoutsState {
  const WorkoutsInitial();
  @override
  List<Object?> get props => [];
}

class WorkoutsLoading extends WorkoutsState {
  const WorkoutsLoading();
  @override
  List<Object?> get props => [];
}

class WorkoutsLoaded extends WorkoutsState {
  @override
  final List<WorkoutEntity> workouts;
  @override
  final bool fromCache;
  const WorkoutsLoaded(this.workouts, {this.fromCache = false});
  @override
  List<Object?> get props => [workouts, fromCache];
}

class WorkoutsError extends WorkoutsState {
  const WorkoutsError();
  @override
  List<Object?> get props => [];
}

class WorkoutsActionError extends WorkoutsState {
  @override
  final List<WorkoutEntity> workouts;
  @override
  final bool fromCache;
  const WorkoutsActionError(this.workouts, {this.fromCache = false});
  @override
  List<Object?> get props => [workouts, fromCache];
}
