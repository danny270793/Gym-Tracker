import '../../../../core/storage/cached.dart';
import '../entities/routine_entity.dart';
import '../entities/weekly_plan_entity.dart';
import '../repositories/plan_repository.dart';

class GetPlanUsecase {
  final PlanRepository _repository;

  const GetPlanUsecase(this._repository);

  Future<Cached<(List<RoutineEntity>, WeeklyPlanEntity)>> call() =>
      _repository.getPlan();
}
