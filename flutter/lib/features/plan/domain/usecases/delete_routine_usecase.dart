import '../entities/weekly_plan_entity.dart';
import '../repositories/plan_repository.dart';

class DeleteRoutineUsecase {
  final PlanRepository _repository;

  const DeleteRoutineUsecase(this._repository);

  Future<WeeklyPlanEntity> call({required String id}) =>
      _repository.deleteRoutine(id);
}
