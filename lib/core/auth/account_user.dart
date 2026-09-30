/// The account's role (auth spec O8): `public.profiles.role`.
enum AccountRole {
  user,
  admin;

  /// Anything but `admin` is a user.
  static AccountRole parse(String? name) => name == 'admin' ? admin : user;
}

/// Who the server says the signed-in user is: the answer of `me()` (auth
/// spec §2.3, §5). The app's own type; no SDK `User` leaves the gateway.
final class AccountUser {
  const AccountUser({
    required this.id,
    required this.isAnonymous,
    required this.role,
    this.email,
  });

  final String id;
  final String? email;
  final bool isAnonymous;
  final AccountRole role;

  bool get isAdmin => role == AccountRole.admin;

  @override
  bool operator ==(Object other) =>
      other is AccountUser &&
      other.id == id &&
      other.email == email &&
      other.isAnonymous == isAnonymous &&
      other.role == role;

  @override
  int get hashCode => Object.hash(id, email, isAnonymous, role);

  @override
  String toString() =>
      'AccountUser($id, anonymous: $isAnonymous, role: ${role.name})';
}
