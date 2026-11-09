import '../entities/exercise_entity.dart';
import '../repositories/exercises_repository.dart';

class SaveExerciseUsecase {
  final ExercisesRepository _repository;

  const SaveExerciseUsecase(this._repository);

  Future<ExerciseEntity> call(ExerciseEntity exercise) =>
      _repository.save(exercise);
}
