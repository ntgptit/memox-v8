import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/mx_status_colors.dart';
import 'package:memox/features/study/presentation/widgets/support/study_appearing_widget.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../../support/widget_harness.dart';

Color? _hiddenBar(WidgetTester tester) {
  final bar = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(StudyAppearingWidget),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (bar.decoration as BoxDecoration).color;
}

void main() {
  testWidgets('the hidden bar is one step off the face it sits on, on the '
      'raised and the recessed ground, light and dark', (tester) async {
    for (final (brightness, scheme, mx) in [
      (Brightness.light, lightColorScheme, MxStatusColors.light),
      (Brightness.dark, darkColorScheme, MxStatusColors.dark),
    ]) {
      final grounds = {
        'raised': mx.cardSurface,
        'recessed': scheme.surfaceContainerLow,
      };
      for (final MapEntry(key: name, value: ground) in grounds.entries) {
        await pumpMx(
          tester,
          SizedBox(
            width: 300,
            child: MxCard(
              isRecessed: name == 'recessed',
              child: const StudyAppearingWidget(
                isShown: false,
                child: SizedBox.shrink(),
              ),
            ),
          ),
          brightness: brightness,
        );
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          _hiddenBar(tester),
          scheme.surfaceContainerHighest,
          reason: '$brightness $name',
        );
        expect(_hiddenBar(tester), isNot(ground), reason: '$brightness $name');
      }
    }
  });
}
