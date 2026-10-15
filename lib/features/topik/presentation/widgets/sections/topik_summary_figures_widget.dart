import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

/// Screen 38's figures (critique S1): accuracy, answered, unanswered and the
/// longest question, two by two so each fits one line at 360 dp. The
/// longest names its real number in the label; with no time it is a dash.
class TopikSummaryFiguresWidget extends StatelessWidget {
  const TopikSummaryFiguresWidget({super.key, required this.summary});

  final TopikAttemptSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final longest = summary.longest;
    final hasLongest = longest != null && longest.timeSpentMs > 0;
    Widget tile(String value, String label) => Expanded(
      child: MxStatTile(
        value: value,
        label: label,
        layout: MxStatTileLayout.boxed,
      ),
    );
    return MxCard(
      child: Column(
        spacing: dimens.space16,
        children: [
          Row(
            spacing: dimens.space16,
            children: [
              tile(
                l10n.topikPercent(summary.accuracyPercent),
                l10n.topikAccuracy,
              ),
              tile('${summary.answeredCount}', l10n.topikAnswered),
            ],
          ),
          Row(
            spacing: dimens.space16,
            children: [
              tile('${summary.unansweredCount}', l10n.topikUnanswered),
              tile(
                hasLongest ? l10n.duration(longest.timeSpentMs) : '–',
                hasLongest
                    ? l10n.topikLongestOf(longest.questionNo)
                    : l10n.topikLongest,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
