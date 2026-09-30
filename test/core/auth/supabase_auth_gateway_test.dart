import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/supabase_auth_gateway.dart';
import 'package:memox/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// The gateway over a real GoTrueClient and a fake HTTP server: its answers
// become the app's types and failures (auth spec §5, plan ruling 16).
Map<String, Object?> _session(String id, {bool anonymous = true}) => {
  'access_token': 'access-$id',
  'token_type': 'bearer',
  'expires_in': 3600,
  // Far in the future, so the client never tries to refresh it.
  'expires_at': 4102444800,
  'refresh_token': 'refresh-$id',
  'user': {
    'id': id,
    'aud': 'authenticated',
    'role': 'authenticated',
    'is_anonymous': anonymous,
    'created_at': '2026-09-30T00:00:00Z',
    'app_metadata': <String, Object?>{},
    'user_metadata': <String, Object?>{},
  },
};

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late Future<http.Response> Function(http.Request request) server;

  SupabaseAuthGateway gateway() => SupabaseAuthGateway(
    GoTrueClient(
      url: 'http://auth.test/auth/v1',
      httpClient: MockClient((request) => server(request)),
      flowType: AuthFlowType.implicit,
      autoRefreshToken: false,
    ),
    pickGoogle: () async =>
        const GoogleCredential(idToken: 'id', email: 'g@example.com'),
  );

  test(
    'an anonymous sign-in gives a user id, a refresh token and an event',
    () async {
      server = (request) async => _json(_session('u1'));
      final g = gateway();
      final ids = <String?>[];
      final subscription = g.userIds.listen(ids.add);
      addTearDown(subscription.cancel);

      await g.signInAnonymously();
      await pumpEventQueue();

      expect(g.currentUserId, 'u1');
      expect(g.refreshToken, 'refresh-u1');
      expect(ids, contains('u1'));
    },
  );

  test(
    'a Google identity of another account is IdentityTaken(google)',
    () async {
      server = (request) async =>
          _json({'error_code': 'identity_already_exists', 'msg': 'taken'}, 422);

      await expectLater(
        gateway().linkGoogle(const GoogleCredential(idToken: 'id')),
        throwsA(
          isA<IdentityTakenFailure>().having(
            (f) => f.method,
            'method',
            IdentityMethod.google,
          ),
        ),
      );
    },
  );

  test('a refused code is InvalidCode; a flood is RateLimited', () async {
    server = (request) async => _json({
      'error_code': 'otp_expired',
      'msg': 'Token has expired or is invalid',
    }, 403);
    await expectLater(
      gateway().verifyEmailSignIn('a@example.com', '000000'),
      throwsA(isA<InvalidCodeFailure>()),
    );

    server = (request) async => _json({
      'error_code': 'over_email_send_rate_limit',
      'msg': 'slow down',
    }, 429);
    await expectLater(
      gateway().requestEmailSignIn('a@example.com'),
      throwsA(isA<RateLimitedFailure>()),
    );
  });

  test('sign-out offline still leaves no session', () async {
    var signedIn = false;
    server = (request) async {
      if (!signedIn) {
        signedIn = true;
        return _json(_session('u1'));
      }
      throw const SocketException('down');
    };
    final g = gateway();
    await g.signInAnonymously();

    await g.signOutLocal();

    expect(g.currentUserId, isNull);
    expect(g.refreshToken, isNull);
  });

  test('a network error is offline', () async {
    server = (request) async => throw const SocketException('down');

    await expectLater(
      gateway().signInAnonymously(),
      throwsA(isA<OfflineFailure>()),
    );
  });
}
