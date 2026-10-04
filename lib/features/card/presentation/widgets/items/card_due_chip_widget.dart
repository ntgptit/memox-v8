import 'package:flutter/widgets.dart';
import 'package:memox/features/card/domain/models/card_due_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

/// When a card comes back, in its tone (screen 07's due chip, ruling E-L4):
/// overdue in warning, today in primary, new and later neutral.
class CardDueChipWidget extends StatelessWidget {
  const CardDueChipWidget({super.key, required this.due});

  final CardDue due;

  @override
  Widget build(BuildContext context) => MxBadge(
    label: context.l10n.cardDue(due),
    tone: switch (due.kind) {
      CardDueKind.overdue => MxBadgeTone.warning,
      CardDueKind.today => MxBadgeTone.primary,
      CardDueKind.newCard || CardDueKind.later => MxBadgeTone.neutral,
    },
  );
}
