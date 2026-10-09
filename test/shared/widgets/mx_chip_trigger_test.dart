import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import '../../support/widget_harness.dart';

final _painted = find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(Material),
);

void main() {
  testWidgets('ghost: no fill, onSurfaceVariant label, a trailing chevron', (
    tester,
  ) async {
    await pumpMx(tester, MxChipTrigger(label: 'Sort: Due', onPressed: () {}));
    final material = tester.widget<Material>(_painted.first);

    expect(tester.getSize(_painted.first).height, 28);
    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, AppColorSchemes.light.onSurfaceVariant);
    expect(find.byIcon(AppIcons.chevronDown), findsOneWidget);
    expect(tester.getSize(find.byIcon(AppIcons.chevronDown)).width, 16);
  });

  testWidgets('opens its menu on tap and meets the 48 target', (tester) async {
    var taps = 0;
    await pumpMx(tester, MxChipTrigger(label: 'Sort', onPressed: () => taps++));
    await tester.tap(find.byType(MxChipTrigger));

    expect(taps, 1);
    await expectAccessibleTargets(tester);
  });

  // SW-REV-010: Import's sheet chip carries a workbook sheet name, user
  // data; a label wider than the column ends in an ellipsis, never an
  // overflow.
  testWidgets('a label wider than its column ends in an ellipsis', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 200,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: MxChipTrigger(
            label: 'Sheet: Vocabulary_Korean_Lesson_12_Final (3 of 5)',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<Text>(
            find.text('Sheet: Vocabulary_Korean_Lesson_12_Final (3 of 5)'),
          )
          .overflow,
      TextOverflow.ellipsis,
    );
  });

  testWidgets('pressed lays onSurfaceVariant; focus draws the shared ring in '
      'primaryForeground, not a Material side', (tester) async {
    await pumpMx(tester, MxChipTrigger(label: 'Sort', onPressed: () {}));
    final style = tester.widget<TextButton>(find.byType(TextButton)).style!;
    expect(
      style.overlayColor!.resolve({WidgetState.pressed}),
      AppColorSchemes.light.onSurfaceVariant.withValues(
        alpha: AppOpacity.pressed,
      ),
    );
    expect(style.side!.resolve({WidgetState.focused}), BorderSide.none);
    expect(
      tester.widget<MxFocusRing>(find.byType(MxFocusRing)).radius,
      BorderRadius.circular(AppRadius.full),
    );

    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final painter =
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) =>
                        w is CustomPaint &&
                        w.foregroundPainter is MxFocusRingPainter,
                  ),
                )
                .foregroundPainter!
            as MxFocusRingPainter;
    expect(painter.color, MxSemanticColors.light.primaryForeground);
  });
}
