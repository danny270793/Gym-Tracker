import 'dart:io';

import 'package:path/path.dart' as p;

import '../../features/exercises/data/datasources/exercises_remote_datasource.dart';
import '../../features/exercises/domain/entities/exercise_entity.dart';
import '../../features/plan/data/datasources/plan_remote_datasource.dart';
import '../../features/plan/domain/entities/routine_entity.dart';
import '../../features/plan/domain/entities/weekly_plan_entity.dart';
import '../../features/workouts/data/datasources/workouts_remote_datasource.dart';
import '../../features/workouts/domain/entities/workout_entity.dart';
import '../auth/auth_session_notifier.dart';
import '../logger/app_logger.dart';
import 'local_json_store.dart';

/// Uploads data saved by the first, device-only version of the app
/// (`exercises.json`, `routines.json`, `weekly_plan.json`, `workouts.json`
/// and `images/`) to Supabase, once per account.
///
/// Every step is an upsert keyed by the original ids, so a run that fails
/// half way (e.g. offline) is simply retried on the next launch. When all
/// steps succeed the legacy files are renamed to `*.migrated.json` (kept as a
/// backup on the device) so the upload never runs again.
class LegacyLocalDataMigrator {
  LegacyLocalDataMigrator({
    required LocalJsonStore store,
    required CurrentUser user,
    required ExercisesRemoteDatasource exercises,
    required PlanRemoteDatasource plan,
    required WorkoutsRemoteDatasource workouts,
  }) : _store = store,
       _user = user,
       _exercises = exercises,
       _plan = plan,
       _workouts = workouts;

  final LocalJsonStore _store;
  final CurrentUser _user;
  final ExercisesRemoteDatasource _exercises;
  final PlanRemoteDatasource _plan;
  final WorkoutsRemoteDatasource _workouts;

  static const legacyFiles = [
    'exercises',
    'routines',
    'weekly_plan',
    'workouts',
  ];

  File _file(String userId, String name) =>
      File(p.join(_store.userDirectory(userId).path, '$name.json'));

  Future<bool> hasLegacyData() async {
    final userId = _user.userId;
    if (userId == null) return false;
    for (final name in legacyFiles) {
      if (await _file(userId, name).exists()) return true;
    }
    return false;
  }

  /// Returns true when something was uploaded.
  Future<bool> migrateIfNeeded() async {
    if (!await hasLegacyData()) return false;
    final userId = _user.requireUserId();
    AppLogger.info('uploading on-device data to Supabase');

    // 1. Exercises, with their photos moved to Storage paths.
    final exercises = [
      for (final r in await _store.readList(userId, 'exercises'))
        ExerciseEntity.fromJson(r),
    ];
    for (final e in exercises) {
      final paths = <String>[];
      for (final name in e.imagePaths) {
        if (name.contains('/')) {
          paths.add(name);
          continue;
        }
        final local = File(
          p.join(_store.imagesDirectory(userId).path, p.basename(name)),
        );
        if (!await local.exists()) continue;
        final path = '$userId/${p.basename(name)}';
        await _exercises.uploadImage(local, path);
        paths.add(path);
      }
      await _exercises.upsert(e.copyWith(imagePaths: paths), userId: userId);
    }
    final exerciseIds = {for (final e in exercises) e.id};

    // 2. Routines (only lines whose exercise still exists) and plan days.
    final routines = [
      for (final r in await _store.readList(userId, 'routines'))
        RoutineEntity.fromJson(r),
    ];
    for (final r in routines) {
      await _plan.saveRoutine(
        RoutineEntity(
          id: r.id,
          title: r.title.trim().isEmpty ? '—' : r.title,
          notes: r.notes,
          exercises: [
            for (final line in r.exercises)
              if (exerciseIds.contains(line.exerciseId)) line,
          ],
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
        ),
      );
    }
    final routineIds = {for (final r in routines) r.id};
    final planRaw = await _store.read(userId, 'weekly_plan');
    if (planRaw is Map<String, dynamic>) {
      final plan = WeeklyPlanEntity.fromJson(planRaw);
      for (final day in plan.routineIdByWeekday.entries) {
        if (routineIds.contains(day.value)) {
          await _plan.setDay(day.key, day.value, userId: userId);
        }
      }
    }

    // 3. Workouts.
    for (final r in await _store.readList(userId, 'workouts')) {
      final w = WorkoutEntity.fromJson(r);
      await _workouts.save(
        WorkoutEntity(
          id: w.id,
          date: w.date,
          // The routine may have been deleted on the device since.
          routineId: routineIds.contains(w.routineId) ? w.routineId : null,
          title: w.title,
          exercises: [
            for (final e in w.exercises)
              if (exerciseIds.contains(e.exerciseId)) e,
          ],
          notes: w.notes,
          finishedAt: w.finishedAt,
          createdAt: w.createdAt,
          updatedAt: w.updatedAt,
        ),
      );
    }

    for (final name in legacyFiles) {
      final f = _file(userId, name);
      if (await f.exists()) {
        await f.rename(p.join(f.parent.path, '$name.migrated.json'));
      }
    }
    AppLogger.info(
      'uploaded ${exercises.length} exercises, ${routines.length} routines',
    );
    return true;
  }
}
