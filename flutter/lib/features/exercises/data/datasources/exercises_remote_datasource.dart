import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/logger/app_logger.dart';
import '../../domain/entities/exercise_entity.dart';

abstract class ExercisesRemoteDatasource {
  Future<List<ExerciseEntity>> getAll();
  Future<void> upsert(ExerciseEntity exercise, {required String userId});
  Future<void> softDelete(String id);
  Future<void> uploadImage(File file, String path);
  Future<Uint8List> downloadImage(String path);
  Future<void> removeImages(List<String> paths);
}

class ExercisesSupabaseDatasource implements ExercisesRemoteDatasource {
  ExercisesSupabaseDatasource(this._client);

  final SupabaseClient _client;

  static const table = 'gym_exercises';
  static const bucket = 'gym-exercise-images';

  @override
  Future<List<ExerciseEntity>> getAll() async {
    AppLogger.debug('fetching exercises');
    final rows = await _client
        .from(table)
        .select()
        .isFilter('deletedAt', null)
        .order('name');
    return [for (final r in rows) ExerciseEntity.fromJson(r)];
  }

  @override
  Future<void> upsert(ExerciseEntity exercise, {required String userId}) {
    AppLogger.debug('upserting exercise ${exercise.id}');
    return _client.from(table).upsert({
      ...exercise.toJson(),
      'userId': userId,
      'deletedAt': null,
    });
  }

  @override
  Future<void> softDelete(String id) {
    final now = DateTime.now().toUtc().toIso8601String();
    return _client
        .from(table)
        .update({'deletedAt': now, 'updatedAt': now})
        .eq('id', id);
  }

  @override
  Future<void> uploadImage(File file, String path) async {
    final ext = path.split('.').last.toLowerCase();
    await _client.storage
        .from(bucket)
        .upload(
          path,
          file,
          fileOptions: FileOptions(
            upsert: true,
            contentType: switch (ext) {
              'png' => 'image/png',
              'webp' => 'image/webp',
              'heic' => 'image/heic',
              _ => 'image/jpeg',
            },
          ),
        );
  }

  @override
  Future<Uint8List> downloadImage(String path) =>
      _client.storage.from(bucket).download(path);

  @override
  Future<void> removeImages(List<String> paths) async {
    if (paths.isEmpty) return;
    await _client.storage.from(bucket).remove(paths);
  }
}
