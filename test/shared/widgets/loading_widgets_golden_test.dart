@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxSpinner and MxSkeleton', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_spinner_skeleton',
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Row(
            spacing: 16,
            children: [
              MxSpinner(),
              MxSpinner(size: MxSpinnerSize.compact),
              MxSpinner(size: MxSpinnerSize.standard),
              MxSpinner(size: MxSpinnerSize.large),
            ],
          ),
          MxSkeletonRow(),
          MxSkeletonRow(),
          MxSkeleton(width: 200),
          MxSkeleton(height: 40, isCircle: true),
        ],
      ),
    );
  });
}
