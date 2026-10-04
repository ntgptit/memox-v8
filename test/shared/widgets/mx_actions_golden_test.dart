@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import 'support/mx_harness.dart';

void main() {
  for (final variant in mxThemes.keys) {
    testWidgets('mx_icon_button tones $variant', (tester) async {
      await expectMxGolden(
        tester,
        component: 'icon_button',
        state: 'tones',
        variant: variant,
        sheet: Wrap(
          children: [
            for (final tone in MxIconButtonTone.values) ...[
              MxIconButton(
                icon: Icons.more_vert,
                semanticLabel: 'More',
                tone: tone,
                onPressed: () {},
              ),
              MxIconButton(
                icon: Icons.more_vert,
                semanticLabel: 'More',
                tone: tone,
                onPressed: null,
              ),
            ],
          ],
        ),
      );
    });
    testWidgets('mx_fab resting $variant', (tester) async {
      await expectMxGolden(
        tester,
        component: 'fab',
        state: 'resting',
        variant: variant,
        sheet: Padding(
          padding: const EdgeInsets.all(16),
          child: MxFab(
            icon: Icons.add,
            semanticLabel: 'New deck',
            onPressed: () {},
          ),
        ),
      );
    });
  }
}
