import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memox/core/sync/sync_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('no connection is network', () {
    expect(
      classifySyncFailure(const SocketException('down')),
      SyncFailureKind.network,
    );
    expect(
      classifySyncFailure(TimeoutException('slow')),
      SyncFailureKind.network,
    );
    expect(
      classifySyncFailure(http.ClientException('reset')),
      SyncFailureKind.network,
    );
    expect(
      classifySyncFailure(AuthRetryableFetchException(message: 'down')),
      SyncFailureKind.network,
    );
  });

  test('a refused anonymous sign-in is signIn', () {
    expect(
      classifySyncFailure(const AuthException('anonymous sign-ins disabled')),
      SyncFailureKind.signIn,
    );
  });

  test('a refused or unreadable RPC is server', () {
    expect(
      classifySyncFailure(const PostgrestException(message: 'denied')),
      SyncFailureKind.server,
    );
    expect(
      classifySyncFailure(const FormatException('bad json')),
      SyncFailureKind.server,
    );
    expect(classifySyncFailure(TypeError()), SyncFailureKind.server);
  });

  test('a sync RPC refused for want of an account is signIn (DEV-192)', () {
    expect(
      classifySyncFailure(const PostgrestException(message: 'UNAUTHORIZED')),
      SyncFailureKind.signIn,
    );
  });

  test('anything else is unknown', () {
    expect(classifySyncFailure(StateError('x')), SyncFailureKind.unknown);
  });

  test('a kind round-trips through its name', () {
    for (final kind in SyncFailureKind.values) {
      expect(SyncFailureKind.parse(kind.name), kind);
    }
    expect(SyncFailureKind.parse(null), isNull);
    expect(SyncFailureKind.parse('gone'), isNull);
  });
}
