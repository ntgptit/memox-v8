import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_history_row_widget.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

/// History of screen 36 (BR-TOPIK-018, BR-TOPIK-021): every attempt, newest
/// first, with its actions; none yet is a calm empty state (the FAB stays).
class TopikHistoryWidget extends StatelessWidget {
  const TopikHistoryWidget({
    super.key,
    required this.attempts,
    required this.onOpenAttempt,
    required this.onOpenSummary,
    required this.onOpenReview,
    required this.onDelete,
  });

  final List<TopikNumberedAttempt> attempts;
  final ValueChanged<String> onOpenAttempt;
  final ValueChanged<String> onOpenSummary;
  final ValueChanged<String> onOpenReview;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (attempts.isEmpty) {
      return MxEmptyState(
        icon: AppIcons.history,
        title: l10n.topikNoAttemptsTitle,
        tone: MxEmptyStateTone.neutral,
      );
    }
    // Headed by its count, as Overview's lists are (wireframe 36).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(label: l10n.topikAttemptCount(attempts.length)),
        MxCard(
          isFullBleed: true,
          child: MxDividedColumn(
            children: [
              for (final numbered in attempts)
                TopikHistoryRowWidget(
                  numbered: numbered,
                  onSummary: () => onOpenSummary(numbered.attempt.id),
                  onReview: () => onOpenReview(numbered.attempt.id),
                  onContinue: () => onOpenAttempt(numbered.attempt.id),
                  onDelete: () => onDelete(numbered.attempt.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
