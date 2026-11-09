import '../../../../core/auth/auth_session_notifier.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/storage/local_json_store.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;
  final LocalJsonStore _store;
  final CurrentUser _user;

  const AuthRepositoryImpl(this._datasource, this._store, this._user);

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) => _datasource.signIn(email: email, password: password);

  /// Data lives in Supabase; the offline copy on this device is dropped.
  @override
  Future<void> signOut() async {
    final uid = _user.userId;
    await _datasource.signOut();
    if (uid == null) return;
    try {
      await _store.clearCache(uid);
    } catch (e, s) {
      AppLogger.error('failed to clear offline cache', e, s);
    }
  }

  @override
  Future<void> updateEmail({required String newEmail}) =>
      _datasource.updateEmail(newEmail: newEmail);

  @override
  Future<void> updatePassword({required String newPassword}) =>
      _datasource.updatePassword(newPassword: newPassword);
}
