import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('error: glyph and text in the error colour', (tester) async {
    await pumpMx(tester, const MxFieldMessage(message: 'Name is required'));

    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.alert)).color,
      AppColorSchemes.light.error,
    );
    expect(
      tester.widget<Text>(find.text('Name is required')).style!.color,
      AppColorSchemes.light.error,
    );
  });

  testWidgets('warning: amber glyph, warning ink text (I1)', (tester) async {
    await pumpMx(
      tester,
      const MxFieldMessage(
        message: 'Ten tags at most',
        tone: MxFieldMessageTone.warning,
      ),
      brightness: Brightness.dark,
    );

    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.alert)).color,
      MxSemanticColors.dark.warning,
    );
    expect(
      tester.widget<Text>(find.text('Ten tags at most')).style!.color,
      MxSemanticColors.dark.warning,
    );
  });

  testWidgets('a long message wraps instead of truncating', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 200,
        child: MxFieldMessage(
          message: 'This deck name is already long and still keeps going on',
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text));

    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
    expect(tester.getSize(find.byType(Text)).height, greaterThan(20));
  });

  testWidgets('announced as a live region', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxFieldMessage(message: 'Name is required'));

    expect(
      tester.getSemantics(find.text('Name is required')),
      isSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });
}
