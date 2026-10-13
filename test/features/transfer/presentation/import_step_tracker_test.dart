import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_step_tracker_widget.dart';

import '../../../support/library_harness.dart';

// A done step's check sits on the mastery fill, so it inks in onMastery,
// not onPrimary: the dark onPrimary is white since spec 2026-09-27 D1.
void main() {
  for (final (brightness, mx) in [
    (Brightness.light, MxColorsExtension.light),
    (Brightness.dark, MxColorsExtension.dark),
  ]) {
    libraryTest('a done step checks in onMastery (${brightness.name})', (
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
      expect(IconTheme.of(tester.element(check)).color, mx.onSuccessContainer);
    });
  }

  test('onMastery reads 3:1 on the mastery fill in both themes', () {
    for (final mx in [MxColorsExtension.light, MxColorsExtension.dark]) {
      final ink = mx.onSuccessContainer.computeLuminance();
      final fill = mx.successContainer.computeLuminance();
      final (hi, lo) = ink > fill ? (ink, fill) : (fill, ink);
      expect((hi + 0.05) / (lo + 0.05), greaterThanOrEqualTo(3));
    }
  });
}
