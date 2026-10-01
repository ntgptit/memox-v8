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
import 'package:memox/shared/widgets/mx_mastery_donut.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

/// An open deck of decks at a glance (screen 01): its mastery donut
/// (BR-DECK-026) beside its algorithm, what it holds, today's work with what
/// is scheduled, and Study this deck while anything waits (FE-A6 D10).
class DeckSummaryCardWidget extends StatelessWidget {
  const DeckSummaryCardWidget({
    super.key,
    required this.level,
    required this.schedulerType,
    this.onStudy,
  });

  final DeckLevel level;
  final SchedulerType schedulerType;

  /// Opens the deck's Study Entry; null hides the action.
  final VoidCallback? onStudy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final due = level.overdueCount + level.dueTodayCount;
    final cards = due + level.newCount + level.scheduledCount;
    final overline = l10n.deckSummaryMastered(
      l10n.schedulerType(schedulerType),
    );
    return MxCard(
      isHero: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          Row(
            spacing: AppSpacing.gutter,
            children: [
              MxMasteryDonut(
                fraction: level.masteryFraction,
                semanticLabel: l10n.cardStatusMastered,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.micro,
                  children: [
                    Text(
                      overline.toUpperCase(),
                      semanticsLabel: overline,
                      style: styles.eyebrow,
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
                      // A term of its own, so it wraps whole (Wrap Rule).
                      scheduledCount: level.scheduledCount,
                      scheduledLabel: l10n.deckScheduledCount,
                      // A hero statement wraps between whole terms, never
                      // "…" (the Wrap Rule; critique 2026-09-30 part 3b).
                      canWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onStudy != null && due + level.newCount > 0)
            MxButton(
              label: due > 0 ? l10n.studyThisDeckDue(due) : l10n.studyThisDeck,
              icon: AppIcons.play,
              isBlock: true,
              onPressed: onStudy,
            ),
        ],
      ),
    );
  }
}
