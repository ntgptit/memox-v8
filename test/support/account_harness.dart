import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/sync/di/sync_providers.dart';

import 'auth_fakes.dart';
import 'library_harness.dart';

/// A widget test over the library backend and one device of [AuthWorld],
/// started on its first anonymous user. The tree goes before the world's
/// database closes, so no stream outlives the test.
void accountTest(
  String description,
  Future<void> Function(WidgetTester tester, LibraryEnv env, AuthWorld world)
  body,
) {
  libraryTest(description, (tester, env) async {
    // Two in-memory databases by design: the app's and the account world's.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final world = AuthWorld();
    try {
      await readyAnonymous(world);
      await body(tester, env, world);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      // Its database and coordinator close on the real clock, not the
      // widget test's.
      await tester.runAsync(world.close);
    }
  });
}

/// The app's account providers on [world]: its coordinator and its sync.
List<Override> accountOverrides(AuthWorld world) => [
  accountCoordinatorProvider.overrideWithValue(world.coordinator),
  syncControlProvider.overrideWithValue(world.sync),
];

/// [world]'s anonymous user attached to [email] through a code.
Future<void> linkEmail(
  AuthWorld world, [
  String email = 'a@example.com',
]) async {
  await world.coordinator.requestCode(email);
  await world.coordinator.verifyCode(email, FakeAuthGateway.code);
}

/// [state] as the only account state, for a surface that renders it.
Override authStateOf(AuthState state) =>
    authStateProvider.overrideWith((ref) => Stream.value(state));

/// A transition record for a rendering test.
AccountTransition transitionOf(
  TransitionKind kind,
  TransitionStage stage, {
  TransitionChoice? choice,
  String? targetHint,
}) {
  final at = DateTime(2026, 9, 30, 9);
  return AccountTransition(
    opId: 'op-render',
    kind: kind,
    stage: stage,
    createdAt: at,
    updatedAt: at,
    choice: choice,
    targetHint: targetHint,
  );
}
