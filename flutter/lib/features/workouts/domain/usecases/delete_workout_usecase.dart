import '../repositories/workouts_repository.dart';

class DeleteWorkoutUsecase {
  final WorkoutsRepository _repository;

  const DeleteWorkoutUsecase(this._repository);

  Future<void> call({required String id}) => _repository.delete(id);
}
