import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/providers/device_account_provider.dart';

import '../../../support/account_harness.dart';

const _account = AccountUser(
  id: 'x',
  email: 'a@example.com',
  isAnonymous: false,
  role: AccountRole.user,
);
const _anonymous = AccountUser(
  id: 'n',
  isAnonymous: true,
  role: AccountRole.user,
);

void main() {
  test('the confirmed, checked or refused account is the device\'s', () {
    expect(deviceAccountOf(const Ready(_account)), _account);
    expect(deviceAccountOf(const Validating(_account)), _account);
    expect(deviceAccountOf(const ReauthRequired(_account)), _account);
  });

  test('an anonymous device, a start and a transition have none', () {
    expect(deviceAccountOf(const Ready(_anonymous)), isNull);
    expect(deviceAccountOf(const Validating(null)), isNull);
    expect(deviceAccountOf(const LocalOnly()), isNull);
    expect(deviceAccountOf(null), isNull);
    expect(
      deviceAccountOf(
        Transitioning(
          transitionOf(TransitionKind.signOut, TransitionStage.started),
        ),
      ),
      isNull,
    );
  });
}
