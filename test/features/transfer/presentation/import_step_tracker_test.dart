import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/core/theme/mx_status_colors.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_step_tracker_widget.dart';

import '../../../support/contrast.dart';
import '../../../support/library_harness.dart';

// A done step's check sits on the mastery fill, so it inks in onSuccessFill,
// not primaryForeground.
void main() {
  for (final (brightness, mx) in [
    (Brightness.light, MxStatusColors.light),
    (Brightness.dark, MxStatusColors.dark),
  ]) {
    libraryTest('a done step checks in onSuccessFill (${brightness.name})', (
      tester,
      env,
    ) async {
      await pumpLibraryScreen(
        tester,
        env,
        const Scaffold(
          body: ImportStepTrackerWidget(current: CardImportStep.preview),
        ),
        brightness: brightness,
      );

      final check = find.byIcon(AppIcons.check).first;
      expect(IconTheme.of(tester.element(check)).color, mx.onSuccessFill);
    });
  }

  // M3F-19: the tracker sits on the screen margin, as the page it steers.
  for (final (width, margin) in [(360.0, 16.0), (700.0, 24.0)]) {
    libraryTest(
      'the tracker keeps the $margin screen margin at ${width.toInt()} '
      'wide',
      (tester, env) async {
        await pumpLibraryScreen(
          tester,
          env,
          WindowWidthScope(
            width: width,
            child: const Scaffold(
              body: ImportStepTrackerWidget(current: CardImportStep.preview),
            ),
          ),
        );

        final gutter = tester
            .widget<Padding>(
              find
                  .descendant(
                    of: find.byType(ImportStepTrackerWidget),
                    matching: find.byType(Padding),
                  )
                  .first,
            )
            .padding
            .resolve(TextDirection.ltr);
        expect((gutter.left, gutter.right), (margin, margin));
      },
    );
  }

  test('onSuccessFill reads 3:1 on the mastery fill in both themes', () {
    for (final mx in [MxStatusColors.light, MxStatusColors.dark]) {
      expect(
        contrastRatio(mx.onSuccessFill, mx.successFill),
        greaterThanOrEqualTo(3),
      );
    }
  });
}
