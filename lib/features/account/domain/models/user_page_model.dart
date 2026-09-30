import 'package:memox/features/account/domain/models/managed_user_model.dart';

/// One page of `role_list`: 50 users by email, and the email to ask after
/// for the next page, null at the last (users spec §2).
final class UserPage {
  const UserPage({required this.users, required this.next});

  final List<ManagedUser> users;
  final String? next;
}
