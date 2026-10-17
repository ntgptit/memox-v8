import 'dart:math';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chart_legend.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';

/// Screen 38's time per question (detail file 38, critique S4):
/// - one bar per question, its height by time, its colour by status;
/// - under each bar a status glyph (check, cross, dash) in the status's text
///   role, a second channel besides colour, and the real number;
/// - it scrolls sideways and fades its edge while more lies past it;
/// - a legend under it names each status's colour.
///
/// Each bar is a control-wide `MxRowInk`; a tap opens that question in
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
    final dimens = context.dimens;
    final l10n = context.l10n;
    final longest = longestAnswerOf(answers);
    final longestMs = longest?.timeSpentMs ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: dimens.space12,
      children: [
        Semantics(
          container: true,
          label: longest == null
              ? l10n.topikChartSummaryNoTime(answers.length)
              : l10n.topikChartSummary(
                  answers.length,
                  longest.questionNo,
                  l10n.duration(longestMs),
                ),
          excludeSemantics: true,
          child: MxScrollFade(
            axis: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                // The cells touch: each bar is centred in its `sizeControl`
                // cell, so at the compact column (328 dp, 6.83 cells) the
                // seventh bar always peeks under the fade (audit
                // 2026-10-17, P2-1).
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final answer in answers)
                    _Bar(
                      answer: answer,
                      share: longestMs == 0
                          ? 0
                          : answer.timeSpentMs / longestMs,
                      onTap: () => onOpen(answer.questionNo),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Colour is not the only cue: each bar carries its status glyph, and
        // the legend says the colours on screen (wireframe 38).
        MxChartLegend(
          series: [
            // In the filter chips' order: Wrong, Unanswered, Correct.
            for (final status in _legendOrder)
              MxBarSeries(
                label: l10n.topikAnswerStatusName(status),
                color: _statusColour(context, status),
              ),
          ],
        ),
      ],
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
      TopikAnswerStatus.correct => context.mxColors.success,
      TopikAnswerStatus.wrong => context.colors.error,
      TopikAnswerStatus.unanswered => context.colors.outline,
    };

/// The glyph under a bar of [status] and its ink: the status's text role.
(IconData, Color) _statusGlyph(
  BuildContext context,
  TopikAnswerStatus status,
) => switch (status) {
  TopikAnswerStatus.correct => (AppIcons.check, context.mxColors.success),
  TopikAnswerStatus.wrong => (AppIcons.close, context.colors.error),
  TopikAnswerStatus.unanswered => (
    AppIcons.remove,
    context.colors.onSurfaceVariant,
  ),
};

class _Bar extends StatelessWidget {
  const _Bar({required this.answer, required this.share, required this.onTap});

  final TopikAttemptAnswer answer;

  /// Its time as a share of the longest.
  final double share;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final status = answer.status ?? TopikAnswerStatus.unanswered;
    final colour = _statusColour(context, status);
    final (glyph, glyphColour) = _statusGlyph(context, status);
    final fullHeight = dimens.sizeControl * 2;
    final radius = BorderRadius.circular(dimens.radiusSm);
    return MxRowInk(
      onTap: onTap,
      borderRadius: radius,
      child: SizedBox(
        width: dimens.sizeControl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: dimens.space4,
          children: [
            SizedBox(
              height: fullHeight,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  key: ValueKey('topik-chart-fill-${answer.questionNo}'),
                  width: dimens.space12,
                  height: max(dimens.space4, fullHeight * share),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colour,
                      borderRadius: BorderRadius.circular(dimens.radiusXs),
                    ),
                  ),
                ),
              ),
            ),
            IconTheme(
              data: IconThemeData(
                color: glyphColour,
                size: dimens.sizeIconButton,
              ),
              child: Icon(glyph),
            ),
            Text(
              '${answer.questionNo}',
              style: context.texts.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
