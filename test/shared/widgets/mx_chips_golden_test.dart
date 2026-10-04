@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import 'support/mx_harness.dart';

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('filter_chip', 'states'): () => Wrap(
      spacing: 8,
      children: [
        MxFilterChip(label: 'All 42', isSelected: true, onSelected: (_) {}),
        MxFilterChip(label: 'Flagged 3', isSelected: false, onSelected: (_) {}),
      ],
    ),
    ('chip_trigger', 'states'): () => Wrap(
      spacing: 8,
      children: [
        MxChipTrigger(label: 'Manual', onOpen: () {}),
        MxChipTrigger(
          label: 'Manual · Due only',
          isActive: true,
          onOpen: () {},
        ),
      ],
    ),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
