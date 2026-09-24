import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// Between parts of the summary line.
const String _separator = ' · ';

/// Where the edited card stands (kit 09's history strip): status, answers,
/// lapses and the due date. It leads to the detail (ruling P4a-L10).
class CardEditSummaryWidget extends StatelessWidget {
  const CardEditSummaryWidget({
    super.key,
    required this.detail,
    required this.onOpenDetails,
  });

  final CardDetail detail;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final schedule = detail.schedule;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final parts = [
      l10n.cardStatus(detail.displayStatus),
      l10n.cardSummaryAnswers(schedule.answerCount),
      l10n.cardSummaryLapses(schedule.lapseCount),
      if (schedule.dueAt case final dueAt?)
        l10n.cardSummaryDue(DateFormat.MMMd(locale).format(dueAt.toLocal())),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: MxCard(
        isFullBleed: true,
        child: MxListRow(
          title: parts.join(_separator),
          leading: const MxIconTile(icon: AppIcons.clock),
          hasChevron: true,
          onTap: onOpenDetails,
          hasDivider: false,
        ),
      ),
    );
  }
}
