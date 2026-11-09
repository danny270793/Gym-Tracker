import 'dart:io';
import 'dart:typed_data';

import 'package:gym_tracker/core/auth/auth_session_notifier.dart';
import 'package:gym_tracker/features/exercises/data/datasources/exercises_remote_datasource.dart';
import 'package:gym_tracker/features/exercises/domain/entities/exercise_entity.dart';
import 'package:gym_tracker/features/plan/data/datasources/plan_remote_datasource.dart';
import 'package:gym_tracker/features/plan/domain/entities/routine_entity.dart';
import 'package:gym_tracker/features/plan/domain/entities/weekly_plan_entity.dart';
import 'package:gym_tracker/features/workouts/data/datasources/workouts_remote_datasource.dart';
import 'package:gym_tracker/features/workouts/domain/entities/workout_entity.dart';

class FakeUser with CurrentUser {
  FakeUser([this.userId = 'alice']);
  @override
  String? userId;
}

/// Shared "server" state; set [offline] to make every call fail like no signal.
class FakeServer {
  bool offline = false;
  final exercises = <String, ExerciseEntity>{};
  final deletedExercises = <String>{};
  final routines = <String, RoutineEntity>{};
  final plan = <int, String>{};
  final workouts = <String, WorkoutEntity>{};
  final images = <String, Uint8List>{};

  void check() {
    if (offline) throw const SocketException('offline');
  }
}

class FakeExercisesRemote implements ExercisesRemoteDatasource {
  FakeExercisesRemote(this.s);
  final FakeServer s;

  @override
  Future<List<ExerciseEntity>> getAll() async {
    s.check();
    return s.exercises.values.toList();
  }

  @override
  Future<void> upsert(ExerciseEntity e, {required String userId}) async {
    s.check();
    s.exercises[e.id] = e;
  }

  @override
  Future<void> softDelete(String id) async {
    s.check();
    s.exercises.remove(id);
    s.deletedExercises.add(id);
  }

  @override
  Future<void> uploadImage(File file, String path) async {
    s.check();
    s.images[path] = await file.readAsBytes();
  }

  @override
  Future<Uint8List> downloadImage(String path) async {
    s.check();
    return s.images[path]!;
  }

  @override
  Future<void> removeImages(List<String> paths) async {
    s.check();
    paths.forEach(s.images.remove);
  }
}

class FakePlanRemote implements PlanRemoteDatasource {
  FakePlanRemote(this.s);
  final FakeServer s;

  @override
  Future<List<RoutineEntity>> getRoutines() async {
    s.check();
    return s.routines.values.toList();
  }

  @override
  Future<WeeklyPlanEntity> getWeeklyPlan() async {
    s.check();
    return WeeklyPlanEntity(routineIdByWeekday: Map.of(s.plan));
  }

  @override
  Future<void> saveRoutine(RoutineEntity r) async {
    s.check();
    s.routines[r.id] = r;
  }

  @override
  Future<void> deleteRoutine(String id) async {
    s.check();
    s.routines.remove(id);
    s.plan.removeWhere((_, v) => v == id);
  }

  @override
  Future<void> setDay(
    int weekday,
    String? routineId, {
    required String userId,
  }) async {
    s.check();
    routineId == null ? s.plan.remove(weekday) : s.plan[weekday] = routineId;
  }
}

class FakeWorkoutsRemote implements WorkoutsRemoteDatasource {
  FakeWorkoutsRemote(this.s);
  final FakeServer s;

  @override
  Future<List<WorkoutEntity>> getAll() async {
    s.check();
    return s.workouts.values.toList();
  }

  @override
  Future<void> save(WorkoutEntity w) async {
    s.check();
    s.workouts[w.id] = w;
  }

  @override
  Future<void> softDelete(String id) async {
    s.check();
    s.workouts.remove(id);
  }
}
