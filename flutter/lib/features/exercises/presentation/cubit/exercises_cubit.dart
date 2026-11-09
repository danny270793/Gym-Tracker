import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logger/app_logger.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/exercise_entity.dart';
import '../../domain/entities/load_type.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/usecases/delete_exercise_usecase.dart';
import '../../domain/usecases/get_exercises_usecase.dart';
import '../../domain/usecases/manage_exercise_images_usecase.dart';
import '../../domain/usecases/save_exercise_usecase.dart';
import 'exercises_state.dart';

class ExercisesCubit extends Cubit<ExercisesState> {
  final GetExercisesUsecase _getExercises;
  final SaveExerciseUsecase _saveExercise;
  final DeleteExerciseUsecase _deleteExercise;
  final ManageExerciseImagesUsecase _images;

  static const _uuid = Uuid();

  ExercisesCubit({
    required GetExercisesUsecase getExercises,
    required SaveExerciseUsecase saveExercise,
    required DeleteExerciseUsecase deleteExercise,
    required ManageExerciseImagesUsecase images,
  }) : _getExercises = getExercises,
       _saveExercise = saveExercise,
       _deleteExercise = deleteExercise,
       _images = images,
       super(const ExercisesInitial());

  /// Saves can finish after the cubit is closed (e.g. a page's debounced save
  /// right after sign-out recreated the per-user cubits).
  @override
  void emit(ExercisesState state) {
    if (!isClosed) super.emit(state);
  }

  static List<ExerciseEntity> _sorted(Iterable<ExerciseEntity> list) =>
      list.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Future<void> load() async {
    AppLogger.debug('loading exercises');
    emit(const ExercisesLoading());
    try {
      final result = await _getExercises();
      AppLogger.info('exercises loaded: ${result.value.length}');
      emit(ExercisesLoaded(_sorted(result.value), fromCache: result.fromCache));
    } catch (e, s) {
      AppLogger.error('failed to load exercises', e, s);
      emit(const ExercisesError());
    }
  }

  /// Creates when [id] is null, otherwise updates. Returns null on failure.
  Future<ExerciseEntity?> save({
    String? id,
    required String name,
    required List<MuscleGroup> primaryMuscles,
    required List<MuscleGroup> secondaryMuscles,
    required Equipment equipment,
    required LoadType loadType,
    String? notes,
    required List<String> imagePaths,
  }) async {
    final current = state.exercises;
    final now = DateTime.now();
    final existing = id == null ? null : state.byId(id);
    final entity = ExerciseEntity(
      id: id ?? _uuid.v4(),
      name: name.trim(),
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles
          .where((m) => !primaryMuscles.contains(m))
          .toList(),
      equipment: equipment,
      loadType: loadType,
      notes: (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
      imagePaths: imagePaths,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      final saved = await _saveExercise(entity);
      AppLogger.info('exercise saved: ${saved.id}');
      emit(
        ExercisesLoaded(
          _sorted([...current.where((e) => e.id != saved.id), saved]),
          fromCache: state.fromCache,
        ),
      );
      final removed = [
        for (final path in existing?.imagePaths ?? const <String>[])
          if (!saved.imagePaths.contains(path)) path,
      ];
      await _images.delete(removed);
      return saved;
    } catch (e, s) {
      AppLogger.error('failed to save exercise', e, s);
      emit(ExercisesActionError(current, fromCache: state.fromCache));
      return null;
    }
  }

  Future<bool> delete({required String id}) async {
    final current = state.exercises;
    final exercise = state.byId(id);
    if (exercise == null) return false;
    try {
      await _deleteExercise(exercise);
      AppLogger.info('exercise deleted: $id');
      emit(
        ExercisesLoaded(
          current.where((e) => e.id != id).toList(),
          fromCache: state.fromCache,
        ),
      );
      return true;
    } catch (e, s) {
      AppLogger.error('failed to delete exercise', e, s);
      emit(ExercisesActionError(current, fromCache: state.fromCache));
      return false;
    }
  }

  Future<String?> importImage(String sourcePath) async {
    try {
      return await _images.import(sourcePath);
    } catch (e, s) {
      AppLogger.error('failed to import image', e, s);
      return null;
    }
  }

  /// Removes an image that was uploaded but never saved on an exercise.
  Future<void> discardImage(String path) async {
    try {
      await _images.delete([path]);
    } catch (e, s) {
      AppLogger.error('failed to discard image', e, s);
    }
  }

  final _imageFiles = <String, Future<File?>>{};

  /// Local copy of a stored image (downloaded once), or null if unavailable.
  Future<File?> imageFile(String path) => _imageFiles.putIfAbsent(
    path,
    () => _images.file(path).then<File?>((f) => f).catchError((Object e) {
      AppLogger.warn('image unavailable: $path ($e)');
      _imageFiles.remove(path);
      return null;
    }),
  );
}
