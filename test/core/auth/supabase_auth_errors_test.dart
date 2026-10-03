import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/supabase_auth_errors.dart';
import 'package:memox/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Auth spec §3.2: the error classes, from GoTrue's codes and the RPCs'.
void main() {
  test('a call that never arrived is offline', () {
    expect(
      classifyAuthError(const SocketException('down')),
      isA<OfflineFailure>(),
    );
    expect(
      classifyAuthError(AuthRetryableFetchException(message: 'offline')),
      isA<OfflineFailure>(),
    );
  });

  test("GoTrue's codes", () {
    Failure of(String code, {IdentityMethod method = IdentityMethod.email}) =>
        classifyAuthError(AuthApiException('x', code: code), method: method);

    for (final code in [
      'refresh_token_not_found',
      'refresh_token_already_used',
      'session_not_found',
      'user_not_found',
    ]) {
      expect(of(code), isA<SessionInvalidFailure>(), reason: code);
    }
    expect(
      of('email_exists'),
      isA<IdentityTakenFailure>().having(
        (f) => f.method,
        'method',
        IdentityMethod.email,
      ),
    );
    expect(
      of('identity_already_exists', method: IdentityMethod.google),
      isA<IdentityTakenFailure>().having(
        (f) => f.method,
        'method',
        IdentityMethod.google,
      ),
    );
    expect(of('otp_expired'), isA<InvalidCodeFailure>());
    expect(of('over_email_send_rate_limit'), isA<RateLimitedFailure>());
    expect(
      classifyAuthError(const AuthApiException('x', statusCode: '429')),
      isA<RateLimitedFailure>(),
    );
    expect(
      classifyAuthError(AuthSessionMissingException()),
      isA<SessionInvalidFailure>(),
    );
    expect(of('unexpected_failure'), isA<ServerFailure>());
  });

  test(
    'an address GoTrue refuses is the address, not a server error (2.42)',
    () {
      Failure of(String message, String code) => classifyAuthError(
        AuthApiException(message, statusCode: '422', code: code),
      );

      expect(
        of('Email address "x@" is invalid', 'email_address_invalid'),
        isA<InvalidEmailFailure>(),
      );
      expect(
        of(
          'Unable to validate email address: invalid format',
          'validation_failed',
        ),
        isA<InvalidEmailFailure>(),
      );
      expect(
        of('Password should be at least 6 characters', 'validation_failed'),
        isA<ServerFailure>(),
      );
    },
  );

  test("the RPCs' codes", () {
    Failure of(String code) =>
        classifyAuthError(PostgrestException(message: code, code: 'P0001'));

    expect(of('NOT_AUTHENTICATED'), isA<SessionInvalidFailure>());
    expect(of('UNAUTHORIZED'), isA<ProfileGoneFailure>());
    expect(of('CLAIM_INVALID'), isA<ClaimInvalidFailure>());
    expect(of('LAST_ADMIN'), isA<LastAdminFailure>());
    expect(of('ANONYMOUS_USER'), isA<AnonymousUserFailure>());
    expect(of('FORBIDDEN'), isA<NotAdminFailure>());
    expect(of('NOT_ANONYMOUS'), isA<ServerFailure>());
  });

  test('a failure passes through; an expired JWT is recognised', () {
    const failure = LastAdminFailure();
    expect(classifyAuthError(failure), same(failure));
    expect(
      isExpiredJwt(
        const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
      ),
      isTrue,
    );
    expect(
      isExpiredJwt(
        const PostgrestException(message: 'LAST_ADMIN', code: 'P0001'),
      ),
      isFalse,
    );
  });
}
