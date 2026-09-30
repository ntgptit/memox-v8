import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memox/core/network/remote_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('a call that never reached the server is network', () {
    for (final error in <Object>[
      const SocketException('down'),
      TimeoutException('slow'),
      http.ClientException('reset'),
      AuthRetryableFetchException(message: 'offline'),
    ]) {
      expect(
        classifyRemoteError(error),
        RemoteErrorKind.network,
        reason: '$error',
      );
    }
  });

  test('a refused sign-in is signIn, a server answer is server', () {
    expect(
      classifyRemoteError(const AuthException('refused')),
      RemoteErrorKind.signIn,
    );
    expect(
      classifyRemoteError(const PostgrestException(message: 'FORBIDDEN')),
      RemoteErrorKind.server,
    );
    expect(
      classifyRemoteError(const FormatException('json')),
      RemoteErrorKind.server,
    );
    expect(classifyRemoteError(StateError('x')), RemoteErrorKind.unknown);
  });

  test("an RPC's business code is its exception message", () {
    expect(
      rpcErrorCode(
        const PostgrestException(message: 'LAST_ADMIN', code: 'P0001'),
      ),
      'LAST_ADMIN',
    );
    expect(rpcErrorCode(const SocketException('down')), isNull);
  });
}
