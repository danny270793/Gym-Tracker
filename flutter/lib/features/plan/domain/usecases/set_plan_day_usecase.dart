import '../entities/weekly_plan_entity.dart';
import '../repositories/plan_repository.dart';

/// Assigns a routine to a weekday, or makes it a rest day when [routineId] is null.
class SetPlanDayUsecase {
  final PlanRepository _repository;

  const SetPlanDayUsecase(this._repository);

  Future<WeeklyPlanEntity> call({
    required int weekday,
    required String? routineId,
  }) => _repository.setDay(weekday, routineId);
}
