import 'dart:io';

import '../repositories/exercises_repository.dart';

/// Reference photos for an exercise, kept in Supabase Storage.
class ManageExerciseImagesUsecase {
  final ExercisesRepository _repository;

  const ManageExerciseImagesUsecase(this._repository);

  Future<String> import(String sourcePath) =>
      _repository.importImage(sourcePath);

  Future<void> delete(List<String> paths) => _repository.deleteImages(paths);

  Future<File> file(String path) => _repository.imageFile(path);
}
