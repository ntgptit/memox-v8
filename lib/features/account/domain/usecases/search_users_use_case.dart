import 'package:memox/features/account/domain/models/user_page_model.dart';
import 'package:memox/features/account/domain/repositories/user_role_repository.dart';

/// Screen 33's search (users spec §3): the typed text, trimmed.
final class SearchUsersUseCase {
  const SearchUsersUseCase(this._roles);

  final UserRoleRepository _roles;

  Future<UserPage> call(String query, {String? after}) =>
      _roles.list(query.trim(), after: after);
}
