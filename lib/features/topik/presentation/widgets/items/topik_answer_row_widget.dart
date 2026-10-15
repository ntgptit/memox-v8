import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// One answer of screen 38 (critique S5):
/// - "Question {no}";
/// - "Your answer ② · Right answer ③ · 1m 05s", option numbers only
///   (brief 2026-10-15); the eye drops the right answer;
/// - the status as a badge: success, danger, or neutral for a blank
///   (never warning).
///
/// The row opens Review at the question; the badge takes the trailing slot,
/// so it has no chevron (`MxListRow` holds one or the other).
class TopikAnswerRowWidget extends StatelessWidget {
  const TopikAnswerRowWidget({
    super.key,
    required this.answer,
    required this.isRightHidden,
    required this.onOpen,
  });

  final TopikAttemptAnswer answer;
  final bool isRightHidden;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = answer.status ?? TopikAnswerStatus.unanswered;
    final selected = answer.selectedIdx;
    final correct = answer.correctIdx;
    final meta = l10n.topikTerms([
      if (selected == null)
        l10n.topikNotAnswered
      else
        l10n.topikYourAnswer(topikCircled(selected)),
      if (!isRightHidden && correct != null)
        l10n.topikRightAnswer(topikCircled(correct)),
      l10n.duration(answer.timeSpentMs),
    ]);
    return MxListRow(
      title: l10n.topikQuestionTitle(answer.questionNo),
      meta: Text(
        meta,
        style: context.texts.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      trailing: MxBadge(
        label: l10n.topikAnswerStatusName(status),
        tone: switch (status) {
          TopikAnswerStatus.correct => MxBadgeTone.success,
          TopikAnswerStatus.wrong => MxBadgeTone.danger,
          TopikAnswerStatus.unanswered => MxBadgeTone.neutral,
        },
      ),
      onTap: onOpen,
    );
  }
}
