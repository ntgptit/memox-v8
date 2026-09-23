@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxButton tones, sizes and states', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_button',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          for (final tone in MxButtonTone.values)
            MxButton(label: tone.name, tone: tone, onPressed: () {}),
          MxButton(
            label: 'Small',
            size: MxButtonSize.small,
            icon: AppIcons.add,
            onPressed: () {},
          ),
          MxButton(
            label: 'Compact',
            size: MxButtonSize.compact,
            onPressed: () {},
          ),
          MxButton(label: 'Chip', size: MxButtonSize.chip, onPressed: () {}),
          MxButton(label: 'Reveal', size: MxButtonSize.study, onPressed: () {}),
          const MxButton(label: 'Disabled', onPressed: null),
          MxButton(label: 'Saving', isLoading: true, onPressed: () {}),
          MxButton(
            label: 'Start review',
            icon: AppIcons.play,
            isBlock: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  });
}
