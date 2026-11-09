import '../auth/auth_session_notifier.dart';
import 'local_json_store.dart';

/// On-device copy of a list of entities for the signed-in user, kept in sync
/// after every successful remote read and write. Read only when offline.
class JsonListCache<T> {
  JsonListCache({
    required LocalJsonStore store,
    required CurrentUser user,
    required this.name,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
  }) : _store = store,
       _user = user;

  final LocalJsonStore _store;
  final CurrentUser _user;

  /// File name without extension, e.g. `cache_exercises`.
  final String name;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  final String Function(T) idOf;

  /// Null when nothing has been cached yet.
  Future<List<T>?> read() async {
    final raw = await _store.read(_user.requireUserId(), name);
    if (raw is! List) return null;
    return [
      for (final r in raw)
        if (r is Map<String, dynamic>) fromJson(r),
    ];
  }

  Future<void> write(List<T> items) => _store.write(
    _user.requireUserId(),
    name,
    [for (final i in items) toJson(i)],
  );

  Future<void> upsert(T item) async {
    final items = await read() ?? <T>[];
    final i = items.indexWhere((e) => idOf(e) == idOf(item));
    if (i >= 0) {
      items[i] = item;
    } else {
      items.add(item);
    }
    await write(items);
  }

  Future<void> remove(String id) async {
    final items = await read();
    if (items == null) return;
    await write(items.where((e) => idOf(e) != id).toList());
  }
}
