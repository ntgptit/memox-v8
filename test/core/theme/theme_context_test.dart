import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';
import 'package:memox/core/theme/theme_context.dart';

void main() {
  testWidgets('the four getters read the ThemeData in scope', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final theme = Theme.of(captured);
    expect(captured.colors, theme.colorScheme);
    expect(captured.texts, theme.textTheme);
    expect(captured.mxColors, MxColorsExtension.dark);
    expect(captured.dimens, isA<AppDimens>());
  });

  testWidgets('both built themes carry both extensions', (tester) async {
    for (final theme in [buildLightTheme(), buildDarkTheme()]) {
      expect(theme.extension<MxColorsExtension>(), isNotNull);
      expect(theme.extension<AppDimens>(), isNotNull);
    }
  });
}
