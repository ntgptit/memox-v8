import 'package:memox/core/auth/account_user.dart';

/// A signed-in account as screen 33 lists it (users spec §2).
final class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
    this.lastSignInAt,
  });

  final String id;
  final String email;
  final AccountRole role;
  final DateTime createdAt;
  final DateTime? lastSignInAt;

  ManagedUser withRole(AccountRole value) => ManagedUser(
    id: id,
    email: email,
    role: value,
    createdAt: createdAt,
    lastSignInAt: lastSignInAt,
  );

  @override
  bool operator ==(Object other) =>
      other is ManagedUser &&
      other.id == id &&
      other.email == email &&
      other.role == role &&
      other.createdAt == createdAt &&
      other.lastSignInAt == lastSignInAt;

  @override
  int get hashCode => Object.hash(id, email, role, createdAt, lastSignInAt);
}
