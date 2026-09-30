import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/supabase_account_api.dart';
import 'package:memox/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final calls = <(String, Map<String, Object?>)>[];
  late Object? Function(String function) answer;
  var refreshes = 0;
  late Future<void> Function() refresh;

  SupabaseAccountApi api() => SupabaseAccountApi(
    rpc: (function, params) async {
      calls.add((function, params));
      final result = answer(function);
      if (result is Exception) throw result;
      return result;
    },
    refreshSession: () {
      refreshes++;
      return refresh();
    },
  );

  setUp(() {
    calls.clear();
    refreshes = 0;
    refresh = () async {};
  });

  test('me reads the account', () async {
    answer = (_) => {
      'id': 'u1',
      'email': 'a@example.com',
      'isAnonymous': false,
      'role': 'admin',
    };

    expect(
      await api().me(),
      const AccountUser(
        id: 'u1',
        email: 'a@example.com',
        isAnonymous: false,
        role: AccountRole.admin,
      ),
    );
    expect(calls.single.$1, 'me');
  });

  test(
    'the claim, the merge, the ack and the deletion call their RPCs',
    () async {
      answer = (function) => switch (function) {
        'account_claim_begin' => 'token-1',
        'account_merge' => {'status': 'MERGED'},
        _ => null,
      };
      final a = api();

      expect(await a.claimBegin(), 'token-1');
      await a.merge('token-1', 'op-1');
      await a.mergeAck('op-1');
      await a.deleteAccount();

      expect(calls.map((c) => c.$1), [
        'account_claim_begin',
        'account_merge',
        'account_merge_ack',
        'account_delete',
      ]);
      expect(calls[1].$2, {'p_token': 'token-1', 'p_operation_id': 'op-1'});
      expect(calls[2].$2, {'p_operation_id': 'op-1'});
    },
  );

  test('errors leave as failures', () async {
    answer = (_) =>
        const PostgrestException(message: 'LAST_ADMIN', code: 'P0001');
    await expectLater(api().deleteAccount(), throwsA(isA<LastAdminFailure>()));
    answer = (_) => const SocketException('down');
    await expectLater(api().me(), throwsA(isA<OfflineFailure>()));
  });

  test('an expired JWT is refreshed once and the call retried', () async {
    var first = true;
    answer = (_) {
      if (first) {
        first = false;
        return const PostgrestException(
          message: 'JWT expired',
          code: 'PGRST301',
        );
      }
      return {'id': 'u1', 'email': null, 'isAnonymous': true, 'role': 'user'};
    };

    final me = await api().me();

    expect(me.id, 'u1');
    expect(refreshes, 1);
    expect(calls, hasLength(2));
  });

  test('a refresh the server refuses is a lost session', () async {
    answer = (_) =>
        const PostgrestException(message: 'JWT expired', code: 'PGRST301');
    refresh = () async =>
        throw const AuthApiException('gone', code: 'refresh_token_not_found');

    await expectLater(api().me(), throwsA(isA<SessionInvalidFailure>()));
  });
}
