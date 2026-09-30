import 'package:memox/core/auth/account_user.dart';
import 'package:memox/features/account/domain/repositories/user_role_repository.dart';

/// Makes a user an admin or a user (auth spec O9); null when the user is
/// gone.
final class SetUserRoleUseCase {
  const SetUserRoleUseCase(this._roles);

  final UserRoleRepository _roles;

  Future<AccountRole?> call(String userId, AccountRole role) {
    if (userId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'must not be empty');
    }
    return _roles.set(userId, role);
  }
}
