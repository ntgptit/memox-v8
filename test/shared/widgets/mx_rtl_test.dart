import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import 'support/mx_harness.dart';

// Right-to-left coverage for every component whose layout has a start and
// an end (spec §5). The symmetric ones have nothing to mirror: MxCard,
// MxIconTile, MxSpinner, MxIconButton, MxFab, MxSelectionCheckbox,
// MxTagChip, MxEmptyState, MxErrorState and MxScreenScroll (the gutter is
// even). The rows, the bar, the breadcrumb, the scaffold, the progress fill
// and the button carry their own RTL tests.

/// One mirrored pair: what sits at the start and what sits at the end.
typedef _Pair = ({Widget Function() build, Finder start, Finder end});

final Map<String, _Pair> _pairs = {
  'MxSheetActions': (
    build: () => SizedBox(
      width: 380,
      child: MxSheetActions(
        cancelLabel: 'Cancel',
        onCancel: () {},
        confirmLabel: 'Save',
        onConfirm: () {},
      ),
    ),
    start: find.text('Cancel'),
    end: find.text('Save'),
  ),
  'MxSettingsRow': (
    build: () => SizedBox(
      width: 380,
      child: MxSettingsRow.navigation(
        title: 'Account',
        icon: Icons.person,
        onTap: () {},
      ),
    ),
    start: find.byType(MxIconTile),
    end: find.byIcon(Icons.chevron_right),
  ),
  'MxOptionRow': (
    build: () => SizedBox(
      width: 380,
      child: MxOptionRow(
        title: 'Manual order',
        isSelected: true,
        onSelected: () {},
      ),
    ),
    start: find.byType(AnimatedContainer),
    end: find.text('Manual order'),
  ),
  'MxStepper': (
    build: () => MxStepper(
      value: 20,
      min: 1,
      max: 99,
      onChanged: (_) {},
      decreaseLabel: 'Fewer',
      increaseLabel: 'More',
    ),
    start: find.byIcon(Icons.remove),
    end: find.byIcon(Icons.add),
  ),
  'MxTextField': (
    build: () => SizedBox(
      width: 380,
      child: MxTextField(
        controller: TextEditingController(),
        label: 'Name',
        requiredText: 'Required',
      ),
    ),
    start: find.text('Name'),
    end: find.text('Required'),
  ),
  'MxInlineBanner': (
    build: () => const SizedBox(
      width: 380,
      child: MxInlineBanner(
        tone: MxInlineBannerTone.warning,
        message: 'Sync is paused',
      ),
    ),
    start: find.byIcon(Icons.warning_amber_outlined),
    end: find.text('Sync is paused'),
  ),
  'MxNote': (
    build: () => SizedBox(
      width: 380,
      child: MxNote(
        text: 'Swipe a card to grade it.',
        onDismiss: () {},
        dismissLabel: 'Dismiss tip',
      ),
    ),
    start: find.byIcon(Icons.info_outline),
    end: find.byIcon(Icons.close),
  ),
  'MxFilterChip': (
    build: () =>
        MxFilterChip(label: 'Flagged', isSelected: true, onSelected: (_) {}),
    start: find.byIcon(Icons.check),
    end: find.text('Flagged'),
  ),
  'MxChipTrigger': (
    build: () => MxChipTrigger(label: 'Manual', onOpen: () {}),
    start: find.text('Manual'),
    end: find.byIcon(Icons.expand_more),
  ),
  'MxSearchField': (
    build: () => SizedBox(
      width: 380,
      child: MxSearchField(
        hint: 'Search decks',
        controller: TextEditingController(text: 'kor'),
        clearLabel: 'Clear',
      ),
    ),
    start: find.byIcon(Icons.search),
    end: find.byIcon(Icons.close),
  ),
  'MxFieldMessage': (
    build: () => const MxFieldMessage(message: 'Enter a name'),
    start: find.byIcon(Icons.error_outline),
    end: find.text('Enter a name'),
  ),
  'MxBadge': (
    build: () => const MxBadge(label: '3 due', icon: Icons.schedule),
    start: find.byIcon(Icons.schedule),
    end: find.text('3 due'),
  ),
  'MxSegmentedTray': (
    build: () => MxSegmentedTray<int>(
      segments: const [
        MxSegmentedTrayItem(value: 7, label: 'Week'),
        MxSegmentedTrayItem(value: 30, label: 'Month'),
      ],
      selected: 7,
      onChanged: (_) {},
    ),
    start: find.text('Week'),
    end: find.text('Month'),
  ),
  'MxListSectionHeader': (
    build: () => SizedBox(
      width: 380,
      child: MxListSectionHeader(
        title: 'Cards',
        trigger: MxChipTrigger(label: 'Newest', onOpen: () {}),
      ),
    ),
    start: find.text('CARDS'),
    end: find.text('Newest'),
  ),
  'MxActionSheetCommandRow': (
    build: () => SizedBox(
      width: 380,
      child: MxActionSheetCommandRow(
        icon: Icons.edit,
        label: 'Rename',
        onTap: () {},
      ),
    ),
    start: find.byIcon(Icons.edit),
    end: find.text('Rename'),
  ),
};

