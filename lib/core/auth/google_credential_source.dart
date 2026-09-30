import 'package:google_sign_in/google_sign_in.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/error/failure.dart';

/// Picks a Google account natively and returns its tokens for GoTrue (auth
/// spec O11). [serverClientId] is the Web OAuth client of SB-A4, from
/// `--dart-define=GOOGLE_WEB_CLIENT_ID=…`. The device check covers it, not a
/// unit test (plan ruling 17).
class GoogleCredentialSource {
  GoogleCredentialSource({
    this.serverClientId = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
  });

  final String serverClientId;
  Future<void>? _initialized;

  Future<GoogleCredential> pick() async {
    final google = GoogleSignIn.instance;
    try {
      await (_initialized ??= google.initialize(
        serverClientId: serverClientId.isEmpty ? null : serverClientId,
      ));
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const ServerFailure(cause: 'Google returned no id token');
      }
      final authorization = await account.authorizationClient
          .authorizationForScopes(const ['email']);
      return GoogleCredential(
        idToken: idToken,
        accessToken: authorization?.accessToken,
        email: account.email,
      );
    } on GoogleSignInException catch (error, stackTrace) {
      final failure = error.code == GoogleSignInExceptionCode.canceled
          ? GoogleCancelledFailure(cause: error)
          : ServerFailure(cause: error);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }
}
