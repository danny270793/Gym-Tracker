import '../../../../core/auth/auth_session_notifier.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/offline_error.dart';
import '../../../../core/storage/cached.dart';
import '../../../../core/storage/json_list_cache.dart';
import '../../../../core/storage/local_json_store.dart';
import '../../domain/entities/routine_entity.dart';
import '../../domain/entities/weekly_plan_entity.dart';
import '../../domain/repositories/plan_repository.dart';
import '../datasources/plan_remote_datasource.dart';

class PlanRepositoryImpl implements PlanRepository {
  PlanRepositoryImpl(this._remote, this._store, this._user)
    : _routines = JsonListCache<RoutineEntity>(
        store: _store,
        user: _user,
        name: 'cache_routines',
        fromJson: RoutineEntity.fromJson,
        toJson: (r) => r.toJson(),
        idOf: (r) => r.id,
      );

  final PlanRemoteDatasource _remote;
  final LocalJsonStore _store;
  final CurrentUser _user;
  final JsonListCache<RoutineEntity> _routines;

  static const _planCache = 'cache_weekly_plan';

  Future<WeeklyPlanEntity?> _readPlanCache() async {
    final raw = await _store.read(_user.requireUserId(), _planCache);
    return raw is Map<String, dynamic> ? WeeklyPlanEntity.fromJson(raw) : null;
  }

  Future<void> _writePlanCache(WeeklyPlanEntity plan) =>
      _store.write(_user.requireUserId(), _planCache, plan.toJson());

  @override
  Future<Cached<(List<RoutineEntity>, WeeklyPlanEntity)>> getPlan() async {
    try {
      final routines = await _remote.getRoutines();
      final plan = await _remote.getWeeklyPlan();
      await _routines.write(routines);
      await _writePlanCache(plan);
      return Cached((routines, plan));
    } catch (e) {
      if (!isOfflineError(e)) rethrow;
      final routines = await _routines.read();
      if (routines == null) rethrow;
      AppLogger.warn('offline: serving cached plan');
      return Cached((
        routines,
        await _readPlanCache() ?? const WeeklyPlanEntity(),
      ), fromCache: true);
    }
  }

  @override
  Future<RoutineEntity> saveRoutine(RoutineEntity routine) async {
    await _remote.saveRoutine(routine);
    await _routines.upsert(routine);
    return routine;
  }

  @override
  Future<WeeklyPlanEntity> deleteRoutine(String id) async {
    await _remote.deleteRoutine(id);
    await _routines.remove(id);
    final plan = (await _readPlanCache() ?? const WeeklyPlanEntity())
        .withoutRoutine(id);
    await _writePlanCache(plan);
    return plan;
  }

  @override
  Future<WeeklyPlanEntity> setDay(int weekday, String? routineId) async {
    await _remote.setDay(weekday, routineId, userId: _user.requireUserId());
    // Re-read so the result reflects the server (e.g. another device's edits).
    final plan = await _remote.getWeeklyPlan();
    await _writePlanCache(plan);
    return plan;
  }
}
