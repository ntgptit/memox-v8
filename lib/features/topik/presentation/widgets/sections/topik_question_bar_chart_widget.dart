import 'dart:math';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chart_legend.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// Screen 38's time per question (detail file 38, critique S4):
/// - one bar per question, its height by time, its colour by status;
/// - the real number under each bar;
/// - it scrolls sideways;
/// - a legend under it names each status's colour.
///
/// Each bar is a control-wide `MxRowInk` with one TalkBack node; a tap opens
/// that question in Review.
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
    final longestMs = answers.fold(0, (most, a) => max(most, a.timeSpentMs));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: dimens.space12,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: dimens.space4,
            children: [
              for (final answer in answers)
                _Bar(
                  answer: answer,
                  share: longestMs == 0 ? 0 : answer.timeSpentMs / longestMs,
                  onTap: () => onOpen(answer.questionNo),
                ),
            ],
          ),
        ),
        // Colour is not the only cue: each bar says its status to TalkBack,
        // and the legend says it on screen (wireframe 38).
        MxChartLegend(
          series: [
            for (final status in TopikAnswerStatus.values)
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

/// The fill of a bar of [status], shared by the bars and the legend.
Color _statusColour(BuildContext context, TopikAnswerStatus status) =>
    switch (status) {
      TopikAnswerStatus.correct => context.mxColors.success,
      TopikAnswerStatus.wrong => context.colors.error,
      TopikAnswerStatus.unanswered => context.colors.outline,
    };

class _Bar extends StatelessWidget {
  const _Bar({required this.answer, required this.share, required this.onTap});

  final TopikAttemptAnswer answer;

  /// Its time as a share of the longest.
  final double share;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final status = answer.status ?? TopikAnswerStatus.unanswered;
    final colour = _statusColour(context, status);
    final fullHeight = dimens.sizeControl * 2;
    final radius = BorderRadius.circular(dimens.radiusSm);
    return MxRowInk(
      onTap: onTap,
      borderRadius: radius,
      child: Semantics(
        label: l10n.topikBarLabel(
          answer.questionNo,
          l10n.topikAnswerStatusName(status),
          l10n.duration(answer.timeSpentMs),
        ),
        excludeSemantics: true,
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
              Text(
                '${answer.questionNo}',
                style: context.texts.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
