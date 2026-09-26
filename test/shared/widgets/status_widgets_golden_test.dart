@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

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

  testWidgets('MxWorkloadBreakdownLine and MxMasteryDonut', (tester) async {
    String overdue(int n) => '$n overdue';
    String today(int n) => '$n today';
    String fresh(int n) => '$n new';
    await expectThemedGoldens(
      tester,
      'mx_workload_donut',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          MxWorkloadBreakdownLine(
            overdueCount: 3,
            todayCount: 12,
            newCount: 5,
            overdueLabel: overdue,
            todayLabel: today,
            newLabel: fresh,
            fallback: 'Nothing due',
            suffix: 'across 4 decks',
          ),
          MxWorkloadBreakdownLine(
            overdueCount: 0,
            todayCount: 4,
            newCount: 0,
            overdueLabel: overdue,
            todayLabel: today,
            newLabel: fresh,
            fallback: 'Nothing due',
          ),
          MxWorkloadBreakdownLine(
            overdueCount: 0,
            todayCount: 0,
            newCount: 0,
            overdueLabel: overdue,
            todayLabel: today,
            newLabel: fresh,
            fallback: '42 cards · nothing due',
          ),
          const Row(
            spacing: 16,
            children: [
              MxMasteryDonut(fraction: 0),
              MxMasteryDonut(fraction: 0.2),
              MxMasteryDonut(fraction: 0.5),
              MxMasteryDonut(fraction: 1),
            ],
          ),
        ],
      ),
    );
  });

  testWidgets('MxStatTile, boxed and inline (FE-A6 D17)', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_stat_tile',
      const Column(
        spacing: 16,
        children: [
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: MxStatTile(
                  value: '0',
                  label: 'New',
                  layout: MxStatTileLayout.boxed,
                ),
              ),
              Expanded(
                child: MxStatTile(
                  value: '12',
                  label: 'Due',
                  emphasis: MxStatTileEmphasis.primary,
                  layout: MxStatTileLayout.boxed,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: MxStatTile(value: '20', label: 'Reviewed'),
              ),
              Expanded(
                child: MxStatTile(value: '20', label: 'Answered'),
              ),
              Expanded(
                child: MxStatTile(value: '3 / 23', label: 'Wrong'),
              ),
            ],
          ),
        ],
      ),
    );
  });
}
