import '../entities/workout_entity.dart';
import '../repositories/workouts_repository.dart';

class SaveWorkoutUsecase {
  final WorkoutsRepository _repository;

  const SaveWorkoutUsecase(this._repository);

  Future<WorkoutEntity> call(WorkoutEntity workout) =>
      _repository.save(workout.copyWith(updatedAt: DateTime.now()));
}
