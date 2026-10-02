import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

/// A card deck's progress (screen 07, spec A13): the mastery donut, the
/// scheduler, how many cards are mastered, today's work (owner decision
/// E-O1), and Study this deck while anything waits (FE-A6 D10). Mastery is
/// stated once: no four-state bar or legend (critique 2026-09-30, R2).
class CardDeckSummaryWidget extends StatelessWidget {
  const CardDeckSummaryWidget({
    super.key,
    required this.view,
    required this.algorithm,
    this.onStudy,
  });

  final CardListView view;

  /// The deck's scheduler, named ("SM-2", "Eight boxes").
  final String algorithm;

  /// Opens the deck's Study Entry; null hides the action.
  final VoidCallback? onStudy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final states = view.statusCounts;
    final total = states.total;
    final workload = view.workload;
    final overline = l10n.cardDeckProgress(algorithm);
    final due = workload.overdue + workload.today;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.grouped),
      child: MxCard(
        isHero: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.grouped,
          children: [
            Row(
              spacing: AppSpacing.gutter,
              children: [
                MxMasteryDonut(
                  fraction: total == 0 ? 0 : states.mastered / total,
                  semanticLabel: context.l10n.cardStatusMastered,
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
                        l10n.cardMasteredOf(states.mastered, total),
                        style: styles.dialogBody,
                      ),
                      MxWorkloadBreakdownLine(
                        overdueCount: workload.overdue,
                        todayCount: workload.today,
                        newCount: workload.newCards,
                        overdueLabel: l10n.workloadOverdue,
                        todayLabel: l10n.workloadToday,
                        newLabel: l10n.workloadNew,
                        fallback: total == 0
                            ? l10n.workloadNoCards
                            : l10n.workloadNothingDue(total),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onStudy != null && due + workload.newCards > 0)
              MxButton(
                label: due > 0
                    ? l10n.studyThisDeckDue(due)
                    : l10n.studyThisDeck,
                icon: AppIcons.play,
                isBlock: true,
                onPressed: onStudy,
              ),
          ],
        ),
      ),
    );
  }
}