double _x(WidgetTester tester, Finder finder) =>
    tester.getCenter(finder.first).dx;

void main() {
  for (final MapEntry(key: name, value: pair) in _pairs.entries) {
    testWidgets('$name mirrors in right-to-left text', (tester) async {
      await pumpMx(tester, pair.build());
      expect(_x(tester, pair.start), lessThan(_x(tester, pair.end)));
      await pumpMx(tester, pair.build(), textDirection: TextDirection.rtl);
      expect(_x(tester, pair.start), greaterThan(_x(tester, pair.end)));
    });
  }

  testWidgets('MxStatusBadge leads with its dot from the start edge', (
    tester,
  ) async {
    const Widget badge = MxStatusBadge(
      kind: MxStatusBadgeKind.learning,
      label: 'Learning',
    );
    double offset() =>
        _x(tester, find.text('Learning')) -
        _x(tester, find.byType(MxStatusBadge));
    await pumpMx(tester, badge);
    expect(offset(), greaterThan(0));
    await pumpMx(tester, badge, textDirection: TextDirection.rtl);
    expect(offset(), lessThan(0));
  });

  testWidgets('MxToggle puts its on thumb at the end edge', (tester) async {
    final Widget toggle = MxToggle(isOn: true, onChanged: (_) {});
    Finder thumb() => find
        .descendant(of: find.byType(MxToggle), matching: find.byType(Container))
        .last;
    double offset() => _x(tester, thumb()) - _x(tester, find.byType(MxToggle));
    await pumpMx(tester, toggle);
    expect(offset(), greaterThan(0));
    await pumpMx(tester, toggle, textDirection: TextDirection.rtl);
    expect(offset(), lessThan(0));
  });

  testWidgets('MxSection and MxFooterBar start their words on the start edge', (
    tester,
  ) async {
    Widget sheet() => SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxSection(title: 'Study', children: [const Text('Daily goal')]),
          const MxFooterBar(caption: 'Saved'),
        ],
      ),
    );
    // The overline and the caption span their column; their words start
    // where their direction starts.
    TextDirection of(String words) =>
        tester.renderObject<RenderParagraph>(find.text(words)).textDirection;
    await pumpMx(tester, sheet());
    expect(of('STUDY'), TextDirection.ltr);
    expect(of('Saved'), TextDirection.ltr);
    await pumpMx(tester, sheet(), textDirection: TextDirection.rtl);
    expect(of('STUDY'), TextDirection.rtl);
    expect(of('Saved'), TextDirection.rtl);
  });

  testWidgets('MxDialog puts its confirm on the left in right-to-left text', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showMxDialog<void>(
            context,
            builder: (_) => MxDialog(
              title: 'Move to Trash?',
              actions: MxSheetActions(
                cancelLabel: 'Cancel',
                onCancel: () {},
                confirmLabel: 'Move',
                onConfirm: () {},
              ),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      _x(tester, find.text('Move')),
      lessThan(_x(tester, find.text('Cancel'))),
    );
  });

  testWidgets('MxBottomSheet starts its title on the right in right-to-left', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showMxBottomSheet<void>(
            context,
            builder: (_) =>
                const MxBottomSheet(title: 'Sort', child: SizedBox(height: 80)),
          ),
          child: const Text('Open'),
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(MxBottomSheet)).right -
          tester.getRect(find.text('Sort')).right,
      16,
    );
  });

  testWidgets('MxSnackbar puts its action on the left in right-to-left', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showMxSnackbar(
            context,
            message: 'Deck moved to Trash',
            actionLabel: 'Undo',
            onAction: () {},
            isUndo: true,
          ),
          child: const Text('Go'),
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(
      _x(tester, find.text('Undo')),
      lessThan(_x(tester, find.text('Deck moved to Trash'))),
    );
  });
}
