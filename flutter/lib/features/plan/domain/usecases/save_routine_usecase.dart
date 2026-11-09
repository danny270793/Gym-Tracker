import '../entities/routine_entity.dart';
import '../repositories/plan_repository.dart';

class SaveRoutineUsecase {
  final PlanRepository _repository;

  const SaveRoutineUsecase(this._repository);

  Future<RoutineEntity> call(RoutineEntity routine) =>
      _repository.saveRoutine(routine);
}
