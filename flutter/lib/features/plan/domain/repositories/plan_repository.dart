import '../../../../core/storage/cached.dart';
import '../entities/routine_entity.dart';
import '../entities/weekly_plan_entity.dart';

abstract class PlanRepository {
  /// Active routines and the weekly plan.
  Future<Cached<(List<RoutineEntity>, WeeklyPlanEntity)>> getPlan();
  Future<RoutineEntity> saveRoutine(RoutineEntity routine);

  /// Soft-deletes the routine and frees the weekdays that used it.
  Future<WeeklyPlanEntity> deleteRoutine(String id);

  /// Assigns [routineId] to [weekday], or makes it a rest day when null.
  Future<WeeklyPlanEntity> setDay(int weekday, String? routineId);
}
