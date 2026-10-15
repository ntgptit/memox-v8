import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_score_donut_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// Screen 38's hero (detail file 38, critique S2, S3): which test, when and
/// how long, then the score in the stat role beside the donut of correct
/// answers. From the attempt's own fields, so it holds when the test is
/// gone (BR-TOPIK-019).
class TopikSummaryHeroWidget extends StatelessWidget {
  const TopikSummaryHeroWidget({
    super.key,
    required this.attempt,
    required this.summary,
  });

  final TopikAttempt attempt;
  final TopikAttemptSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    return MxCard(
      isHero: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: dimens.space16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: dimens.space4,
            children: [
              Text(
                l10n.topikTerms([
                  l10n.topikRoundNumber(attempt.round),
                  l10n.topikLevelName(attempt.level),
                  l10n.topikSectionName(attempt.section),
                ]),
                style: context.texts.titleMedium,
              ),
              Text(
                l10n.topikTerms([
                  l10n.topikDateTime(attempt.startedAt),
                  l10n.duration(attempt.totalTimeMs),
                ]),
                style: context.texts.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Semantics(
            label: l10n.topikScoreLabel(
              summary.score,
              summary.maxScore,
              summary.correctCount,
              summary.questionCount,
            ),
            excludeSemantics: true,
            child: Row(
              spacing: dimens.space16,
              children: [
                Expanded(
                  child: Text(
                    l10n.topikOfTotal(summary.score, summary.maxScore),
                    style: context.texts.displayMedium,
                  ),
                ),
                TopikScoreDonutWidget(
                  correct: summary.correctCount,
                  total: summary.questionCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
