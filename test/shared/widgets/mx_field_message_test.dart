import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a message is announced as it appears', (tester) async {
    await pumpMx(tester, const MxFieldMessage(message: 'Enter a name'));
    expect(
      tester.getSemantics(find.text('Enter a name')),
      isSemantics(isLiveRegion: true),
    );
  });

  testWidgets('each tone writes in its role', (tester) async {
    final ThemeData theme = mxThemes['light']!;
    await pumpMx(tester, const MxFieldMessage(message: 'Too long'));
    expect(
      tester.widget<Text>(find.text('Too long')).style!.color,
      theme.colorScheme.error,
    );
    await pumpMx(
      tester,
      const MxFieldMessage(message: 'Close', tone: MxFieldMessageTone.warning),
    );
    expect(
      tester.widget<Icon>(find.byType(Icon)).color,
      theme.extension<AppSemanticColors>()!.warning,
    );
  });
}
