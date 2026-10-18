import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_transition_layer_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

// System Back at the transition layer's root (DEV-167): Cancel while it
// shows (account_transition_layer_test.dart), swallowed otherwise.

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
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
