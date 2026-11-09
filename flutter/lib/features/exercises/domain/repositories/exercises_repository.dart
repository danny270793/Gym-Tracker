import 'dart:io';

import '../../../../core/storage/cached.dart';
import '../entities/exercise_entity.dart';

abstract class ExercisesRepository {
  /// Active (not deleted) exercises.
  Future<Cached<List<ExerciseEntity>>> getAll();

  /// Inserts or replaces by id.
  Future<ExerciseEntity> save(ExerciseEntity exercise);

  /// Soft-deletes the exercise (workout history keeps pointing at it) and
  /// removes its photos.
  Future<void> delete(ExerciseEntity exercise);

  /// Uploads a picked image; returns its Storage path.
  Future<String> importImage(String sourcePath);
  Future<void> deleteImages(List<String> paths);

  /// Local copy of a stored image, downloaded on first use.
  Future<File> imageFile(String path);
}
