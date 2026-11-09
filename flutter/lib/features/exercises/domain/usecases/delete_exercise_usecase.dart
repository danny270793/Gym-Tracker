import '../entities/exercise_entity.dart';
import '../repositories/exercises_repository.dart';

class DeleteExerciseUsecase {
  final ExercisesRepository _repository;

  const DeleteExerciseUsecase(this._repository);

  Future<void> call(ExerciseEntity exercise) => _repository.delete(exercise);
}
