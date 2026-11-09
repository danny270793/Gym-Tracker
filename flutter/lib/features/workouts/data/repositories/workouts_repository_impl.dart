import '../../../../core/auth/auth_session_notifier.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/offline_error.dart';
import '../../../../core/storage/cached.dart';
import '../../../../core/storage/json_list_cache.dart';
import '../../../../core/storage/local_json_store.dart';
import '../../../../core/storage/serial_queue.dart';
import '../../domain/entities/workout_entity.dart';
import '../../domain/repositories/workouts_repository.dart';
import '../datasources/workouts_remote_datasource.dart';

class WorkoutsRepositoryImpl implements WorkoutsRepository {
  WorkoutsRepositoryImpl(this._remote, LocalJsonStore store, CurrentUser user)
    : _cache = JsonListCache<WorkoutEntity>(
        store: store,
        user: user,
        name: 'cache_workouts',
        fromJson: WorkoutEntity.fromJson,
        toJson: (w) => w.toJson(),
        idOf: (w) => w.id,
      );

  final WorkoutsRemoteDatasource _remote;
  final JsonListCache<WorkoutEntity> _cache;

  /// The logging screen autosaves; keep saves of the same workout in order so
  /// an older snapshot never lands after a newer one.
  final _queue = SerialQueue();

  static List<WorkoutEntity> _sorted(List<WorkoutEntity> list) =>
      list..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<Cached<List<WorkoutEntity>>> getAll() async {
    try {
      final list = await _remote.getAll();
      await _cache.write(list);
      return Cached(_sorted(list));
    } catch (e) {
      if (!isOfflineError(e)) rethrow;
      final cached = await _cache.read();
      if (cached == null) rethrow;
      AppLogger.warn('offline: serving ${cached.length} cached workouts');
      return Cached(_sorted(cached), fromCache: true);
    }
  }

  @override
  Future<WorkoutEntity> save(WorkoutEntity workout) => _queue.run(() async {
    await _remote.save(workout);
    await _cache.upsert(workout);
    return workout;
  });

  @override
  Future<void> delete(String id) => _queue.run(() async {
    await _remote.softDelete(id);
    await _cache.remove(id);
  });
}
