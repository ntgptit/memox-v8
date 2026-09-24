import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';
import 'package:memox/shared/widgets/mx_status_distribution.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

/// A deck of cards at a glance (screen 07, spec A13): its algorithm, how
/// much is mastered, today's work and the cards by display state. Study
/// waits under Coming soon (spec A4).
class CardDeckSummaryWidget extends StatelessWidget {
  const CardDeckSummaryWidget({
    super.key,
    required this.status,
    required this.workload,
    required this.schedulerType,
  });

  final CardStatusCounts status;
  final CardWorkload workload;
  final SchedulerType schedulerType;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final total = status.total;
    // Ruling E-L6: the card feature names the algorithm itself.
    final algorithm = schedulerType == SchedulerType.sm2
        ? l10n.cardSchedulerSm2
        : l10n.cardSchedulerEightBox;
    return MxCard(
      isHero: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          Row(
            spacing: AppSpacing.grouped,
            children: [
              MxMasteryDonut(
                fraction: total == 0 ? 0 : status.mastered / total,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.micro,
                  children: [
                    Text(
                      l10n.cardSummaryOverline(algorithm).toUpperCase(),
                      style: styles.overline,
                    ),
                    Text(
                      l10n.cardSummaryMastered(status.mastered, total),
                      style: styles.rowTitle,
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
          MxStatusDistribution(
            counts: mxStatusCounts(status),
            label: (badge) => l10n.cardStatus(cardDisplayStatusOf(badge)),
          ),
        ],
      ),
    );
  }
}
