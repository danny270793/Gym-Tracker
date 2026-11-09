import '../../../../core/storage/cached.dart';
import '../entities/workout_entity.dart';

abstract class WorkoutsRepository {
  /// Newest first.
  Future<Cached<List<WorkoutEntity>>> getAll();

  /// Inserts or replaces by id, with all exercises and sets.
  Future<WorkoutEntity> save(WorkoutEntity workout);
  Future<void> delete(String id);
}
