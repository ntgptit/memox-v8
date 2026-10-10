import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_soft_ground.dart';

void main() {
  testWidgets('a soft ground themes its content with Indigo Day in Night', (
    tester,
  ) async {
    late Color onSurface;
    late Color primaryText;
    late Color defaultText;
    late Color iconColor;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: MxSoftGround(
          decoration: const BoxDecoration(color: Color(0xFFE6FCF4)),
          child: Builder(
            builder: (context) {
              onSurface = context.colors.onSurface;
              primaryText = context.semanticColors.primaryText;
              defaultText = DefaultTextStyle.of(context).style.color!;
              iconColor = IconTheme.of(context).color!;
              return const Text('x');
            },
          ),
        ),
      ),
    );

    expect(onSurface, const Color(0xFF282E3E));
    expect(primaryText, MxSemanticColors.light.primaryText);
    expect(defaultText, const Color(0xFF282E3E));
    expect(iconColor, const Color(0xFF282E3E));
  });

  testWidgets('it paints the decoration it is given', (tester) async {
    const decoration = BoxDecoration(color: Color(0xFFFFEDAB));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const MxSoftGround(decoration: decoration, child: Text('x')),
      ),
    );

    final box = tester.widget<DecoratedBox>(
      find
          .ancestor(of: find.text('x'), matching: find.byType(DecoratedBox))
          .first,
    );
    expect(box.decoration, decoration);
  });
}
