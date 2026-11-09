import 'package:equatable/equatable.dart';

import '../../domain/entities/routine_entity.dart';
import '../../domain/entities/weekly_plan_entity.dart';

sealed class PlanState extends Equatable {
  const PlanState();

  List<RoutineEntity> get routines => const [];
  WeeklyPlanEntity get weeklyPlan => const WeeklyPlanEntity();

  /// True when the data is the offline copy of the last successful read.
  bool get fromCache => false;

  RoutineEntity? routineById(String? id) {
    if (id == null) return null;
    for (final r in routines) {
      if (r.id == id) return r;
    }
    return null;
  }

  RoutineEntity? routineForWeekday(int weekday) =>
      routineById(weeklyPlan.routineIdFor(weekday));
}

class PlanInitial extends PlanState {
  const PlanInitial();
  @override
  List<Object?> get props => [];
}

class PlanLoading extends PlanState {
  const PlanLoading();
  @override
  List<Object?> get props => [];
}

class PlanLoaded extends PlanState {
  @override
  final List<RoutineEntity> routines;
  @override
  final WeeklyPlanEntity weeklyPlan;
  @override
  final bool fromCache;
  const PlanLoaded(this.routines, this.weeklyPlan, {this.fromCache = false});
  @override
  List<Object?> get props => [routines, weeklyPlan, fromCache];
}

class PlanError extends PlanState {
  const PlanError();
  @override
  List<Object?> get props => [];
}

class PlanActionError extends PlanState {
  @override
  final List<RoutineEntity> routines;
  @override
  final WeeklyPlanEntity weeklyPlan;
  @override
  final bool fromCache;
  const PlanActionError(
    this.routines,
    this.weeklyPlan, {
    this.fromCache = false,
  });
  @override
  List<Object?> get props => [routines, weeklyPlan, fromCache];
}
