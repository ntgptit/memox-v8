import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// A recent attempt (BR-TOPIK-021): "#n", when, the score, the correct
/// answers and how long; an
/// attempt in progress reads "In progress" and continues.
class TopikRecentAttemptRowWidget extends StatelessWidget {
  const TopikRecentAttemptRowWidget({
    super.key,
    required this.numbered,
    required this.onOpen,
  });

  final TopikNumberedAttempt numbered;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attempt = numbered.attempt;
    final score = attempt.score;
    final meta = l10n.topikTerms([
      l10n.topikDateTime(attempt.startedAt),
      if (!attempt.isCompleted || score == null)
        l10n.topikStatusInProgress
      else ...[
        l10n.topikOfTotal(score, attempt.maxScore),
        l10n.topikCorrectOfTotal(
          attempt.correctCount ?? 0,
          attempt.questionCount,
        ),
        l10n.duration(attempt.totalTimeMs),
      ],
    ]);
    return MxListRow(
      title: l10n.topikAttemptNumber(numbered.number),
      meta: Text(
        meta,
        style: context.texts.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      hasChevron: true,
      onTap: onOpen,
    );
  }
}
