import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/golden_harness.dart';
import '../../support/theme_harness.dart';

// The frame a themed golden captures (test/support/golden_harness.dart): a
// field's error line, which ForUI expands from the frame after the mount,
// is captured whole, at the same capture time as before.
void main() {
  testWidgets('an entrance started on the frame after the mount is finished '
      'by the capture, still at the capture time', (tester) async {
    final theme = buildLightTheme();
    await tester.pumpWidget(
      MaterialApp(
        themeAnimationDuration: Duration.zero,
        theme: materialHostTheme(theme),
        builder: mxThemeBuilder(theme),
        home: const Scaffold(
          body: MxTextField(
            hintText: 'Deck name',
            errorText: 'Name is required',
          ),
        ),
      ),
    );
    final mounted = tester.binding.clock.now();

    await pumpToGoldenFrame(tester);

    final line = tester.widget<Align>(
      find
          .ancestor(
            of: find.text('Name is required'),
            matching: find.byType(Align),
          )
          .first,
    );
    expect(line.heightFactor, 1);
    expect(tester.binding.clock.now().difference(mounted), goldenCaptureTime);
  });
}
