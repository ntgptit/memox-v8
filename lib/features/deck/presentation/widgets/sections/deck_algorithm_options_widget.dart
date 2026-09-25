import 'package:flutter/widgets.dart';
import 'package:memox/features/deck/presentation/widgets/support/scheduler_type_label_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

/// The two algorithms with what each does (screen 02). Locked, both stay
/// visible and disabled (UC-DECK-002 A1: never hidden); while a switch runs,
/// its row spins and neither can be chosen.
class DeckAlgorithmOptionsWidget extends StatelessWidget {
  const DeckAlgorithmOptionsWidget({
    super.key,
    required this.current,
    required this.isLocked,
    required this.switchingTo,
    required this.onSelected,
  });

  final SchedulerType current;
  final bool isLocked;

  /// The algorithm a running switch moves to; null when none runs.
  final SchedulerType? switchingTo;
  final ValueChanged<SchedulerType> onSelected;

  static String _description(AppLocalizations l10n, SchedulerType type) =>
      switch (type) {
        SchedulerType.eightBox => l10n.algorithmEightBoxDescription,
        SchedulerType.sm2 => l10n.algorithmSm2Description,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const types = SchedulerType.values;
    final isChoosable = !isLocked && switchingTo == null;
    return MxCard(
      isFullBleed: true,
      child: Column(
        children: [
          for (final (index, type) in types.indexed)
            MxOptionRow(
              title: l10n.schedulerType(type),
              description: _description(l10n, type),
              isSelected: type == current,
              onSelected: isChoosable ? () => onSelected(type) : null,
              trailing: type == switchingTo
                  ? MxSpinner(semanticLabel: context.l10n.commonLoading)
                  : null,
              hasDivider: index < types.length - 1,
            ),
        ],
      ),
    );
  }
}
