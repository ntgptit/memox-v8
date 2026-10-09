import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_transition_layer_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

// System Back at the transition layer's root (DEV-167): Cancel while it
// shows, swallowed otherwise.

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  accountTest('Back on a sign-out stopped offline does what Cancel does: the '
      'account and every change stay', (tester, env, world) async {
    await linkEmail(world);
    world.device.pending = 2;
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    world.network.goOffline();
    await world.coordinator.signOut();
    await _settle(tester);
    expect(find.text(_en.commonCancel), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _settle(tester);

    expect(find.byType(AccountTransitionLayerWidget), findsNothing);
    expect(world.state, isA<Validating>());
    expect(world.device.resets, 0);
    expect(world.device.pending, 2);
  });

  libraryTest('Back while the layer runs, with no Cancel, is swallowed', (
    tester,
    env,
  ) async {
    final layer = GlobalKey<NavigatorState>();
    await pumpLibraryScreen(
      tester,
      env,
      AccountTransitionLayerWidget(navigatorKey: layer),
      overrides: [
        authStateOf(
          Transitioning(
            transitionOf(
              TransitionKind.switchAccount,
              TransitionStage.targetSignedIn,
              choice: TransitionChoice.merge,
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    expect(find.text(_en.commonCancel), findsNothing);

    expect(await layer.currentState!.maybePop(), isTrue);
    await tester.pump();

    expect(find.text(_en.accountStepMerging), findsWidgets);
  });
}
