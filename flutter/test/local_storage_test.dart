import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/storage/legacy_local_data_migrator.dart';
import 'package:gym_tracker/core/storage/local_json_store.dart';
import 'package:gym_tracker/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:gym_tracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gym_tracker/features/auth/domain/entities/user_entity.dart';
import 'package:gym_tracker/features/exercises/data/repositories/exercises_repository_impl.dart';
import 'package:gym_tracker/features/plan/data/repositories/plan_repository_impl.dart';
import 'package:gym_tracker/features/plan/domain/entities/routine_entity.dart';
import 'package:gym_tracker/features/workouts/data/repositories/workouts_repository_impl.dart';

import 'fake_remotes.dart';
import 'test_data.dart';

class _FakeAuth implements AuthRemoteDatasource {
  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async => const UserEntity(id: 'alice', email: '');
  @override
  Future<void> signOut() async {}
  @override
  Future<void> updateEmail({required String newEmail}) async {}
  @override
  Future<void> updatePassword({required String newPassword}) async {}
}

void main() {
  late Directory tmp;
  late LocalJsonStore store;
  late FakeServer server;
  late FakeUser user;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gym_tracker_test');
    store = LocalJsonStore(tmp);
    server = FakeServer();
    user = FakeUser();
  });

  tearDown(() => tmp.delete(recursive: true));

  test(
    'reads come from the server and fall back to the cache offline',
    () async {
      final repo = ExercisesRepositoryImpl(
        FakeExercisesRemote(server),
        store,
        user,
      );
      await repo.save(exercise('press'));
      final online = await repo.getAll();
      expect(online.fromCache, isFalse);
      expect(online.value.map((e) => e.id), ['press']);

      server.offline = true;
      final offline = await repo.getAll();
      expect(offline.fromCache, isTrue);
      expect(offline.value.map((e) => e.id), ['press']);
    },
  );

  test('offline with nothing cached rethrows; writes fail offline', () async {
    final repo = WorkoutsRepositoryImpl(
      FakeWorkoutsRemote(server),
      store,
      user,
    );
    server.offline = true;
    expect(repo.getAll(), throwsA(isA<SocketException>()));
    expect(
      repo.save(workout('w', DateTime(2026), {})),
      throwsA(isA<SocketException>()),
    );
  });

  test('cache is per user', () async {
    final repo = ExercisesRepositoryImpl(
      FakeExercisesRemote(server),
      store,
      user,
    );
    await repo.save(exercise('press'));
    await repo.getAll();
    server.offline = true;
    user.userId = 'bob';
    expect(repo.getAll(), throwsA(isA<SocketException>()));
  });

  test('workouts come back newest first; concurrent saves all land', () async {
    final repo = WorkoutsRepositoryImpl(
      FakeWorkoutsRemote(server),
      store,
      user,
    );
    await Future.wait([
      for (var i = 0; i < 20; i++)
        repo.save(workout('w$i', DateTime(2026, 3, 1 + i), {})),
    ]);
    final all = (await repo.getAll()).value;
    expect(all, hasLength(20));
    expect(all.first.id, 'w19');
    server.offline = true;
    expect((await repo.getAll()).value, hasLength(20));
  });

  test('deleting a routine frees its plan days', () async {
    final repo = PlanRepositoryImpl(FakePlanRemote(server), store, user);
    await repo.saveRoutine(
      RoutineEntity(
        id: 'push',
        title: 'Push',
        createdAt: epoch,
        updatedAt: epoch,
      ),
    );
    await repo.setDay(1, 'push');
    final plan = await repo.setDay(4, 'push');
    expect(plan.trainingDays, 2);
    expect((await repo.deleteRoutine('push')).trainingDays, 0);
    expect((await repo.getPlan()).value.$1, isEmpty);
  });

  test(
    'images upload, download once into the local copy, and delete',
    () async {
      final repo = ExercisesRepositoryImpl(
        FakeExercisesRemote(server),
        store,
        user,
      );
      final src = File('${tmp.path}/photo.jpg')..writeAsBytesSync([1, 2, 3]);
      final path = await repo.importImage(src.path);
      expect(path, startsWith('alice/'));
      expect(server.images[path], [1, 2, 3]);

      // Drop the local copy: it is downloaded again on demand.
      await store.clearCache('alice');
      final file = await repo.imageFile(path);
      expect(file.readAsBytesSync(), [1, 2, 3]);

      await repo.deleteImages([path]);
      expect(server.images, isEmpty);
      expect(file.existsSync(), isFalse);
    },
  );

  test(
    'sign-out clears the offline copy but keeps migration backups',
    () async {
      final repo = ExercisesRepositoryImpl(
        FakeExercisesRemote(server),
        store,
        user,
      );
      await repo.save(exercise('press'));
      await repo.getAll();
      final backup = File(
        '${store.userDirectory('alice').path}/exercises.migrated.json',
      )..writeAsStringSync('{}');
      await AuthRepositoryImpl(_FakeAuth(), store, user).signOut();
      server.offline = true;
      expect(repo.getAll(), throwsA(isA<SocketException>()));
      expect(backup.existsSync(), isTrue);
    },
  );

  test(
    'device-only data is uploaded once, with photos, then backed up',
    () async {
      final dir = store.userDirectory('alice');
      final photo = File('${store.imagesDirectory('alice').path}/p1.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync([9]);
      expect(photo.existsSync(), isTrue);
      await store.write('alice', 'exercises', [
        exercise('press').copyWith(imagePaths: ['p1.jpg']).toJson(),
      ]);
      await store.write('alice', 'routines', [
        RoutineEntity(
          id: 'push',
          title: 'Push',
          exercises: const [
            PlannedExercise(exerciseId: 'press'),
            PlannedExercise(exerciseId: 'gone'),
          ],
          createdAt: epoch,
          updatedAt: epoch,
        ).toJson(),
      ]);
      await store.write('alice', 'weekly_plan', {
        'days': {'1': 'push', '3': 'missing'},
      });
      await store.write('alice', 'workouts', [
        workout('w1', DateTime(2026, 3, 2), {
          'press': [done(8, 50)],
          'gone': [done(8, 10)],
        }).toJson(),
      ]);

      LegacyLocalDataMigrator migrator() => LegacyLocalDataMigrator(
        store: store,
        user: user,
        exercises: FakeExercisesRemote(server),
        plan: FakePlanRemote(server),
        workouts: FakeWorkoutsRemote(server),
      );

      // Offline: nothing is marked done, so it retries later.
      server.offline = true;
      await expectLater(
        migrator().migrateIfNeeded(),
        throwsA(isA<SocketException>()),
      );
      expect(await migrator().hasLegacyData(), isTrue);

      server.offline = false;
      expect(await migrator().migrateIfNeeded(), isTrue);
      expect(server.exercises['press']!.imagePaths, ['alice/p1.jpg']);
      expect(server.images['alice/p1.jpg'], [9]);
      expect(server.routines['push']!.exercises.map((e) => e.exerciseId), [
        'press',
      ]);
      expect(server.plan, {1: 'push'});
      expect(server.workouts['w1']!.exercises.map((e) => e.exerciseId), [
        'press',
      ]);
      expect(File('${dir.path}/exercises.migrated.json').existsSync(), isTrue);
      expect(await migrator().migrateIfNeeded(), isFalse);
    },
  );
}
