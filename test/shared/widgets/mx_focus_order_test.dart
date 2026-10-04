import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import 'support/mx_harness.dart';

/// Every Mx control shows the 2dp ring around what it paints when reached by
/// the keyboard, and never after a tap (DESIGN.md, MxFocusRing).
void main() {
  tearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );

  testWidgets('MxButton (chip size, short label)', (tester) async {
    final Widget control = MxButton(
      label: 'Go',
      size: MxButtonSize.chip,
      onPressed: () {},
    );
    await pumpMx(tester, control);
    final Size painted = tester.getSize(
      find.descendant(
        of: find.byType(TextButton),
        matching: find.byType(Material),
      ),
    );
    expect(painted.height, AppSize.buttonChip);
    await expectMxKeyboardRingOnly(tester, control, painted: painted);
  });

  testWidgets('MxIconButton: a circle around the 36 ink box', (tester) async {
    await expectMxKeyboardRingOnly(
      tester,
      MxIconButton(icon: Icons.add, semanticLabel: 'Add', onPressed: () {}),
      painted: const Size.square(AppSize.iconButton),
    );
  });

  testWidgets('MxFab', (tester) async {
    await expectMxKeyboardRingOnly(
      tester,
      MxFab(icon: Icons.add, semanticLabel: 'New deck', onPressed: () {}),
      painted: const Size.square(AppSize.fab),
    );
  });

  testWidgets('MxToggle', (tester) async {
    await expectMxKeyboardRingOnly(
      tester,
      MxToggle(isOn: true, onChanged: (_) {}, semanticLabel: 'Sound'),
      painted: const Size(AppSize.toggleWidth, AppSize.toggleHeight),
    );
  });

  testWidgets('MxFilterChip', (tester) async {
    final Widget control = MxFilterChip(
      label: 'All 42',
      isSelected: false,
      onSelected: (_) {},
    );
    await pumpMx(tester, control);
    final double width = tester.getSize(find.byType(DecoratedBox).last).width;
    await expectMxKeyboardRingOnly(
      tester,
      control,
      painted: Size(width, AppSize.chip),
    );
  });

  testWidgets('MxChipTrigger', (tester) async {
    final Widget control = MxChipTrigger(label: 'Manual', onOpen: () {});
    await pumpMx(tester, control);
    final double width = tester.getSize(find.byType(DecoratedBox).last).width;
    await expectMxKeyboardRingOnly(
      tester,
      control,
      painted: Size(width, AppSize.chip),
    );
  });

  testWidgets('MxSegmentedTray: the reached segment', (tester) async {
    final Widget control = MxSegmentedTray<int>(
      segments: const [
        MxSegmentedTrayItem(value: 1, label: 'Day'),
        MxSegmentedTrayItem(value: 2, label: 'Week'),
      ],
      selected: 1,
      onChanged: (_) {},
    );
    await pumpMx(tester, control);
    final double width = tester
        .getSize(
          find.ancestor(
            of: find.text('Day'),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .width;
    await expectMxKeyboardRingOnly(
      tester,
      control,
      painted: Size(width, AppSize.segment),
    );
  });

  testWidgets('MxOptionRow', (tester) async {
    final Widget control = SizedBox(
      width: 300,
      child: MxOptionRow(
        title: 'Manual order',
        isSelected: false,
        onSelected: () {},
      ),
    );
    await pumpMx(tester, control);
    final Size row = tester.getSize(find.byType(MxOptionRow));
    await expectMxKeyboardRingOnly(tester, control, painted: row);
  });

  testWidgets('MxSearchField trigger', (tester) async {
    final Widget control = SizedBox(
      width: 300,
      child: MxSearchField(hint: 'Search decks', onOpen: () {}),
    );
    await pumpMx(tester, control);
    final Size field = tester.getSize(find.byType(MxSearchField));
    await expectMxKeyboardRingOnly(tester, control, painted: field);
  });
}
