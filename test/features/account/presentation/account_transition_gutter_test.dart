import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_transition_layer_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

// M3F-19: the running step, centred in its page, keeps the screen margin at
// its sides and the space16 breathing room above and below.

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  for (final (width, margin) in [(360.0, 16.0), (700.0, 24.0)]) {
    libraryTest('the running step keeps the $margin screen margin at '
        '${width.toInt()} wide', (tester, env) async {
      await pumpLibraryScreen(
        tester,
        env,
        WindowWidthScope(
          width: width,
          child: AccountTransitionLayerWidget(navigatorKey: GlobalKey()),
        ),
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

      final gutter = tester
          .widget<Padding>(
            find
                .ancestor(
                  of: find.text(_en.accountSafeToClose),
                  matching: find.byType(Padding),
                )
                .first,
          )
          .padding
          .resolve(TextDirection.ltr);
      expect((gutter.left, gutter.right), (margin, margin));
      expect(
        (gutter.top, gutter.bottom),
        (const AppDimens().space16, const AppDimens().space16),
      );
    });
  }
}
