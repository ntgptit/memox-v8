import 'package:memox/core/auth/account_user.dart';
import 'package:memox/features/account/data/datasources/user_role_remote_data_source.dart';
import 'package:memox/features/account/data/mappers/user_role_mapper.dart';
import 'package:memox/features/account/domain/models/user_page_model.dart';
import 'package:memox/features/account/domain/repositories/user_role_repository.dart';

/// Roles through the admin RPCs (users spec §2).
final class UserRoleRepositoryImpl implements UserRoleRepository {
  UserRoleRepositoryImpl(this._remote);

  final UserRoleRemoteDataSource _remote;

  @override
  Future<UserPage> list(String query, {String? after}) =>
      _guard(() async => userPageOfJson(await _remote.list(query, after)));

  @override
  Future<AccountRole?> set(String userId, AccountRole role) => _guard(() async {
    final held = await _remote.set(userId, role.name);
    return held == null ? null : AccountRole.parse(held);
  });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapUserRoleError(error), stackTrace);
    }
  }
}
