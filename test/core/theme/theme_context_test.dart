import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/theme_context.dart';

void main() {
  testWidgets('semanticColors follows a theme switch', (tester) async {
    final mode = ValueNotifier(ThemeMode.light);
    addTearDown(mode.dispose);
    late Color primaryText;
    await tester.pumpWidget(
      ValueListenableBuilder(
        valueListenable: mode,
        builder: (_, value, _) => MaterialApp(
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: value,
          home: Builder(
            builder: (context) {
              primaryText = context.semanticColors.primaryText;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(primaryText, MxSemanticColors.light.primaryText);

    mode.value = ThemeMode.dark;
    await tester.pumpAndSettle();
    expect(primaryText, MxSemanticColors.dark.primaryText);
  });
}
