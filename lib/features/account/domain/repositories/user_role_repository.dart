import 'package:memox/core/auth/account_user.dart';
import 'package:memox/features/account/domain/models/user_page_model.dart';

/// An admin's reads and changes of roles (users spec §2). Throws
/// `NotAdminFailure`, `LastAdminFailure`, `AnonymousUserFailure`,
/// `OfflineFailure` or `ServerFailure`.
abstract interface class UserRoleRepository {
  /// The users whose email contains [query] (everyone when blank), after
  /// the email [after].
  Future<UserPage> list(String query, {String? after});

  /// The role [userId] now holds, or null when the user is gone.
  Future<AccountRole?> set(String userId, AccountRole role);
}
