import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

/// A deck's or a level's workload: overdue · today · new, or the calm line
/// when nothing is due ("3 cards · nothing due", "No cards yet").
class DeckWorkloadLineWidget extends StatelessWidget {
  const DeckWorkloadLineWidget({
    super.key,
    required this.overdueCount,
    required this.todayCount,
    required this.newCount,
    required this.cardCount,
  });

  final int overdueCount;
  final int todayCount;
  final int newCount;

  /// Every card counted, due or not, to word the nothing-due line.
  final int cardCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxWorkloadBreakdownLine(
      overdueCount: overdueCount,
      todayCount: todayCount,
      newCount: newCount,
      overdueLabel: l10n.workloadOverdue,
      todayLabel: l10n.workloadToday,
      newLabel: l10n.workloadNew,
      fallback: cardCount == 0
          ? l10n.workloadNoCards
          : l10n.workloadNothingDue(cardCount),
    );
  }
}
