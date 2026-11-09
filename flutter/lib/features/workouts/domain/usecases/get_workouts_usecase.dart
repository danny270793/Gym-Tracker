import '../../../../core/storage/cached.dart';
import '../entities/workout_entity.dart';
import '../repositories/workouts_repository.dart';

class GetWorkoutsUsecase {
  final WorkoutsRepository _repository;

  const GetWorkoutsUsecase(this._repository);

  Future<Cached<List<WorkoutEntity>>> call() => _repository.getAll();
}
