import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/scheduler_type_label_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

/// An open deck of decks at a glance (screen 01): its algorithm, what it
/// holds, today's work with what is scheduled, and Study, disabled until
/// study sessions exist (spec A4). No mastery until BE-A7 (spec A5).
class DeckSummaryCardWidget extends StatelessWidget {
  const DeckSummaryCardWidget({
    super.key,
    required this.level,
    required this.schedulerType,
  });

  final DeckLevel level;
  final SchedulerType schedulerType;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final due = level.overdueCount + level.dueTodayCount;
    final cards = due + level.newCount + level.scheduledCount;
    return MxCard(
      isHero: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.micro,
        children: [
          Text(
            l10n.schedulerType(schedulerType).toUpperCase(),
            style: styles.overline,
          ),
          Text(
            l10n.deckRowMeta(
              l10n.deckSubDeckCount(level.deckCount),
              l10n.deckCardCount(cards),
            ),
            style: styles.rowTitle,
          ),
          MxWorkloadBreakdownLine(
            overdueCount: level.overdueCount,
            todayCount: level.dueTodayCount,
            newCount: level.newCount,
            overdueLabel: l10n.workloadOverdue,
            todayLabel: l10n.workloadToday,
            newLabel: l10n.workloadNew,
            fallback: cards == 0
                ? l10n.workloadNoCards
                : l10n.workloadNothingDue(cards),
            suffix: level.scheduledCount > 0
                ? l10n.deckScheduledCount(level.scheduledCount)
                : null,
          ),
          const SizedBox(height: AppSpacing.grouped),
          MxButton(
            label: due > 0 ? l10n.deckStudyThisDue(due) : l10n.deckStudyThis,
            icon: AppIcons.play,
            isBlock: true,
            onPressed: null,
          ),
        ],
      ),
    );
  }
}
