import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/supabase_auth_errors.dart';
import 'package:memox/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [AuthGateway] over GoTrue (auth spec §5, O11). The one place that touches
/// Supabase's `User` and `Session`; only ids and tokens leave it.
class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._auth, {required this._pickGoogle});

  /// On the client main.dart initialized.
  factory SupabaseAuthGateway.instance({
    required Future<GoogleCredential> Function() pickGoogle,
  }) => SupabaseAuthGateway(
    Supabase.instance.client.auth,
    pickGoogle: pickGoogle,
  );

  final GoTrueClient _auth;
  final Future<GoogleCredential> Function() _pickGoogle;

  @override
  String? get currentUserId => _auth.currentSession?.user.id;

  @override
  Stream<String?> get userIds =>
      _auth.onAuthStateChange.map((state) => state.session?.user.id);

  @override
  String? get refreshToken => _auth.currentSession?.refreshToken;

  @override
  Future<void> signInAnonymously() => _guard(_auth.signInAnonymously);

  @override
  Future<void> requestEmailLink(String email) =>
      _guard(() => _auth.updateUser(UserAttributes(email: email)));

  @override
  Future<void> verifyEmailLink(String email, String code) => _guard(
    () => _auth.verifyOTP(type: OtpType.emailChange, email: email, token: code),
  );

  @override
  Future<void> requestEmailSignIn(String email) =>
      _guard(() => _auth.signInWithOtp(email: email, shouldCreateUser: true));

  @override
  Future<void> verifyEmailSignIn(String email, String code) => _guard(
    () => _auth.verifyOTP(type: OtpType.email, email: email, token: code),
  );

  @override
  Future<GoogleCredential> pickGoogle() => _pickGoogle();

  @override
  Future<void> linkGoogle(GoogleCredential credential) => _guard(
    () => _auth.linkIdentityWithIdToken(
      provider: OAuthProvider.google,
      idToken: credential.idToken,
      accessToken: credential.accessToken,
    ),
    method: IdentityMethod.google,
  );

  @override
  Future<void> signInGoogle(GoogleCredential credential) => _guard(
    () => _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: credential.idToken,
      accessToken: credential.accessToken,
    ),
    method: IdentityMethod.google,
  );

  @override
  Future<void> restoreSession(String refreshToken) =>
      _guard(() => _auth.setSession(refreshToken));

  /// GoTrue drops the session before it tells the server. When the server
  /// cannot be reached, the device is signed out all the same, which is
  /// what matters here.
  @override
  Future<void> signOutLocal() async {
    try {
      await _auth.signOut();
    } on Object catch (error, stackTrace) {
      if (_auth.currentSession == null) return;
      Error.throwWithStackTrace(classifyAuthError(error), stackTrace);
    }
  }

  static Future<void> _guard(
    Future<Object?> Function() call, {
    IdentityMethod method = IdentityMethod.email,
  }) async {
    try {
      await call();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        classifyAuthError(error, method: method),
        stackTrace,
      );
    }
  }
}
