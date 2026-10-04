@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: children,
  ),
);

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('toggle', 'states'): () => Wrap(
      spacing: 8,
      children: [
        MxToggle(isOn: true, onChanged: (_) {}),
        MxToggle(isOn: false, onChanged: (_) {}),
        const MxToggle(isOn: true, onChanged: null),
        const MxToggle(isOn: false, onChanged: null),
      ],
    ),
    ('selection_checkbox', 'states'): () => const Wrap(
      spacing: 16,
      children: [
        MxSelectionCheckbox(isChecked: true),
        MxSelectionCheckbox(isChecked: false),
      ],
    ),
    ('option_row', 'states'): () => _column([
      MxOptionRow(
        title: 'Manual order',
        description: 'Drag decks to arrange them',
        isSelected: true,
        onSelected: () {},
      ),
      MxOptionRow(
        title: 'Date added',
        description: 'Newest first',
        isSelected: false,
        onSelected: () {},
      ),
      const MxOptionRow(
        title: 'SM-2',
        description: 'Locked after the first review',
        isSelected: false,
        onSelected: null,
      ),
      const MxOptionRow(
        title: 'Eight boxes',
        isSelected: true,
        onSelected: null,
      ),
    ]),
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
