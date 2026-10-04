import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

import 'support/mx_harness.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    testWidgets(
      '$name: the Section Label, upper-cased, in on-surface-variant',
      (tester) async {
        await pumpMx(
          tester,
          const MxListSectionHeader(title: 'Decks'),
          theme: theme,
        );
        final Text label = tester.widget<Text>(find.text('DECKS'));
        expect(label.style?.color, theme.colorScheme.onSurfaceVariant);
        expect(label.style?.fontSize, theme.textTheme.labelMedium?.fontSize);
      },
    );
  }

  testWidgets('a header for TalkBack; 8 down when it stands alone', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      const SizedBox(width: 380, child: MxListSectionHeader(title: 'Decks')),
    );
    expect(
      tester.getSemantics(find.text('DECKS')),
      isSemantics(isHeader: true),
    );
    final Rect header = tester.getRect(find.byType(MxListSectionHeader));
    final Rect label = tester.getRect(find.text('DECKS'));
    expect(label.top - header.top, 8);
    expect(label.left - header.left, 16);
    semantics.dispose();
  });

  testWidgets('48 tall with a trailing chip trigger at its end', (
    tester,
  ) async {
    var opened = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 380,
        child: MxListSectionHeader(
          title: 'Cards',
          trigger: MxChipTrigger(label: 'Newest', onOpen: () => opened++),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(MxListSectionHeader)).height,
      greaterThanOrEqualTo(AppSize.tapTarget),
    );
    await tester.tap(find.text('Newest'));
    expect(opened, 1);
  });
}
