import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Between parts of the summary line.
const String _separator = ' · ';

/// Where the edited card stands (kit 09's history strip): the status as the
/// badge screen 10 shows, then answers, lapses and the due date. It leads to
/// the detail (ruling P4a-L10; audit 2026-10-19, G6).
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
    final status = detail.displayStatus;
    final parts = [
      l10n.cardSummaryAnswers(schedule.answerCount),
      l10n.cardSummaryLapses(schedule.lapseCount),
      if (schedule.dueAt case final dueAt?)
        l10n.cardSummaryDue(DateFormat.MMMd(locale).format(dueAt.toLocal())),
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: context.dimens.space16),
      child: MxCard(
        isFullBleed: true,
        child: MxListRow(
          title: parts.join(_separator),
          leading: MxStatusBadge(
            status: mxCardStatus(status),
            label: l10n.cardStatus(status),
          ),
          hasChevron: true,
          onTap: onOpenDetails,
        ),
      ),
    );
  }
}
