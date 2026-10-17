import 'package:flutter/widgets.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_row.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';

/// All · Wrong · Unanswered · Correct, each with its count in the chip's
/// count slot (screens 38, 39). [isEmptyDisabled] turns off a chip with no
/// question (39, critique V5); 38 lets it show its empty state.
class TopikAnswerFilterChipsWidget extends StatelessWidget {
  const TopikAnswerFilterChipsWidget({
    super.key,
    required this.summary,
    required this.selected,
    required this.onSelected,
    this.isEmptyDisabled = false,
  });

  final TopikAttemptSummary summary;
  final TopikAnswerFilter selected;
  final ValueChanged<TopikAnswerFilter> onSelected;
  final bool isEmptyDisabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The chips never shrink or wrap, so at 360 dp the row scrolls and a
    // cut chip fades at the edge instead of being clipped (audit 2026-10-17
    // TOPIK-2).
    return MxScrollFade(
      axis: Axis.horizontal,
      child: MxChipRow(
        children: [
          for (final filter in TopikAnswerFilter.values)
            _chip(l10n.topikFilterName(filter), filter),
        ],
      ),
    );
  }

  Widget _chip(String label, TopikAnswerFilter filter) {
    final count = summary.answersFor(filter).length;
    final isOff = isEmptyDisabled && count == 0 && filter != selected;
    return MxFilterChip(
      label: label,
      count: count,
      isSelected: filter == selected,
      onSelected: isOff ? null : (_) => onSelected(filter),
    );
  }
}
