import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_bulk_bar_widget.dart';

import '../../../support/widget_harness.dart';

void main() {
  // M3F-12: the bar's glyphs bring no IconTheme, so they read the ambient
  // one, which was the SDK's black 87% (white in dark), not a colour role.
  for (final brightness in Brightness.values) {
    testWidgets('M3F-12: a bulk command glyph is onSurfaceVariant '
        '($brightness)', (tester) async {
      await pumpMx(
        tester,
        CardBulkBarWidget(
          actions: [(icon: AppIcons.remove, label: 'Move', onTap: () {})],
        ),
        brightness: brightness,
      );
      final context = tester.element(find.byIcon(AppIcons.remove));

      expect(IconTheme.of(context).color, context.colors.mutedForeground);
    });
  }
}
