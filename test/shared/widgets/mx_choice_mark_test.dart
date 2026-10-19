import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_choice_mark.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';

import '../../support/widget_harness.dart';

// The second channel of an answered choice (audit 2026-10-19, G3): a check
// on the right one, a cross on the wrong pick, in the tile's foreground.
void main() {
  const ink = Colors.teal;

  for (final (tone, glyph) in [
    (MxChoiceTone.right, AppIcons.check),
    (MxChoiceTone.wrong, AppIcons.close),
    (MxChoiceTone.idle, null),
    (MxChoiceTone.selected, null),
  ]) {
    testWidgets('${tone.name}: ${glyph == null ? 'no mark' : 'its glyph'}', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpMx(tester, MxChoiceMark(tone: tone, color: ink));

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      if (glyph == null) {
        expect(icons, isEmpty);
      } else {
        expect(icons.single.icon, glyph);
        final theme = IconTheme.of(tester.element(find.byType(Icon)));
        expect(theme.color, ink);
        expect(theme.size, const AppDimens().sizeIconInline);
      }
      // An unmarked tone keeps the room, so the text beside it holds still
      // (final review F7).
      expect(
        tester.getSize(find.byType(MxChoiceMark)),
        Size.square(const AppDimens().sizeIconInline),
      );
      expect(MxChoiceMark.isMarked(tone), glyph != null);
      // The tile's label already says right or wrong.
      expect(tester.getSemantics(find.byType(MxChoiceMark)).label, isEmpty);
      handle.dispose();
    });
  }
}
