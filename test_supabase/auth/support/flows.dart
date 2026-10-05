import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';

import 'local_device.dart';
import 'local_env.dart';
import 'mailpit.dart';

/// An account that holds [names]: a device creates them, syncs, links a
/// fresh email and closes. Returns the email and the account's id.
Future<({String email, String id})> accountWithDecks(
  LocalEnv env,
  Mailpit mail,
  Set<String> names,
) async {
  final device = await LocalDevice.launch(env);
  try {
    for (final name in names) {
      await device.createDeck(name);
    }
    await device.syncNow();
    final email = freshEmail();
    await device.signInByEmail(mail, email);
    await device.syncNow();
    return (email: email, id: device.userId!);
  } finally {
    await device.close();
  }
}

/// A device whose library is [names], synced, on its anonymous user.
Future<LocalDevice> anonymousWithDecks(
  LocalEnv env,
  Set<String> names, {
  StoreFor? store,
}) async {
  final device = await LocalDevice.launch(env, store: store);
  for (final name in names) {
    await device.createDeck(name);
  }
  await device.syncNow();
  return device;
}

/// The app's path when an email already has an account (#17, #18, #21):
/// the link is refused, the switch starts with [choice], and the target
/// signs in with a code. Ends synced on the account.
Future<void> moveTo(
  LocalDevice device,
  Mailpit mail,
  String email,
  TransitionChoice choice,
) async {
  await expectLater(
    device.coordinator.requestCode(email),
    throwsA(isA<IdentityTakenFailure>()),
  );
  await device.coordinator.beginSwitch(choice: choice, targetHint: email);
  await device.waitFor<Transitioning>(where: (s) => s.isAwaitingTargetSignIn);
  await device.signInByEmail(mail, email);
  await device.waitFor<Ready>(where: (s) => s.user.email == email);
  await device.syncNow();
}
