import 'package:memox/core/error/failure.dart';
import 'package:memox/core/network/remote_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The one mapping from GoTrue's and the account RPCs' errors to the app's
/// [Failure]s (auth spec §3.2). [method] says which identity a "taken"
/// answer is about.
Failure classifyAuthError(
  Object error, {
  IdentityMethod method = IdentityMethod.email,
}) {
  if (error is Failure) return error;
  if (classifyRemoteError(error) == RemoteErrorKind.network) {
    return OfflineFailure(cause: error);
  }
  if (error is AuthException) return _fromAuth(error, method);
  return switch (rpcErrorCode(error)) {
    'NOT_AUTHENTICATED' => SessionInvalidFailure(cause: error),
    'UNAUTHORIZED' => ProfileGoneFailure(cause: error),
    'CLAIM_INVALID' => ClaimInvalidFailure(cause: error),
    'LAST_ADMIN' => LastAdminFailure(cause: error),
    'ANONYMOUS_USER' => AnonymousUserFailure(cause: error),
    'FORBIDDEN' => NotAdminFailure(cause: error),
    _ => ServerFailure(cause: error),
  };
}

Failure _fromAuth(AuthException error, IdentityMethod method) {
  if (error is AuthSessionMissingException) {
    return SessionInvalidFailure(cause: error);
  }
  return switch (error.code) {
    'refresh_token_not_found' ||
    'refresh_token_already_used' ||
    'session_not_found' ||
    'user_not_found' => SessionInvalidFailure(cause: error),
    'email_exists' || 'identity_already_exists' => IdentityTakenFailure(
      method: method,
      cause: error,
    ),
    // GoTrue answers a wrong and an expired code alike (plan ruling 2).
    'otp_expired' => InvalidCodeFailure(cause: error),
    'over_email_send_rate_limit' ||
    'over_request_rate_limit' => RateLimitedFailure(cause: error),
    'email_address_invalid' => InvalidEmailFailure(cause: error),
    // GoTrue words a malformed address as a validation failure too.
    'validation_failed' when _refusesAddress(error) => InvalidEmailFailure(
      cause: error,
    ),
    _ when error.statusCode == '429' => RateLimitedFailure(cause: error),
    _ => ServerFailure(cause: error),
  };
}

/// "Unable to validate email address: invalid format": the send-code
/// answer. Other validation failures that merely mention an email, such as
/// the verify call's "Only an email address or phone number should be
/// provided on verify", are not the address's fault.
bool _refusesAddress(AuthException error) =>
    error.message.toLowerCase().contains('validate email address');

/// PostgREST refused the access token as expired or invalid. The SDK
/// refreshes on a timer; a call that lands in between refreshes once.
bool isExpiredJwt(Object error) =>
    error is PostgrestException &&
    (error.code == 'PGRST301' || error.code == 'PGRST303');
