import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/supabase_auth_errors.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/data/datasources/user_role_remote_data_source.dart';
import 'package:memox/features/account/domain/models/managed_user_model.dart';
import 'package:memox/features/account/domain/models/user_page_model.dart';

/// One user of `role_list`'s JSON.
ManagedUser managedUserOfJson(Map<String, Object?> json) => ManagedUser(
  id: json['id']! as String,
  email: json['email']! as String,
  role: AccountRole.parse(json['role'] as String?),
  createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
  lastSignInAt: switch (json['lastSignInAt']) {
    final String at => DateTime.parse(at).toUtc(),
    _ => null,
  },
);

/// `role_list`'s answer.
UserPage userPageOfJson(Map<String, Object?> json) => UserPage(
  users: [
    for (final item in json['items']! as List)
      managedUserOfJson(item! as Map<String, Object?>),
  ],
  next: json['next'] as String?,
);

/// The [Failure] a role call's error becomes (plan ruling 1): no session is
/// "not an admin"; the codes are core's one mapping.
Failure mapUserRoleError(Object error) => error is UserRoleSessionMissing
    ? NotAdminFailure(cause: error)
    : classifyAuthError(error);
