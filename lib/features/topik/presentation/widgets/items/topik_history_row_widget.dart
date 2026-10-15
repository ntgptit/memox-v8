import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// One attempt in History (critique F1, BR-TOPIK-021): "#n" with its status
/// badge, then when, "{score} / {max}", "{correct} / {count} correct" and how
/// long, then its actions as small outline
/// buttons (never primary: one row of many, The One Accent Rule) and the
/// delete button at the end.
class TopikHistoryRowWidget extends StatelessWidget {
  const TopikHistoryRowWidget({
    super.key,
    required this.numbered,
    required this.onSummary,
    required this.onReview,
    required this.onContinue,
    required this.onDelete,
  });

  final TopikNumberedAttempt numbered;
  final VoidCallback onSummary;
  final VoidCallback onReview;
  final VoidCallback onContinue;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final attempt = numbered.attempt;
    final isCompleted = attempt.isCompleted;
    final meta = l10n.topikTerms([
      l10n.topikDateTime(attempt.startedAt),
      if (isCompleted) ...[
        l10n.topikOfTotal(attempt.score ?? 0, attempt.maxScore),
        l10n.topikCorrectOfTotal(
          attempt.correctCount ?? 0,
          attempt.questionCount,
        ),
      ],
      l10n.duration(attempt.totalTimeMs),
    ]);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space16,
        vertical: dimens.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: dimens.space8,
        children: [
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: dimens.space4,
              children: [
                Row(
                  spacing: dimens.space8,
                  children: [
                    Text(
                      l10n.topikAttemptNumber(numbered.number),
                      style: context.texts.titleSmall,
                    ),
                    MxBadge(
                      label: isCompleted
                          ? l10n.topikCompleted
                          : l10n.topikStatusInProgress,
                      tone: isCompleted
                          ? MxBadgeTone.success
                          : MxBadgeTone.neutral,
                    ),
                  ],
                ),
                Text(
                  meta,
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: dimens.space8,
                  runSpacing: dimens.space8,
                  children: [
                    if (isCompleted) ...[
                      MxButton(
                        label: l10n.topikSummary,
                        onPressed: onSummary,
                        tone: MxButtonTone.outline,
                        size: MxButtonSize.small,
                      ),
                      MxButton(
                        label: l10n.topikReview,
                        onPressed: onReview,
                        tone: MxButtonTone.outline,
                        size: MxButtonSize.small,
                      ),
                    ] else
                      MxButton(
                        label: l10n.topikContinue,
                        onPressed: onContinue,
                        tone: MxButtonTone.outline,
                        size: MxButtonSize.small,
                      ),
                  ],
                ),
              ),
              MxIconButton(
                icon: AppIcons.delete,
                semanticLabel: l10n.topikDeleteAttempt,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
