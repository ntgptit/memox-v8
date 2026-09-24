import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

/// A card deck's progress (screen 07, spec A13): the mastery donut, the
/// scheduler, how many cards are mastered, today's work (owner decision
/// E-O1), then the four display states as a bar and a legend. Study waits
/// under Coming soon (spec A4, amended).
class CardDeckSummaryWidget extends StatelessWidget {
  const CardDeckSummaryWidget({
    super.key,
    required this.view,
    required this.algorithm,
  });

  final CardListView view;

  /// The deck's scheduler, named ("SM-2", "Eight boxes").
  final String algorithm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final states = view.statusCounts;
    final total = states.total;
    final workload = view.workload;
    final overline = l10n.cardDeckProgress(algorithm);
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
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.micro,
                    children: [
                      Text(
                        overline.toUpperCase(),
                        semanticsLabel: overline,
                        style: styles.overline,
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
            _StatusBar(counts: states),
            Wrap(
              spacing: AppSpacing.control,
              runSpacing: AppSpacing.micro,
              children: [
                for (final (status, count) in _entries(states))
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpacing.micro,
                    children: [
                      MxStatusBadge(
                        status: mxCardStatus(status),
                        label: l10n.cardStatus(status),
                        isDot: true,
                      ),
                      Text(
                        l10n.cardStatusCount(l10n.cardStatus(status), count),
                        style: styles.rowDescription,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static List<(CardDisplayStatus, int)> _entries(CardStatusCounts counts) => [
    (CardDisplayStatus.newCard, counts.newCards),
    (CardDisplayStatus.beginning, counts.beginning),
    (CardDisplayStatus.reviewing, counts.reviewing),
    (CardDisplayStatus.mastered, counts.mastered),
  ];
}

/// The four display states side by side, each as wide as its share. The
/// legend says the same in words, so the bar is not read out.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.counts});

  final CardStatusCounts counts;

  static const double _height = 6;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final fills = [
      (counts.newCards, semantic.statusNew),
      (counts.beginning, semantic.statusLearning),
      (counts.reviewing, semantic.statusReviewing),
      (counts.mastered, semantic.statusMastered),
    ];
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: SizedBox(
          height: _height,
          child: ColoredBox(
            color: context.colors.surfaceContainer,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (count, color) in fills)
                  if (count > 0)
                    Expanded(
                      flex: count,
                      child: ColoredBox(color: color),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
