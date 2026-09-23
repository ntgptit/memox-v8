@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxBadge, MxStatusBadge and MxTagChip', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_badges_tags',
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MxBadge(label: '23 due'),
              MxBadge(label: '4 mastered', tone: MxBadgeTone.mastery),
              MxBadge(label: '2 late', tone: MxBadgeTone.warning),
              MxBadge(label: '1 failed', tone: MxBadgeTone.danger),
              MxBadge(label: '128 cards', tone: MxBadgeTone.neutral),
              MxBadge(label: '23 due', isSolid: true),
              MxBadge(
                label: '12 ready',
                tone: MxBadgeTone.mastery,
                icon: AppIcons.check,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MxStatusBadge(status: MxCardStatus.newCard, label: 'New'),
              MxStatusBadge(status: MxCardStatus.learning, label: 'Learning'),
              MxStatusBadge(status: MxCardStatus.reviewing, label: 'Reviewing'),
              MxStatusBadge(status: MxCardStatus.mastered, label: 'Mastered'),
              MxStatusBadge(
                status: MxCardStatus.learning,
                label: 'Learning',
                isDot: true,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MxTagChip(label: 'verbs'),
              MxTagChip(label: 'N5', isDense: true),
              MxTagChip(label: 'a tag long enough to reach the maximum'),
            ],
          ),
        ],
      ),
    );
  });
}
