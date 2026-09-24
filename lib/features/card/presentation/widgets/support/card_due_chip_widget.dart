import 'package:flutter/material.dart';
import 'package:memox/features/card/domain/models/card_due_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

/// A card's due chip (screen 07): new and later are neutral, today is
/// primary, overdue is warning.
class CardDueChipWidget extends StatelessWidget {
  const CardDueChipWidget({super.key, required this.due});

  final CardDue due;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, tone) = switch (due.kind) {
      CardDueKind.newCard => (l10n.cardDueNew, MxBadgeTone.neutral),
      CardDueKind.today => (l10n.cardDueToday, MxBadgeTone.primary),
      CardDueKind.later => (l10n.cardDueIn(due.days), MxBadgeTone.neutral),
      CardDueKind.overdue => (
        l10n.cardDueOverdue(due.days),
        MxBadgeTone.warning,
      ),
    };
    return MxBadge(label: label, tone: tone);
  }
}
