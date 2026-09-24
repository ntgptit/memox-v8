import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_flag_mark.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_outcome_tile.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_status_distribution.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

/// Group E: counts, lifecycle, tags, rules and the workload and mastery
/// indicators.
class GalleryStatusSection extends StatelessWidget {
  const GalleryStatusSection({super.key});

  static String _overdue(int count) => '$count overdue';
  static String _today(int count) => '$count today';
  static String _fresh(int count) => '$count new';

  @override
  Widget build(BuildContext context) => const GallerySection(
    title: 'E · Status & metadata',
    children: [
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
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
      _CardListSamples(),
      Row(
        spacing: AppSpacing.control,
        children: [
          Expanded(
            child: MxOutcomeTile(
              label: 'Kept',
              body: 'Decks, cards and history',
              tone: MxOutcomeTone.kept,
            ),
          ),
          Expanded(
            child: MxOutcomeTile(
              label: 'Lost',
              body: 'Schedules and due dates',
              tone: MxOutcomeTone.lost,
            ),
          ),
        ],
      ),
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
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
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MxTagChip(label: 'verbs'),
          MxTagChip(label: 'N5', isDense: true),
          MxTagChip(label: 'a tag long enough to reach the maximum'),
        ],
      ),
      MxNote(text: 'Deleted decks stay recoverable for 30 days.'),
      MxWorkloadBreakdownLine(
        overdueCount: 3,
        todayCount: 12,
        newCount: 5,
        overdueLabel: _overdue,
        todayLabel: _today,
        newLabel: _fresh,
        fallback: 'Nothing due',
        suffix: 'across 4 decks',
      ),
      MxWorkloadBreakdownLine(
        overdueCount: 0,
        todayCount: 0,
        newCount: 0,
        overdueLabel: _overdue,
        todayLabel: _today,
        newLabel: _fresh,
        fallback: '42 cards · nothing due',
      ),
      Row(
        spacing: AppSpacing.gutter,
        children: [
          MxMasteryDonut(fraction: 0),
          MxMasteryDonut(fraction: 0.2),
          MxMasteryDonut(fraction: 0.5),
          MxMasteryDonut(fraction: 1),
        ],
      ),
    ],
  );
}

String _statusName(MxCardStatus status) => switch (status) {
  MxCardStatus.newCard => 'New',
  MxCardStatus.learning => 'Beginning',
  MxCardStatus.reviewing => 'Reviewing',
  MxCardStatus.mastered => 'Mastered',
};

/// The card list's marks (screen 07): the flag, a plain status label and the
/// status distribution.
class _CardListSamples extends StatelessWidget {
  const _CardListSamples();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.grouped,
    children: [
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MxFlagMark(semanticLabel: 'Flagged'),
          MxStatusBadge(
            status: MxCardStatus.reviewing,
            label: 'Reviewing',
            isPlain: true,
          ),
        ],
      ),
      MxStatusDistribution(
        counts: MxStatusCounts(
          newCards: 100,
          learning: 140,
          reviewing: 100,
          mastered: 80,
        ),
        label: _statusName,
      ),
    ],
  );
}
