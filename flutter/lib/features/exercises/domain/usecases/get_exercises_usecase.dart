import '../../../../core/storage/cached.dart';
import '../entities/exercise_entity.dart';
import '../repositories/exercises_repository.dart';

class GetExercisesUsecase {
  final ExercisesRepository _repository;

  const GetExercisesUsecase(this._repository);

  Future<Cached<List<ExerciseEntity>>> call() => _repository.getAll();
}
