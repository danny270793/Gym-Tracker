import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/logger/app_logger.dart';
import '../../domain/entities/routine_entity.dart';
import '../../domain/entities/weekly_plan_entity.dart';

abstract class PlanRemoteDatasource {
  Future<List<RoutineEntity>> getRoutines();
  Future<WeeklyPlanEntity> getWeeklyPlan();
  Future<void> saveRoutine(RoutineEntity routine);
  Future<void> deleteRoutine(String id);
  Future<void> setDay(int weekday, String? routineId, {required String userId});
}

class PlanSupabaseDatasource implements PlanRemoteDatasource {
  PlanSupabaseDatasource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RoutineEntity>> getRoutines() async {
    AppLogger.debug('fetching routines');
    final rows = await _client
        .from('gym_routines')
        .select('*, gym_routine_exercises(*)')
        .isFilter('deletedAt', null);
    return [for (final r in rows) routineFromRow(r)];
  }

  /// Maps a `gym_routines` row with embedded `gym_routine_exercises`.
  static RoutineEntity routineFromRow(Map<String, dynamic> row) {
    final children = [
      ...((row['gym_routine_exercises'] as List?) ?? const [])
          .cast<Map<String, dynamic>>(),
    ]..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    return RoutineEntity.fromJson({...row, 'exercises': children});
  }

  @override
  Future<WeeklyPlanEntity> getWeeklyPlan() async {
    final rows = await _client.from('gym_weekly_plan').select();
    return WeeklyPlanEntity(
      routineIdByWeekday: {
        for (final r in rows) r['weekday'] as int: r['routineId'] as String,
      },
    );
  }

  @override
  Future<void> saveRoutine(RoutineEntity routine) {
    AppLogger.debug('saving routine ${routine.id}');
    return _client.rpc(
      'gym_save_routine',
      params: {'p_routine': routine.toJson()},
    );
  }

  @override
  Future<void> deleteRoutine(String id) =>
      _client.rpc('gym_delete_routine', params: {'p_id': id});

  @override
  Future<void> setDay(
    int weekday,
    String? routineId, {
    required String userId,
  }) async {
    if (routineId == null) {
      await _client.from('gym_weekly_plan').delete().eq('weekday', weekday);
      return;
    }
    await _client.from('gym_weekly_plan').upsert({
      'userId': userId,
      'weekday': weekday,
      'routineId': routineId,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'userId,weekday');
  }
}
