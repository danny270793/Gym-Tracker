import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../../core/auth/auth_session_notifier.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/offline_error.dart';
import '../../../../core/storage/cached.dart';
import '../../../../core/storage/json_list_cache.dart';
import '../../../../core/storage/local_json_store.dart';
import '../../domain/entities/exercise_entity.dart';
import '../../domain/repositories/exercises_repository.dart';
import '../datasources/exercises_remote_datasource.dart';

class ExercisesRepositoryImpl implements ExercisesRepository {
  ExercisesRepositoryImpl(this._remote, this._store, this._user)
    : _cache = JsonListCache<ExerciseEntity>(
        store: _store,
        user: _user,
        name: 'cache_exercises',
        fromJson: ExerciseEntity.fromJson,
        toJson: (e) => e.toJson(),
        idOf: (e) => e.id,
      );

  final ExercisesRemoteDatasource _remote;
  final LocalJsonStore _store;
  final CurrentUser _user;
  final JsonListCache<ExerciseEntity> _cache;

  static const _uuid = Uuid();

  @override
  Future<Cached<List<ExerciseEntity>>> getAll() async {
    try {
      final list = await _remote.getAll();
      await _cache.write(list);
      return Cached(list);
    } catch (e) {
      if (!isOfflineError(e)) rethrow;
      final cached = await _cache.read();
      if (cached == null) rethrow;
      AppLogger.warn('offline: serving ${cached.length} cached exercises');
      return Cached(cached, fromCache: true);
    }
  }

  @override
  Future<ExerciseEntity> save(ExerciseEntity exercise) async {
    await _remote.upsert(exercise, userId: _user.requireUserId());
    await _cache.upsert(exercise);
    return exercise;
  }

  @override
  Future<void> delete(ExerciseEntity exercise) async {
    await _remote.softDelete(exercise.id);
    await _cache.remove(exercise.id);
    await deleteImages(exercise.imagePaths);
  }

  /// `<app documents>/gym_tracker/users/<userId>/images/<file>`.
  File _localFile(String path) => File(
    p.join(
      _store.imagesDirectory(_user.requireUserId()).path,
      p.basename(path),
    ),
  );

  @override
  Future<String> importImage(String sourcePath) async {
    final userId = _user.requireUserId();
    final ext = p.extension(sourcePath).toLowerCase();
    final path = '$userId/${_uuid.v4()}${ext.isEmpty ? '.jpg' : ext}';
    final source = File(sourcePath);
    await _remote.uploadImage(source, path);
    final local = _localFile(path);
    await local.parent.create(recursive: true);
    await source.copy(local.path);
    AppLogger.info('image uploaded: $path');
    return path;
  }

  @override
  Future<void> deleteImages(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _remote.removeImages(paths);
    } catch (e, s) {
      // An orphaned file in Storage is harmless; don't fail the edit for it.
      AppLogger.error('failed to remove images from storage', e, s);
    }
    for (final path in paths) {
      final f = _localFile(path);
      if (await f.exists()) await f.delete();
    }
  }

  @override
  Future<File> imageFile(String path) async {
    final local = _localFile(path);
    if (await local.exists()) return local;
    final bytes = await _remote.downloadImage(path);
    await local.parent.create(recursive: true);
    await local.writeAsBytes(bytes, flush: true);
    return local;
  }
}
