@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import 'support/mx_harness.dart';

void main() {
  final Map<String, Widget> sheets = {
    'tones': Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tone in MxButtonTone.values) ...[
          MxButton(label: tone.name, tone: tone, onPressed: () {}),
          MxButton(label: tone.name, tone: tone, onPressed: null),
        ],
      ],
    ),
    'sizes': Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final size in MxButtonSize.values)
          MxButton(label: size.name, size: size, onPressed: () {}),
        for (final size in MxButtonSize.values)
          MxButton(
            label: size.name,
            size: size,
            tone: MxButtonTone.outline,
            icon: Icons.add,
            onPressed: () {},
          ),
      ],
    ),
    'states': SizedBox(
      width: 380,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          MxButton(label: 'Saving the deck', isLoading: true, onPressed: () {}),
          MxButton(
            label: 'Study this deck · 4 due',
            detail: 'Overdue first, then today',
            onPressed: () {},
          ),
          SizedBox(
            width: 220,
            child: MxButton(
              label: 'Import the cards from a file you exported before',
              tone: MxButtonTone.secondary,
              onPressed: () {},
            ),
          ),
          MxButton(
            label: 'Move to Trash',
            tone: MxButtonTone.destructive,
            icon: Icons.delete_outline,
            onPressed: () {},
          ),
        ],
      ),
    ),
  };
  for (final MapEntry(key: state, value: sheet) in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_button $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: 'button',
          state: state,
          variant: variant,
          sheet: sheet,
        );
      });
    }
  }
}
