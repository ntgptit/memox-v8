import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/data/datasources/user_role_remote_data_source.dart';
import 'package:memox/features/account/data/repositories/user_role_repository_impl.dart';

// SP2b 2.48: an RPC that never answers must not leave screen 33 spinning.
void main() {
  UserRoleRemoteDataSource silent() => UserRoleRemoteDataSource(
    rpc: (_, _) => Completer<Object?>().future,
    hasSession: () => true,
  );

  test('a role call that never answers times out at the call limit', () {
    fakeAsync((async) {
      Object? error;
      unawaited(
        silent()
            .list('', null)
            .then<void>(
              (_) {},
              onError: (Object caught) {
                error = caught;
              },
            ),
      );

      async.elapse(
        UserRoleRemoteDataSource.roleCallTimeout - const Duration(seconds: 1),
      );
      expect(error, isNull);
      async.elapse(const Duration(seconds: 1));
      expect(error, isA<TimeoutException>());
    });
  });

  test('role_set times out too, and the repository reads it as offline', () {
    fakeAsync((async) {
      Object? error;
      unawaited(
        UserRoleRepositoryImpl(silent())
            .set('u1', AccountRole.user)
            .then<void>(
              (_) {},
              onError: (Object caught) {
                error = caught;
              },
            ),
      );

      async.elapse(UserRoleRemoteDataSource.roleCallTimeout);
      expect(error, isA<OfflineFailure>());
    });
  });
}
