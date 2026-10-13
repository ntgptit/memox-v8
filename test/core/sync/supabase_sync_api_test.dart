import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/supabase_sync_api.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_models.dart';

void main() {
  late List<String> calls;
  late Map<String, Object?> lastParams;

  SupabaseSyncApi apiReturning(Object? response, {Object? sessionError}) =>
      SupabaseSyncApi(
        ensureSession: () async {
          calls.add('session');
          if (sessionError != null) {
            throw sessionError;
          }
        },
        rpc: (function, params) async {
          calls.add(function);
          lastParams = params;
          return response;
        },
      );

  setUp(() {
    calls = [];
    lastParams = {};
  });

  test(
    'push sends the request as sync_push(request) after ensuring a session',
    () async {
      final api = apiReturning({
        'results': [
          {
            'opId': 'o',
            'status': 'applied',
            'serverVersion': 4,
            'code': null,
            'current': null,
          },
        ],
      });

      final response = await api.push(
        const PushRequestModel(
          deviceId: 'd',
          operations: [
            SyncOperationModel(
              opId: 'o',
              entityType: 'deck',
              entityId: 'x',
              op: 'delete',
              row: null,
            ),
          ],
        ),
      );

      expect(calls, ['session', 'sync_push']);
      expect(lastParams, {
        'request': {
          'deviceId': 'd',
          'operations': [
            {
              'opId': 'o',
              'entityType': 'deck',
              'entityId': 'x',
              'op': 'delete',
              'row': null,
            },
          ],
        },
      });
      expect(response.results.single.serverVersion, 4);
    },
  );

  test(
    'changes calls sync_changes(since, max_rows) and parses the page',
    () async {
      final api = apiReturning({
        'changes': [
          {
            'entityType': 'deck',
            'entityId': 'x',
            'serverVersion': 7,
            'deleted': true,
            'row': null,
          },
        ],
        'nextSince': 7,
        'hasMore': false,
      });

      final page = await api.changes(3, 500);

      expect(calls, ['session', 'sync_changes']);
      expect(lastParams, {'since': 3, 'max_rows': 500});
      expect(page.changes.single.isDeleted, isTrue);
      expect(page.nextSince, 7);
    },
  );

  test('a failed sign-in stops the call and reaches the scheduler', () async {
    final api = apiReturning(null, sessionError: StateError('offline'));

    await expectLater(api.changes(0, 500), throwsStateError);
    expect(calls, ['session']);
  });

  group('an RPC that never answers (DEV-186)', () {
    SupabaseSyncApi hanging() => SupabaseSyncApi(
      ensureSession: () async {},
      rpc: (_, _) => Completer<Object?>().future,
      timeout: const Duration(milliseconds: 20),
    );

    test('push times out as a network failure', () async {
      final error = await hanging()
          .push(const PushRequestModel(deviceId: 'd', operations: []))
          .then<Object>((_) => 'no error', onError: (Object e) => e);

      expect(error, isA<TimeoutException>());
      expect(classifySyncFailure(error), SyncFailureKind.network);
    });

    test('changes times out as a network failure', () async {
      final error = await hanging()
          .changes(0, 500)
          .then<Object>((_) => 'no error', onError: (Object e) => e);

      expect(error, isA<TimeoutException>());
      expect(classifySyncFailure(error), SyncFailureKind.network);
    });

    test('the default bound is 30 seconds', () {
      expect(SupabaseSyncApi.rpcTimeout, const Duration(seconds: 30));
    });
  });

  test('an RPC error reaches the scheduler', () async {
    final api = SupabaseSyncApi(
      ensureSession: () async {},
      rpc: (_, _) async => throw StateError('P0001 VALIDATION_FAILED'),
    );

    await expectLater(api.changes(0, 500), throwsStateError);
  });
}
