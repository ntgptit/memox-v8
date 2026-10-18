import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_status_colors.dart';
import 'package:memox/core/theme/theme_context.dart';

import '../../support/theme_harness.dart';

void main() {
  testWidgets('the getters read the ForUI theme in scope', (tester) async {
    final captured = await contextOf(tester, buildDarkTheme());
    final theme = buildDarkTheme();
    expect(captured.colors, theme.colors);
    expect(captured.texts.body.fontSize, theme.typography.body.xs.fontSize);
    expect(captured.status, MxStatusColors.dark);
    expect(captured.dimens, isA<AppDimens>());
    expect(captured.radii, theme.style.borderRadius);
    expect(captured.hairline, theme.style.borderWidth);
  });

  testWidgets('a ForUI theme without the app extensions fails with the fix '
      'named', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.touch,
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(
      () => captured.dimens,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('buildLightTheme()'),
        ),
      ),
    );
    expect(() => captured.status, throwsStateError);
  });
}
