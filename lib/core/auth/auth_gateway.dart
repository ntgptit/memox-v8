/// A Google account picked on the device (auth spec O11). Held in memory
/// only, and never logged: [toString] names no token.
final class GoogleCredential {
  const GoogleCredential({required this.idToken, this.accessToken, this.email});

  final String idToken;
  final String? accessToken;
  final String? email;

  @override
  String toString() => 'GoogleCredential(${email ?? 'unknown'})';
}

/// How an account signs in (account UI spec §9 B1): its identities.
enum SignInMethod { google, email }

/// Who is signed in, and every way to change that (auth spec §5). The SDK
/// is the truth about the session (R1). Every method throws a `Failure`.
abstract interface class AuthGateway {
  String? get currentUserId;

  /// The SDK's user id on every auth event, null once it holds no session.
  Stream<String?> get userIds;

  String? get refreshToken;

  /// The current user's identities, from the session the SDK keeps on the
  /// device: works offline (spec §9 B1). Empty without a session.
  Set<SignInMethod> get signInMethods;

  Future<void> signInAnonymously();

  /// Attaches [email] to the current anonymous user: a code goes to it.
  Future<void> requestEmailLink(String email);

  Future<void> verifyEmailLink(String email, String code);

  /// Signs in to [email]'s account, creating it if needed: a code goes to
  /// it.
  Future<void> requestEmailSignIn(String email);

  Future<void> verifyEmailSignIn(String email, String code);

  Future<GoogleCredential> pickGoogle();

  /// Attaches the Google identity to the current anonymous user.
  Future<void> linkGoogle(GoogleCredential credential);

  Future<void> signInGoogle(GoogleCredential credential);

  /// Back to the account of [refreshToken] (#25, #33).
  Future<void> restoreSession(String refreshToken);

  /// Drops the session on this device, even offline.
  Future<void> signOutLocal();
}
