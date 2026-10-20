import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_line_chart.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';

/// Score trend of screen 36 (follow-ups spec G8): each submitted attempt's
/// score, oldest first, as a line from 0 to the test's maximum. Scores count
/// submitted attempts only (BR-TOPIK-020); one point is not a trend, so the
/// section shows from two (BR-TOPIK-029 starts there too). Best and Average
/// stay the tiles' numbers: no number sits on a point.
class TopikScoreTrendWidget extends StatelessWidget {
  const TopikScoreTrendWidget({super.key, required this.attempts});

  /// The test's attempts, newest first, as the detail holds them.
  final List<TopikNumberedAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final scored = topikScoredAttemptsOf(attempts);
    if (scored.length < 2) return const SizedBox.shrink();
    final l10n = context.l10n;
    final dimens = context.dimens;
    // The test's maximum; a content update could change it between
    // attempts, so the line takes the largest.
    var maxScore = 0;
    for (final numbered in scored) {
      if (numbered.attempt.maxScore > maxScore) {
        maxScore = numbered.attempt.maxScore;
      }
    }
    // A test with no points to score has no scale to draw against.
    if (maxScore == 0) return const SizedBox.shrink();
    final scores = [
      for (final numbered in scored) numbered.attempt.score!.toString(),
    ].join(', ');
    return Padding(
      padding: EdgeInsets.only(top: dimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxListSectionHeader(label: l10n.topikScoreTrend),
          MxCard(
            child: MxLineChart(
              points: [
                for (final numbered in scored)
                  MxLinePoint(
                    value: numbered.attempt.score!.toDouble(),
                    label: l10n.topikAttemptNumber(numbered.number),
                  ),
              ],
              maxValue: maxScore.toDouble(),
              maxLabel: maxScore.toString(),
              ground: MxScrollFadeGround.raised,
              semanticLabel: l10n.topikScoreTrendSummary(
                scored.length,
                scores,
                maxScore,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
