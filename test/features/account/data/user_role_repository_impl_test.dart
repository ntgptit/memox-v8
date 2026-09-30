import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/data/datasources/user_role_remote_data_source.dart';
import 'package:memox/features/account/data/repositories/user_role_repository_impl.dart';
import 'package:memox/features/account/domain/models/managed_user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  late List<(String, Map<String, Object?>)> calls;
  late Object? Function(String, Map<String, Object?>) answer;
  var hasSession = true;

  UserRoleRepositoryImpl repository() => UserRoleRepositoryImpl(
    UserRoleRemoteDataSource(
      rpc: (function, params) async {
        calls.add((function, params));
        return answer(function, params);
      },
      hasSession: () => hasSession,
    ),
  );

  setUp(() {
    calls = [];
    hasSession = true;
  });

  test('a page of users, read from role_list', () async {
    answer = (_, _) => {
      'items': [
        {
          'id': 'u1',
          'email': 'a@example.com',
          'role': 'admin',
          'createdAt': '2026-09-01T08:00:00.000Z',
          'lastSignInAt': null,
        },
      ],
      'next': 'a@example.com',
    };

    final page = await repository().list('a', after: 'x@example.com');

    expect(calls.single.$1, 'role_list');
    expect(calls.single.$2, {'p_query': 'a', 'p_after': 'x@example.com'});
    expect(page.next, 'a@example.com');
    expect(
      page.users.single,
      ManagedUser(
        id: 'u1',
        email: 'a@example.com',
        role: AccountRole.admin,
        createdAt: DateTime.utc(2026, 9, 1, 8),
      ),
    );
  });

  test(
    'a role set is the role the server now holds; a gone user is null',
    () async {
      answer = (_, params) => {'id': params['p_user'], 'role': 'admin'};
      expect(
        await repository().set('u1', AccountRole.admin),
        AccountRole.admin,
      );
      expect(calls.single.$1, 'role_set');
      expect(calls.single.$2, {'p_user': 'u1', 'p_role': 'admin'});

      answer = (_, _) => throw const PostgrestException(message: 'NOT_FOUND');
      expect(await repository().set('u2', AccountRole.user), isNull);
    },
  );

  test('the server\'s refusals become the app\'s failures', () async {
    for (final (code, matcher) in [
      ('FORBIDDEN', isA<NotAdminFailure>()),
      ('LAST_ADMIN', isA<LastAdminFailure>()),
      ('ANONYMOUS_USER', isA<AnonymousUserFailure>()),
    ]) {
      answer = (_, _) => throw PostgrestException(message: code);
      await expectLater(
        repository().set('u1', AccountRole.user),
        throwsA(matcher),
      );
    }
  });

  test('no session is not an admin, and the server is not asked', () async {
    hasSession = false;

    await expectLater(repository().list(''), throwsA(isA<NotAdminFailure>()));
    expect(calls, isEmpty);
  });
}
