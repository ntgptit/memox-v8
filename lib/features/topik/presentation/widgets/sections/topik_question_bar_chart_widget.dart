import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bar_chart.dart';
import 'package:memox/shared/widgets/mx_chart_legend.dart';

/// Screen 38's time per question (detail file 38, critique S4), on the
/// shared [MxBarChart] (audit 2026-10-19, G4):
/// - one bar per question, its height by time, its colour by status;
/// - under each bar a status glyph (check, cross, dash) in the status's text
///   role, a second channel besides colour, and the real number;
/// - a dashed guide at the longest question carries its time;
/// - it scrolls sideways and fades its edge while more lies past it;
/// - a legend under it names each status's colour.
///
/// Each bar's cell is a control-wide ink; a tap opens that question in
/// Review. TalkBack gets one summary node for the whole chart and none for
/// the bars (owner 2026-10-17, ruling S4): the answer rows below are its
/// way to each question.
class TopikQuestionBarChartWidget extends StatelessWidget {
  const TopikQuestionBarChartWidget({
    super.key,
    required this.answers,
    required this.onOpen,
  });

  final List<TopikAttemptAnswer> answers;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final longest = longestAnswerOf(answers);
    final longestMs = longest?.timeSpentMs ?? 0;
    return MxBarChart(
      semanticLabel: longest == null
          ? l10n.topikChartSummaryNoTime(answers.length)
          : l10n.topikChartSummary(
              answers.length,
              longest.questionNo,
              l10n.duration(longestMs),
            ),
      guideLabel: longest == null ? null : l10n.duration(longestMs),
      onOpen: (index) => onOpen(answers[index].questionNo),
      bars: [for (final answer in answers) _bar(context, answer)],
      // Colour is not the only cue: each bar carries its status glyph, and
      // the legend says the colours on screen (wireframe 38).
      legend: [
        // In the filter chips' order: Wrong, Unanswered, Correct.
        for (final status in _legendOrder)
          MxBarSeries(
            label: l10n.topikAnswerStatusName(status),
            color: _statusColour(context, status),
          ),
      ],
    );
  }

  MxBar _bar(BuildContext context, TopikAttemptAnswer answer) {
    final status = answer.status ?? TopikAnswerStatus.unanswered;
    final (glyph, glyphColour) = _statusGlyph(context, status);
    return MxBar(
      value: answer.timeSpentMs.toDouble(),
      color: _statusColour(context, status),
      label: answer.questionNo.toString(),
      cellKey: ValueKey('topik-chart-cell-${answer.questionNo}'),
      marker: IconTheme(
        data: IconThemeData(
          color: glyphColour,
          size: context.dimens.sizeIconCompact,
        ),
        child: Icon(glyph),
      ),
    );
  }
}

const _legendOrder = [
  TopikAnswerStatus.wrong,
  TopikAnswerStatus.unanswered,
  TopikAnswerStatus.correct,
];

/// The fill of a bar of [status], shared by the bars and the legend.
Color _statusColour(BuildContext context, TopikAnswerStatus status) =>
    switch (status) {
      TopikAnswerStatus.correct => context.status.success,
      TopikAnswerStatus.wrong => context.colors.error,
      TopikAnswerStatus.unanswered => context.colors.border,
    };

/// The glyph under a bar of [status] and its ink: the status's text role.
(IconData, Color) _statusGlyph(
  BuildContext context,
  TopikAnswerStatus status,
) => switch (status) {
  TopikAnswerStatus.correct => (AppIcons.check, context.status.success),
  TopikAnswerStatus.wrong => (AppIcons.close, context.colors.error),
  TopikAnswerStatus.unanswered => (
    AppIcons.remove,
    context.colors.mutedForeground,
  ),
};
