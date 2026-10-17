import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

/// Screen 38's figures (critique S1; owner 2026-10-17): the average time per
/// question, answered, unanswered and the longest question, two by two so
/// each label fits one line at 360 dp. The longest names its real number in
/// the label; a time figure with no time is a dash that reads "None".
class TopikSummaryFiguresWidget extends StatelessWidget {
  const TopikSummaryFiguresWidget({super.key, required this.summary});

  final TopikAttemptSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final longest = summary.longest;
    final hasLongest = longest != null && longest.timeSpentMs > 0;
    final averageMs = summary.averageTimeMs;
    Widget tile(String value, String label, {String? semanticValue}) =>
        Expanded(
          child: MxStatTile(
            value: value,
            label: label,
            semanticValue: semanticValue,
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
                averageMs > 0 ? l10n.duration(averageMs) : '–',
                l10n.topikAveragePerQuestion,
                // TalkBack reads a bare dash as "en dash" (Q-P6-5).
                semanticValue: averageMs > 0 ? null : l10n.topikNone,
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
                // TalkBack reads a bare dash as "en dash" (Q-P6-5).
                semanticValue: hasLongest ? null : l10n.topikNone,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
