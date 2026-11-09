import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Signed-in user id, or null. Data is stored on the device per user, so every
/// local datasource reads [userId] at call time.
abstract mixin class CurrentUser {
  String? get userId;

  /// Throws when nobody is signed in: data calls are only made inside the shell.
  String requireUserId() {
    final id = userId;
    if (id == null || id.isEmpty) throw StateError('no signed-in user');
    return id;
  }
}

/// Bridges Supabase auth events to a [ChangeNotifier] for go_router's
/// `refreshListenable` and for re-creating the per-user cubits in `App`.
class AuthSessionNotifier extends ChangeNotifier with CurrentUser {
  AuthSessionNotifier(this._client) {
    _userId = _client.auth.currentUser?.id;
    _sub = _client.auth.onAuthStateChange.listen((data) {
      final next = data.session?.user.id;
      if (next != _userId) {
        _userId = next;
        notifyListeners();
      }
    });
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _sub;
  String? _userId;

  @override
  String? get userId => _userId;

  bool get isSignedIn => _userId != null;

  String get email => _client.auth.currentUser?.email ?? '';

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
