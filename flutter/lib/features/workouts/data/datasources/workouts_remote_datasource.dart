import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/logger/app_logger.dart';
import '../../domain/entities/workout_entity.dart';

abstract class WorkoutsRemoteDatasource {
  /// Newest first.
  Future<List<WorkoutEntity>> getAll();
  Future<void> save(WorkoutEntity workout);
  Future<void> softDelete(String id);
}

class WorkoutsSupabaseDatasource implements WorkoutsRemoteDatasource {
  WorkoutsSupabaseDatasource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<WorkoutEntity>> getAll() async {
    AppLogger.debug('fetching workouts');
    final rows = await _client
        .from('gym_workouts')
        .select('*, gym_workout_exercises(*, gym_workout_sets(*))')
        .isFilter('deletedAt', null)
        .order('date', ascending: false);
    return [for (final r in rows) workoutFromRow(r)];
  }

  static int _byPosition(Map<String, dynamic> a, Map<String, dynamic> b) =>
      (a['position'] as int).compareTo(b['position'] as int);

  static List<Map<String, dynamic>> _children(Object? raw) =>
      [...((raw as List?) ?? const []).cast<Map<String, dynamic>>()]
        ..sort(_byPosition);

  /// Maps a `gym_workouts` row with embedded exercises and sets to the app's
  /// JSON shape (`planned` snapshot, ordered `sets`).
  static WorkoutEntity workoutFromRow(Map<String, dynamic> row) =>
      WorkoutEntity.fromJson({
        ...row,
        'exercises': [
          for (final e in _children(row['gym_workout_exercises']))
            {
              ...e,
              'planned': e['plannedSets'] == null
                  ? null
                  : {
                      'sets': e['plannedSets'],
                      'reps': e['plannedReps'],
                      'load': e['plannedLoad'],
                    },
              'sets': _children(e['gym_workout_sets']),
            },
        ],
      });

  @override
  Future<void> save(WorkoutEntity workout) {
    AppLogger.debug('saving workout ${workout.id}');
    return _client.rpc(
      'gym_save_workout',
      params: {'p_workout': workout.toJson()},
    );
  }

  @override
  Future<void> softDelete(String id) {
    final now = DateTime.now().toUtc().toIso8601String();
    return _client
        .from('gym_workouts')
        .update({'deletedAt': now, 'updatedAt': now})
        .eq('id', id);
  }
}
