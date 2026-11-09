import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../logger/app_logger.dart';

/// On-device files, one folder per signed-in user. Supabase is the source of
/// truth; this holds the offline copy of the last successful reads and the
/// downloaded exercise photos:
///
/// ```
/// <app documents>/gym_tracker/users/<userId>/
///   cache_exercises.json  cache_routines.json  cache_weekly_plan.json
///   cache_workouts.json   images/<uuid>.jpg
///   *.migrated.json       (backup of the device-only first version)
/// ```
///
/// Each JSON file is `{"version": n, "data": ...}`. Writes go to a temp file
/// first, then rename, so a crash mid-write never leaves a truncated file.
class LocalJsonStore {
  LocalJsonStore(this.rootDirectory);

  /// `<app documents>/gym_tracker`.
  final Directory rootDirectory;

  static const int currentVersion = 1;

  static Future<LocalJsonStore> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(docs.path, 'gym_tracker'));
    await root.create(recursive: true);
    return LocalJsonStore(root);
  }

  Directory userDirectory(String userId) =>
      Directory(p.join(rootDirectory.path, 'users', userId));

  Directory imagesDirectory(String userId) =>
      Directory(p.join(userDirectory(userId).path, 'images'));

  File _file(String userId, String name) =>
      File(p.join(userDirectory(userId).path, '$name.json'));

  /// Returns the `data` payload of [name], or null when the file is missing or unreadable.
  Future<Object?> read(String userId, String name) async {
    final file = _file(userId, name);
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    } catch (e, s) {
      AppLogger.error('failed to read $name.json', e, s);
      return null;
    }
  }

  Future<void> write(String userId, String name, Object? data) async {
    final file = _file(userId, name);
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({'version': currentVersion, 'data': data}),
      flush: true,
    );
    await tmp.rename(file.path);
  }

  /// Deletes the offline copy and downloaded photos for [userId] (on sign-out).
  /// Keeps `*.migrated.json` backups.
  Future<void> clearCache(String userId) async {
    final dir = userDirectory(userId);
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (entity is File && name.startsWith('cache_')) await entity.delete();
    }
    final images = imagesDirectory(userId);
    if (await images.exists()) await images.delete(recursive: true);
  }

  /// Reads [name] as a list of JSON objects (empty when missing).
  Future<List<Map<String, dynamic>>> readList(
    String userId,
    String name,
  ) async {
    final raw = await read(userId, name);
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }
}
